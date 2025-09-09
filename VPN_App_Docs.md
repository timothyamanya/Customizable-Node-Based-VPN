# Reaver VPN App Documentation

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Reaver VPN Application                      │
├─────────────────────────────────────────────────────────────────┤
│  UI Layer: Login, Home, Register Screens + Widgets           │
├─────────────────────────────────────────────────────────────────┤
│  Providers: AuthProvider, VpnProvider (State Management)     │
├─────────────────────────────────────────────────────────────────┤
│  Services: AuthService, MockServerService, VpnConnection     │
├─────────────────────────────────────────────────────────────────┤
│  Data: Firebase Auth, Firestore, Local Storage              │
└─────────────────────────────────────────────────────────────────┘
```

## System Flow

```
App Launch → Check Auth → Login Screen (if not authenticated)
                    ↓
              Home Screen (if authenticated)
                    ↓
              Load VPN Servers
                    ↓
              Select Mode (Auto/Manual)
                    ↓
              Connect/Disconnect
```

## Code Breakdown

### 1. Main App Entry (`lib/main.dart`)
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
```

### 2. Authentication System

**AuthProvider (`lib/providers/auth_provider.dart`):**
- Manages user authentication state
- Handles login/logout operations
- Stores user data and session

**AuthService (`lib/services/auth_service.dart`):**
- Firebase Authentication integration
- User registration and login
- Secure token storage
- Password reset functionality

### 3. VPN Management

**VpnProvider (`lib/providers/vpn_provider.dart`):**
- Manages VPN connection states
- Handles server selection (Automatic/Manual)
- Controls connection/disconnection
- Error handling and retry logic

**MockServerService (`lib/services/mock_server_service.dart`):**
- Provides mock server data
- Simulates ping times
- Manages server list updates

### 4. UI Components

**Login Screen (`lib/screens/login_screen.dart`):**
- Email/password input
- Form validation
- Loading states
- Error handling

**Home Screen (`lib/screens/home_screen.dart`):**
- Connection status display
- Mode selector (Auto/Manual)
- Logout functionality
- Server information

**Connect Button (`lib/widgets/connect_button.dart`):**
- Dynamic button states
- Color-coded actions
- Disabled states during transitions

## Firebase Integration

### Dependencies
```yaml
firebase_core: ^2.24.2
firebase_auth: ^4.15.3
cloud_firestore: ^4.13.6
flutter_secure_storage: ^9.0.0
```

### Services Used
1. **Firebase Authentication**: User login/registration
2. **Cloud Firestore**: User profile storage
3. **Secure Storage**: Auth token management

## Server Management

### Automatic Mode
- Automatically selects best server based on ping
- No user intervention required
- Real-time ping updates

### Manual Mode
- User selects specific country and server
- Full control over server selection
- Detailed server information display

## Key Features

1. **Authentication**: Complete Firebase integration
2. **VPN Management**: Auto/Manual server selection
3. **UI/UX**: Material Design 3 with responsive layout
4. **State Management**: Provider pattern implementation
5. **Security**: Secure storage and proper authentication

## Technical Stack

- **Framework**: Flutter 3.7.0
- **State Management**: Provider 6.0.0
- **Backend**: Firebase (Auth + Firestore)
- **Security**: Flutter Secure Storage
- **Architecture**: MVVM with Service Layer 