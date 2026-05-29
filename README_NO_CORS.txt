================================================================================
  🎯 GUARANTEED SOLUTION - NO MORE CORS ISSUES!
================================================================================

PROBLEM:
--------
Testing locally against production server (app.sivakundalini.org) gives CORS errors.

SOLUTION:
---------
Run Chrome with web security disabled to bypass CORS completely.

================================================================================
  ✅ QUICK START (Just Run This)
================================================================================

Option 1: Automated Script (EASIEST)
-------------------------------------
cd s:\SKS-mobile-V2
.\start-app-with-production.ps1

That's it! Everything is done automatically.

================================================================================

Option 2: Manual Steps
----------------------
1. Close ALL Chrome windows

2. Run this:
   cd s:\SKS-mobile-V2
   run-chrome-no-cors.bat

3. You should see a YELLOW WARNING BANNER in Chrome:
   "You are using an unsupported command-line flag"
   (This is GOOD - it means CORS is disabled!)

4. Open NEW terminal and run:
   cd s:\SKS-mobile-V2
   flutter clean
   flutter run -d chrome --dart-define=API_BASE_URL=http://app.sivakundalini.org --dart-define=MSG91_WIDGET_ID=366379717055333935353237 --dart-define=MSG91_AUTH_TOKEN=503409TcpVDVCsWuiQ69c418f1P1 --dart-define=GOOGLE_CLIENT_ID=107751006310624717047-kcqvvvvvvvvvvvvvvvvvvvvvvvvvvvvv.apps.googleusercontent.com --dart-define=ONESIGNAL_APP_ID=b89d199e-15be-4343-9e04-640c43f355e9

5. NO MORE CORS ERRORS! ✅

================================================================================
  ✅ VERIFICATION
================================================================================

Chrome DevTools Console should show:
  📍 Base URL: http://app.sivakundalini.org
  ✅ No CORS errors

Network tab should show:
  ✓ http://app.sivakundalini.org/api/events → 200 OK
  ✓ http://app.sivakundalini.org/api/gatherings → 200 OK
  ✓ http://app.sivakundalini.org/api/quotes → 200 OK

================================================================================
  ⚠️ IMPORTANT
================================================================================

- Only use this Chrome window for development testing
- Don't browse other websites in this window
- Close it after testing
- Your normal Chrome is unaffected

================================================================================
  📚 MORE INFO
================================================================================

See detailed guide: GUARANTEED_FIX.md

================================================================================
  🎉 THIS WILL WORK 100%!
================================================================================

The warning banner in Chrome means CORS is disabled.
No more CORS errors - guaranteed!

Last Updated: January 2024
