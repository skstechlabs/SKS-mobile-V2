# UI Components Showcase

## 🎨 Visual Component Library

### Navigation Components

#### Bottom Navigation Bar
- 4 tabs: Home, Learnings, Connect, Events
- Active state: Saffron color with filled icon
- Inactive state: Dark brown (60% opacity) with outlined icon
- Smooth transitions between tabs
- Elevation shadow on top

#### App Bar
- Transparent background with gradient
- Title: "Divine Path" in Lora font
- Notification bell icon on right
- Back button on detail screens
- Elevation: 0 (flat design)

### Card Components

#### Standard Card
- White background
- 16px border radius
- Soft shadow (8px blur, 4px offset)
- 16px padding
- Used for: About section, recommendations

#### Image Card
- Image at top (16:9 aspect ratio)
- Content padding: 16px
- Rounded corners: 16px
- Shimmer placeholder during load
- Used for: Events, bhajans, videos

#### Horizontal Scroll Card
- Width: 280px (music), 160px (bhajans)
- Margin right: 12px
- Snap scrolling disabled
- Shows partial next item
- Used for: Music, bhajans, videos

### Button Components

#### Primary Button (Elevated)
- Background: Saffron gradient
- Text: White, 16px, SemiBold
- Padding: 12px vertical, 24px horizontal
- Border radius: 12px
- Elevation: 2
- Press animation: Scale 0.95

#### Secondary Button (Outlined)
- Border: 2px solid Saffron
- Text: Saffron, 16px, SemiBold
- Background: Transparent
- Same padding and radius as primary

#### Icon Button
- Size: 48x48px (touch target)
- Icon: 24px
- Ripple effect on press
- Used for: Play, share, notifications

### Loading States

#### Shimmer Effect
- Base color: Grey 300
- Highlight color: Grey 100
- Animation: 1.5s linear infinite
- Matches content shape
- Used for: Images, cards, lists

#### Empty State
- Large icon (80px)
- Title text
- Description text
- Optional action button
- Centered layout
- Used for: No notifications, no content

### Special Components

#### Quote Carousel
- Height: 200px
- Auto-play: 5 seconds
- Enlarge center: true
- Gradient background: Saffron
- Share button overlay
- Dot indicators below

#### Guruji Section
- Height: 400px
- Full-width image
- Animated glow effect (2s loop)
- Gradient overlay at bottom
- Title centered at bottom

#### Filter Chips
- Height: 40px
- Horizontal scroll
- Selected: Saffron background, white text
- Unselected: White background, dark text
- Border radius: 20px

### Text Styles

#### Display Large
- Font: Playfair Display
- Size: 32px
- Weight: Bold
- Color: Dark Brown
- Used for: Hero titles

#### Headline Medium
- Font: Lora
- Size: 24px
- Weight: SemiBold
- Color: Dark Brown
- Used for: Section headers

#### Body Large
- Font: Open Sans
- Size: 16px
- Weight: Regular
- Color: Dark Brown
- Used for: Content, descriptions

### Color Usage

#### Primary Actions
- Saffron (#FF9933)
- Used for: CTAs, active states, highlights

#### Accents
- Gold (#D4AF37)
- Used for: Icons, special elements, glow

#### Backgrounds
- White (#FFFBF5): Cards, surfaces
- Beige (#F5E6D3): Page backgrounds
- Gradient: Beige to White to Soft Gray

#### Text
- Dark Brown (#4A3728): Primary text
- Dark Brown 60%: Secondary text
- White: Text on colored backgrounds

### Spacing System

- 4px: Icon-text gap
- 8px: Small spacing
- 12px: Medium spacing, card margins
- 16px: Standard padding, section spacing
- 24px: Large spacing between sections
- 32px: Extra large spacing

### Animation Timings

- Button press: 200ms
- Page transition: 300ms
- Fade in: 400ms
- Shimmer loop: 1500ms
- Glow effect: 2000ms
- Carousel auto-play: 5000ms

---

**All components follow Material Design 3 guidelines with spiritual customization**
