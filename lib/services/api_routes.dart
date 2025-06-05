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
  static const String notifications = '$baseUrl/notification';
  static const String notificationsByType = '$notifications/type';
  static const String notificationsUrgent = '$notifications/urgent';
  static const String notificationsRead = '$notifications/read';
  static const String notificationsMarkAllRead = '$notifications/mark-all-read';
  static const String notificationsLatestUnread = '$notifications/latest-unread';
  static const String notificationsBulkMarkRead = '$notifications/bulk-mark-read';
  static const String notificationsBulkDelete = '$notifications/bulk-delete';
  static const String notificationsAll = '$notifications/all';
  static const String notificationsCount = '$notifications/counts';
  static const String notificationsUnreadCount = '$notifications/unread-count';
  static String notificationDetail(String uuid) => '$notifications/$uuid';
  static String notificationMarkRead(String uuid) => '$notifications/$uuid/read';
  static String notificationMarkUnread(String uuid) => '$notifications/$uuid/unread';
  static String notificationsByTypeFilter(String type) => '$notificationsByType/$type';
  static const String budgets = '$baseUrl/budgets';
  static const String budgetsQuickCreate = '$budgets/quick-create';
  static const String budgetsStatistics = '$budgets/statistics';
  static const String budgetsAlerts = '$budgets/alerts';
  static String budgetDetail(String uuid) => '$budgets/$uuid';
  static String budgetRecalculate(String uuid) => '$budgets/$uuid/recalculate';
  static const String budgetsPeriodTypes = '$budgets/period-types';
  static const String budgetsSummary = '$budgets/summary';
  static const String budgetsTrending = '$budgets/trending';
  static String budgetsByCategory(String categoryUuid) => '$budgets/category/$categoryUuid';

}


