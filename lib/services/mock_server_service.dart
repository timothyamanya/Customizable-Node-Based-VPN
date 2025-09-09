// lib/services/mock_server_service.dart
import 'dart:math';
import '../models/server_node.dart';
import '../models/vpn_country.dart';

class MockServerService {
  final Random _random = Random();
  List<VpnCountry> _countries = [];

  Future<List<VpnCountry>> getAvailableCountriesWithNodes() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (_countries.isNotEmpty) {
      // Simulate ping updates on subsequent calls
      _updatePings();
      return _countries;
    }

    _countries = [
      VpnCountry(
        name: "United States",
        code: "US",
        flagEmoji: "🇺🇸",
        nodes: [
          ServerNode(id: "us1", countryCode: "US", countryName: "United States", city: "New York", ipAddress: "192.0.2.1", currentPing: _random.nextInt(100) + 20),
          ServerNode(id: "us2", countryCode: "US", countryName: "United States", city: "Los Angeles", ipAddress: "192.0.2.2", currentPing: _random.nextInt(100) + 50),
          ServerNode(id: "us3", countryCode: "US", countryName: "United States", city: "Chicago", ipAddress: "192.0.2.3", currentPing: _random.nextInt(100) + 40),
        ],
      ),
      VpnCountry(
        name: "Germany",
        code: "DE",
        flagEmoji: "🇩🇪",
        nodes: [
          ServerNode(id: "de1", countryCode: "DE", countryName: "Germany", city: "Frankfurt", ipAddress: "198.51.100.1", currentPing: _random.nextInt(100) + 30),
          ServerNode(id: "de2", countryCode: "DE", countryName: "Germany", city: "Berlin", ipAddress: "198.51.100.2", currentPing: _random.nextInt(100) + 40),
        ],
      ),
      VpnCountry(
        name: "Japan",
        code: "JP",
        flagEmoji: "🇯🇵",
        nodes: [
          ServerNode(id: "jp1", countryCode: "JP", countryName: "Japan", city: "Tokyo", ipAddress: "203.0.113.1", currentPing: _random.nextInt(100) + 80),
          ServerNode(id: "jp2", countryCode: "JP", countryName: "Japan", city: "Osaka", ipAddress: "203.0.113.2", currentPing: _random.nextInt(100) + 90),
        ],
      ),
      VpnCountry(
        name: "Singapore",
        code: "SG",
        flagEmoji: "🇸🇬",
        nodes: [
          ServerNode(id: "sg1", countryCode: "SG", countryName: "Singapore", city: "Singapore", ipAddress: "203.0.113.80", currentPing: _random.nextInt(100) + 70),
        ],
      ),
    ];
    _updatePings(); // Initial sort
    return _countries;
  }

  void _updatePings() {
    for (var country in _countries) {
      for (var node in country.nodes) {
        // Simulate ping fluctuation
        node.currentPing = _random.nextInt(150) + 20; // Pings between 20ms and 170ms
      }
      // Sort nodes by ping within each country
      country.nodes.sort((a, b) => a.currentPing.compareTo(b.currentPing));
    }
  }

  // Call this to simulate ping refreshes
  Future<void> refreshPings() async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate delay
    _updatePings();
  }
}