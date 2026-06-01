# Video Quality Switching - Testing Guide

## Quick Test Steps

### 1. Basic Quality Switching Test (5 minutes)

1. **Open any class video**
   - Navigate to Classes → Select any class → Open Day 1 video

2. **Test Auto to Manual Quality**
   - Video should start in "Auto" mode
   - Click the Quality button (shows "Auto" or "Auto (720p)")
   - Select "480p" from the menu
   - ✅ **Expected**: Video continues smoothly without flickering
   - ✅ **Expected**: Quality button now shows "480p"
   - ✅ **Expected**: Video doesn't restart or jump

3. **Test Manual to Manual Quality**
   - Click Quality button again
   - Select "720p"
   - ✅ **Expected**: Smooth transition, no flickering
   - ✅ **Expected**: Quality button shows "720p"

4. **Test Manual to Auto Quality**
   - Click Quality button
   - Select "Auto"
   - ✅ **Expected**: Smooth transition
   - ✅ **Expected**: Quality button shows "Auto (XXXp)" where XXX is the auto-selected quality

### 2. Controls Test During Quality Switch (3 minutes)

1. **Play/Pause During Switch**
   - While video is playing, switch quality
   - ✅ **Expected**: Video continues playing after switch
   - Pause the video, then switch quality
   - ✅ **Expected**: Video stays paused after switch

2. **Seek During Quality Switch**
   - Switch quality
   - Immediately drag the progress bar
   - ✅ **Expected**: Seeking works normally

3. **Speed Control**
   - Switch quality
   - Change playback speed (1.5x, 2x, etc.)
   - ✅ **Expected**: Speed control works normally

4. **Fullscreen**
   - Enter fullscreen
   - Switch quality
   - ✅ **Expected**: Stays in fullscreen, smooth transition
   - Exit fullscreen
   - ✅ **Expected**: Works normally

### 3. Network Conditions Test (5 minutes)

**Test on Different Networks:**

1. **WiFi (High Speed)**
   - Switch from Auto to 1080p
   - ✅ **Expected**: Loads quickly, plays smoothly

2. **4G (Medium Speed)**
   - Switch from Auto to 720p
   - ✅ **Expected**: Loads reasonably fast, plays smoothly

3. **3G (Low Speed)**
   - Switch from Auto to 360p
   - ✅ **Expected**: Loads and plays without buffering

4. **Auto Quality Adaptation**
   - Set to "Auto"
   - Watch the quality button
   - ✅ **Expected**: Shows current quality like "Auto (480p)"
   - ✅ **Expected**: Quality adjusts based on network speed

### 4. Edge Cases Test (5 minutes)

1. **Rapid Quality Switching**
   - Switch quality 3-4 times rapidly
   - ✅ **Expected**: No crashes, eventually settles on last selected quality

2. **Quality Switch at Video Start**
   - Open video
   - Immediately switch quality before it starts playing
   - ✅ **Expected**: Works without issues

3. **Quality Switch Near End**
   - Seek to last 10 seconds of video
   - Switch quality
   - ✅ **Expected**: Completes video normally

4. **Quality Switch After Pause/Resume**
   - Pause video
   - Wait 5 seconds
   - Switch quality
   - Resume playing
   - ✅ **Expected**: Works smoothly

## Common Issues & Solutions

### Issue: Video flickers when switching quality
**Solution**: This should be fixed now. If still happening:
- Check console for HLS.js errors
- Verify network connection is stable
- Try clearing app cache

### Issue: Quality button doesn't update
**Solution**: 
- Refresh the page/restart app
- Check if HLS playlist has multiple quality levels

### Issue: Video buffers after quality switch
**Solution**: 
- This is normal for 1-2 seconds on slow networks
- If buffering is excessive (>5 seconds), check network speed

### Issue: Controls don't work after quality switch
**Solution**: This should be fixed now. If still happening:
- Report immediately with device details
- Check browser console for errors

## Device Testing Matrix

Test on at least these devices:

| Device Type | OS | Browser/App | Priority |
|-------------|----|-----------|----|
| Android Phone | Android 11+ | App | High |
| Android Tablet | Android 11+ | App | Medium |
| iPhone | iOS 15+ | App | High |
| iPad | iOS 15+ | App | Medium |
| Desktop | Windows | Chrome | Low |
| Desktop | macOS | Safari | Low |

## Performance Benchmarks

### Quality Switch Time
- **Target**: < 1 second
- **Acceptable**: < 2 seconds
- **Poor**: > 3 seconds

### Frame Drops
- **Target**: 0 dropped frames
- **Acceptable**: < 5 frames
- **Poor**: > 10 frames

### Buffering After Switch
- **Target**: 0 seconds
- **Acceptable**: < 2 seconds
- **Poor**: > 3 seconds

## Reporting Issues

If you find issues, report with:
1. Device model and OS version
2. Network type (WiFi/4G/3G)
3. Steps to reproduce
4. Video of the issue (if possible)
5. Console logs (if available)

## Sign-off Checklist

Before approving for production:

- [ ] All basic quality switching tests pass
- [ ] All controls work during and after quality switch
- [ ] Tested on WiFi, 4G, and 3G
- [ ] Tested on at least 2 Android devices
- [ ] Tested on at least 1 iOS device
- [ ] No flickering or frame drops observed
- [ ] Quality button updates correctly
- [ ] Auto quality adapts to network conditions
- [ ] All edge cases handled gracefully
- [ ] No crashes or errors in console

## Test Results Template

```
Date: ___________
Tester: ___________
Device: ___________
OS: ___________
Network: ___________

Basic Quality Switching: ☐ Pass ☐ Fail
Controls During Switch: ☐ Pass ☐ Fail
Network Conditions: ☐ Pass ☐ Fail
Edge Cases: ☐ Pass ☐ Fail

Issues Found:
1. ___________
2. ___________

Overall: ☐ Approved ☐ Needs Work

Notes:
___________
```
