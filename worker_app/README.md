# NEARA - Worker Partner Application

The NEARA Worker App is a robust, feature-rich Flutter platform designed for skilled service professionals. It enables workers to discover local requests, manage job lifecycles, and track earnings in real-time.

---

## 🛠️ Highlights & Core Features

### 📋 Smart Job Management
- **Incoming Requests**: Real-time notifications for nearby service needs.
- **Proposal System**: Create custom proposals with inspection fees and base service costs.
- **Live Status Workflow**: Intuitive status updates (Arrived, Advance Paid, Service Started/Completed).
- **Photo Documentation**: Mandatory "Before" and "After" photo uploads for job verification.

### 💰 Real-time Earnings Ledger
- **Live Transactions**: Powered by Supabase Realtime—earnings appear instantly after customer payment.
- **Detailed History**: Full tracking of individual payments (Advance and Final).
- **Withdrawal Sync**: Manage and verify your wallet balance with a single tap.

### 📍 Navigation & Contact
- **One-Tap Map Navigation**: Direct integration with Google Maps to reach customer locations quickly.
- **Direct Contact**: Instant dialer accessibility to call customers as needed.
- **Precise GPS**: Uses high-accuracy coordinates from the user profile for exact destination targeting.

---

## 🏗️ Technical Architecture

This app uses **Riverpod** for reactive state management and a **Service-Provider** pattern for clean backend interactions.

### 📂 Feature Layout
```text
lib/
├── features/
│   ├── auth/           # Worker registration & profile management
│   ├── dashboard/      # Main stats and active job views
│   ├── requests/       # Filtering and accepting new service requests
│   ├── proposals/      # Management of sent and accepted offers
│   ├── jobs/           # In-progress flow and photo documentation
│   └── earnings/       # Real-time ledger and transaction views
├── services/           # Supabase, Notifications, and Geolocation logic
└── core/               # Theme and Shared UI components
```

---

## ⚙️ Setup & Configuration

1.  **Environment Setup**
    Create a `.env` file in the `worker_app` root:
    ```env
    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_supabase_key
    ```

2.  **Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run Development**
    ```bash
    flutter run
    ```

---

## 🛡️ Data Compliance & RLS
- The application respect's Supabase's **Row Level Security** policies.
- Worker's can only view requests that are within their designated service zone or have been assigned to them.
- All payment transactions are immutable and logged for accounting accuracy.

---

## 📄 Support
Refer to the main project README for cross-app architecture details.
