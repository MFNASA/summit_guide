class ApiConfig {
  static const String baseUrl =
      'https://summiteguide.vercel.app';

  // AUTH
  static const String googleLogin = '$baseUrl/api/auth/google';
  static const String emailRegister = '$baseUrl/api/auth/register';
  static const String emailLogin = '$baseUrl/api/auth/login';

  // OTP
  static const String verifyOtp = '$baseUrl/api/auth/verify-otp';
  static const String resendOtp = '$baseUrl/api/auth/resend-otp';
  // MOUNTAINS
  static const String mountainsEndpoint = '$baseUrl/api/mountains';
  //TICKETS
  static const String tickets = '$baseUrl/api/tickets/book';
  static const String myTickets = '$baseUrl/api/tickets/my';
  //CUACA
  static const String weather = '$baseUrl/api/weather/forecast';
  static const String weatherByCoordinates = '$baseUrl/api/weather/history';
  static const String weatherHistory = '$baseUrl/api/user/profile';
  static const String updateProfile = '$baseUrl/api/rental/my';
}