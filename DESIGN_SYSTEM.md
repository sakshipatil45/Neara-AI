# NEARA Design System v1.0
## Hyperlocal Service Platform Design Language

---

## 🎯 Design Philosophy

**Trust Through Clarity** - NEARA's design emphasizes transparency, safety, and instant comprehension, crucial for emergency service scenarios.

### Core Principles
- **Voice-First Interface**: Large, accessible voice controls with clear visual feedback
- **Emergency-Ready**: High contrast, clear hierarchy for critical actions
- **Hyperlocal Trust**: Visual elements that convey community connection and reliability
- **Cross-Platform Consistency**: Unified experience across Customer and Worker apps

---

## 🎨 Color Palette

### Primary Colors
```
Primary Blue: #2563EB (Trustworthy, professional)
Primary Light: #3B82F6 (Interactive elements)
Primary Dark: #1E40AF (Emphasis, CTAs)
```

### Secondary Colors
```
Success Green: #059669 (Completed services, success states)
Warning Orange: #EA580C (Urgent requests, attention needed)
Error Red: #DC2626 (Emergency, critical actions)
Info Blue: #0284C7 (Information, neutral states)
```

### Neutral Scale
```
Gray 50: #F9FAFB (Background, cards)
Gray 100: #F3F4F6 (Subtle backgrounds)
Gray 200: #E5E7EB (Borders, dividers)
Gray 300: #D1D5DB (Disabled states)
Gray 400: #9CA3AF (Placeholder text)
Gray 500: #6B7280 (Secondary text)
Gray 600: #4B5563 (Primary text)
Gray 700: #374151 (Headings)
Gray 800: #1F2937 (Strong emphasis)
Gray 900: #111827 (Maximum contrast)
```

### Semantic Colors
```
Background Primary: #FFFFFF
Background Secondary: #F9FAFB
Background Tertiary: #F3F4F6

Text Primary: #111827
Text Secondary: #374151
Text Tertiary: #6B7280
Text Disabled: #9CA3AF

Border Default: #E5E7EB
Border Focus: #2563EB
Border Error: #DC2626
```

---

## 📝 Typography Scale

### Font Family
```
Primary: 'Inter' (System fallback: -apple-system, sans-serif)
Monospace: 'JetBrains Mono' (Code, numbers)
```

### Type Scale
```
Display Large: 48px / 1.2 / 700 (Hero headings)
Display Medium: 36px / 1.3 / 600 (Section headings)
Display Small: 30px / 1.4 / 600 (Card headings)

Headline Large: 24px / 1.4 / 600 (Page titles)
Headline Medium: 20px / 1.5 / 500 (Component titles)
Headline Small: 18px / 1.5 / 500 (List headers)

Body Large: 16px / 1.6 / 400 (Primary content)
Body Medium: 14px / 1.5 / 400 (Secondary content)
Body Small: 12px / 1.4 / 400 (Captions, metadata)

Button Large: 16px / 1.0 / 600 (Primary actions)
Button Medium: 14px / 1.0 / 500 (Secondary actions)
Button Small: 12px / 1.0 / 500 (Tertiary actions)
```

---

## 🔲 Spacing System

### Base Unit: 4px

```
XXS: 2px   (0.5 × base)
XS:  4px   (1 × base)  
SM:  8px   (2 × base)
MD:  12px  (3 × base)
LG:  16px  (4 × base)
XL:  24px  (6 × base)
2XL: 32px  (8 × base)
3XL: 48px  (12 × base)
4XL: 64px  (16 × base)
5XL: 96px  (24 × base)
```

### Component Spacing
```
Component Padding: 16px
Card Padding: 20px
Section Padding: 24px
Screen Padding: 20px
Button Padding: 12px × 24px
Input Padding: 12px × 16px
```

---

## 🔘 Border Radius

```
None: 0px
XS: 4px    (Small elements, chips)
SM: 6px    (Buttons, inputs)
MD: 8px    (Cards, containers)
LG: 12px   (Modal, sheets)
XL: 16px   (Large containers)
2XL: 24px  (Hero elements)
Full: 9999px (Circular elements)
```

---

## 🎭 Elevation & Shadows

```
Level 0: none (Flat elements)
Level 1: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24)
Level 2: 0 3px 6px rgba(0,0,0,0.16), 0 3px 6px rgba(0,0,0,0.23)
Level 3: 0 10px 20px rgba(0,0,0,0.19), 0 6px 6px rgba(0,0,0,0.23)
Level 4: 0 14px 28px rgba(0,0,0,0.25), 0 10px 10px rgba(0,0,0,0.22)
Level 5: 0 19px 38px rgba(0,0,0,0.30), 0 15px 12px rgba(0,0,0,0.22)
```

---

## 📱 Component Library

### 1. Buttons

#### Primary Button
```
Background: Primary Blue (#2563EB)
Text: White
Height: 48px (touch-friendly)
Padding: 12px × 24px
Border Radius: 6px
Font: Button Large
Shadow: Level 1
```

#### Secondary Button
```
Background: Transparent
Border: 1.5px solid Primary Blue
Text: Primary Blue
Height: 48px
Padding: 12px × 24px
Border Radius: 6px
Font: Button Large
```

#### Voice Action Button (Special)
```
Background: Linear gradient Primary Blue to Primary Light
Size: 80px × 80px (large touch target)
Border Radius: Full (circular)
Icon: Microphone (24px)
Shadow: Level 3
Animation: Pulse on active
```

### 2. Input Fields

#### Text Input
```
Background: White
Border: 1px solid Gray 200
Focus Border: Primary Blue
Height: 48px
Padding: 12px × 16px
Border Radius: 6px
Font: Body Large
Placeholder: Text Tertiary
```

#### Phone Number Input
```
Background: White
Border: 1px solid Gray 200  
Height: 48px
Left Icon: Flag/Country code
Padding: 12px × 48px × 12px × 16px
Border Radius: 6px
Font: Body Large (Monospace for number)
```

### 3. Cards

#### Service Card
```
Background: White
Border: 1px solid Gray 200
Padding: 20px
Border Radius: 8px
Shadow: Level 1
Hover Shadow: Level 2
```

#### Worker Profile Card
```
Background: White
Border: 1px solid Gray 200
Padding: 16px
Border Radius: 8px
Avatar Size: 48px
Rating Stars: 16px
Shadow: Level 1
```

#### Emergency Card (Special)
```
Background: Linear gradient from Error Red to darker red
Text: White
Padding: 16px
Border Radius: 8px
Icon Size: 32px
Shadow: Level 3
```

### 4. Navigation

#### Tab Bar
```
Background: White
Height: 64px
Border Top: 1px solid Gray 200
Active Color: Primary Blue
Inactive Color: Gray 400
Icon Size: 24px
Font: Body Small
```

#### App Bar
```
Background: White
Height: 56px
Elevation: Level 1
Title Font: Headline Medium
Icon Size: 24px
Padding: 0 × 16px
```

---

## 🎯 Voice-First Design Patterns

### 1. Voice Input States
```
Idle: Gray circle with microphone icon
Listening: Blue pulsing circle with sound waves
Processing: Blue loading spinner
Success: Green checkmark with fade
Error: Red error icon with shake animation
```

### 2. Voice Feedback
```
Visual: Animated waveform during recording
Haptic: Light tap on start/stop
Audio: Subtle beep confirmation
Text: Real-time transcription display
```

### 3. Emergency Mode Indicators
```
SOS Button: Red circular button (always visible)
Emergency Banner: Red gradient background
Emergency Typography: Bold, high contrast
Emergency Actions: Extra large touch targets
```

---

## ♿ Accessibility Guidelines

### 1. Touch Targets
```
Minimum Size: 44px × 44px
Recommended: 48px × 48px
Voice Button: 80px × 80px
Emergency Button: 60px × 60px
```

### 2. Color Contrast
```
Normal Text: 4.5:1 minimum ratio
Large Text: 3:1 minimum ratio  
UI Elements: 3:1 minimum ratio
Emergency Elements: 7:1 ratio (AAA)
```

### 3. Voice Accessibility
```
Voice feedback for all actions
Screen reader support for voice states
Alternative input methods for voice features
Clear pronunciation in voice prompts
```

---

## 📱 App-Specific Variations

### Customer App Theme
```
Primary Focus: Trust and ease of use
Hero Element: Large voice button on home screen
Emergency Access: Always-visible SOS button
Color Emphasis: Calming blues with trust indicators
```

### Worker Partner App Theme  
```
Primary Focus: Efficiency and professional tools
Hero Element: Job status and earnings dashboard
Quick Actions: Accept/decline job buttons
Color Emphasis: Professional blues with success greens
```

---

## 🔄 Animation & Motion

### Duration Scale
```
Micro: 100ms (Hover, focus)
Quick: 200ms (Button press, small transitions)
Standard: 300ms (Page transitions, modal)
Gentle: 500ms (Large movements, complex animations)
Slow: 800ms (Loading states, voice feedback)
```

### Easing Curves
```
Standard: cubic-bezier(0.2, 0, 0, 1)
Decelerate: cubic-bezier(0, 0, 0.2, 1)
Accelerate: cubic-bezier(0.4, 0, 1, 1)
Emphasized: cubic-bezier(0.2, 0, 0, 1)
```

### Motion Patterns
```
Enter: Slide up + fade in
Exit: Slide down + fade out  
Voice Active: Scale pulse + glow
Emergency: Urgent shake + red flash
Loading: Smooth rotation
Success: Gentle bounce + green flash
```

---

## 📏 Responsive Breakpoints

```
Mobile: 0 - 767px (Primary target)
Tablet: 768px - 1023px  
Desktop: 1024px+ (Admin views)
```

### Layout Guidelines
```
Mobile: Single column, bottom navigation
Tablet: Adapted mobile layout with larger spacing
Desktop: Two-column layout for admin features
```

---

This design system ensures consistency, accessibility, and trust-building across the NEARA platform while maintaining the voice-first, emergency-ready focus of the service.