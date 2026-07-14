import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/localization_service.dart';
import 'auth_state.dart';

const List<String> _countries = ['India', 'USA', 'UK', 'Others'];
const List<String> _languages = [
  'English', 'తెలుగు (Telugu)', 'हिंदी (Hindi)',
  'தமிழ் (Tamil)', 'ಕನ್ನಡ (Kannada)', 'മലയാളം (Malayalam)',
];
const List<String> _referralSources = [
  'Friends-Family', 'SKS YouTube Videos', 'Facebook', 'Instagram',
  'Guruji Interview in PMC', 'Guruji Interview in Other Channels',
  'ఇంటర్వ్యూ చూసి', 'Other',
];

class EnhancedProfileSetupScreen extends StatefulWidget {
  final bool isEditMode;
  const EnhancedProfileSetupScreen({super.key, this.isEditMode = false});

  @override
  State<EnhancedProfileSetupScreen> createState() =>
      _EnhancedProfileSetupScreenState();
}

class _EnhancedProfileSetupScreenState
    extends State<EnhancedProfileSetupScreen> {
  final _authState = AuthState();
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();

  // Step tracking
  int _step = 0;
  static const int _totalSteps = 3;

  // Step 1 controllers
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  String? _selectedGender;
  File? _profileImage;
  bool _isGoogleUser = false;
  bool _mobileEditable = false;

  // Step 2 controllers
  final _ageCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  String? _selectedLanguage;
  String? _selectedCountry;
  final _countryOtherCtrl = TextEditingController();

  // Step 3 controllers
  String? _selectedReferral;
  final _referralOtherCtrl = TextEditingController();
  final _referrerNameCtrl = TextEditingController();
  final _referrerMobileCtrl = TextEditingController();
  final _fullAddressCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = 'English';
    _selectedCountry = 'India';
    final user = _authState.user;
    if (user != null) {
      _isGoogleUser = user.authProvider == 'google';
      final hasMobile = user.mobile.isNotEmpty &&
          RegExp(r'^\+?[0-9]{7,15}$').hasMatch(user.mobile);
      _mobileEditable = _isGoogleUser && !hasMobile;
      if (!_mobileEditable) _mobileCtrl.text = user.mobile;
      if (user.name.isNotEmpty) _nameCtrl.text = user.name;
    }
    if (widget.isEditMode) _loadProfile();
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _mobileCtrl, _ageCtrl, _cityCtrl, _professionCtrl,
      _countryOtherCtrl, _referralOtherCtrl, _referrerNameCtrl,
      _referrerMobileCtrl, _fullAddressCtrl, _commentsCtrl,
    ]) c.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final r = await _apiService.getProfile();
      if (r['success'] == true && mounted) {
        final d = r['user'] as Map<String, dynamic>;
        setState(() {
          _nameCtrl.text = d['name'] as String? ?? '';
          _selectedGender = d['gender'] as String?;
          _cityCtrl.text = d['city'] as String? ?? '';
          _professionCtrl.text = d['profession'] as String? ?? '';
          _selectedLanguage = d['preferred_language'] as String? ?? 'English';
          _selectedCountry = d['country'] as String? ?? 'India';
          _fullAddressCtrl.text = d['full_address'] as String? ?? '';
          _commentsCtrl.text = d['comments'] as String? ?? '';
          _selectedReferral = d['how_did_you_know'] as String?;
          _referrerNameCtrl.text = d['referrer_name'] as String? ?? '';
          _referrerMobileCtrl.text = d['referrer_mobile'] as String? ?? '';
          if (d['date_of_birth'] != null) {
            try {
              final dob = DateTime.parse(d['date_of_birth'] as String);
              _ageCtrl.text = (DateTime.now().year - dob.year).toString();
            } catch (_) {}
          }
        });
      }
    } catch (_) {}
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      if (!_validateStep()) return;
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  bool _validateStep() {
    if (_step == 0) {
      if (_nameCtrl.text.trim().length < 2) {
        _snack('Please enter your full name'); return false;
      }
      if (_selectedGender == null) {
        _snack('Please select your gender'); return false;
      }
    }
    if (_step == 1) {
      if (_ageCtrl.text.trim().isEmpty) {
        _snack('Please enter your age'); return false;
      }
      if (_cityCtrl.text.trim().isEmpty) {
        _snack('Please enter your city'); return false;
      }
    }
    return true;
  }

  Future<void> _pickImage() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) { _snack('Gallery permission required'); return; }
    final img = await _imagePicker.pickImage(
      source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (img != null) setState(() => _profileImage = File(img.path));
  }

  Future<void> _submit() async {
    if (!_validateStep()) return;
    setState(() => _isLoading = true);
    try {
      final country = _selectedCountry == 'Others'
          ? _countryOtherCtrl.text.trim() : _selectedCountry!;
      final result = widget.isEditMode
          ? await _apiService.updateProfile({
              'name': _nameCtrl.text.trim(),
              'gender': _selectedGender,
              'age': int.tryParse(_ageCtrl.text.trim()) ?? 0,
              'city': _cityCtrl.text.trim(),
              'profession': _professionCtrl.text.trim(),
              'preferred_language': _selectedLanguage,
              'country': country,
              'how_did_you_know': _selectedReferral ?? '',
              'referrer_name': _referrerNameCtrl.text.trim().isNotEmpty ? _referrerNameCtrl.text.trim() : null,
              'full_address': _fullAddressCtrl.text.trim().isNotEmpty ? _fullAddressCtrl.text.trim() : null,
              'comments': _commentsCtrl.text.trim().isNotEmpty ? _commentsCtrl.text.trim() : null,
            })
          : await _apiService.completeProfile(
              name: _nameCtrl.text.trim(),
              gender: _selectedGender ?? 'Other',
              age: int.tryParse(_ageCtrl.text.trim()) ?? 0,
              city: _cityCtrl.text.trim(),
              profession: _professionCtrl.text.trim().isNotEmpty
                  ? _professionCtrl.text.trim() : 'Sadhak',
              preferredLanguage: _selectedLanguage ?? 'English',
              country: country,
              howDidYouKnow: _selectedReferral ?? 'Friends-Family',
              fullAddress: _fullAddressCtrl.text.trim().isNotEmpty
                  ? _fullAddressCtrl.text.trim() : null,
              mobile: _mobileEditable && _mobileCtrl.text.trim().isNotEmpty
                  ? _mobileCtrl.text.trim() : null,
            );
      setState(() => _isLoading = false);
      if (result['success'] == true && mounted) {
        if (result['user'] != null) {
          final u = _authState.user!.copyWith(
            name: (result['user'] as Map)['name'] as String?,
            isProfileComplete: true,
          );
          await _authState.updateProfile(u);
        }
        if (widget.isEditMode) {
          context.pop();
          _snack('Profile updated successfully');
        } else {
          context.go('/notification-permission');
        }
      } else {
        _snack(result['message'] ?? 'Failed to save profile');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Something went wrong. Please try again.');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => _step > 0 ? _back() : context.pop(),
        ),
        title: Text(
          widget.isEditMode ? context.tr('edit_profile') : context.tr('create_profile'),
          style: const TextStyle(
            color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Step progress bar ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                Row(
                  children: List.generate(_totalSteps, (i) {
                    final done = i <= _step;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: done ? AppTheme.primary : AppTheme.softGray,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _stepTitles[_step],
                      style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Step ${_step + 1} of $_totalSteps',
                      style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Step content ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              physics: const BouncingScrollPhysics(),
              child: _buildStep(),
            ),
          ),

          // ── Bottom button ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: GestureDetector(
              onTap: _isLoading ? null : _next,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 14, offset: const Offset(0, 5)),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          _step == _totalSteps - 1 ? context.tr('save_profile') : context.tr('continue'),
                          style: const TextStyle(
                            color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> get _stepTitles => [
    context.tr('step_personal_info'),
    context.tr('step_location_profession'),
    context.tr('step_additional_details'),
  ];

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      default: return const SizedBox.shrink();
    }
  }

  // ── Step 1: Name, Gender, Photo ────────────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('tell_us_about_yourself'),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        const Text('Your basic identity in the spiritual journey',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),

        // Photo picker
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.tagBg,
                    border: Border.all(color: AppTheme.tagBorder, width: 2),
                  ),
                  child: _profileImage != null
                      ? ClipOval(child: Image.file(_profileImage!, fit: BoxFit.cover))
                      : const Icon(Icons.person_rounded, size: 46, color: AppTheme.primary),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primary, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(child: Text(context.tr('tap_to_add_photo'), style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
        const SizedBox(height: 24),

        _field(label: 'Full Name *', hint: 'e.g. Ravi Kumar', controller: _nameCtrl, icon: Icons.person_outline_rounded),
        const SizedBox(height: 16),

        if (_mobileEditable) ...[
          _field(label: 'Mobile Number *', hint: 'Enter 10-digit mobile', controller: _mobileCtrl, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
        ],

        // Gender
        const Text('Gender *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Row(
          children: ['Male', 'Female', 'Other'].map((g) {
            final sel = _selectedGender == g;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = g),
                child: Container(
                  margin: EdgeInsets.only(right: g != 'Other' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primary : AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? AppTheme.primary : AppTheme.softGray),
                  ),
                  child: Text(g,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sel ? Colors.white : AppTheme.textSecondary,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Step 2: Age, City, Profession, Language, Country ──────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('step_location_profession'),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(context.tr('location_profession_subtitle'),
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),

        _field(label: 'Age *', hint: 'e.g. 28', controller: _ageCtrl, icon: Icons.cake_outlined, keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _field(label: 'City *', hint: 'e.g. Hyderabad', controller: _cityCtrl, icon: Icons.location_city_outlined),
        const SizedBox(height: 16),
        _field(label: 'Profession', hint: 'e.g. Software Engineer', controller: _professionCtrl, icon: Icons.work_outline_rounded),
        const SizedBox(height: 16),

        _dropdown(label: 'Preferred Language *', value: _selectedLanguage,
          items: _languages, icon: Icons.language_outlined,
          onChanged: (v) => setState(() => _selectedLanguage = v)),
        const SizedBox(height: 16),

        _dropdown(label: 'Country *', value: _selectedCountry,
          items: _countries, icon: Icons.public_outlined,
          onChanged: (v) => setState(() => _selectedCountry = v)),

        if (_selectedCountry == 'Others') ...[
          const SizedBox(height: 12),
          _field(label: 'Specify Country', hint: 'Your country', controller: _countryOtherCtrl, icon: Icons.public_outlined),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Step 3: Referral, Address, Comments ───────────────────────────────────
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('A Few More Details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(context.tr('almost_done'),
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),

        _dropdown(label: 'How did you know about us?', value: _selectedReferral,
          items: _referralSources, icon: Icons.info_outline_rounded,
          onChanged: (v) => setState(() => _selectedReferral = v)),

        if (_selectedReferral == 'Other') ...[
          const SizedBox(height: 12),
          _field(label: 'Please specify', hint: 'How did you know?', controller: _referralOtherCtrl, icon: Icons.edit_outlined),
        ],
        const SizedBox(height: 16),
        _field(label: 'Referred by (Name)', hint: 'Optional', controller: _referrerNameCtrl, icon: Icons.person_add_outlined),
        const SizedBox(height: 16),
        _field(label: 'Referrer\'s Mobile', hint: 'Optional', controller: _referrerMobileCtrl, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        _field(label: 'Full Address', hint: 'Optional', controller: _fullAddressCtrl, icon: Icons.home_outlined, maxLines: 2),
        const SizedBox(height: 16),
        _field(label: 'Any message for Guruji?', hint: 'Optional', controller: _commentsCtrl, icon: Icons.message_outlined, maxLines: 3),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Shared field widget ───────────────────────────────────────────────────
  Widget _field({
    required String label, required String hint,
    required TextEditingController controller, required IconData icon,
    TextInputType keyboardType = TextInputType.text, int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
            filled: true,
            fillColor: AppTheme.cardSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.softGray)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.softGray)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  // ── Shared dropdown widget ────────────────────────────────────────────────
  Widget _dropdown({
    required String label, required String? value,
    required List<String> items, required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: items.contains(value) ? value : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
            filled: true,
            fillColor: AppTheme.cardSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.softGray)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.softGray)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          items: items.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)))).toList(),
          onChanged: onChanged,
          hint: Text('Select...', style: const TextStyle(color: AppTheme.textHint, fontSize: 14)),
          dropdownColor: AppTheme.cardSurface,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
