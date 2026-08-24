class Api {
  static const String baseUrl = 'http://132.154.156.82:5999';

  // Auth
  static const String login  = '/api/auth/login';
  static const String logout = '/api/auth/logout';

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
  static const String dashboardSummary  = '/api/dashboard/summary';
  static const String dashboardPayments = '/api/dashboard/payments';

  // Pledge
  static const String pledgeList   = '/api/pledge/';
  static const String createPledge = '/api/pledge/';
  static String pledgeDetail(int id) => '/api/pledge/$id';
  static String pledgePay(int id)    => '/api/pledge/$id/pay';
  static String pledgeCancel(int id) => '/api/pledge/$id/cancel';

  // Donor
  static const String donorList          = '/api/donor/';
  static String donorDetail(int id)      => '/api/donor/$id';

  // Dashboard (extended)
  static const String dashboardCollectors = '/api/dashboard/collectors';
  static const String dashboardEvents     = '/api/dashboard/events';

  // Token
  static const String generateToken = '/api/token/generate';
  static const String tokenList     = '/api/token/list';

  // Attendance (test feature)
  static const String attendSubmit = '/test/attend';
}
