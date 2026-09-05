import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/settings/controller/settings/settings_notifier.dart';
import 'package:zenio/features/settings/presentation/widgets/settings_item_tile.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/providers/default_wallet_provider/default_wallet_provider.dart';
import 'package:zenio/shared/providers/package_info_provider/package_info_provider.dart';
import 'package:zenio/shared/services/csv_export_service.dart';
import 'package:zenio/shared/services/csv_import_service.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/add_transaction_bottom_sheet.dart';
import 'package:zenio/shared/widgets/custom_navigation_bar.dart';
import 'package:zenio/shared/widgets/zenio_snack_bar.dart';

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
                        padding: const EdgeInsets.fromLTRB(10, 16, 10, 120),
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
                                        color: Color(0xFF111111),
                                      ),
                                    ),
                                  )
                                : Assets.icons.currency.svg(
                                    width: 24,
                                    height: 24,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFF111111),
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
                                                color: Color(0xFF111111),
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
                                                  color: Color(0xFF111111),
                                                ),
                                              ),
                                              Text(
                                                'Indian Rupee',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF8E8E93),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (currencyCode.toUpperCase() == 'INR')
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Color(0xFF10B981),
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
                                                color: Color(0xFF10B981),
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
                                                  color: Color(0xFF111111),
                                                ),
                                              ),
                                              Text(
                                                'US Dollar',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF8E8E93),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (currencyCode.toUpperCase() == 'DLR')
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Color(0xFF10B981),
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
                                          color: Color(0xFF8E8E93),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: Color(0xFF8E8E93),
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
                                  Color(0xFF111111),
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
                                                            Color(0xFF111111),
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      '${card.cardType} • $currencySymbol ${NumberFormat('#,##0.00').format(card.balance)}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Color(0xFF8E8E93),
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
                                                  color: Color(0xFF10B981),
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
                                              color: Color(0xFF8E8E93),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 16,
                                          color: Color(0xFF8E8E93),
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
                            title: 'Biometric Lock',
                            icon: Assets.icons.biometric.svg(
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF111111),
                                BlendMode.srcIn,
                              ),
                            ),
                            iconBgColor: const Color(0xFFE8F8F0),
                            isSwitch: true,
                            switchValue: settings.isBiometricEnabled,
                            onSwitchChanged: (val) {
                              ref
                                  .read(settingsNotifierProvider.notifier)
                                  .toggleBiometric(val);
                            },
                          ),
                          const SizedBox(height: 12),

                          // SECTION 3: DATA MANAGEMENT
                          _buildSectionHeader('Data Management'),
                          SettingsItemTile(
                            title: 'Export Data (CSV)',
                            icon: Assets.icons.export.svg(
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF111111),
                                BlendMode.srcIn,
                              ),
                            ),
                            iconBgColor: const Color(0xFFF4ECFB),
                            onTap: () async {
                              ZenioSnackBar.show(
                                context,
                                message: 'Preparing CSV export...',
                                duration: const Duration(milliseconds: 1500),
                              );
                              try {
                                await ref
                                    .read(csvExportServiceProvider)
                                    .exportDataToCsv();
                              } catch (e) {
                                if (context.mounted) {
                                  ZenioSnackBar.show(
                                    context,
                                    message: 'Failed to export data: $e',
                                    type: ZenioSnackBarType.error,
                                  );
                                }
                              }
                            },
                          ),
                          SettingsItemTile(
                            title: 'Import Data (CSV)',
                            icon: Assets.icons.import.svg(
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF111111),
                                BlendMode.srcIn,
                              ),
                            ),
                            iconBgColor: const Color(0xFFE6F3FF),
                            onTap: () async {
                              try {
                                final count = await ref
                                    .read(csvImportServiceProvider)
                                    .pickAndImportCsv();
                                if (count == null) {
                                  return;
                                }
                                await ref
                                    .read(homeNotifierProvider.notifier)
                                    .loadMoneyTrackerData();
                                await ref
                                    .read(walletNotifierProvider.notifier)
                                    .loadWalletData();

                                if (context.mounted) {
                                  ZenioSnackBar.show(
                                    context,
                                    message:
                                        'Successfully imported $count transaction${count == 1 ? '' : 's'}!',
                                    type: ZenioSnackBarType.success,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ZenioSnackBar.show(
                                    context,
                                    message: 'Failed to import data: $e',
                                    type: ZenioSnackBarType.error,
                                  );
                                }
                              }
                            },
                          ),
                          SettingsItemTile(
                            title: 'Clear All App Data',
                            icon: Assets.icons.delete.svg(
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFDD3D34),
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
                                    'Are you sure you want to clear all app data? This action cannot be undone.',
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
                                          color: Color(0xFF8E8E93),
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
                                          color: Color(0xFFDD3D34),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if ((confirm ?? false) && mounted) {
                                await ref
                                    .read(settingsNotifierProvider.notifier)
                                    .clearAllData();
                                if (context.mounted) {
                                  ZenioSnackBar.show(
                                    context,
                                    message: 'All app data cleared',
                                  );
                                }
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
                                Color(0xFF111111),
                                BlendMode.srcIn,
                              ),
                            ),
                            iconBgColor: const Color(0xFFFDF3E7),
                            trailing: Assets.icons.rightArrow.svg(
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF8E8E93),
                                BlendMode.srcIn,
                              ),
                            ),
                            onTap: () {},
                          ),
                          SettingsItemTile(
                            title: 'Contact support',
                            icon: Assets.icons.support.svg(
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF111111),
                                BlendMode.srcIn,
                              ),
                            ),
                            iconBgColor: const Color(0xFFE6F3FF),
                            badgeText: settings.supportEmail,
                          ),
                          SettingsItemTile(
                            title: 'Version',
                            icon: Assets.icons.info.svg(
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF111111),
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

                      // Floating Navigation Bar (Selected Index = 3)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: CustomNavigationBar(
                          selectedIndex: 3,
                          onTabSelected: (index) {
                            widget.onTabSelected?.call(index);
                          },
                          onAddTap: () {
                            AddTransactionBottomSheet.show(context);
                          },
                        ),
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
          color: Color(0xFF8E8E93),
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
