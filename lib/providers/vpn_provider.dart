// lib/providers/vpn_provider.dart
import 'package:flutter/foundation.dart';
import '../models/server_node.dart';
import '../models/vpn_country.dart';
import '../services/mock_server_service.dart';
import '../services/vpn_connection_service.dart'; // Placeholder

enum VpnConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

enum ServerSelectionMode {
  automatic,
  manual,
}

class VpnProvider with ChangeNotifier {
  final MockServerService _mockServerService = MockServerService();
  final VpnConnectionService _vpnConnectionService = VpnConnectionService(); // Placeholder

  List<VpnCountry> _availableCountries = [];
  List<VpnCountry> get availableCountries => _availableCountries;

  ServerNode? _selectedServer;
  ServerNode? get selectedServer => _selectedServer;

  ServerNode? _connectedServer;
  ServerNode? get connectedServer => _connectedServer;

  VpnConnectionState _connectionState = VpnConnectionState.disconnected;
  VpnConnectionState get connectionState => _connectionState;

  ServerSelectionMode _selectionMode = ServerSelectionMode.automatic;
  ServerSelectionMode get selectionMode => _selectionMode;

  VpnCountry? _manuallySelectedCountry;
  VpnCountry? get manuallySelectedCountry => _manuallySelectedCountry;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoadingServers = false;
  bool get isLoadingServers => _isLoadingServers;

  VpnProvider() {
    _vpnConnectionService.initialize(); // Initialize the placeholder service
    loadServers();
  }

  Future<void> loadServers({bool refreshPings = false}) async {
    _isLoadingServers = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (refreshPings) {
        await _mockServerService.refreshPings();
        // If countries are already loaded, we just need to update them
        // This assumes refreshPings() in MockServerService updates the underlying list it returns.
        // For a more robust way, re-fetch and update.
        _availableCountries = await _mockServerService.getAvailableCountriesWithNodes();
      } else {
        _availableCountries = await _mockServerService.getAvailableCountriesWithNodes();
      }

      // After loading/refreshing, if in automatic mode and not connected/connecting,
      // determine the best server but don't select it yet.
      // The user will press connect.
    } catch (e) {
      _errorMessage = "Failed to load servers: $e";
      _availableCountries = []; // Clear countries on error
    } finally {
      _isLoadingServers = false;
      notifyListeners();
    }
  }

  void setSelectionMode(ServerSelectionMode mode) {
    if (_selectionMode == mode) return;
    _selectionMode = mode;
    _manuallySelectedCountry = null; // Reset country if switching modes
    _selectedServer = null; // Reset specific server selection
    print("Selection mode changed to: $mode");
    notifyListeners();
  }

  void selectCountryForManualMode(VpnCountry country) {
    if (_selectionMode == ServerSelectionMode.manual) {
      _manuallySelectedCountry = country;
      _selectedServer = null; // Reset server selection when country changes
      print("Manual country selected: ${country.name}");
      notifyListeners();
    }
  }

  void selectServer(ServerNode server) {
    _selectedServer = server;
    print("Server selected: ${server.city} - Ping: ${server.currentPing}ms");
    notifyListeners();
  }

  ServerNode? getBestAutomaticNode() {
    if (_availableCountries.isEmpty) return null;

    ServerNode? bestNode;
    int lowestPing = 9999;

    for (var country in _availableCountries) {
      for (var node in country.nodes) {
        if (node.currentPing < lowestPing) {
          lowestPing = node.currentPing;
          bestNode = node;
        }
      }
    }
    return bestNode;
  }

  Future<void> connect() async {
    if (_connectionState == VpnConnectionState.connecting || _connectionState == VpnConnectionState.connected) {
      return;
    }

    _connectionState = VpnConnectionState.connecting;
    _errorMessage = null;
    notifyListeners();

    ServerNode? serverToConnect;

    if (_selectionMode == ServerSelectionMode.automatic) {
      serverToConnect = getBestAutomaticNode();
      if (serverToConnect != null) {
        _selectedServer = serverToConnect; // Update selected server for UI
      }
    } else {
      serverToConnect = _selectedServer;
    }

    if (serverToConnect == null) {
      _errorMessage = "No server selected or available.";
      _connectionState = VpnConnectionState.error;
      notifyListeners();
      return;
    }

    // Actual connection logic using the placeholder service
    try {
      final success = await _vpnConnectionService.connect(serverToConnect);
      if (success) {
        _connectionState = VpnConnectionState.connected;
        _connectedServer = serverToConnect;
      } else {
        _errorMessage = "Failed to connect to ${serverToConnect.city}.";
        _connectionState = VpnConnectionState.error;
        _connectedServer = null;
      }
    } catch (e) {
      _errorMessage = "Connection error: $e";
      _connectionState = VpnConnectionState.error;
      _connectedServer = null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    if (_connectionState != VpnConnectionState.connected && _connectionState != VpnConnectionState.connecting) {
      return;
    }

    _connectionState = VpnConnectionState.disconnecting;
    notifyListeners();

    // Actual disconnection logic
    try {
      await _vpnConnectionService.disconnect();
      _connectionState = VpnConnectionState.disconnected;
      _connectedServer = null;
      // _selectedServer = null; // Optionally clear selected server on disconnect
    } catch (e) {
      _errorMessage = "Disconnection error: $e";
      _connectionState = VpnConnectionState.error; // Or revert to connected if disconnect failed critically
    } finally {
      notifyListeners();
    }
  }
}