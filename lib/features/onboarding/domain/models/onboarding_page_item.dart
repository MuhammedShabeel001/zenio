import 'package:zenio/shared/utils/assets.gen.dart';

class OnboardingPageItem {
  const OnboardingPageItem({
    required this.image,
    required this.title,
    required this.subtitle,
  });

  final AssetGenImage image;
  final String title;
  final String subtitle;

  static List<OnboardingPageItem> get pages => [
        OnboardingPageItem(
          image: Assets.images.page1Png,
          title: 'Find Your Financial Zen',
          subtitle:
              'Take a deep breath. Effortlessly track your expenses, manage your wealth, and find clarity in one beautiful place.',
        ),
        OnboardingPageItem(
          image: Assets.images.page2Png,
          title: 'Clarity at a Glance',
          subtitle:
              'Manage multiple wallets, log daily transactions in seconds, and watch your spending habits transform into beautiful visual insights.',
        ),
        OnboardingPageItem(
          image: Assets.images.page3Png,
          title: 'Bills & Friends, Handled',
          subtitle:
              'Never stress over awkward bill splits, forgotten debts, or sneaky subscription charges again. Zenio keeps everything perfectly balanced.',
        ),
        OnboardingPageItem(
          image: Assets.images.page4Png,
          title: 'Build Your Vault',
          subtitle:
              'Set meaningful savings goals and watch your money grow. Ready to master your finances with Zenio?',
        ),
      ];
}
