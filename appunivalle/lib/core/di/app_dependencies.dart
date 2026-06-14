/// Composition root (raiz de dependencias) de la app.
///
/// Construye y cablea, en un solo lugar, los objetos de larga vida: storage,
/// [ApiClient] y repositorios. Tambien resuelve la URL base inicial leyendola
/// de [ServerConfigStore] (o el default de compilacion) y centraliza el
/// cambio de servidor en caliente.
///
/// Se crea una vez en `main()` (es async porque lee storage) y se pasa al
/// arbol de widgets.
library;

import '../config/env.dart';
import '../config/server_config_store.dart';
import '../network/api_client.dart';
import '../network/token_storage.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/postulaciones/data/postulaciones_repository.dart';
import '../../features/archivos/data/archivos_repository.dart';
import '../../features/catalogos/data/modalidades_repository.dart';
import '../../features/catalogos/data/tutores_repository.dart';
import '../../features/catalogos/data/carreras_repository.dart';
import '../../features/notificaciones/data/notificaciones_repository.dart';

class AppDependencies {
  AppDependencies._({
    required this.tokenStorage,
    required this.serverConfigStore,
    required this.apiClient,
    required this.authRepository,
    required this.postulacionesRepository,
    required this.archivosRepository,
    required this.tutoresRepository,
    required this.modalidadesRepository,
    required this.carrerasRepository,
    required this.notificacionesRepository,
  });

  final TokenStorage tokenStorage;
  final ServerConfigStore serverConfigStore;
  final ApiClient apiClient;
  final AuthRepository authRepository;
  final PostulacionesRepository postulacionesRepository;
  final ArchivosRepository archivosRepository;
  final TutoresRepository tutoresRepository;
  final ModalidadesRepository modalidadesRepository;
  final CarrerasRepository carrerasRepository;
  final NotificacionesRepository notificacionesRepository;

  /// Construye el grafo de dependencias.
  ///
  /// Lee la URL base persistida; si no hay, usa [ApiConfig.defaultBaseUrl].
  /// El handler de 401 se conecta luego con [setUnauthorizedHandler], cuando
  /// ya existe el controlador de sesion.
  static Future<AppDependencies> create() async {
    final tokenStorage = TokenStorage();
    final serverConfigStore = ServerConfigStore();

    final guardada = await serverConfigStore.readBaseUrl();
    final baseInicial =
        (guardada != null && guardada.isNotEmpty) ? guardada : ApiConfig.defaultBaseUrl;

    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      serverBaseUrl: baseInicial,
    );
    final authRepository = AuthRepository(
      dio: apiClient.dio,
      tokenStorage: tokenStorage,
    );
    final postulacionesRepository =
        PostulacionesRepository(dio: apiClient.dio);
    final archivosRepository = ArchivosRepository(dio: apiClient.dio);
    final tutoresRepository = TutoresRepository(dio: apiClient.dio);
    final modalidadesRepository = ModalidadesRepository(dio: apiClient.dio);
    final carrerasRepository = CarrerasRepository(dio: apiClient.dio);
    final notificacionesRepository = NotificacionesRepository(dio: apiClient.dio);

    return AppDependencies._(
      tokenStorage: tokenStorage,
      serverConfigStore: serverConfigStore,
      apiClient: apiClient,
      authRepository: authRepository,
      postulacionesRepository: postulacionesRepository,
      archivosRepository: archivosRepository,
      tutoresRepository: tutoresRepository,
      modalidadesRepository: modalidadesRepository,
      carrerasRepository: carrerasRepository,
      notificacionesRepository: notificacionesRepository,
    );
  }

  /// Conecta el handler de 401 (token rechazado) al cliente HTTP.
  void setUnauthorizedHandler(void Function()? handler) =>
      apiClient.onUnauthorized = handler;

  /// URL base del servidor en uso (sin el prefijo `/api/v1`).
  String get serverBaseUrl => apiClient.serverBaseUrl;

  /// Cambia el servidor destino: lo persiste y lo aplica en caliente.
  Future<void> setServerBaseUrl(String serverBaseUrl) async {
    final limpio = serverBaseUrl.trim();
    await serverConfigStore.saveBaseUrl(limpio);
    apiClient.updateServerBaseUrl(limpio);
  }

  /// Vuelve al servidor por defecto de compilacion (borra el guardado).
  Future<void> resetServerBaseUrl() async {
    await serverConfigStore.clear();
    apiClient.updateServerBaseUrl(ApiConfig.defaultBaseUrl);
  }
}
