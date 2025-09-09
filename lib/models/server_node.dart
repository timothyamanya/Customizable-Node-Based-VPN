// lib/models/server_node.dart
class ServerNode {
  final String id;
  final String countryCode; // e.g., "US"
  final String countryName; // e.g., "United States"
  final String city;
  final String ipAddress; // For display or connection config
  int currentPing; // Simulated ping in ms

  ServerNode({
    required this.id,
    required this.countryCode,
    required this.countryName,
    required this.city,
    required this.ipAddress,
    this.currentPing = 999, // Default high ping
  });

  // For easy comparison and sorting
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ServerNode && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}