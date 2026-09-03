class Api {
  static const String baseUrl = 'http://132.154.156.82:5999';

  /// Absolute URL for a media path returned by the backend (e.g. "/media/avatars/x.jpg").
  static String media(String path) =>
      path.startsWith('http') ? path : '$baseUrl${path.startsWith('/') ? '' : '/'}$path';

  // Auth
  static const String login  = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String me     = '/api/auth/me';

  // Collector
  static const String collectorEvents   = '/api/collector/events';
  static const String collectorSummary  = '/api/collector/summary';
  static const String collectorPayments = '/api/collector/payments';

  // Payment
  static const String initiatePayment = '/api/payment/initiate';
  static String confirmUpi(int id)    => '/pay/qr/$id/confirm';
  static String confirmCash(int id)   => '/pay/cash/$id/confirm';
  static String confirmCheque(int id) => '/pay/cheque/$id/confirm';
  static String cancelPayment(int id) => '/pay/qr/$id/cancel';
  static String receipt(int id)       => '/api/payment/receipt/$id';

  // Dashboard
  static const String dashboardSummary    = '/api/dashboard/summary';
  static const String dashboardPayments   = '/api/dashboard/payments';
  static const String dashboardCollectors = '/api/dashboard/collectors';
  static const String dashboardEvents     = '/api/dashboard/events';
  static String eventReport(int id)       => '/api/dashboard/event-report/$id';

  // Pledge
  static const String pledgeList   = '/api/pledge/';
  static const String createPledge = '/api/pledge/';
  static String pledgeDetail(int id) => '/api/pledge/$id';
  static String pledgePay(int id)    => '/api/pledge/$id/pay';
  static String pledgeCancel(int id) => '/api/pledge/$id/cancel';

  // Donor
  static const String donorList     = '/api/donor/';
  static String donorDetail(int id) => '/api/donor/$id';

  // Token
  static const String generateToken = '/api/token/generate';
  static const String bulkToken     = '/api/token/bulk';
  static const String tokenList     = '/api/token/list';
  static String voidToken(String no) => '/api/token/$no/void';
  static const String tokenConfig      = '/api/admin/token-config';
  static const String tokenConfigReset = '/api/admin/token-config/reset';

  // Users
  static const String users       = '/api/users/';
  static String user(int id)      => '/api/users/$id';
  static String userLoginQr(int id) => '/api/users/$id/login-qr';
  static const String myAvatar    = '/api/users/me/avatar';

  // Admin config
  static const String adminConfig = '/api/admin/config';

  // Events
  static const String events         = '/api/events/';
  static const String activeEvents   = '/api/events/active';
  static String event(int id)        => '/api/events/$id';
  static String eventSummary(int id) => '/api/events/$id/summary';

  // Budgets
  static const String budgets           = '/api/budgets/';
  static const String budgetAllSummary  = '/api/budgets/all-summary';
  static const String budgetReport      = '/api/budgets/report';
  static String budget(int id)          => '/api/budgets/$id';

  // Expenses
  static const String expenses   = '/api/expenses/';
  static String expense(int id)  => '/api/expenses/$id';

  // Announcements
  static const String announcements     = '/api/announcements/';
  static String announcement(int id)    => '/api/announcements/$id';

  // Committee
  static const String committee        = '/api/committee/';
  static String committeeMember(int id) => '/api/committee/$id';

  // Contact queries
  static const String contactQueries      = '/api/contact/queries';
  static String contactQuery(int id)      => '/api/contact/queries/$id';
  static String contactQueryStatus(int id) => '/api/contact/queries/$id/status';

  // Attendance (staff-facing JSON API)
  static const String attendanceSession   = '/api/attendance/session';
  static const String attendanceSessions  = '/api/attendance/sessions';
  static const String attendanceQr        = '/api/attendance/session/qr.png';
  static const String attendanceReset     = '/api/attendance/session/reset';
  static const String attendanceRecords   = '/api/attendance/records';
  static const String attendanceHistory   = '/api/attendance/history';
}
