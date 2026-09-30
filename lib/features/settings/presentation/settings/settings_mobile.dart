import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/feedback/presentation/widgets/feedback_bottom_sheet.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/settings/controller/settings/settings_notifier.dart';
import 'package:zenio/features/settings/presentation/widgets/settings_item_tile.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/shared/services/csv_export_service.dart';
import 'package:zenio/shared/services/csv_import_service.dart';
import 'package:zenio/shared/shared.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class SettingsScreenMobile extends ConsumerStatefulWidget {
  const SettingsScreenMobile({
    this.onTabSelected,
    super.key,
  });

  final ValueChanged<int>? onTabSelected;

  @override
  ConsumerState<SettingsScreenMobile> createState() =>
      _SettingsScreenMobileState();
}

class _SettingsScreenMobileState extends ConsumerState<SettingsScreenMobile> {
  bool _isChangingVaultLock = false;
  bool _isTransferringData = false;

  Future<void> _clearAllData() async {
    setState(() => _isTransferringData = true);
    try {
      await ref.read(settingsNotifierProvider.notifier).clearAllData();
      if (!mounted) return;
      ZenioSnackBar.show(
        context,
        message: 'All app data cleared',
        type: ZenioSnackBarType.success,
      );
    } catch (_) {
      if (!mounted) return;
      ZenioSnackBar.show(
        context,
        message: "Couldn't clear all data. Some items may remain; please "
            'try again.',
        type: ZenioSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isTransferringData = false);
    }
  }

  /// Shares all transactions as CSV. [tileContext] anchors the share sheet,
  /// which iPad requires.
  Future<void> _exportTransactions(BuildContext tileContext) async {
    if (_isTransferringData) return;
    final box = tileContext.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _isTransferringData = true);
    try {
      final count = await ref
          .read(csvExportServiceProvider)
          .exportDataToCsv(sharePositionOrigin: origin);
      if (!mounted) return;
      if (count == 0) {
        ZenioSnackBar.show(
          context,
          message: 'No transactions to export yet.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      ZenioSnackBar.show(
        context,
        message: "Couldn't create the export. Please try again.",
        type: ZenioSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isTransferringData = false);
    }
  }

  Future<void> _importTransactions() async {
    if (_isTransferringData) return;
    setState(() => _isTransferringData = true);
    try {
      final result = await ref
          .read(csvImportServiceProvider)
          .pickAndImportCsv(defaultWallet: ref.read(defaultWalletProvider));
      if (result == null) return; // Cancelled.
      await ref.read(homeNotifierProvider.notifier).loadMoneyTrackerData();
      if (!mounted) return;

      final imported = result.imported;
      final skipped = result.skipped;
      final present = result.alreadyPresent;
      final skippedNote = [
        if (present > 0)
          ' ${AppNumberFormat.formatNumber(present)} '
              "${present == 1 ? 'was' : 'were'} already in Zenio.",
        if (skipped > 0)
          ' Skipped ${AppNumberFormat.formatNumber(skipped)} '
              "row${skipped == 1 ? '' : 's'} that couldn't be read.",
      ].join();
      ZenioSnackBar.show(
        context,
        message: imported == 0
            ? 'No transactions found in this file.$skippedNote'
            : 'Imported ${AppNumberFormat.formatNumber(imported)} '
                "transaction${imported == 1 ? '' : 's'}.$skippedNote",
        type: imported == 0
            ? ZenioSnackBarType.warning
            : ZenioSnackBarType.success,
        duration: const Duration(seconds: 4),
      );
    } catch (_) {
      if (!mounted) return;
      ZenioSnackBar.show(
        context,
        message: "Couldn't import that file. Check that it's a CSV "
            'exported from Zenio or a spreadsheet, and try again.',
        type: ZenioSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isTransferringData = false);
    }
  }


  /// Vault Lock asks for the fingerprint, face or device PIN before the Vault
  /// opens. Changing it needs the same check, except that it can always be
  /// turned off on a device without a screen lock, where there is nothing to
  /// check and the Vault could otherwise never be opened.
  Future<void> _setVaultLock({required bool enable}) async {
    setState(() => _isChangingVaultLock = true);
    try {
      final auth = ref.read(biometricServiceProvider);
      final deviceSecured = await auth.isDeviceSupported();
      if (enable && !deviceSecured) {
        if (!mounted) return;
        await DeviceLockDialog.show(
          context,
          message: 'Vault Lock uses your fingerprint, face or screen lock to '
              'protect the Vault. Set up a screen lock in your device '
              'settings first.',
        );
        return;
      }
      if (deviceSecured) {
        final confirmed = await auth.authenticate(
          localizedReason:
              enable ? 'Turn on Vault Lock' : 'Turn off Vault Lock',
        );
        if (!confirmed) return;
      }
      await ref
          .read(settingsNotifierProvider.notifier)
          .setVaultLock(enabled: enable);
      await HapticFeedback.lightImpact();
      if (!mounted) return;
      ZenioSnackBar.show(
        context,
        message: enable ? 'Vault Lock is on' : 'Vault Lock is off',
        type: enable ? ZenioSnackBarType.success : ZenioSnackBarType.info,
      );
    } catch (_) {
      if (!mounted) return;
      ZenioSnackBar.show(
        context,
        message: "Couldn't change Vault Lock. Please try again.",
        type: ZenioSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isChangingVaultLock = false);
    }
  }

  final GlobalKey<PopupMenuButtonState<String>> _currencyMenuKey = GlobalKey();
  final GlobalKey<PopupMenuButtonState<String>> _walletMenuKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsNotifierProvider);
    final settings = state.settings;
    final currencyCode = ref.watch(currencyCodeProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final walletState = ref.watch(walletNotifierProvider);
    final cards = walletState.cards;
    final defaultWallet = ref.watch(defaultWalletProvider);
    final dynamicVersion = ref.watch(appVersionProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Header Title (Exact match to Home, Wallet, Subscriptions, Debts)
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 20),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // White Rounded Settings Body Container
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F2F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      ListView(
                        padding: EdgeInsets.fromLTRB(
                          10,
                          16,
                          10,
                          CustomNavigationBar.reservedHeight(context) + 15,
                        ),
                        children: [
                          // SECTION 1: PREFERENCES
                          _buildSectionHeader('Preferences', isFirst: true),
                          SettingsItemTile(
                            title: 'Primary Currency',
                            icon: currencyCode.toUpperCase() == 'DLR'
                                ? const Center(
                                    child: Text(
                                      r'$',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: ZenioColors.textPrimary,
                                      ),
                                    ),
                                  )
                                : Assets.icons.currency.svg(
                                    width: 24,
                                    height: 24,
                                    colorFilter: const ColorFilter.mode(
                                      ZenioColors.textPrimary,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                            iconBgColor: currencyCode.toUpperCase() == 'DLR'
                                ? const Color(0xFFE8F8F0)
                                : const Color(0xFFFDF3E7),
                            trailing: Theme(
                              data: Theme.of(context).copyWith(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                              ),
                              child: PopupMenuButton<String>(
                                key: _currencyMenuKey,
                                tooltip: 'Select Currency',
                                elevation: 12,
                                shadowColor: Colors.black.withValues(alpha: 0.12),
                                color: Colors.white,
                                surfaceTintColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 190,
                                  maxWidth: 220,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(
                                    color: Color(0xFFE5E5EA),
                                    width: 1.2,
                                  ),
                                ),
                                offset: const Offset(0, 38),
                                onSelected: (String currency) {
                                  ref
                                      .read(settingsNotifierProvider.notifier)
                                      .updatePrimaryCurrency(currency);
                                },
                                itemBuilder: (BuildContext context) => [
                                  PopupMenuItem<String>(
                                    value: 'INR',
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFDF3E7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Text(
                                              '₹',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: ZenioColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'INR',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: ZenioColors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                'Indian Rupee',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: ZenioColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (currencyCode.toUpperCase() == 'INR')
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: ZenioColors.primary,
                                            size: 18,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    enabled: false,
                                    height: 1,
                                    padding: EdgeInsets.zero,
                                    child: Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Color(0xFFF2F2F5),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'DLR',
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE8F8F0),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Text(
                                              r'$',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: ZenioColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'DLR',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: ZenioColors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                'US Dollar',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: ZenioColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (currencyCode.toUpperCase() == 'DLR')
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: ZenioColors.primary,
                                            size: 18,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F2F5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$currencySymbol  $currencyCode',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: ZenioColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: ZenioColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            onTap: () {
                              _currencyMenuKey.currentState?.showButtonMenu();
                            },
                          ),
                          if (cards.length >= 2)
                            SettingsItemTile(
                              title: 'Default Wallet',
                              icon: Assets.icons.wallet.svg(
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  ZenioColors.textPrimary,
                                  BlendMode.srcIn,
                                ),
                              ),
                              iconBgColor: const Color(0xFFE6F3FF),
                              trailing: Theme(
                                data: Theme.of(context).copyWith(
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                ),
                                child: PopupMenuButton<String>(
                                  key: _walletMenuKey,
                                  tooltip: 'Select Default Wallet',
                                  elevation: 12,
                                  shadowColor:
                                      Colors.black.withValues(alpha: 0.12),
                                  color: Colors.white,
                                  surfaceTintColor: Colors.transparent,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 220,
                                    maxWidth: 290,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: const BorderSide(
                                      color: Color(0xFFE5E5EA),
                                      width: 1.2,
                                    ),
                                  ),
                                  offset: const Offset(0, 38),
                                  onSelected: (String walletName) {
                                    ref
                                        .read(settingsNotifierProvider.notifier)
                                        .updateDefaultWallet(walletName);
                                  },
                                  itemBuilder: (BuildContext context) {
                                    final items = <PopupMenuEntry<String>>[];
                                    for (var i = 0; i < cards.length; i++) {
                                      final card = cards[i];
                                      final isSelected = card.bankName
                                              .trim()
                                              .toLowerCase() ==
                                          defaultWallet.trim().toLowerCase();
                                      items.add(
                                        PopupMenuItem<String>(
                                          value: card.bankName,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFE6F3FF),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Assets.icons.wallet.svg(
                                                    width: 16,
                                                    height: 16,
                                                    colorFilter:
                                                        const ColorFilter.mode(
                                                      Color(0xFF007AFF),
                                                      BlendMode.srcIn,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      card.bankName,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            ZenioColors.textPrimary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      '${card.cardType} • $currencySymbol ${AppNumberFormat.formatAmount(card.balance, alwaysShowDecimals: true)}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            ZenioColors.textSecondary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                const Icon(
                                                  Icons.check_circle_rounded,
                                                  color: ZenioColors.primary,
                                                  size: 18,
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                      if (i < cards.length - 1) {
                                        items.add(
                                          const PopupMenuItem<String>(
                                            enabled: false,
                                            height: 1,
                                            padding: EdgeInsets.zero,
                                            child: Divider(
                                              height: 1,
                                              thickness: 1,
                                              color: Color(0xFFF2F2F5),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                    return items;
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F2F5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 130,
                                          ),
                                          child: Text(
                                            defaultWallet,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: ZenioColors.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 16,
                                          color: ZenioColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              onTap: () {
                                _walletMenuKey.currentState?.showButtonMenu();
                              },
                            ),
                          const SizedBox(height: 12),

                          // SECTION 2: SECURITY
                          _buildSectionHeader('Security'),
                          SettingsItemTile(
                            title: 'Vault Lock',
                            icon: Assets.icons.biometric.svg(
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                ZenioColors.textPrimary,
                                BlendMode.srcIn,
                              ),
                            ),
                            iconBgColor: const Color(0xFFE8F8F0),
                            isSwitch: true,
                            switchValue: settings.isBiometricEnabled,
                            onSwitchChanged: _isChangingVaultLock
                                ? null
                                : (value) => _setVaultLock(enable: value),
                          ),
                          const SizedBox(height: 12),

                          // SECTION 3: DATA MANAGEMENT
                          _buildSectionHeader('Data Management'),
                          Builder(
                            builder: (tileContext) => SettingsItemTile(
                              title: 'Export Transactions (CSV)',
                              icon: Assets.icons.export.svg(
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  ZenioColors.textPrimary,
                                  BlendMode.srcIn,
                                ),
                              ),
                              iconBgColor: const Color(0xFFF4ECFB),
                              onTap: () => _exportTransactions(tileContext),
                            ),
                          ),
                          SettingsItemTile(
                            title: 'Import Transactions (CSV)',
                            icon: Assets.icons.import.svg(
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                ZenioColors.textPrimary,
                                BlendMode.srcIn,
                              ),
                            ),
                            iconBgColor: const Color(0xFFE6F3FF),
                            onTap: _importTransactions,
                          ),
                          SettingsItemTile(
                            title: 'Clear All App Data',
                            icon: Assets.icons.delete.svg(
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                ZenioColors.danger,
                                BlendMode.srcIn,
                              ),
                            ),
                            iconBgColor: const Color(0xFFFFEAEA),
                            isDestructive: true,
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  title: const Text(
                                    'Clear All Data',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                  content: const Text(
                                    'This permanently deletes all transactions, wallets, debts, subscriptions, splits and Vault items on this device. It cannot be undone. Export your transactions first if you want to keep them.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: ZenioColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text(
                                        'Clear',
                                        style: TextStyle(
                                          color: ZenioColors.danger,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if ((confirm ?? false) && mounted) {
                                await _clearAllData();
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // SECTION 4: SUPPORT & FEEDBACK
                          _buildSectionHeader('Support & Feedback'),
                          SettingsItemTile(
                            title: 'Send Feedback',
                            icon: Assets.icons.feedback.svg(
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                ZenioColors.textPrimary,
                                BlendMode.srcIn,
                              ),
                            ),
                            iconBgColor: const Color(0xFFFDF3E7),
                            trailing: Assets.icons.rightArrow.svg(
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                ZenioColors.textSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                            onTap: () => FeedbackBottomSheet.show(context),
                          ),
                          // SettingsItemTile(
                          //   title: 'Contact support',
                          //   icon: Assets.icons.support.svg(
                          //     width: 24,
                          //     height: 24,
                          //     colorFilter: const ColorFilter.mode(
                          //       ZenioColors.textPrimary,
                          //       BlendMode.srcIn,
                          //     ),
                          //   ),
                          //   iconBgColor: const Color(0xFFE6F3FF),
                          //   badgeText: settings.supportEmail,
                          // ),
                          SettingsItemTile(
                            title: 'Version',
                            icon: Assets.icons.info.svg(
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                ZenioColors.textPrimary,
                                BlendMode.srcIn,
                              ),
                            ),
                            badgeText: dynamicVersion.isNotEmpty
                                ? dynamicVersion
                                : (settings.appVersion.isNotEmpty
                                    ? settings.appVersion
                                    : 'v 2.0.0'),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isFirst = false}) {
    return Padding(
      padding: EdgeInsets.only(
        left: 6,
        top: isFirst ? 0 : 6,
        bottom: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ZenioColors.textSecondary,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
