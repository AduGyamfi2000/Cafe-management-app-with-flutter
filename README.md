# Cafe Management App with Flutter

A Flutter application for a cafe that offers a default Customer Ordering page and an Admin Dashboard behind a secure login.

## Features

- Customer ordering flow with required selection of "Eat-In" or "Take-Out"
- Menu browsing and cart building
- Automatic subtotal, 10% tax, and total calculation
- Admin login secured with a predefined username/password
- Full CRUD for menu items and prices
- Menu and order type settings persisted locally using `shared_preferences`

## Admin Credentials

- Username: `admin`
- Password: `cafepass`

## Getting Started

1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Open this folder in your IDE.
3. Run `flutter pub get` to install dependencies.
4. Run the app with `flutter run`.

## Notes

- The customer screen opens by default.
- Use the admin icon in the app bar to access the admin login.
- Changes made in the admin dashboard persist between app launches.
