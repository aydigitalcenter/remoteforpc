# Remote Mouse

Control your macOS computer from your iPhone or Android device. A Flutter-based Remote Mouse application with a macOS server and mobile controller.

## Features

- **Mouse Control**: Move cursor, click, and scroll using your phone's touchscreen
- **Keyboard Input**: Type text from your mobile device
- **Media Controls**: Play/pause, volume control, and track navigation
- **Secure Pairing**: PIN-based authentication
- **Network Discovery**: Automatic server discovery using mDNS/Bonjour
- **Low Latency**: UDP for mouse movements, WebSocket for everything else

## Project Structure

```
remoteforpc/              # Mobile controller app (iOS & Android)
  lib/
    screens/              # Discovery, pairing, controller screens
    services/             # Connection and discovery services
    widgets/              # Trackpad and UI widgets

macos_server/             # macOS server application
  lib/
    services/             # WebSocket, UDP, input control
    models/               # State management
  macos/Runner/           # Swift platform channels

packages/remote_protocol/ # Shared message definitions
```

## Getting Started

### macOS Server

**Prerequisites:**
- macOS 10.15 or later
- Flutter SDK installed
- Xcode command line tools

**Setup:**

1. Navigate to the server directory:
   ```bash
   cd macos_server
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the server:
   ```bash
   flutter run -d macos
   ```

4. **Grant Accessibility Permission:**
   - When first launched, click on "Grant Accessibility" in the menu bar
   - Go to System Preferences > Privacy & Security > Accessibility
   - Enable the checkbox for "macos_server"

5. **Note the PIN:**
   - The 6-digit PIN is displayed in the menu bar
   - You'll need this PIN to pair your mobile device

**Build standalone app:**
```bash
flutter build macos --release
```

The app will be located at: `build/macos/Build/Products/Release/macos_server.app`

### Mobile App

**Prerequisites:**
- Flutter SDK installed
- iOS device/simulator or Android device/emulator

**Setup:**

1. From the project root:
   ```bash
   flutter pub get
   ```

2. Run on your device:
   ```bash
   # For iOS
   flutter run -d ios

   # For Android
   flutter run -d android
   ```

3. **Connect to Server:**
   - Ensure your mobile device is on the same WiFi network as your Mac
   - The app will automatically discover the server
   - Tap on the discovered server
   - Enter the 6-digit PIN from the server's menu bar
   - Start controlling your Mac!

## How to Use

### Trackpad Gestures
- **One finger drag**: Move mouse cursor
- **Single tap**: Left click
- **Long press**: Right click
- **Two finger drag**: Scroll

### Media Controls
- Use the top bar for play/pause, track navigation, and volume control

### Keyboard
- Tap the keyboard icon in the app bar to show/hide the keyboard
- Type text and press Enter to send

## Development

### Testing
```bash
# Test mobile app
flutter test

# Test server
cd macos_server && flutter test
```

### Debugging
```bash
# Enable verbose logging
flutter run -v

# Monitor network traffic
sudo tcpdump -i any port 8080 or port 8081
```

## Architecture

- **Mobile App**: Flutter (Dart) - iOS & Android
- **Server**: Flutter Desktop (Dart) + Swift platform channels
- **Communication**: 
  - WebSocket (port 8080) for control commands
  - UDP (port 8081) for mouse movements
  - mDNS for service discovery

## Troubleshooting

**Server not discovered:**
- Check that both devices are on the same WiFi network
- Some corporate/guest WiFi networks block mDNS
- Try manually entering the server IP address

**Mouse/keyboard not working:**
- Ensure Accessibility permission is granted
- Restart the server application
- Check that the PIN was entered correctly

**Connection drops:**
- Check WiFi signal strength
- Ensure macOS isn't sleeping
- Check firewall settings

## License

This project is open source and available under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
