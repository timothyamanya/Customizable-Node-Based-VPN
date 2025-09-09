# Reaver VPN App Documentation

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Reaver VPN Application                      │
├─────────────────────────────────────────────────────────────────┤
│  Presentation Layer (UI)                                      │
│  ├── Login Screen                                             │
│  ├── Home Screen                                              │
│  ├── Register Screen                                          │
│  └── Widgets (Connect Button, Country Selector)              │
├─────────────────────────────────────────────────────────────────┤
│  Business Logic Layer (Providers)                             │
│  ├── AuthProvider (Authentication State Management)           │
│  └── VpnProvider (VPN Connection & Server Management)        │
├─────────────────────────────────────────────────────────────────┤
│  Service Layer                                                │
│  ├── AuthService (Firebase Authentication)                    │
│  ├── MockServerService (Server Data Management)              │
│  └── VpnConnectionService (VPN Connection Logic)             │
├─────────────────────────────────────────────────────────────────┤
│  Data Layer                                                   │
│  ├── Firebase Firestore (User Data)                          │
│  ├── Firebase Auth (Authentication)                           │
│  └── Local Storage (Secure Storage)                          │
└─────────────────────────────────────────────────────────────────┘
```

## System Flow Chart

```
START
  │
  ▼
┌─────────────────┐
│   App Launch    │
└─────────────────┘
  │
  ▼
┌─────────────────┐
│ Check Auth      │
│ State           │
└─────────────────┘
  │
  ├─ Authenticated ──► ┌─────────────────┐
  │                    │   Home Screen   │
  │                    └─────────────────┘
  │                             │
  │                             ▼
  │                    ┌─────────────────┐
  │                    │ Load VPN        │
  │                    │ Servers         │
  │                    └─────────────────┘
  │                             │
  │                             ▼
  │                    ┌─────────────────┐
  │                    │ Select Mode     │
  │                    │ (Auto/Manual)   │
  │                    └─────────────────┘
  │                             │
  │                             ▼
  │                    ┌─────────────────┐
  │                    │ Connect/        │
  │                    │ Disconnect      │
  │                    └─────────────────┘
  │
  └─ Not Authenticated ──► ┌─────────────────┐
                           │  Login Screen   │
                           └─────────────────┘
                                    │
                                    ▼
                           ┌─────────────────┐
                           │ User Login/     │
                           │ Registration    │
                           └─────────────────┘
                                    │
                                    ▼
                           ┌─────────────────┐
                           │ Firebase Auth   │
                           │ Validation      │
                           └─────────────────┘
```

## Code Breakdown

### 1. Main Application Entry Point

**File: `lib/main.dart`**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VpnProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Reaver VPN',
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}
```

### 2. Authentication System

**File: `lib/providers/auth_provider.dart`**
```dart
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  String? _username;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _user != null;
  
  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _authService.signInWithEmailAndPassword(email, password);
      await _fetchUsername();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### 3. Firebase Authentication Service

**File: `lib/services/auth_service.dart`**
```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password, String username) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'isPremium': false,
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }
}
```

### 4. VPN Connection Management

**File: `lib/providers/vpn_provider.dart`**
```dart
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
  final VpnConnectionService _vpnConnectionService = VpnConnectionService();

  Future<void> loadServers({bool refreshPings = false}) async {
    _isLoadingServers = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      if (refreshPings) {
        await _mockServerService.refreshPings();
      }
      _availableCountries = await _mockServerService.getAvailableCountriesWithNodes();
    } catch (e) {
      _errorMessage = "Failed to load servers: $e";
    } finally {
      _isLoadingServers = false;
      notifyListeners();
    }
  }

  Future<void> connect() async {
    if (_connectionState == VpnConnectionState.connecting || 
        _connectionState == VpnConnectionState.connected) {
      return;
    }

    _connectionState = VpnConnectionState.connecting;
    _errorMessage = null;
    notifyListeners();

    ServerNode? serverToConnect;
    
    if (_selectionMode == ServerSelectionMode.automatic) {
      serverToConnect = getBestAutomaticNode();
    } else {
      serverToConnect = _selectedServer;
    }

    try {
      final success = await _vpnConnectionService.connect(serverToConnect);
      if (success) {
        _connectionState = VpnConnectionState.connected;
        _connectedServer = serverToConnect;
      } else {
        _errorMessage = "Failed to connect to ${serverToConnect.city}.";
        _connectionState = VpnConnectionState.error;
      }
    } catch (e) {
      _errorMessage = "Connection error: $e";
      _connectionState = VpnConnectionState.error;
    } finally {
      notifyListeners();
    }
  }
}
```

### 5. Server Management System

**File: `lib/services/mock_server_service.dart`**
```dart
class MockServerService {
  final Random _random = Random();
  List<VpnCountry> _countries = [];

  Future<List<VpnCountry>> getAvailableCountriesWithNodes() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_countries.isNotEmpty) {
      _updatePings();
      return _countries;
    }

    _countries = [
      VpnCountry(
        name: "United States",
        code: "US",
        flagEmoji: "🇺🇸",
        nodes: [
          ServerNode(id: "us1", countryCode: "US", countryName: "United States", 
                    city: "New York", ipAddress: "192.0.2.1", 
                    currentPing: _random.nextInt(100) + 20),
          ServerNode(id: "us2", countryCode: "US", countryName: "United States", 
                    city: "Los Angeles", ipAddress: "192.0.2.2", 
                    currentPing: _random.nextInt(100) + 50),
        ],
      ),
      VpnCountry(
        name: "Germany",
        code: "DE",
        flagEmoji: "🇩🇪",
        nodes: [
          ServerNode(id: "de1", countryCode: "DE", countryName: "Germany", 
                    city: "Frankfurt", ipAddress: "198.51.100.1", 
                    currentPing: _random.nextInt(100) + 30),
        ],
      ),
    ];
    _updatePings();
    return _countries;
  }

  void _updatePings() {
    for (var country in _countries) {
      for (var node in country.nodes) {
        node.currentPing = _random.nextInt(150) + 20;
      }
      country.nodes.sort((a, b) => a.currentPing.compareTo(b.currentPing));
    }
  }
}
```

### 6. Login Screen Implementation

**File: `lib/screens/login_screen.dart`**
```dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.vpn_lock,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      if (auth.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await auth.signIn(
                              _emailController.text.trim(),
                              _passwordController.text,
                            );
                            if (auth.error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(auth.error!),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### 7. Home Screen with Logout Functionality

**File: `lib/screens/home_screen.dart`**
```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vpnProvider = Provider.of<VpnProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reaver VPN'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) async {
              if (value == 'logout') {
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
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
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
                      else
                          Text(
                            'Not Connected',
                            textAlign: TextAlign.center,
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const ConnectButton(),
            const SizedBox(height: 20),
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
            else
              const Expanded(
                child: CountrySelector(),
              ),
          ],
        ),
      ),
    );
  }
}
```

### 8. Connect Button Widget

**File: `lib/widgets/connect_button.dart`**
```dart
class ConnectButton extends StatelessWidget {
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
          onPressed = null;
        }
        break;
      case VpnConnectionState.connecting:
        buttonText = "CONNECTING...";
        buttonColor = Colors.orange;
        onPressed = null;
        break;
      case VpnConnectionState.connected:
        buttonText = "DISCONNECT";
        buttonColor = Colors.red;
        onPressed = () => vpnProvider.disconnect();
        break;
      case VpnConnectionState.disconnecting:
        buttonText = "DISCONNECTING...";
        buttonColor = Colors.orange.shade700;
        onPressed = null;
        break;
      case VpnConnectionState.error:
        buttonText = "RETRY";
        buttonColor = Colors.blueGrey;
        onPressed = () => vpnProvider.connect();
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
```

## Firebase Integration

### Dependencies
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  flutter_secure_storage: ^9.0.0
  crypto: ^3.0.3
```

### Firebase Services Used
1. **Firebase Authentication**: Email/password authentication
2. **Cloud Firestore**: User profile storage
3. **Secure Storage**: Auth token management

## Server Management

### Automatic vs Manual Mode

**Automatic Mode:**
- Automatically selects best server based on ping
- No user intervention required
- Real-time ping updates
- Optimal performance selection

**Manual Mode:**
- User selects specific country and server
- Full control over server selection
- Detailed server information display
- Ping information for each server

### Server Data Structure
```dart
class ServerNode {
  final String id;
  final String countryCode;
  final String countryName;
  final String city;
  final String ipAddress;
  int currentPing;

  ServerNode({
    required this.id,
    required this.countryCode,
    required this.countryName,
    required this.city,
    required this.ipAddress,
    this.currentPing = 999,
  });
}
```

## Overall System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           REAVER VPN APPLICATION                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐        │
│  │   UI Layer      │    │  State Mgmt     │    │  Service Layer  │        │
│  │                 │    │                 │    │                 │        │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │        │
│  │ │Login Screen │ │    │ │AuthProvider │ │    │ │AuthService  │ │        │
│  │ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │        │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │        │
│  │ │Home Screen  │ │◄──►│ │VpnProvider  │ │◄──►│ │VpnService   │ │        │
│  │ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │        │
│  │ ┌─────────────┐ │    │                 │    │ ┌─────────────┐ │        │
│  │ │Widgets      │ │    │                 │    │ │ServerService│ │        │
│  │ └─────────────┘ │    │                 │    │ └─────────────┘ │        │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘        │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐        │
│  │   Firebase      │    │   Local Storage │    │   Mock Data     │        │
│  │   Backend       │    │                 │    │                 │        │
│  │                 │    │                 │    │                 │        │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │        │
│  │ │Firebase Auth│ │    │ │Secure Storage│ │    │ │Server Nodes │ │        │
│  │ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │        │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │        │
│  │ │Firestore    │ │    │ │Shared Prefs │ │    │ │Ping Data    │ │        │
│  │ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │        │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Key Features Summary

1. **Authentication System**
   - Firebase Authentication integration
   - User registration and login
   - Password reset functionality
   - Secure token storage

2. **VPN Connection Management**
   - Automatic and manual server selection
   - Real-time ping monitoring
   - Connection state management
   - Error handling and retry logic

3. **Server Management**
   - Mock server data with realistic ping simulation
   - Country-based server organization
   - Automatic best server selection
   - Manual server selection with detailed information

4. **User Interface**
   - Material Design 3 theming
   - Responsive layout
   - Loading states and error handling
   - Intuitive navigation

5. **State Management**
   - Provider pattern implementation
   - Centralized state management
   - Reactive UI updates
   - Persistent state handling

## Technical Specifications

### Dependencies
- **Flutter SDK**: ^3.7.0
- **Provider**: ^6.0.0 (State Management)
- **Firebase Core**: ^2.24.2
- **Firebase Auth**: ^4.15.3
- **Cloud Firestore**: ^4.13.6
- **Flutter Secure Storage**: ^9.0.0
- **Crypto**: ^3.0.3 (Password Hashing)

### Architecture Patterns
- **Provider Pattern**: State management
- **Service Layer Pattern**: Business logic separation
- **Repository Pattern**: Data access abstraction
- **MVVM Pattern**: Model-View-ViewModel structure

### Security Features
- Secure token storage
- Password hashing
- Firebase security rules
- Input validation
- Error handling 