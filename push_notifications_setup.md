# Step-by-Step Production Push Notifications Setup

To make push notifications deliver to **every device** that downloads this app, you must link your own **Firebase Console** and **Supabase Console** using the production code we have built. 

Follow these 4 simple phases:

---

## Phase 1: Configure Firebase for the Client App

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Create a new Firebase project (e.g., `IEEE Event Keeper`).
3. Click the **Android Icon** to add an Android app:
   - **Android Package Name**: `com.example.ieee` (matching your `build.gradle` applicationId).
   - Click **Register App**.
4. Download the `google-services.json` file.
5. Move the downloaded `google-services.json` file into your project's directory at:
   `IEEE NB/android/app/google-services.json`
6. Open [lib/utils/constants.dart](file:///home/user/Downloads/IEEE%20NB/lib/utils/constants.dart) and update the programmatic fields with your actual Firebase project settings (found in Firebase **Project Settings -> General**):
   ```dart
   static const String firebaseApiKey = 'YOUR_REAL_API_KEY';
   static const String firebaseAppId = 'YOUR_REAL_APP_ID';
   static const String firebaseMessagingSenderId = 'YOUR_MESSAGING_SENDER_ID';
   static const String firebaseProjectId = 'YOUR_PROJECT_ID';
   ```

Now, when any device launches the app, it will register with Firebase and subscribe to the `events` topic.

---

## Phase 2: Generate Firebase Service Account Key

To allow your backend (Supabase) to send push messages securely:
1. In the Firebase Console, go to **Project Settings -> Service accounts**.
2. Click **Generate new private key**.
3. This downloads a `.json` file containing your Firebase Private Key credentials. Keep this file safe and never commit it to Git.

---

## Phase 3: Set Secrets & Deploy Supabase Edge Function

1. Install the Supabase CLI on your computer if you haven't already:
   ```bash
   npm install -g supabase
   ```
2. Log in using your Supabase account:
   ```bash
   supabase login
   ```
3. Set your project reference (replace `YOUR_PROJECT_REF` with `pzewonetjzuqxqyhsxnz`):
   ```bash
   supabase link --project-ref YOUR_PROJECT_REF
   ```
4. Set the Firebase Service Account JSON as a secret in your Supabase project vault (replace the `<JSON_CONTENT>` with the text content of your downloaded private key JSON file):
   ```bash
   supabase secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account",...}'
   ```
5. Deploy the edge function:
   ```bash
   supabase functions deploy send-event-notification
   ```

---

## Phase 4: Create the Database Webhook

Whenever a new event is added to the database, Supabase will trigger the edge function to broadcast the notification:
1. Go to your [Supabase Dashboard](https://supabase.com/dashboard).
2. Go to **Database -> Webhooks**.
3. Click **Create Webhook**:
   - **Name**: `send-event-notification-on-insert`
   - **Table**: `events`
   - **Events**: Check `Insert`
   - **Type of Webhook**: Choose **Supabase Edge Functions**
   - **Edge Function**: Select `send-event-notification`
4. Click **Save**.

---

### Verification
Once these steps are completed:
- Any device that opens the app will subscribe to the `events` topic.
- When an event is added to Supabase, the database webhook triggers the edge function.
- The edge function authenticates with Firebase and broadcasts a system-level heads-up notification to the `/topics/events` topic, sending it to **every single device** instantly, even if the app is in the background or closed!
