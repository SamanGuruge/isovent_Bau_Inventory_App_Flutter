# isovent_bau_inventory_app

Mobile application for Isovent Bau for Inventory Handling

## Firebase Setup Checklist

1. Ensure Firebase options exist and app initializes in `/Users/samanguruge/StudioProjects/Isovent_Bau_Inventory_App/lib/main.dart`.
2. Place platform config files:
   - `/Users/samanguruge/StudioProjects/Isovent_Bau_Inventory_App/android/app/google-services.json`
   - `/Users/samanguruge/StudioProjects/Isovent_Bau_Inventory_App/ios/Runner/GoogleService-Info.plist`
3. Enable Email/Password (and Google if needed) in Firebase Auth.
4. Publish Firestore rules after editing:
   - Firebase Console -> Firestore Database -> Rules -> Publish
   - or CLI: `firebase deploy --only firestore:rules`
5. Confirm authenticated access:
   - Logged out: app shows Login and does not seed.
   - Logged in: seed runs and product list loads.

## Firestore Rules Snippets

### DEV TEMP RULES (diagnostic only, not for production)

```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### SAFE BASELINE RULES (recommended)

```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /meta/{docId} {
      allow read, write: if request.auth != null;
    }

    match /products/{docId} {
      allow read, write: if request.auth != null;
    }
    match /brands/{docId} {
      allow read, write: if request.auth != null;
    }
    match /categories/{docId} {
      allow read, write: if request.auth != null;
    }
    match /subCategories/{docId} {
      allow read, write: if request.auth != null;
    }
    match /units/{docId} {
      allow read, write: if request.auth != null;
    }
    match /variantAttributes/{docId} {
      allow read, write: if request.auth != null;
    }
    match /warranties/{docId} {
      allow read, write: if request.auth != null;
    }

    match /{col}/{docId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
