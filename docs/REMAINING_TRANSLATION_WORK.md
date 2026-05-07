# Remaining Translation Work

## Summary
The home page translation is complete, but the detail pages still have hardcoded English content that needs translation.

## Pages That Need Translation

### 1. ✅ Home Page (COMPLETE)
- All text translated
- Vision & Mission content
- Values
- Song titles
- Button texts

### 2. ❌ Guru Journey Page (`lib/features/guru_journey/guru_journey_page.dart`)
**Hardcoded Content:**
- Page title: "Journey of our Guru"
- Button text: "Tap to watch on YouTube"
- 5 paragraphs of Guruji's story
- Footer: "🙏 Jai Gurudev 🙏"

**Translation Keys Added to en.json:**
- `guru_journey_title`
- `guru_journey_watch_youtube`
- `guru_journey_para1` through `guru_journey_para5`
- `jai_gurudev`

**What Needs to be Done:**
1. Import `localization_service.dart`
2. Replace all hardcoded strings with `context.tr('key')`
3. Add Telugu and Hindi translations to te.json and hi.json

### 3. ❌ Kundalini Science Page (`lib/features/kundalini_science/kundalini_science_page.dart`)
**Hardcoded Content:**
- Page title: "The Science of Kundalini Awakening"
- 3 paragraphs explaining Kundalini
- Footer: "🌟 Awaken Your Inner Energy 🌟"

**Translation Keys Added to en.json:**
- `kundalini_science_title`
- `kundalini_science_para1` through `kundalini_science_para3`
- `awaken_inner_energy`

**What Needs to be Done:**
1. Import `localization_service.dart`
2. Replace all hardcoded strings with `context.tr('key')`
3. Add Telugu and Hindi translations

### 4. ❌ Benefits Page (`lib/features/benefits/benefits_page.dart`)
**Hardcoded Content:**
- Page title: "Benefits of Kundalini Sadhana"
- 6 benefit items with titles and descriptions:
  - Enhanced Energy
  - Mental Clarity
  - Emotional Balance
  - Chakra Activation
  - Spiritual Awakening
  - Inner Transformation
- Footer: "✨ Transform Your Life ✨"

**Translation Keys Added to en.json:**
- `benefits_title`
- `benefit_enhanced_energy`, `benefit_enhanced_energy_desc`
- `benefit_mental_clarity`, `benefit_mental_clarity_desc`
- `benefit_emotional_balance`, `benefit_emotional_balance_desc`
- `benefit_chakra_activation`, `benefit_chakra_activation_desc`
- `benefit_spiritual_awakening`, `benefit_spiritual_awakening_desc`
- `benefit_inner_transformation`, `benefit_inner_transformation_desc`
- `transform_your_life`

**What Needs to be Done:**
1. Import `localization_service.dart`
2. Replace all hardcoded strings with `context.tr('key')`
3. Update `_buildBenefit()` method to accept translation keys
4. Add Telugu and Hindi translations

### 5. ❌ Chakra Detail Page (`lib/features/chakras/chakra_detail_page.dart`)
**Hardcoded Content:**
- 7 chakras with names, Sanskrit names, locations, colors, elements, mantras, and descriptions
- Info card labels: "LOCATION", "COLOR", "ELEMENT", "MANTRA"
- "About" section title

**Translation Keys Added to en.json:**
- Chakra names: `chakra_root`, `chakra_sacral`, etc.
- Sanskrit names: `chakra_mooladhara`, `chakra_swadhisthana`, etc.
- Labels: `chakra_location`, `chakra_color`, `chakra_element`, `chakra_mantra`, `chakra_about`
- All chakra properties and descriptions (35+ keys)

**What Needs to be Done:**
1. Import `localization_service.dart`
2. Create a method to build chakra data using translation keys
3. Replace hardcoded chakra list with translated version
4. Add Telugu and Hindi translations (35+ keys per language)

### 6. ❌ Learnings/Classes Page (`lib/features/learnings/learnings_page.dart`)
**Hardcoded Content:**
- Page title: "Learnings"
- Subtitle: "Your path to spiritual evolution"
- Section headers: "Online Courses", "Residential Courses"
- Level titles: "Level 1", "Level 2", etc.
- Class names: "Brahmarandhra Opening", "Sushumna Nadi Activation", etc.
- Status messages: "Completed", "Available", "Locked", etc.
- Error messages
- Button texts

**Translation Keys Added to en.json:**
- `learnings_title`, `learnings_subtitle`
- `online_courses`, `residential_courses`, `residential_courses_desc`
- `level_1` through `level_5_1`
- Class names and descriptions
- Status messages
- Error messages

**What Needs to be Done:**
1. Import `localization_service.dart`
2. Replace all hardcoded strings with `context.tr('key')`
3. Update status messages and error handling
4. Add Telugu and Hindi translations

## Translation Keys Summary

### Already Added to en.json: ~120 new keys
- Guru Journey: 7 keys
- Kundalini Science: 5 keys
- Benefits: 14 keys
- Chakras: 50+ keys
- Learnings: 40+ keys

### Still Need to Add:
- Telugu translations (te.json): ~120 keys
- Hindi translations (hi.json): ~120 keys

## Recommended Approach

### Option 1: Quick Fix (Translate Most Important Pages First)
1. **Guru Journey** (highest priority - tells Guruji's story)
2. **Benefits** (second priority - explains value)
3. **Learnings** (third priority - main feature)
4. **Kundalini Science** (fourth priority)
5. **Chakras** (fifth priority - most complex)

### Option 2: Complete Translation (All Pages)
1. Add all Telugu translations to te.json (~120 keys)
2. Add all Hindi translations to hi.json (~120 keys)
3. Update all 5 pages to use translation keys
4. Test language switching on all pages

## Files to Update

### Translation Files:
- ✅ `assets/translations/en.json` (keys added)
- ❌ `assets/translations/te.json` (needs ~120 new keys)
- ❌ `assets/translations/hi.json` (needs ~120 new keys)

### Dart Files:
- ❌ `lib/features/guru_journey/guru_journey_page.dart`
- ❌ `lib/features/kundalini_science/kundalini_science_page.dart`
- ❌ `lib/features/benefits/benefits_page.dart`
- ❌ `lib/features/chakras/chakra_detail_page.dart`
- ❌ `lib/features/learnings/learnings_page.dart`

## Testing Checklist

After translation:
- [ ] Switch to Telugu - verify all pages show Telugu text
- [ ] Switch to Hindi - verify all pages show Hindi text
- [ ] Switch back to English - verify all pages show English text
- [ ] Check that no "key not found" errors appear
- [ ] Verify all special characters (emojis, Sanskrit) display correctly
- [ ] Test on both web and mobile platforms

## Next Steps

Would you like me to:
1. **Translate one page at a time** (starting with Guru Journey)?
2. **Add all Telugu and Hindi translations first**, then update all pages?
3. **Focus on specific pages** you consider most important?

Let me know your preference and I'll proceed accordingly!
