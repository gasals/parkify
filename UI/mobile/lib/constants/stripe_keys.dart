class StripeKeys {
  static const String publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );
  static const String merchantIdentifier = String.fromEnvironment(
    'STRIPE_MERCHANT_IDENTIFIER',
    defaultValue: 'merchant.flutter.stripe.test',
  );
  static const String urlScheme = String.fromEnvironment(
    'STRIPE_URL_SCHEME',
    defaultValue: 'parkify',
  );

  static bool get isConfigured => publishableKey.isNotEmpty;
}
