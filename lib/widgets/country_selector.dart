// lib/widgets/country_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vpn_provider.dart';
import '../models/vpn_country.dart';
import 'server_node_tile.dart';

class CountrySelector extends StatelessWidget {
  const CountrySelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vpnProvider = Provider.of<VpnProvider>(context);

    if (vpnProvider.isLoadingServers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vpnProvider.availableCountries.isEmpty && vpnProvider.errorMessage == null) {
      return const Center(child: Text("No servers available."));
    }

    if (vpnProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Error: ${vpnProvider.errorMessage}", style: TextStyle(color: Colors.red)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Select Country & Server:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () => vpnProvider.loadServers(refreshPings: true),
                tooltip: "Refresh Pings",
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: vpnProvider.availableCountries.length,
            itemBuilder: (context, index) {
              VpnCountry country = vpnProvider.availableCountries[index];
              bool isCountrySelected = vpnProvider.manuallySelectedCountry?.code == country.code;

              return ExpansionTile(
                key: PageStorageKey(country.code), // To preserve expansion state
                leading: Text(country.flagEmoji, style: const TextStyle(fontSize: 24)),
                title: Text(country.name),
                initiallyExpanded: isCountrySelected,
                onExpansionChanged: (expanded) {
                  if (expanded) {
                    vpnProvider.selectCountryForManualMode(country);
                  } else if (isCountrySelected) {
                    // Optional: clear selection if tile is collapsed by user
                    // vpnProvider.selectCountryForManualMode(null);
                  }
                },
                children: country.nodes.map((node) {
                  // Nodes are already sorted by ping in the provider/service
                  return ServerNodeTile(
                    node: node,
                    isSelected: vpnProvider.selectedServer?.id == node.id,
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}