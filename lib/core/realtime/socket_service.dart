import 'package:socket_io_client/socket_io_client.dart' as io;

import '../api/api_config.dart';

/// Client Socket.IO (namespace `/events`, auth par token JWT), reconnexion
/// auto, pause/reprise pilotées par le cycle de vie de l'app.
class SocketService {
  io.Socket? _socket;

  /// Refus consécutifs du jeton par le serveur avant d'abandonner.
  static const maxAuthRetries = 3;

  bool get isConnected => _socket?.connected ?? false;

  /// [token] est relu à chaque (re)connexion : après un rafraîchissement de
  /// session, le socket présente le jeton courant et non l'expiré. Quand le
  /// serveur refuse le jeton il coupe la connexion : [refreshSession] est
  /// alors appelé avant de se reconnecter.
  void connect({
    required String? Function() token,
    required void Function(String event, dynamic data) onEvent,
    Future<bool> Function()? refreshSession,
  }) {
    disconnect();
    final socket = io.io(
      ApiConfig.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .disableAutoConnect()
          .build(),
    );
    // Fonction d'auth : appelée par socket_io_client à chaque connexion.
    socket.auth = (void Function(dynamic) send) => send({'token': token()});

    var authRetries = 0;
    socket.on('connected', (_) => authRetries = 0);
    socket.on('disconnect', (reason) async {
      if (reason != 'io server disconnect' ||
          refreshSession == null ||
          authRetries >= maxAuthRetries) {
        return;
      }
      authRetries++;
      final refreshed = await refreshSession();
      if (refreshed && identical(_socket, socket)) socket.connect();
    });

    socket.onAny((event, data) => onEvent(event, data));
    socket.connect();
    _socket = socket;
  }

  /// App en arrière-plan : on coupe la connexion sans jeter le socket.
  void pause() => _socket?.disconnect();

  /// Retour au premier plan : reconnexion (l'UI refait ses fetchs à côté).
  void resume() => _socket?.connect();

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
