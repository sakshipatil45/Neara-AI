# NEARA - Hyperlocal Service Discovery Platform

A voice-first hyperlocal service platform connecting users with nearby skilled workers through AI-powered intent recognition.

## 🏗️ Project Structure

This repository contains two Flutter applications:

### Customer App (`/Customer App/customer_app/`)
- **Purpose**: Customer-facing app for requesting services
- **Key Features**: Voice AI, Worker search, Payment processing, Service tracking

### Worker Partner App (`/Worker Partner App/worker_partner_app/`)
- **Purpose**: Worker-facing app for managing service requests
- **Key Features**: Job management, Earnings tracking, Profile management

## 🚀 Technology Stack

- **Frontend**: Flutter 3.16+
- **Backend**: Supabase (PostgreSQL + Realtime)
- **AI**: Google Gemini 2.5 Flash
- **Maps**: Google Maps API
- **Payments**: Razorpay/UPI
- **State Management**: Riverpod
- **Navigation**: GoRouter

## 🎯 Core Features

### Voice-First AI Intent Recognition
- Natural language processing for service requests
- Multi-language support (Hindi, English)
- 90%+ accuracy in intent detection

### Hyperlocal Worker Matching
- Location-based worker discovery
- Real-time availability tracking
- Smart matching algorithm with ratings & proximity

### Secure Escrow Payments
- Advance payment protection
- Automatic fund release on completion
- Multiple payment options (UPI, Cards, Wallets)

### Emergency SOS Mode
- Instant emergency service requests
- Auto-notification to emergency contacts
- Priority worker matching for urgent situations

## 📱 Getting Started

### Prerequisites
- Flutter 3.16 or higher
- Dart SDK 3.2 or higher
- Android Studio / VS Code
- Supabase account
- Google Cloud API access

### Customer App Setup
```bash
cd "Customer App/customer_app"
flutter pub get
flutter run
```

### Worker Partner App Setup
```bash
cd "Worker Partner App/worker_partner_app"
flutter pub get
flutter run
```

## 🔧 Development Roadmap

- [x] **Phase 1**: Authentication & Core Setup
- [x] **Phase 2**: Voice AI & Intent Recognition
- [x] **Phase 3**: Worker Matching & Discovery
- [x] **Phase 4**: Payment Integration & Escrow
- [x] **Phase 5**: Real-time Communication
- [ ] **Phase 6**: Performance Optimization
- [ ] **Phase 7**: Testing & Deployment

## 🛡️ Security Features

- Row Level Security (RLS) policies
- Encrypted payment data
- Location privacy protection
- Secure API communication

## 📊 Success Metrics

- Intent detection accuracy: >90%
- Service completion rate: >90%
- Worker response time: <10 minutes
- Average customer rating: >4.5/5

## 🤝 Contributing

This project follows clean architecture principles with feature-based module organization.

## 📄 License

Private Repository - All Rights Reserved

---

*Built for connecting communities through technology* 🔗