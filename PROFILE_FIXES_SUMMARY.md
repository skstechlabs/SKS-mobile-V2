# Profile Management Fixes

## Issues Fixed

### 1. Manage Profiles - Continuous Loading ✅

**Problem:**
- Profile selection screen was continuously loading
- Never showed the profiles list
- API methods were missing

**Root Cause:**
- `getProfiles()` method missing in `api_service.dart`
- `getProfilesConfig()` method missing in `api_service.dart`
- `switchProfile()` method missing in `api_service.dart`

**Solution:**
Added three missing API methods to `lib/core/services/api_service.dart`:

```dart
// ── 32. GET /api/profiles - Get all profiles
Future<Map<String, dynamic>> getProfiles() async {
  try {
    final idToken = await _getIdToken();
    if (idToken == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final response = await _dio.get(
      '/api/profiles',
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );

    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    return _handleError(e);
  }
}

// ── 33. GET /api/profiles/config - Get profiles configuration
Future<Map<String, dynamic>> getProfilesConfig() async {
  try {
    final idToken = await _getIdToken();
    if (idToken == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final response = await _dio.get(
      '/api/profiles/config',
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );

    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    return _handleError(e);
  }
}

// ── 34. POST /api/profiles/switch - Switch to a profile
Future<Map<String, dynamic>> switchProfile(String profileUid) async {
  try {
    final idToken = await _getIdToken();
    if (idToken == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final response = await _dio.post(
      '/api/profiles/switch',
      data: {'profile_uid': profileUid},
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );

    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    return _handleError(e);
  }
}
```

### 2. Edit Profile Functionality - TODO

**Current State:**
- Profile screen displays user information
- No edit button or edit functionality exists
- `enhanced_profile_setup_screen.dart` has all the form fields

**Required Changes:**
1. Add "Edit Profile" button to `profile_screen.dart`
2. Modify `enhanced_profile_setup_screen.dart` to support edit mode:
   - Accept existing user data as parameter
   - Pre-fill all fields with current values
   - Make mobile number field read-only (cannot be edited)
   - Change title from "Complete Your Profile" to "Edit Profile"
   - Update API call to use update endpoint instead of create

**Recommended Implementation:**

#### Step 1: Add Edit Button to Profile Screen
```dart
// In profile_screen.dart, add after profile picture:
ElevatedButton.icon(
  onPressed: () => context.push('/edit-profile'),
  icon: const Icon(Icons.edit),
  label: Text(context.tr('edit_profile')),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primary,
    foregroundColor: Colors.white,
  ),
),
```

#### Step 2: Modify Enhanced Profile Setup Screen
```dart
class EnhancedProfileSetupScreen extends StatefulWidget {
  final bool isEditMode;
  final UserModel? existingUser;
  
  const EnhancedProfileSetupScreen({
    super.key,
    this.isEditMode = false,
    this.existingUser,
  });
  
  @override
  State<EnhancedProfileSetupScreen> createState() => _EnhancedProfileSetupScreenState();
}

class _EnhancedProfileSetupScreenState extends State<EnhancedProfileSetupScreen> {
  @override
  void initState() {
    super.initState();
    
    // Pre-fill fields if in edit mode
    if (widget.isEditMode && widget.existingUser != null) {
      _nameController.text = widget.existingUser!.name;
      _selectedGender = widget.existingUser!.gender;
      // ... pre-fill other fields
    }
  }
  
  // In build method, change title:
  Text(
    widget.isEditMode 
      ? context.tr('edit_profile')
      : context.tr('complete_your_profile'),
    ...
  ),
  
  // Make mobile field read-only:
  _buildField(
    controller: TextEditingController(text: _authState.user?.mobile ?? ''),
    label: context.tr('mobile'),
    icon: Icons.phone_outlined,
    readOnly: true,  // Always read-only
    enabled: false,  // Cannot be edited
  ),
}
```

#### Step 3: Add Route
```dart
// In router configuration:
GoRoute(
  path: '/edit-profile',
  builder: (context, state) => EnhancedProfileSetupScreen(
    isEditMode: true,
    existingUser: AuthState().user,
  ),
),
```

#### Step 4: Add Update API Method
```dart
// In api_service.dart:
Future<Map<String, dynamic>> updateUserProfile({
  required String name,
  String? gender,
  String? photo,
  // ... other fields
}) async {
  try {
    final idToken = await _getIdToken();
    if (idToken == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final response = await _dio.put(
      '/api/user/profile',
      data: {
        'name': name,
        'gender': gender,
        'photo': photo,
        // ... other fields
      },
      options: Options(headers: {'Authorization': 'Bearer $idToken'}),
    );

    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    return _handleError(e);
  }
}
```

## Files Modified

### ✅ Completed:
- `SKS-mobile-V2/lib/core/services/api_service.dart` - Added profile management API methods

### 📋 TODO:
- `SKS-mobile-V2/lib/features/profile/profile_screen.dart` - Add edit button
- `SKS-mobile-V2/lib/features/auth/enhanced_profile_setup_screen.dart` - Add edit mode support
- `SKS-mobile-V2/lib/core/router/app_router.dart` - Add edit-profile route
- `SKS-mobile-V2/lib/core/services/api_service.dart` - Add updateUserProfile method

## Testing Checklist

### Manage Profiles (Fixed):
- [ ] Open manage profiles screen
- [ ] Should load profiles list (not continuously loading)
- [ ] Should show all user profiles
- [ ] Should be able to switch between profiles
- [ ] Should navigate correctly after switching

### Edit Profile (TODO):
- [ ] Edit button visible on profile screen
- [ ] Clicking edit opens edit form
- [ ] All fields pre-filled with current values
- [ ] Mobile number field is read-only
- [ ] Can update name, gender, photo, etc.
- [ ] Cannot change mobile number
- [ ] Save button updates profile
- [ ] Returns to profile screen after save

---

**Status:** 
- Manage Profiles: ✅ Fixed
- Edit Profile: 📋 Needs Implementation

**Date:** April 10, 2026
