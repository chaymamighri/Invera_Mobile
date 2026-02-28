class ApiConfig {
  // Changez cette URL selon votre environnement
  //static const String baseUrl = 'http://localhost:8081'; // Pour web
  static const String baseUrl = 'http://192.168.56.1:8081';
  
  static const String apiPrefix = '/api/auth';
  
  // Endpoints
  static const String loginEndpoint = '$apiPrefix/login';
  static const String meEndpoint = '$apiPrefix/me';
  static const String forgotPasswordEndpoint = '$apiPrefix/forgot-password';
  static const String resetPasswordEndpoint = '$apiPrefix/reset-password';
  static const String changePasswordEndpoint = '$apiPrefix/change-password';
  static const String allUsersEndpoint = '$apiPrefix/all';
  
  // Headers
  static const String contentType = 'application/json';
  static const String authHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
  
  // Timeouts
  static const int connectionTimeout = 30000; // 30 secondes
  static const int receiveTimeout = 30000; // 30 secondes
}