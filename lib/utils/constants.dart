class Constants {
  // Replace these with your actual Supabase credentials.
  // If left as placeholders, the app will automatically run in "Demo Mock Mode"
  // allowing you to test all features (realtime, admin/user roles, PDF/CSV export) instantly.
  static const String supabaseUrl ='https://pzewonetjzuqxqyhsxnz.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB6ZXdvbmV0anp1cXhxeWhzeG56Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMwOTQ0MzYsImV4cCI6MjA5ODY3MDQzNn0.Dn9y31w8c9Jpilj_TadI2hRLgEeIznrBYBbcKf7BHW8';
  
  // Firebase Service Account JSON (in String format) for sending notifications via FCM HTTP v1.
  // Download this from your Firebase Console -> Project Settings -> Service Accounts -> Generate new private key.
  // In a production app, notifications should be sent via a backend (e.g. Supabase Edge Functions),
  // but for collaborative testing/demos, you can paste the JSON content here.
  static const String firebaseServiceAccountJson = 'YOUR_FIREBASE_SERVICE_ACCOUNT_JSON';

  // Firebase programmatic initialization configuration (optional fallback)
  // Fill these with your actual Firebase project settings so the app can register for notifications.
  static const String firebaseApiKey = 'AIzaSyDummyKey-ForInitializationOnly';
  static const String firebaseAppId = '1:1234567890:android:abc123xyz';
  static const String firebaseMessagingSenderId = '1234567890';
  static const String firebaseProjectId = 'ieee-event-keeper';
}
