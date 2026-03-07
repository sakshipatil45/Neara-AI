# NEARA - Customer Application

The NEARA Customer App is a premium, voice-first Flutter application designed for effortless service discovery. It empowers users to find, book, and track skilled local workers using natural language.

---

## 🎨 Design Philosophy
- **Vibrant & Premium UI**: Custom gradients, glassmorphism, and smooth micro-animations.
- **Accessibility First**: Designed with large touch targets and intuitive voice navigation.
- **Safety Centric**: SOS mode and secure identity verification.

---

## 🛠️ Key Modules & Features

### 🎙️ AI Voice Interface
- **Gemini AI Integration**: Leverages Google's most advanced LLM to parse service requirements.
- **Intent Extraction**: Automatically detects service categories (Plumbing, Electrical, Beauty, etc.) from voice input.
- **Contextual Responses**: Interactive AI assistant that guides the user through the booking process.

### 📍 Hyperlocal Discovery
- **Real-time Worker Map**: View nearby verified workers on a live map.
- **Smart Sorting**: Workers are ranked by proximity, rating, and historical reliability.
- **Profile Previews**: Detailed worker portfolios, including service history and reviews.

### 💳 Milestone-based Payments
- **Escrow System**: Funds are held securely and only released when you confirm service completion.
- **Advance Payments**: Seamlessly pay the initial booking fee to secure the worker's arrival.
- **Payment Modes**: Supports UPI, Cards, and Net Banking.

### 🚨 SOS & Urgent Services
- **Emergency Button**: One-tap SOS triggers immediate matching for critical repairs or roadside aid.
- **Live Tracking**: See the worker's exact location as they move towards you.

---

## 📂 Feature-Based Structure

```text
lib/
├── features/
│   ├── auth/           # Login & Profile verification
│   ├── dashboard/      # Main UI and service categories
│   ├── voice_ai/       # Gemini AI & Microphone logic
│   ├── search/         # Worker filters & Map views
│   ├── tracking/       # Real-time job status & GPS
│   └── payments/       # Wallet and Transaction history
├── core/               # Theme, constants, and network logic
└── models/             # Data entities (User, Worker, Job)
```

---

## ⚙️ Configuration

1.  **Environment Variables**
    Create a `.env` file in the `customer_app` root:
    ```env
    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_supabase_key
    GEMINI_API_KEY=your_google_ai_key
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

## 🤝 Support
For any issues regarding the customer app, please refer to the main repository documentation.
