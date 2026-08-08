import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/settings/controller/settings/settings_notifier.dart';
import 'package:zenio/features/settings/presentation/widgets/settings_item_tile.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Header Title
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Light Curved Content Sheet
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7F9),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                  child: Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                        children: [
                          // SECTION 1: PREFERENCES
                          _buildSectionHeader('Preferences'),
                          SettingsItemTile(
                            title: 'Primary Currency',
                            icon: Assets.icons.currency.svg(
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF111111),
                                BlendMode.srcIn,
                              ),
                            ),
                            badgeText: '₹  ${settings.primaryCurrency}',
                          ),
                          SettingsItemTile(
                            title: 'Default Wallet',
                            icon: Assets.icons.wallet.svg(
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF111111),
                                BlendMode.srcIn,
                              ),
                            ),
                            badgeText: settings.defaultWallet,
                          ),
                          const SizedBox(height: 16),

                          // SECTION 2: SECURITY
                          _buildSectionHeader('Security'),
                          SettingsItemTile(
                            title: 'Biometric Lock',
                            icon: Assets.icons.biometric.svg(
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF111111),
                                BlendMode.srcIn,
                              ),
                            ),
                            isSwitch: true,
                            switchValue: settings.isBiometricEnabled,
                            onSwitchChanged: (val) {
                              ref
                                  .read(settingsNotifierProvider.notifier)
                                  .toggleBiometric(val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // SECTION 3: DATA MANAGEMENT
                          _buildSectionHeader('Data Management'),
                          SettingsItemTile(
                            title: 'Export Data (CSV)',
                            icon: Assets.icons.export.svg(
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF111111),
                                BlendMode.srcIn,
                              ),
                            ),
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
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFD0021B),
                                BlendMode.srcIn,
                              ),
                            ),
                            iconBgColor: const Color(0xFFFDE8E8),
                            isDestructive: true,
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Clear All Data'),
                                  content: const Text(
                                    'Are you sure you want to clear all app data? This action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text(
                                        'Clear',
                                        style: TextStyle(color: Colors.red),
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
                          const SizedBox(height: 16),

                          // SECTION 4: SUPPORT & FEEDBACK
                          _buildSectionHeader('Support & Feedback'),
                          SettingsItemTile(
                            title: 'Send Feedback',
                            icon: Assets.icons.feedback.svg(
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF111111),
                                BlendMode.srcIn,
                              ),
                            ),
                            trailing: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEAEAEA),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  '>',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF777777),
                                  ),
                                ),
                              ),
                            ),
                            onTap: () {},
                          ),
                          SettingsItemTile(
                            title: 'Contact support',
                            icon: Assets.icons.support.svg(
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF111111),
                                BlendMode.srcIn,
                              ),
                            ),
                            badgeText: settings.supportEmail,
                          ),
                          SettingsItemTile(
                            title: 'Version',
                            icon: Assets.icons.info.svg(
                              width: 20,
                              height: 20,
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
                          onAddTap: () {},
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFFA0A0A5),
        ),
      ),
    );
  }
}
