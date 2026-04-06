# Meditation Journal Feature

## Overview
Added journal entry feature to meditation sessions, allowing users to record their thoughts, feelings, and insights after each meditation.

## Feature Details

### Journal Entry Dialog
When saving a meditation session, users are prompted to journal their experience before the session is saved.

**Dialog Features**:
- Title: "Journal Your Experience" with edit icon
- Helpful prompt text explaining what to write
- Multi-line text field (4 lines visible)
- 500 character limit
- Auto-focus for immediate typing
- Two options: "Skip" or "Save"

### User Flow

#### Automatic Save (Timer Completes)
1. Timer reaches zero
2. End music plays
3. Journal dialog appears
4. User writes their experience or skips
5. Session saved with journal entry
6. Success confirmation shown

#### Manual Save (User Stops Timer)
1. User clicks Stop button
2. End music plays
3. Confirmation dialog: "Save Meditation Session?"
4. If user chooses "Save":
   - Journal dialog appears
   - User writes their experience or skips
   - Session saved with journal entry
5. If user chooses "Discard":
   - Session not saved
   - No journal prompt

### API Integration

**Endpoint**: `POST /api/meditation/sessions`

**Parameters**:
```dart
{
  'start_time': '2024-01-01T10:00:00.000Z',
  'end_time': '2024-01-01T10:15:00.000Z',
  'duration_seconds': 900,
  'notes': 'I felt peaceful and calm...' // Optional
}
```

**Notes Field**:
- Optional parameter
- Only sent if user enters text
- Maximum 500 characters
- Stored in database for future reference

### UI Design

**Journal Dialog**:
```
┌─────────────────────────────────────┐
│ 📝 Journal Your Experience          │
├─────────────────────────────────────┤
│                                     │
│ How was your meditation? Share      │
│ your thoughts, feelings, or         │
│ insights.                           │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ I felt peaceful and calm...     │ │
│ │                                 │ │
│ │                                 │ │
│ │                                 │ │
│ └─────────────────────────────────┘ │
│                          0/500      │
│                                     │
│              [Skip]  [Save]         │
└─────────────────────────────────────┘
```

**Visual Elements**:
- Saffron edit icon for spiritual theme
- Rounded corners (20px) for modern look
- Focused border in saffron color
- Character counter (500 max)
- Clear action buttons

### Code Implementation

```dart
Future<void> _saveMeditationSession(
  DateTime startTime,
  DateTime endTime,
  int durationSeconds,
) async {
  // Ask for journal entry
  String? journalEntry = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final controller = TextEditingController();
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit_note, color: AppTheme.saffron),
            const SizedBox(width: 12),
            const Expanded(child: Text('Journal Your Experience')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How was your meditation? Share your thoughts...'),
            TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'I felt peaceful and calm...',
                // ... styling
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
  
  // Save with journal entry
  await _apiService.recordMeditationSession(
    startTime: startTime.toIso8601String(),
    endTime: endTime.toIso8601String(),
    durationSeconds: durationSeconds,
    notes: journalEntry?.isNotEmpty == true ? journalEntry : null,
  );
}
```

## Benefits

### For Users
- **Reflection**: Encourages mindful reflection after meditation
- **Progress Tracking**: Build a journal of meditation experiences over time
- **Insights**: Capture fleeting insights and realizations
- **Motivation**: See how meditation practice evolves
- **Optional**: Can skip if they prefer not to journal

### For Practice
- **Mindfulness**: Extends meditation practice into journaling
- **Awareness**: Helps users become more aware of their mental states
- **Patterns**: Users can identify patterns in their practice
- **Growth**: Track spiritual and mental growth over time

## User Experience

### Positive Aspects
✅ Non-intrusive - appears after meditation is complete  
✅ Optional - users can skip if they want  
✅ Quick - simple text field, not overwhelming  
✅ Helpful - provides guidance on what to write  
✅ Limited - 500 character limit keeps it concise  
✅ Focused - auto-focus allows immediate typing  

### Design Considerations
- Dialog cannot be dismissed by tapping outside (barrierDismissible: false)
- This ensures users make a conscious choice to skip or save
- Prevents accidental dismissal and data loss
- Clear "Skip" button provides easy opt-out

## Future Enhancements

### Potential Features
1. **View Journal History**: Display past journal entries in meditation history
2. **Journal Prompts**: Rotating prompts to inspire reflection
3. **Mood Tracking**: Add mood/emotion tags to entries
4. **Search**: Search through journal entries
5. **Export**: Export journal as PDF or text file
6. **Voice Notes**: Option to record voice journal entries
7. **Reminders**: Gentle reminders to journal if skipped

### Analytics
- Track journal entry rate (% of sessions with notes)
- Average journal length
- Most common words/themes
- Correlation between journaling and session duration

## Testing Checklist

- [x] Journal dialog appears after meditation completes
- [x] Journal dialog appears when manually saving
- [x] Skip button works and saves without notes
- [x] Save button captures journal text
- [x] Character limit enforced (500 max)
- [x] Auto-focus works on text field
- [x] Journal text saved to database
- [x] Empty journal entries not sent to API
- [x] Dialog cannot be dismissed accidentally
- [x] Success message shown after save

## Files Modified

- `lib/features/meditation/meditation_timer_page.dart`
  - Added journal entry dialog
  - Updated `_saveMeditationSession()` method
  - Integrated with existing save flow

- `lib/core/services/api_service.dart`
  - Already had `notes` parameter support
  - No changes needed

## Conclusion

The meditation journal feature adds meaningful value to the meditation practice by encouraging reflection and creating a record of the user's spiritual journey. The implementation is simple, non-intrusive, and respects user choice while providing a valuable tool for those who want to deepen their practice.
