class ApiRoutes {
  static const String baseUrl = 'http://192.168.5.248:8001/api';
  static String registerUrl = '$baseUrl/register';
  static String loginUrl = '$baseUrl/login';
  static String otpUrl = '$baseUrl/otp';
  static String verifyUrl = '$baseUrl/verify';
  static String logoutUrl = '$baseUrl/logout';
  static String resetOtpUrl = '$baseUrl/reset/otp';
  static String resetPasswordUrl = '$baseUrl/reset/password';
  static String currencyUrl = '$baseUrl/currency';
  static String accountTypeUrl = '$baseUrl/account-type';
  static String accountUrl = '$baseUrl/account';
  static String categoryUrl = '$baseUrl/category';
  static String transactionUrl = '$baseUrl/transaction';
  static String transferUrl = '$baseUrl/transaction/currency-transfer';
  static String profileUrl = '$baseUrl/profile';
  static String updatePasswordUrl= '$baseUrl/profile/password';
  static String notificationUrl = '$baseUrl/notification';
  static String settingsUrl = '$baseUrl/settings';
  static String budgetUrl = '$baseUrl/budget';
  static String googleSignUpUrl = '$baseUrl/google-signup';
  static String googleLoginUrl = '$baseUrl/google-login';

}
