class ApiConfig {
  // Override with:
  // flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081
  // flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8081
  static const String defaultBaseUrl = 'http://172.20.10.7:8081';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8081';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  static const String apiPrefix = '/api/auth';
  static const String clientsPrefix = '/api/clients';
  static const String commandesPrefix = '/api/commandes';
  static const String facturesPrefix = '/api/factures';
  static const String productsPrefix = '/api/produits';
  static const String categoriesPrefix = '/api/categories';
  static const String fournisseursPrefix = '/api/fournisseurs';
  static const String commandesFournisseursPrefix =
      '/api/commandes-fournisseurs';

  // Endpoints
  static const String loginEndpoint = '$apiPrefix/login';
  static const String meEndpoint = '$apiPrefix/me';
  static const String forgotPasswordEndpoint = '$apiPrefix/forgot-password';
  static const String resetPasswordEndpoint = '$apiPrefix/reset-password';
  static const String createPasswordEndpoint = '$apiPrefix/create-password';
  static const String changePasswordEndpoint = '$apiPrefix/change-password';
  static const String updateProfileEndpoint = '$apiPrefix/update-profile';
  static const String allUsersEndpoint = '$apiPrefix/all';

  // Clients endpoints
  static const String createClientEndpoint = '$clientsPrefix/creer';
  static const String listClientsEndpoint = '$clientsPrefix/liste';
  static const String searchClientsEndpoint = '$clientsPrefix/rechercher';
  static const String verifyClientPhoneEndpoint =
      '$clientsPrefix/verifier-telephone';
  static const String updateClientEndpoint = '$clientsPrefix/update';
  static const String clientTypesEndpoint = '$clientsPrefix/types';

  // Commandes endpoints
  static const String listCommandesEndpoint =
      '$commandesPrefix/getAllCommandes';
  static const String createCommandeEndpoint = '$commandesPrefix/creer';

  // Factures endpoints
  static const String facturesAllEndpoint = '$facturesPrefix/all';
  static const String facturesGenerateEndpoint = '$facturesPrefix/generer';

  // Produits endpoints
  static const String productsAllEndpoint = '$productsPrefix/all';
  static const String productsSearchEndpoint = '$productsPrefix/search';
  static const String productsAddEndpoint = '$productsPrefix/add';
  static const String productsLowStockEndpoint = '$productsPrefix/low-stock';

  // Categories endpoints
  static const String categoriesAllEndpoint = '$categoriesPrefix/all';

  // Fournisseurs endpoints
  static const String fournisseursAllEndpoint = '$fournisseursPrefix/all';
  static const String fournisseursActiveEndpoint = '$fournisseursPrefix/active';

  // Commandes fournisseurs endpoints
  static const String commandesFournisseursAllEndpoint =
      '$commandesFournisseursPrefix/All';
  static const String commandesFournisseursArchivedEndpoint =
      '$commandesFournisseursPrefix/archived';
  static const String commandesFournisseursAddEndpoint =
      '$commandesFournisseursPrefix/add';

  // Headers
  static const String contentType = 'application/json';
  static const String authHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 secondes
  static const int receiveTimeout = 30000; // 30 secondes
}
