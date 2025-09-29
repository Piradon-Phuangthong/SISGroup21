# Mobile Figma Designs - Omada Contacts App

## Design System Overview

### Color Palette
- **Primary**: #6366F1 (Indigo)
- **Secondary**: #8B5CF6 (Purple) 
- **Success**: #10B981 (Emerald)
- **Warning**: #F59E0B (Amber)
- **Error**: #EF4444 (Red)
- **Background**: #FFFFFF (Light) / #0F172A (Dark)
- **Surface**: #F8FAFC (Light) / #1E293B (Dark)
- **Text Primary**: #0F172A (Light) / #F8FAFC (Dark)
- **Text Secondary**: #64748B (Light) / #94A3B8 (Dark)

### Typography
- **Headings**: Inter Bold, 24px-32px
- **Body**: Inter Regular, 16px
- **Caption**: Inter Medium, 14px
- **Small**: Inter Regular, 12px

### Spacing & Layout
- **Container Padding**: 16px
- **Card Padding**: 20px
- **Button Height**: 48px
- **Input Height**: 56px
- **Border Radius**: 12px
- **Shadow**: 0 4px 6px -1px rgba(0, 0, 0, 0.1)

---

## 0. Splash Screen

### Layout Structure
```
┌─────────────────────────────────┐
│                                 │
│                                 │ ← Gradient Background
│                                 │   (Coral #FF6B6B to 
│                                 │    Deep Blue #4ECDC4 to
│                                 │    Purple #45B7D1 to
│                                 │    Indigo #96CEB4)
│                                 │
│            Omada                │ ← App Logo/Name
│                                 │   (Large, White, Centered)
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
└─────────────────────────────────┘
```

### Design Specifications
- **Background**: Vertical linear gradient
  - Top: `#FF6B6B` (Coral Red)
  - Mid-top: `#FF8E53` (Orange)
  - Mid-bottom: `#A8E6CF` (Light Blue)
  - Bottom: `#4A90E2` (Deep Blue/Indigo)
- **Logo**: "Omada" in white
  - Font: Inter Bold, 48px
  - Color: #FFFFFF
  - Position: Centered vertically and horizontally
  - Letter spacing: 2px for elegance
- **Animation**: 
  - Fade in logo after 300ms
  - Gentle pulse animation (scale 1.0 to 1.05)
  - Auto-transition after 2 seconds

### Key Features
- **Brand-focused design** with prominent logo
- **Vibrant gradient** that represents connection and energy
- **Smooth animations** for professional feel
- **Fast load time** with minimal elements
- **Seamless transition** to authentication or main app
- **Status bar**: Hidden for immersive experience

### Technical Implementation
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFF6B6B), // Coral
        Color(0xFFFF8E53), // Orange
        Color(0xFFA8E6CF), // Light Blue
        Color(0xFF4A90E2), // Deep Blue
      ],
    ),
  ),
  child: Center(
    child: Text(
      'Omada',
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 2.0,
      ),
    ),
  ),
)
```

---

## 1. Home/Dashboard Screen

### Layout Structure
```
┌─────────────────────────────────┐
│ [≡] Omada Contacts    [🔔] [👤] │ ← App Bar
├─────────────────────────────────┤
│ Welcome back, [User Name]       │ ← Greeting
│ Quick access to your contacts   │
├─────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌──────┐ │ ← Quick Stats
│ │   📱    │ │   🏷️    │ │  ⭐  │ │
│ │ 1,234   │ │   45    │ │  12  │ │
│ │Contacts │ │  Tags   │ │Favs  │ │
│ └─────────┘ └─────────┘ └──────┘ │
├─────────────────────────────────┤
│ Recent Activity                 │ ← Section Header
│ ┌─────────────────────────────┐ │
│ │ 📞 John Smith               │ │ ← Activity Item
│ │ Added 2 hours ago           │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 📧 Sarah Johnson            │ │
│ │ Updated profile 1 day ago   │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Quick Actions                   │ ← Section Header
│ ┌─────────┐ ┌─────────┐ ┌──────┐ │
│ │   ➕    │ │   🔍    │ │  📱  │ │ ← Action Buttons
│ │  Add    │ │ Search  │ │Share │ │
│ │Contact  │ │        │ │ Card  │ │
│ └─────────┘ └─────────┘ └──────┘ │
└─────────────────────────────────┘
```

### Key Features
- **Personalized greeting** with user's name
- **Quick stats cards** showing total contacts, tags, and favorites
- **Recent activity feed** with latest contact updates
- **Quick action buttons** for common tasks
- **Floating Action Button** for adding contacts
- **Bottom navigation** (Contacts, My Card, Account)

---

## 2. Contacts List Screen

### Layout Structure
```
┌─────────────────────────────────┐
│ [←] Contacts        [➕] [🔍] │ ← App Bar
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │ ← Search Bar
│ │ 🔍 Search contacts...       │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ 🏷️ Tags: [Work] [Family] [+]   │ ← Filter Row
├─────────────────────────────────┤
│ A                               │ ← Alphabet Section
│ ┌─────────────────────────────┐ │
│ │ [👤] Alex Johnson           │ │ ← Contact Tile
│ │     📱 +1 (555) 123-4567   │ │
│ │     🏷️ Work, Colleague      │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ [👤] Anna Smith             │ │
│ │     📧 anna@company.com     │ │
│ │     🏷️ Family               │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ B                               │
│ ┌─────────────────────────────┐ │
│ │ [👤] Bob Wilson             │ │
│ │     📱 +1 (555) 987-6543   │ │
│ │     🏷️ Work                 │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### Key Features
- **Search bar** with real-time filtering
- **Tag filter chips** for quick filtering
- **Alphabetical sections** with sticky headers
- **Contact tiles** showing avatar, name, primary contact method, and tags
- **Pull-to-refresh** functionality
- **Floating Action Button** for adding new contacts
- **Long-press menu** for edit/delete actions

---

## 3. Individual Contact Detail Screen

### Layout Structure
```
┌─────────────────────────────────┐
│ [←] [👤] John Smith    [⋮] [📤] │ ← App Bar
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │ ← Contact Header
│ │        [👤]                │ │
│ │      John Smith             │ │
│ │   Software Engineer         │ │
│ │   🏷️ Work, Colleague        │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Contact Information             │ ← Section Header
│ ┌─────────────────────────────┐ │
│ │ 📱 Mobile                   │ │ ← Contact Method
│ │    +1 (555) 123-4567        │ │
│ │    [📞] [💬] [📧]           │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 📧 Email                    │ │
│ │    john@company.com         │ │
│ │    [📧] [📋]               │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 💼 LinkedIn                 │ │
│ │    linkedin.com/in/johnsmith│ │
│ │    [🔗] [📋]               │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Notes & History                 │ ← Section Header
│ ┌─────────────────────────────┐ │
│ │ 📝 Notes                    │ │
│ │ Met at conference 2024...   │ │
│ │ [Edit]                     │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 📅 Recent Activity          │ │
│ │ • Profile updated 2 days ago│ │
│ │ • Added LinkedIn 1 week ago │ │
│ │ • Contact created 2 weeks ago│ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### Key Features
- **Large contact avatar** with initials
- **Contact information cards** with action buttons
- **Notes section** for personal context
- **Activity history** showing recent changes
- **Share button** for sending contact info
- **Edit button** for modifying contact details
- **Tag display** with color-coded chips

---

## 4. Add New Contact Screen

### Layout Structure
```
┌─────────────────────────────────┐
│ [←] Add Contact        [Save]   │ ← App Bar
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │ ← Basic Info
│ │ First Name *                │ │
│ │ ┌─────────────────────────┐ │ │
│ │ │                         │ │ │
│ │ └─────────────────────────┘ │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ Last Name *                 │ │
│ │ ┌─────────────────────────┐ │ │
│ │ │                         │ │ │
│ │ └─────────────────────────┘ │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Contact Methods                 │ ← Section Header
│ ┌─────────────────────────────┐ │
│ │ 📱 Phone                    │ │
│ │ ┌─────────────────────────┐ │ │
│ │ │ +1 (___) ___-____       │ │ │
│ │ └─────────────────────────┘ │ │
│ │ [Primary] [Work] [Home]     │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 📧 Email                    │ │
│ │ ┌─────────────────────────┐ │ │
│ │ │                         │ │ │
│ │ └─────────────────────────┘ │ │
│ │ [Primary] [Work] [Personal] │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 💼 LinkedIn                │ │
│ │ ┌─────────────────────────┐ │ │
│ │ │ linkedin.com/in/         │ │ │
│ │ └─────────────────────────┘ │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Tags                            │ ← Section Header
│ ┌─────────────────────────────┐ │
│ │ 🏷️ Work 🏷️ Family 🏷️ +     │ │ ← Tag Chips
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Notes                           │ ← Section Header
│ ┌─────────────────────────────┐ │
│ │ ┌─────────────────────────┐ │ │
│ │ │ Add a note...           │ │ │
│ │ │                         │ │ │
│ │ └─────────────────────────┘ │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### Key Features
- **Form validation** with required field indicators
- **Multiple contact methods** with type selection
- **Tag assignment** with existing tags and quick add
- **Notes field** for additional context
- **Save/Cancel buttons** in app bar
- **Real-time validation** feedback
- **Auto-save draft** functionality

---

## 5. Edit Profile Screen

### Layout Structure
```
┌─────────────────────────────────┐
│ [←] My Profile          [Save]  │ ← App Bar
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │ ← Profile Header
│ │        [👤]                │ │
│ │      [Edit Photo]          │ │
│ │      John Smith             │ │
│ │   Software Engineer         │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Personal Information             │ ← Section Header
│ ┌─────────────────────────────┐ │
│ │ First Name *                │ │
│ │ ┌─────────────────────────┐ │ │
│ │ │ John                    │ │ │
│ │ └─────────────────────────┘ │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ Last Name *                 │ │
│ │ ┌─────────────────────────┐ │ │
│ │ │ Smith                   │ │ │
│ │ └─────────────────────────┘ │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Contact Channels                 │ ← Section Header
│ ┌─────────────────────────────┐ │
│ │ 📱 Mobile (Primary)         │ │
│ │    +1 (555) 123-4567        │ │
│ │    [Edit] [Delete]          │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 📧 Email (Primary)          │ │
│ │    john@company.com         │ │
│ │    [Edit] [Delete]          │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 💼 LinkedIn                 │ │
│ │    linkedin.com/in/johnsmith│ │
│ │    [Edit] [Delete]          │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ ➕ Add Channel              │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Sharing Settings                │ ← Section Header
│ ┌─────────────────────────────┐ │
│ │ Default Sharing Level       │ │
│ │ ┌─────────────────────────┐ │ │
│ │ │ Full Profile ▼          │ │ │
│ │ └─────────────────────────┘ │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ Auto-update shared info     │ │
│ │ ┌─────────────────────────┐ │ │
│ │ │ ☑️ Enabled              │ │ │
│ │ └─────────────────────────┘ │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### Key Features
- **Profile photo** with edit option
- **Personal information** editing
- **Contact channels** management with add/edit/delete
- **Sharing settings** for privacy control
- **Auto-update toggle** for shared information
- **Save changes** with validation
- **Preview mode** to see how profile appears to others

---

## 6. Web Share Page (Linktree-style)

### Layout Structure
```
┌─────────────────────────────────┐
│ [←] Back to App    [🔗] [📤]    │ ← App Bar
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │ ← Profile Card
│ │        [👤]                │ │
│ │      John Smith             │ │
│ │   Software Engineer         │ │
│ │   at Tech Company           │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Contact Methods                 │ ← Section Header
│ ┌─────────────────────────────┐ │
│ │ 📱 Call                     │ │ ← Action Button
│ │    +1 (555) 123-4567        │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 📧 Email                    │ │
│ │    john@company.com         │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 💼 LinkedIn                 │ │
│ │    View Profile             │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 💬 WhatsApp                │ │
│ │    Start Chat               │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Social Links                    │ ← Section Header
│ ┌─────────────────────────────┐ │
│ │ 🐦 Twitter                  │ │
│ │    @johnsmith               │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 📸 Instagram                │ │
│ │    @johnsmith               │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │ ← CTA Section
│ │ Download Omada Contacts     │ │
│ │ to connect with John         │ │
│ │ [📱 Download App]           │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### Key Features
- **Clean, minimal design** optimized for mobile
- **Contact information** with clickable actions
- **Social media links** with platform icons
- **Call-to-action** to download the app
- **Responsive design** for different screen sizes
- **Share buttons** for social media
- **QR code** for easy contact addition

---

## Design Guidelines

### Interaction Patterns
- **Tap targets**: Minimum 44px for accessibility
- **Loading states**: Skeleton screens for content loading
- **Error states**: Clear error messages with retry options
- **Empty states**: Helpful illustrations and guidance
- **Success feedback**: Toast notifications and haptic feedback

### Accessibility
- **Color contrast**: WCAG AA compliant
- **Text scaling**: Support for dynamic type
- **Screen readers**: Proper semantic markup
- **Keyboard navigation**: Full keyboard support
- **Focus indicators**: Clear focus states

### Responsive Design
- **Breakpoints**: 320px (small), 375px (medium), 414px (large)
- **Grid system**: 12-column flexible grid
- **Spacing**: Consistent 8px base unit
- **Typography**: Fluid typography scaling

### Animation & Transitions
- **Page transitions**: 300ms ease-in-out
- **Micro-interactions**: 150ms for button presses
- **Loading animations**: Subtle pulse or skeleton
- **Gesture feedback**: Haptic feedback for actions
