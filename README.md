# IEEE Event Keeper 📅

A modern, collaborative, real-time community calendar web application designed for IEEE student branches. Built with **Flutter Web**, **Supabase Backend**, **PostgreSQL**, and **Riverpod** state management, adhering to a clean architectural pattern.

## Core Features
1. **Interactive Calendar UI**: Supports Month, Week, Day, and Agenda/List views powered by Syncfusion Calendar, with responsive layouts for Desktop, Tablet, and Mobile.
2. **Google OAuth & User Profiles**: Secure Google authentication with automatic PostgreSQL user profile generation.
3. **Role-Based Permissions (RLS)**: Enforces access controls where ordinary members can only edit/delete events they created, while Administrators have full CRUD rights over all events.
4. **Real-time Sync**: Instant database changes synced to all connected users without page refreshing, powered by Supabase Realtime replication.
5. **CSV & PDF Exports**: Download entire event schedules as formatted CSV spreadsheets or generate professional PDF timetables with browser printing.
6. **Social Sharing**: Share events instantly with mobile-scannable QR Codes, copyable event links, and web sharing API integrations.
7. **Premium Aesthetics**: Adaptive Dark/Light Mode using the Material 3 design system with custom color-coded categories, loading states, and toast notifications.

---

## 🚀 Quick Start: Demo Mock Mode
For testing and development purposes, this project features an **automatic Demo Mock Mode**. 

If you run the application without entering Supabase credentials, the app will execute fully in-memory, simulating authentication states, real-time database modifications, role-based security policies, and PDF/CSV exports. 

### Run Locally:
```bash
# Get dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome
```

---

## 🛠️ Production Supabase Integration
To connect the application to a production Supabase database:

### 1. Database Schema Configuration
Run the provided SQL script [schema.sql](schema.sql) in your **Supabase SQL Editor** to configure tables, constraints, default categories, and security rules:
- Creates `profiles`, `categories`, and `events` tables.
- Installs an auth trigger that automatically syncs newly logged-in Google accounts with your `profiles` table.
- Registers default category colors.
- Enables **Row Level Security (RLS)** and configures access control policies.
- Activates **Realtime Replication** on the `events` table.

### 2. Configure Client Credentials
Replace the placeholders in `lib/utils/constants.dart` with your Supabase Project credentials:
```dart
class Constants {
  static const String supabaseUrl = 'https://your-project-id.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
}
```

### 3. Google Sign-In Setup
To allow Google authentication on web:
1. Navigate to the Google Cloud Console and create an **OAuth Web Client ID**.
2. Add your Supabase project redirect URL (found in the Supabase Dashboard under Auth > URL Configuration) to the **Authorized redirect URIs** in Google Console.
3. In your Supabase Dashboard, go to **Auth > Providers > Google**, enable the provider, and paste your **Client ID** and **Client Secret**.

---

## 📂 Project Structure
Following Clean Architecture principles:
```
lib/
├── models/          # Dart models representing Database tables (Profile, Category, Event)
├── services/        # Client API connections and printing/export helpers
├── providers/       # Riverpod state notifiers (Auth, Events, Categories, Theme)
├── screens/         # Page widgets (Login, Home, Event Detail)
├── widgets/         # Component UI widgets (Calendar, Event Form Dialog)
└── utils/           # Theme designs, color schemes, and configuration constants
```
