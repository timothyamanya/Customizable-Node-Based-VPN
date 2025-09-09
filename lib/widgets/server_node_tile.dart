// lib/widgets/server_node_tile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/server_node.dart';
import '../providers/vpn_provider.dart';

class ServerNodeTile extends StatelessWidget {
  final ServerNode node;
  final bool isSelected;

  const ServerNodeTile({
    Key? key,
    required this.node,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vpnProvider = Provider.of<VpnProvider>(context, listen: false);
    final bool isConnectedToThisNode = vpnProvider.connectedServer?.id == node.id;

    return ListTile(
      leading: Icon(
        Icons.public,
        color: isConnectedToThisNode ? Colors.green : Theme.of(context).iconTheme.color,
      ),
      title: Text('${node.city} (${node.countryCode})'),
      subtitle: Text('IP: ${node.ipAddress}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${node.currentPing} ms'),
          const SizedBox(width: 8),
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
          ),
        ],
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
      onTap: () {
        vpnProvider.selectServer(node);
      },
    );
  }
}