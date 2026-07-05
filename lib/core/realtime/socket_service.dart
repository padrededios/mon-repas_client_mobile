import 'package:socket_io_client/socket_io_client.dart' as io;

import '../api/api_config.dart';

/// Client Socket.IO (namespace `/events`, auth par token JWT), reconnexion
/// auto, pause/reprise pilotées par le cycle de vie de l'app.
class SocketService {
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect({
    required String token,
    required void Function(String event, dynamic data) onEvent,
  }) {
    disconnect();
    final socket = io.io(
      ApiConfig.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .disableAutoConnect()
          .build(),
    );
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
