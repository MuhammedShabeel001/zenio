import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/settings/controller/settings/settings_notifier.dart';
import 'package:zenio/features/settings/presentation/widgets/currency_picker_bottom_sheet.dart';
import 'package:zenio/features/settings/presentation/widgets/settings_item_tile.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/add_transaction_bottom_sheet.dart';
import 'package:zenio/shared/widgets/custom_navigation_bar.dart';

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
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsNotifierProvider);
    final settings = state.settings;
    final currencyCode = ref.watch(currencyCodeProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

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

            // Light Curved Content Sheet (#F7F7F7, Radius: 30)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
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
                            badgeText: '$currencySymbol  $currencyCode',
                            onTap: () {
                              CurrencyPickerBottomSheet.show(context);
                            },
                          ),
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
                            badgeText: settings.defaultWallet,
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
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Exporting CSV data...'),
                                ),
                              );
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
                              final messenger = ScaffoldMessenger.of(context);
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
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('All data cleared'),
                                  ),
                                );
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
                            badgeText: settings.appVersion,
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
