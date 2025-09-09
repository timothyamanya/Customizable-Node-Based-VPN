// lib/widgets/connect_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';

class ConnectButton extends StatelessWidget {
  const ConnectButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vpnProvider = Provider.of<VpnProvider>(context);

    String buttonText = "CONNECT";
    Color buttonColor = Colors.green;
    VoidCallback? onPressed = () => vpnProvider.connect();

    switch (vpnProvider.connectionState) {
      case VpnConnectionState.disconnected:
        buttonText = "CONNECT";
        buttonColor = Colors.blue;
        onPressed = () => vpnProvider.connect();
        if (vpnProvider.selectionMode == ServerSelectionMode.manual && vpnProvider.selectedServer == null) {
          onPressed = null; // Disable if manual and no server selected
        }
        break;
      case VpnConnectionState.connecting:
        buttonText = "CONNECTING...";
        buttonColor = Colors.orange;
        onPressed = null; // Disable while connecting
        break;
      case VpnConnectionState.connected:
        buttonText = "DISCONNECT";
        buttonColor = Colors.red;
        onPressed = () => vpnProvider.disconnect();
        break;
      case VpnConnectionState.disconnecting:
        buttonText = "DISCONNECTING...";
        buttonColor = Colors.orange.shade700;
        onPressed = null; // Disable while disconnecting
        break;
      case VpnConnectionState.error:
        buttonText = "RETRY";
        buttonColor = Colors.blueGrey;
        onPressed = () => vpnProvider.connect(); // Or a more specific retry logic
        if (vpnProvider.selectionMode == ServerSelectionMode.manual && vpnProvider.selectedServer == null) {
          onPressed = null;
        }
        break;
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        textStyle: const TextStyle(fontSize: 18, color: Colors.white),
        foregroundColor: Colors.white,
      ),
      onPressed: onPressed,
      child: Text(buttonText),
    );
  }
}