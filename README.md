# RAKSHA: Women's Safety Ecosystem

RAKSHA is a mobile and hardware-integrated women's safety ecosystem. It provides real-time emergency detection, high-accuracy live location tracking, and automated guardian notification capabilities. The system consists of a Flutter mobile application, a Bluetooth Low Energy (BLE) smart shoe wearable, and a Firebase-based backend.

## System Architecture

The ecosystem consists of three main components:

1. **Flutter Mobile Application**: A cross-platform mobile client built using Flutter (target SDK 3.5.0+). State management is handled via Riverpod, and navigation is managed using GoRouter.
2. **RAKSHA Smart Shoe (Wearable)**: A BLE-enabled hardware device equipped with an accelerometer, gyroscope, heel pressure (FSR) sensor, and GPS module.
3. **Backend Services**: Hosted on Firebase, utilizing Firebase Authentication, Firestore Database, Firebase Cloud Messaging (FCM), and TypeScript Cloud Functions.

## Core Features

### BLE Smart Shoe Integration
The mobile app connects to the RAKSHA Shoe via Bluetooth Low Energy using the `flutter_blue_plus` package.
- **Auto-Discovery**: The app automatically scans for and connects to devices advertising with the name `RAKSHA_SHOE`.
- **Sensor Data Parsing**: Subscribes to the characteristic `6e400003-b5a3-f393-e0a9-e50e24dcca9e` of service `6e400001-b5a3-f393-e0a9-e50e24dcca9e` to parse incoming JSON telemetry packets.
- **Telemetry Data**: Collects heel pressure (FSR), 3-axis accelerometer values (g), 3-axis gyroscope values (deg/s), GPS status, and device battery level.

### Live Location Tracking
During an active emergency, the application streams real-time location coordinates to Firestore:
- **Tracking Rate**: Updates are published every 5 seconds to the Firestore subcollection `emergencies/{emergencyId}/locations/{userId}`.
- **Multi-Role Tracking**: Supports location streaming for both the victim and responding guardians.

### Geolocation Fallback System
To handle scenarios where GPS is disabled or lacks a satellite fix, the system implements a runtime fallback:
- **Developer Coordinates**: Configured at compile time using environment variables.
- **Automatic Fallback**: The Geolocator service automatically switches to compile-time fallback coordinates when high-accuracy live GPS fixes fail.

### Automated Guardian Notifications
A background Firestore trigger handles automated alarm dispatch:
- **Trigger**: Activates upon document creation in the `emergencies` Firestore collection.
- **Recipient Resolution**: Queries the user's `emergency_contacts` list and the `connections` subcollection to find all registered guardian user IDs.
- **Multicast Notification**: Collects active FCM tokens from each guardian's `users/{uid}/fcm_tokens` subcollection and sends high-priority push notifications using Firebase Cloud Messaging.

## Directory Structure

### Mobile Application (lib/)
- `core/config/`: Configuration loaders, including fallback coordinate management.
- `core/services/`: BLE communication service (`BleService`) handling connection states, scanning, notifications, and telemetry parsing.
- `core/theme/`: Visual theme and color definitions.
- `core/router/`: App navigation routing via GoRouter.
- `features/`: Screen layouts and UI flows grouped by business logic domain (Authentication, Emergency responses, History, Map tracking, Onboarding, Connections, Profile details, Shoe status, and Splash).
- `models/`: App-wide data models (SensorData, EmergencyModel, OfflineEmergencyModel, etc.).
- `providers/`: State management providers managed via Riverpod.
- `repositories/`: Data repositories wrapping Firestore and Auth CRUD operations.
- `services/`: Helper services (AuthService, LiveLocationService, NotificationService, ConnectionLocalStorage).

### Backend (functions/)
- `src/index.ts`: Firebase Cloud Functions written in TypeScript:
  - `sendTestNotification`: HTTPS function to verify FCM connectivity.
  - `onEmergencyCreated`: Firestore trigger dispatched on document creation in the `emergencies` collection to resolve and notify guardians.

## Getting Started & Configuration

### Prerequisites
- Flutter SDK (version 3.5.0 or higher)
- Node.js (for deploying Cloud Functions)
- Firebase CLI

### 1. Run-time Environment Configuration
Configure the fallback coordinates at compile/run time. Do not hardcode coordinates in the codebase. Use the `--dart-define` flag:

```bash
flutter run \
  --dart-define=FALLBACK_LAT=YOUR_LATITUDE \
  --dart-define=FALLBACK_LNG=YOUR_LONGITUDE
```

### 2. Firebase Project Initialization
Download the `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) configuration files from your Firebase Console and place them in their respective platform directories. Additionally, ensure the `lib/firebase_options.dart` file matches your target project credentials.

### 3. Deploying Cloud Functions
Navigate to the `functions/` directory to build and deploy the TypeScript functions:

```bash
# Navigate to functions folder
cd functions

# Install dependencies
npm install

# Build the TypeScript source code
npm run build

# Deploy functions to Firebase
firebase deploy --only functions
```

### 4. Firestore Security Rules
Ensure Firestore security rules (configured in `firestore.rules`) allow authenticated read/write access to the `emergencies`, `users`, and `safety_events` collections as required by the application flow.

## BLE Telemetry Packet Format

The RAKSHA Shoe transmits data packets as UTF-8 encoded JSON strings over BLE notifications. Below is an example of the telemetry structure:

```json
{
  "state": "NORMAL",
  "fsr": 450,
  "accel": 1.02,
  "gyro": 0.05,
  "lat": 12.9716,
  "lon": 77.5946,
  "battery": 87,
  "gpsFresh": true,
  "timestamp": "2026-08-29T11:45:00.000Z"
}
```

- `state`: Mode status (e.g., `NORMAL` or `EMERGENCY`).
- `fsr`: Force Sensitive Resistor reading indicating heel pressure.
- `accel` / `gyro`: Accelerometer and gyroscope readings.
- `lat` / `lon`: Latitudinal and longitudinal coordinates from the shoe's GPS module.
- `gpsFresh`: Boolean indicating if the location fix is current.
