# AGQ Investments App

A comprehensive Flutter investment tracking application for AGQ Investments, providing clients with real-time portfolio management, analytics, and investment insights.

## 📱 Overview

The AGQ Investments app is a secure, feature-rich mobile application that enables investment clients to track their portfolios, view detailed analytics, monitor transactions, and manage their investment accounts. The app supports multiple investment funds (AGQ and AK1) and provides sophisticated charting and reporting capabilities.

## ✨ Key Features

### 🔐 Authentication & Security
- **Multi-factor Authentication**: Email/password, Google Sign-In, and Apple Sign-In
- **Biometric Security**: Face ID and Touch ID support for secure app access
- **Email Verification**: Required email verification for account security
- **Password Recovery**: Secure forgot password functionality

### 📊 Dashboard & Portfolio Management
- **Real-time Portfolio Overview**: Live total assets display with YTD performance
- **Multi-fund Support**: Track AGQ and AK1 investment funds separately
- **Asset Breakdown**: Detailed breakdown of individual assets within each fund
- **Connected Users**: Support for linked family/joint accounts
- **Recent Activity**: Quick access to latest transactions and updates

### 📈 Advanced Analytics
- **Interactive Charts**: Beautiful line charts with multiple time ranges
  - Last week, month, 6 months, year, YTD, and 2-year views
- **Asset Structure Visualization**: Pie charts showing fund composition
- **Performance Tracking**: Historical performance analysis
- **Timeline Selection**: Flexible date range selection for detailed analysis

### 📋 Activity & Transaction Tracking
- **Transaction History**: Comprehensive activity log with filtering and sorting
- **Smart Filtering**: Filter by transaction type, date range, and amount
- **Detailed Transaction Views**: Modal popups with complete transaction details
- **Search Functionality**: Quick search through transaction history

### 🔔 Notifications & Alerts
- **Push Notifications**: Real-time updates on portfolio changes
- **In-app Notifications**: Centralized notification center
- **Activity Alerts**: Notifications for deposits, withdrawals, and market updates
- **Mark as Read**: Notification management capabilities

### 👤 Profile & Account Management
- **User Profiles**: Manage personal and connected user profiles
- **Document Access**: View and download investment statements and reports
- **Settings Management**: Customize app preferences and security settings
- **Help Center**: Built-in support and FAQ system
- **Legal & Compliance**: Access to disclaimers and legal documents

## 🛠 Technical Stack

### Frontend
- **Flutter 3.4.0+**: Cross-platform mobile development
- **Dart**: Programming language
- **Provider**: State management
- **Flutter ScreenUtil**: Responsive design

### Backend & Database
- **Firebase Core**: Backend infrastructure
- **Cloud Firestore**: NoSQL database for real-time data
- **Firebase Authentication**: User authentication and management
- **Firebase Cloud Functions**: Serverless backend logic
- **Firebase Storage**: File and document storage
- **Firebase Messaging**: Push notifications

### Charts & Visualization
- **FL Chart**: Beautiful, customizable charts and graphs
- **Interactive Line Charts**: Real-time portfolio performance
- **Pie Charts**: Asset allocation visualization

### Security & Authentication
- **Local Authentication**: Biometric authentication (Face ID/Touch ID)
- **Google Sign-In**: OAuth integration
- **Apple Sign-In**: Native Apple authentication
- **Crypto**: Secure data encryption

### UI/UX
- **Custom Fonts**: Titillium Web font family
- **SVG Support**: Scalable vector graphics
- **Responsive Design**: Optimized for all screen sizes
- **Custom Animations**: Smooth transitions and interactions

### Additional Features
- **PDF Viewer**: In-app document viewing
- **File Operations**: Download and share capabilities
- **Connectivity Monitoring**: Network status awareness
- **Device Information**: Platform-specific optimizations

## 📱 Supported Platforms

- **iOS**: iPhone and iPad (iOS 12.0+)
- **Android**: Android 6.0+ (API level 23+)

## 📝 Important Note

This repository was originally named `team_shaikh_app` and has been renamed to `agq_app`. Due to this historical naming, you'll find references to `team_shaikh_app` throughout the codebase, including:
- Firebase project configuration
- Package imports and references
- Internal file structures and paths

This is expected and does not affect the app's functionality. The app is properly branded as "AGQ Investments" in the user interface.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.4.0 or higher
- Dart SDK
- iOS development: Xcode 14.0+
- Android development: Android Studio with Android SDK

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd agq_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Add iOS and Android apps to your Firebase project
   - Download and add configuration files:
     - `google-services.json` for Android (place in `android/app/`)
     - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)

4. **iOS Setup**
   ```bash
   cd ios
   pod install
   cd ..
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

### Configuration

1. **Firebase Configuration**
   - Update `lib/firebase_options.dart` with your Firebase project settings
   - Configure authentication providers in Firebase Console
   - Set up Firestore database rules and structure

2. **App Configuration**
   - Update `assets/config.json` with your specific settings
   - Configure push notification settings
   - Set up proper signing certificates for production

## 📁 Project Structure

```
lib/
├── components/          # Reusable UI components
├── database/           # Data models and database helpers
│   └── models/        # Data model classes
├── screens/           # App screens and pages
│   ├── authenticate/  # Authentication flows
│   ├── dashboard/     # Main dashboard
│   ├── analytics/     # Analytics and charts
│   ├── activity/      # Transaction history
│   ├── notifications/ # Notification center
│   ├── profile/       # User profile and settings
│   └── utils/         # Screen utilities
├── firebase_options.dart
└── main.dart          # App entry point
```

## 🔧 Build & Deployment

### Development Build
```bash
flutter build apk --debug        # Android debug
flutter build ios --debug        # iOS debug
```

### Production Build
```bash
flutter build apk --release      # Android release
flutter build ios --release      # iOS release
```

### App Store Deployment
- Configure proper signing certificates
- Update version numbers in `pubspec.yaml`
- Follow platform-specific store guidelines

## 📄 License

This project is proprietary software owned by AGQ Investments. All rights reserved.

## 🤝 Contributing

This is a private project. For internal development team members, please follow the established code review process and coding standards.

## 📞 Support

For technical support or questions, please contact the development team or refer to the in-app help center.

---

**Version**: 1.5.3+18  
**Last Updated**: September 2024  
**Minimum Flutter Version**: 3.4.0