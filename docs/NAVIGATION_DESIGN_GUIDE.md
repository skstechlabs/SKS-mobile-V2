# Navigation & Reminders Design Guide

## Visual Layout

### Header (AppBar)
```
┌─────────────────────────────────────────────────────┐
│  Siva Kundalini Sadhana              👤 Profile     │
└─────────────────────────────────────────────────────┘
```

**Features:**
- App title on left (22px, bold)
- Profile icon on right (26px)
- Clean, minimal design
- Saffron accent on profile button

---

### Bottom Navigation Bar
```
┌─────────────────────────────────────────────────────┐
│                                                       │
│                        🔔                            │ ← Floating button
│                    (64x64)                           │   (elevated)
│                                                       │
├─────────┬─────────┬─────────┬─────────┬─────────────┤
│  🏠     │  📚     │         │  🤝     │  📅         │
│  Home   │ Classes │         │ Contact │  Events     │
└─────────┴─────────┴─────────┴─────────┴─────────────┘
```

**Features:**
- 5 navigation items (center is placeholder for floating button)
- Large circular notification button (64x64) floating above center
- Saffron gradient with shadow
- Icon size: 24px for nav items, 32px for notification
- Text size: 12px
- Responsive spacing

---

### Home Page - Reminders Section

```
┌─────────────────────────────────────────────────────┐
│  🔔 Daily Reminders                    [Manage →]   │
│  Set reminders to build your spiritual practice     │
│                                                      │
│  ┌──────────────────────────────────────────────┐  │
│  │ ☀️  Morning Meditation              [Toggle] │  │
│  │     Start your day with peace                │  │
│  └──────────────────────────────────────────────┘  │
│                                                      │
│  ┌──────────────────────────────────────────────┐  │
│  │ 🌙  Evening Meditation              [Toggle] │  │
│  │     End your day with gratitude              │  │
│  └──────────────────────────────────────────────┘  │
│                                                      │
│  ┌──────────────────────────────────────────────┐  │
│  │ 🧘  Daily Practice                  [Toggle] │  │
│  │     Consistent practice leads to growth      │  │
│  └──────────────────────────────────────────────┘  │
│                                                      │
│  ┌──────────────────────────────────────────────┐  │
│  │ 👥  Weekly Satsang                  [Toggle] │  │
│  │     Join our community every Sunday          │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

---

## Preset Reminder Cards

### Active State
```
┌────────────────────────────────────────────────┐
│  ┌────┐                                        │
│  │ ☀️ │  Morning Meditation          ⚪ ON   │
│  └────┘  Start your day with peace            │
│          and clarity                           │
└────────────────────────────────────────────────┘
```
- Gradient background (color-specific)
- Colored icon container with shadow
- Bold title text
- Toggle switch in active color

### Inactive State
```
┌────────────────────────────────────────────────┐
│  ┌────┐                                        │
│  │ ☀️ │  Morning Meditation          ⚪ OFF  │
│  └────┘  Start your day with peace            │
│          and clarity                           │
└────────────────────────────────────────────────┘
```
- Gray gradient background
- Gray icon container
- Muted text colors
- Gray toggle switch

---

## Color Palette

### Preset Reminders
| Reminder | Color | Hex | Icon |
|----------|-------|-----|------|
| Morning Meditation | Orange | `#FF9800` | ☀️ wb_sunny |
| Evening Meditation | Deep Purple | `#673AB7` | 🌙 nightlight_round |
| Daily Practice | Teal | `#009688` | 🧘 self_improvement |
| Weekly Satsang | Pink | `#E91E63` | 👥 groups |

### Navigation
| Element | Color | Usage |
|---------|-------|-------|
| Saffron | `#F97316` | Active state, notification button |
| Dark Brown | `#4A3728` | Inactive state (60% opacity) |
| White | `#FFFFFF` | Background, icon colors |

---

## Responsive Breakpoints

### Mobile Portrait (320px - 599px)
- Full-width cards
- Single column layout
- 16px horizontal padding
- 56px bottom nav height
- 64px floating button

### Mobile Landscape (600px - 767px)
- Same as portrait
- Adjusted for wider screen
- Optimized touch targets

### Tablet (768px - 1023px)
- Wider cards with max-width
- Increased padding (24px)
- Larger touch targets
- Better spacing

### Desktop (1024px+)
- Centered content (max 800px)
- Hover effects enabled
- Keyboard navigation
- Mouse interactions

---

## Interaction States

### Preset Reminder Card

**Default:**
- Gradient background based on active state
- Icon with matching gradient
- Clear typography

**Hover (Desktop):**
- Slight elevation increase
- Subtle scale transform (1.02)
- Cursor pointer

**Pressed:**
- Reduced elevation
- Ripple effect
- Haptic feedback (mobile)

**Toggle Switch:**
- Smooth animation (200ms)
- Color transition
- State change feedback

---

## Accessibility

### Touch Targets
- Minimum 48x48 pixels
- Adequate spacing between elements
- Clear visual feedback

### Text Contrast
- Title: 4.5:1 minimum
- Body: 4.5:1 minimum
- Disabled: 3:1 minimum

### Screen Readers
- Semantic HTML/widgets
- Proper labels
- State announcements
- Navigation hints

### Keyboard Navigation
- Tab order logical
- Focus indicators visible
- Enter/Space activation
- Escape to dismiss

---

## Animation Timings

| Element | Duration | Easing |
|---------|----------|--------|
| Toggle Switch | 200ms | ease-in-out |
| Card Hover | 150ms | ease-out |
| Navigation | 300ms | ease-in-out |
| Floating Button | 250ms | spring |
| Gradient Transition | 300ms | linear |

---

## Typography Scale

| Element | Size | Weight | Line Height |
|---------|------|--------|-------------|
| App Title | 22px | Bold (700) | 1.2 |
| Section Title | 20px | Bold (700) | 1.3 |
| Card Title | 16px | Bold (700) | 1.4 |
| Card Description | 13px | Regular (400) | 1.3 |
| Nav Label | 12px | Semi-bold (600) | 1.2 |
| Body Text | 14px | Regular (400) | 1.5 |

---

## Spacing System

| Size | Value | Usage |
|------|-------|-------|
| xs | 4px | Tight spacing |
| sm | 8px | Icon padding |
| md | 12px | Button padding |
| lg | 16px | Card padding |
| xl | 20px | Section spacing |
| 2xl | 24px | Large gaps |

---

## Shadow Elevation

| Level | Usage | Shadow |
|-------|-------|--------|
| 1 | Cards | 0 2px 4px rgba(0,0,0,0.08) |
| 2 | Floating button | 0 4px 12px rgba(249,115,22,0.4) |
| 3 | Modal | 0 8px 24px rgba(0,0,0,0.15) |

---

## Implementation Notes

### Performance
- Use `const` constructors where possible
- Minimize rebuilds with proper state management
- Lazy load images
- Cache network responses

### Testing
- Test on multiple screen sizes
- Verify touch targets
- Check color contrast
- Test with screen readers
- Validate keyboard navigation

### Maintenance
- Keep colors in theme file
- Use consistent spacing variables
- Document custom widgets
- Write unit tests for logic

---

## User Flow Examples

### Enable Morning Meditation
1. User opens app → Home page
2. Scrolls to "Daily Reminders" section
3. Sees "Morning Meditation" card (inactive)
4. Taps toggle switch
5. Card animates to active state (orange gradient)
6. Backend creates reminder with defaults (6:00 AM, all days)
7. Success message appears
8. User receives notification at 6:00 AM next day

### Customize Reminder
1. User taps on "Morning Meditation" card
2. Navigates to reminders screen
3. Sees all reminders including "Morning Meditation"
4. Taps edit icon
5. Changes time to 7:00 AM
6. Selects weekdays only
7. Saves changes
8. Returns to home page
9. Card still shows active state

### Access Notifications
1. User taps large center button in bottom nav
2. Navigates to notifications screen
3. Sees all app notifications
4. Can tap to view details
5. Can swipe to dismiss

---

This design creates a cohesive, user-friendly experience that encourages daily spiritual practice through beautiful, accessible reminders.
