// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/connect_button.dart';
import '../widgets/country_selector.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vpnProvider = Provider.of<VpnProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reaver VPN'),
        actions: [
          // Profile menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) async {
              if (value == 'logout') {
                // Show confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  await authProvider.signOut();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(authProvider.username ?? authProvider.user?.email ?? 'User'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
          // Refresh button
          if (vpnProvider.selectionMode == ServerSelectionMode.automatic && !vpnProvider.isLoadingServers)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => vpnProvider.loadServers(refreshPings: true),
              tooltip: "Refresh Server Pings",
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Connection Status
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Status: ${vpnProvider.connectionState.toString().split('.').last.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: vpnProvider.connectionState == VpnConnectionState.connected
                            ? Colors.green
                            : vpnProvider.connectionState == VpnConnectionState.error
                            ? Colors.red
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (vpnProvider.connectedServer != null)
                      Text(
                        'Connected to: ${vpnProvider.connectedServer!.city}, ${vpnProvider.connectedServer!.countryName}',
                        textAlign: TextAlign.center,
                      )
                    else if (vpnProvider.selectionMode == ServerSelectionMode.automatic && vpnProvider.connectionState == VpnConnectionState.disconnected)
                      Text(
                        'Mode: Automatic (Best Server)',
                        textAlign: TextAlign.center,
                      )
                    else if (vpnProvider.selectedServer != null && vpnProvider.connectionState == VpnConnectionState.disconnected)
                        Text(
                          'Selected: ${vpnProvider.selectedServer!.city}, ${vpnProvider.selectedServer!.countryName} (Ping: ${vpnProvider.selectedServer!.currentPing}ms)',
                          textAlign: TextAlign.center,
                        )
                      else if (vpnProvider.connectionState == VpnConnectionState.connecting && vpnProvider.selectedServer != null)
                          Text(
                            'Connecting to: ${vpnProvider.selectedServer!.city}...',
                            textAlign: TextAlign.center,
                          )
                        else
                          Text(
                            'Not Connected',
                            textAlign: TextAlign.center,
                          ),
                    if (vpnProvider.errorMessage != null && vpnProvider.connectionState == VpnConnectionState.error)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Error: ${vpnProvider.errorMessage}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Connect Button
            const ConnectButton(),
            const SizedBox(height: 20),

            // Mode Selector (Automatic / Manual)
            SegmentedButton<ServerSelectionMode>(
              segments: const <ButtonSegment<ServerSelectionMode>>[
                ButtonSegment<ServerSelectionMode>(
                    value: ServerSelectionMode.automatic,
                    label: Text('Automatic'),
                    icon: Icon(Icons.settings_ethernet)),
                ButtonSegment<ServerSelectionMode>(
                    value: ServerSelectionMode.manual,
                    label: Text('Manual'),
                    icon: Icon(Icons.list)),
              ],
              selected: <ServerSelectionMode>{vpnProvider.selectionMode},
              onSelectionChanged: (Set<ServerSelectionMode> newSelection) {
                vpnProvider.setSelectionMode(newSelection.first);
              },
              showSelectedIcon: false,
            ),
            const SizedBox(height: 10),

            // Server List Area (Conditional based on mode)
            if (vpnProvider.selectionMode == ServerSelectionMode.automatic)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.public_outlined, size: 60, color: Theme.of(context).primaryColor),
                      const SizedBox(height: 10),
                      const Text(
                        'Automatic mode will select the best server for you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      if (vpnProvider.isLoadingServers)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        )
                      else if (vpnProvider.getBestAutomaticNode() != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Optimal Server: ${vpnProvider.getBestAutomaticNode()!.city} (${vpnProvider.getBestAutomaticNode()!.currentPing}ms)",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        )
                    ],
                  ),
                ),
              )
            else // Manual Mode
              const Expanded(
                child: CountrySelector(),
              ),
          ],
        ),
      ),
    );
  }
}