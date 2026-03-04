class ApiConfig {
  // Changez cette URL selon votre environnement
  //static const String baseUrl = 'http://localhost:8081'; // Pour web
  static const String baseUrl = 'http://172.20.10.7:8081';
  
  static const String apiPrefix = '/api/auth';
  static const String clientsPrefix = '/api/clients';
  
  // Endpoints
  static const String loginEndpoint = '$apiPrefix/login';
  static const String meEndpoint = '$apiPrefix/me';
  static const String forgotPasswordEndpoint = '$apiPrefix/forgot-password';
  static const String resetPasswordEndpoint = '$apiPrefix/reset-password';
  static const String createPasswordEndpoint = '$apiPrefix/create-password';
  static const String changePasswordEndpoint = '$apiPrefix/change-password';
  static const String allUsersEndpoint = '$apiPrefix/all';

  // Clients endpoints
  static const String createClientEndpoint = '$clientsPrefix/creer';
  static const String listClientsEndpoint = '$clientsPrefix/liste';
  static const String searchClientsEndpoint = '$clientsPrefix/rechercher';
  static const String verifyClientPhoneEndpoint = '$clientsPrefix/verifier-telephone';
  static const String updateClientEndpoint = '$clientsPrefix/update';
  static const String clientTypesEndpoint = '$clientsPrefix/types';
  
  // Headers
  static const String contentType = 'application/json';
  static const String authHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
  
  // Timeouts
  static const int connectionTimeout = 30000; // 30 secondes
  static const int receiveTimeout = 30000; // 30 secondes
}
