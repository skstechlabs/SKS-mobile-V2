# Audio Migration to Cloudflare R2 - Implementation Checklist

## 📋 Complete Step-by-Step Tracker

Use this checklist to track your progress through the migration.

### Phase 1: Cloudflare R2 Setup ☐

- [ ] 1.1 Login to Cloudflare Dashboard
- [ ] 1.2 Create R2 bucket named `sks-audio-files`
- [ ] 1.3 Enable public access
- [ ] 1.4 Create API token with Read & Write permissions
- [ ] 1.5 Save credentials in `.env` file
- [ ] 1.6 Verify configuration

### Phase 2: Upload Audio Files ☐

- [ ] 2.1 Install `@aws-sdk/client-s3` package
- [ ] 2.2 Run `scripts/upload-audio-to-r2.js`
- [ ] 2.3 Verify all 11 files uploaded
- [ ] 2.4 Test one URL in browser

### Phase 3: Database Setup ☐

- [ ] 3.1 Update SQL script with account ID
- [ ] 3.2 Run `populate_audios_with_cloudflare.sql`
- [ ] 3.3 Verify 11 records in database
- [ ] 3.4 Test category counts

### Phase 4: Test Backend API ☐

- [ ] 4.1 Test `/api/audios` endpoint
- [ ] 4.2 Test `/api/audios/category/bhajan`
- [ ] 4.3 Test `/api/audios/category/meditation`
- [ ] 4.4 Verify audio URLs work

### Phase 5: Update Mobile App ☐

- [ ] 5.1 Update `all_songs_page.dart`
- [ ] 5.2 Update `home_page.dart`
- [ ] 5.3 Update `playlist_screen.dart`
- [ ] 5.4 Update `mini_audio_player.dart`
- [ ] 5.5 Update `main_scaffold.dart`
- [ ] 5.6 Run `flutter analyze`

### Phase 6: Testing ☐

- [ ] 6.1 App launches successfully
- [ ] 6.2 Audio list loads from API
- [ ] 6.3 First-time playback works
- [ ] 6.4 Cached playback instant
- [ ] 6.5 Offline mode works
- [ ] 6.6 Player controls work
- [ ] 6.7 Background playback works

### Phase 7: Remove Assets ☐

- [ ] 7.1 Comment out `assets/audio/` in pubspec.yaml
- [ ] 7.2 Rebuild app
- [ ] 7.3 Verify app size reduced by ~50%
- [ ] 7.4 Test audio still works

### Phase 8: Deploy ☐

- [ ] 8.1 Build release APK
- [ ] 8.2 Test on multiple devices
- [ ] 8.3 Upload to Play Store
- [ ] 8.4 Monitor for issues

---

## Quick Reference

**Documentation:**
- Migration Guide: `AUDIO_CLOUDFLARE_MIGRATION_GUIDE.md`
- R2 Setup: `../sks-mobile-backend-service/CLOUDFLARE_R2_SETUP.md`
- Update Guide: `UPDATE_TO_CLOUDFLARE_AUDIO.md`

**Key Files:**
- Backend SQL: `../sks-mobile-backend-service/sql/populate_audios_with_cloudflare.sql`
- Upload Script: `../sks-mobile-backend-service/scripts/upload-audio-to-r2.js`
- Audio Provider: `lib/core/providers/audio_provider.dart`

**Completion Status:** ___ / 8 Phases ✓
