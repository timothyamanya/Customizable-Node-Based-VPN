// lib/models/vpn_country.dart
import 'server_node.dart';

class VpnCountry {
  final String name;
  final String code; // e.g., "US"
  final String flagEmoji; // For simple display
  List<ServerNode> nodes;

  VpnCountry({
    required this.name,
    required this.code,
    required this.flagEmoji,
    required this.nodes,
  });
}