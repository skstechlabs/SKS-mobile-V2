import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/localization_service.dart';
import 'auth_state.dart';

const List<String> _countries = ['India', 'USA', 'UK', 'Others'];

const List<String> _languages = [
  'English',
  'తెలుగు (Telugu)',
  'हिंदी (Hindi)',
  'தமிழ் (Tamil)',
  'ಕನ್ನಡ (Kannada)',
  'മലയാളം (Malayalam)',
];

const List<String> _referralSources = [
  'Friends-Family',
  'SKS YouTube Videos',
  'Facebook',
  'Instagram',
  'Guruji Interview in PMC',
  'Guruji Interview in Other Channels',
  'ఇంటర్వ్యూ చూసి',
  'Other',
];

class EnhancedProfileSetupScreen extends StatefulWidget {
  final bool isEditMode;
  
  const EnhancedProfileSetupScreen({
    super.key,
    this.isEditMode = false,
  });

  @override
  State<EnhancedProfileSetupScreen> createState() => _EnhancedProfileSetupScreenState();
}

class _EnhancedProfileSetupScreenState extends State<EnhancedProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthState _authState = AuthState();
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  // Controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _professionController = TextEditingController();
  final _referralOtherController = TextEditingController();
  final _referrerNameController = TextEditingController();
  final _referrerMobileController = TextEditingController();
  final _countryOtherController = TextEditingController();
  final _fullAddressController = TextEditingController();
  final _commentsController = TextEditingController();

  // Selections
  String? _selectedGender;
  String? _selectedLanguage;
  String? _selectedReferralSource;
  String? _selectedCountry;
  
  // Google users may not have a mobile number — allow them to enter one
  bool _isGoogleUser = false;
  bool _mobileEditable = false;
  
  File? _profileImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.isEditMode) {
      // In edit mode, fetch complete profile from backend
      _loadProfileData();
    } else {
      // In setup mode, pre-fill name if available (Google sign-in)
      final user = _authState.user;
      if (user != null && user.name.isNotEmpty) {
        _nameController.text = user.name;
      }
      
      // Detect Google users — they may have no mobile number
      if (user != null) {
        _isGoogleUser = user.authProvider == 'google';
        final hasMobile = user.mobile.isNotEmpty &&
            RegExp(r'^\+?[0-9]{7,15}$').hasMatch(user.mobile);
        _mobileEditable = _isGoogleUser && !hasMobile;
        if (!_mobileEditable) {
          _mobileController.text = user.mobile;
        }
      }
      
      // Set default language to English
      _selectedLanguage = 'English';
      _selectedCountry = 'India';
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final result = await _apiService.getProfile();
      
      if (result['success'] == true && mounted) {
        final userData = result['user'] as Map<String, dynamic>;
        
        setState(() {
          // Pre-fill all fields from backend
          _nameController.text = userData['name'] as String? ?? '';
          _selectedGender = userData['gender'] as String?;
          
          // Calculate age from date_of_birth
          if (userData['date_of_birth'] != null) {
            try {
              final dob = DateTime.parse(userData['date_of_birth'] as String);
              final age = DateTime.now().year - dob.year;
              _ageController.text = age.toString();
            } catch (e) {
              debugPrint('Error parsing date of birth: $e');
            }
          }
          
          _cityController.text = userData['city'] as String? ?? userData['address'] as String? ?? '';
          _professionController.text = userData['profession'] as String? ?? '';
          _selectedLanguage = userData['preferred_language'] as String? ?? 'English';
          _selectedCountry = userData['country'] as String? ?? 'India';
          _fullAddressController.text = userData['full_address'] as String? ?? userData['address'] as String? ?? '';
          _commentsController.text = userData['comments'] as String? ?? '';
          
          // Handle referral info
          _selectedReferralSource = userData['how_did_you_know'] as String?;
          if (_selectedReferralSource == 'Other') {
            _referralOtherController.text = userData['how_did_you_know_other'] as String? ?? '';
          }
          
          _referrerNameController.text = userData['referrer_name'] as String? ?? '';
          _referrerMobileController.text = userData['referrer_mobile'] as String? ?? '';
          
          // If country is not in the list, select "Others" and fill the other field
          if (_selectedCountry != null && !_countries.contains(_selectedCountry)) {
            _countryOtherController.text = _selectedCountry!;
            _selectedCountry = 'Others';
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      // Continue with empty fields if loading fails
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _professionController.dispose();
    _referralOtherController.dispose();
    _referrerNameController.dispose();
    _referrerMobileController.dispose();
    _countryOtherController.dispose();
    _fullAddressController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate required selections
    if (_selectedGender == null) {
      _showSnackBar(context.tr('please_select_gender'));
      return;
    }
    if (_selectedLanguage == null) {
      _showSnackBar(context.tr('please_select_language'));
      return;
    }
    if (_selectedReferralSource == null) {
      _showSnackBar(context.tr('please_select_referral_source'));
      return;
    }
    if (_selectedCountry == null) {
      _showSnackBar(context.tr('please_select_country'));
      return;
    }

    // Validate mobile for Google users who need to enter it
    if (_mobileEditable && _mobileController.text.trim().length < 10) {
      _showSnackBar(context.tr('mobile_required'));
      return;
    }

    // Validate full address
    if (_fullAddressController.text.trim().isEmpty) {
      _showSnackBar(context.tr('address_required'));
      return;
    }

    // Validate conditional fields
    if (_selectedReferralSource == 'Other' && _referralOtherController.text.trim().isEmpty) {
      _showSnackBar(context.tr('please_specify_other_referral'));
      return;
    }
    if (_selectedCountry == 'Others' && _countryOtherController.text.trim().isEmpty) {
      _showSnackBar(context.tr('please_specify_other_country'));
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Upload profile image if selected
      String? photoUrl;
      if (_profileImage != null) {
        try {
          final uploadResult = await _apiService.uploadProfilePhoto(_profileImage!);
          if (uploadResult['success'] == true) {
            photoUrl = uploadResult['photoUrl'];
          }
        } catch (uploadError) {
          debugPrint('Photo upload error: $uploadError');
          // Continue without photo if upload fails
        }
      }

      // Prepare data
      final country = _selectedCountry == 'Others' 
          ? _countryOtherController.text.trim() 
          : _selectedCountry!;
      
      final howDidYouKnow = _selectedReferralSource!;
      final howDidYouKnowOther = _selectedReferralSource == 'Other' 
          ? _referralOtherController.text.trim() 
          : null;

      // Call backend API to save/update profile
      final result = widget.isEditMode
          ? await _apiService.updateProfile({
              'name': _nameController.text.trim(),
              'gender': _selectedGender,
              'age': int.parse(_ageController.text.trim()),
              'city': _cityController.text.trim(),
              'profession': _professionController.text.trim(),
              'preferred_language': _selectedLanguage,
              'how_did_you_know': howDidYouKnow,
              'how_did_you_know_other': howDidYouKnowOther,
              'referrer_name': _referrerNameController.text.trim().isNotEmpty 
                  ? _referrerNameController.text.trim() 
                  : null,
              'referrer_mobile': _referrerMobileController.text.trim().isNotEmpty 
                  ? _referrerMobileController.text.trim() 
                  : null,
              'country': country,
              'full_address': _fullAddressController.text.trim().isNotEmpty 
                  ? _fullAddressController.text.trim() 
                  : null,
              'comments': _commentsController.text.trim().isNotEmpty 
                  ? _commentsController.text.trim() 
                  : null,
              if (photoUrl != null) 'photo': photoUrl,
            })
          : await _apiService.completeProfile(
              name: _nameController.text.trim(),
              gender: _selectedGender!,
              age: int.parse(_ageController.text.trim()),
              city: _cityController.text.trim(),
              profession: _professionController.text.trim(),
              preferredLanguage: _selectedLanguage!,
              country: country,
              howDidYouKnow: howDidYouKnow,
              howDidYouKnowOther: howDidYouKnowOther,
              referrerName: _referrerNameController.text.trim().isNotEmpty 
                  ? _referrerNameController.text.trim() 
                  : null,
              referrerMobile: _referrerMobileController.text.trim().isNotEmpty 
                  ? _referrerMobileController.text.trim() 
                  : null,
              fullAddress: _fullAddressController.text.trim().isNotEmpty 
                  ? _fullAddressController.text.trim() 
                  : null,
              comments: _commentsController.text.trim().isNotEmpty 
                  ? _commentsController.text.trim() 
                  : null,
              // Pass mobile for Google users who entered it
              mobile: _mobileEditable && _mobileController.text.trim().isNotEmpty
                  ? _mobileController.text.trim()
                  : null,
            );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // Update local state
        final userData = result['user'] as Map<String, dynamic>;
        final updated = _authState.user!.copyWith(
          name: userData['name'] as String?,
          gender: userData['gender'] as String?,
          photo: userData['photo'] as String?,
          isProfileComplete: userData['is_profile_complete'] as bool? ?? true,
        );

        await _authState.updateProfile(updated); // Now persists to cache

        if (mounted) {
          if (widget.isEditMode) {
            // In edit mode, go back to profile screen
            context.pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('profile_updated_successfully')),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // In setup mode, go to notification permission screen
            context.go('/notification-permission');
          }
        }
      } else {
        _showSnackBar(result['message'] ?? context.tr('failed_to_save_profile'));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(context.tr('error_saving_profile'));
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.isEditMode 
            ? context.tr('edit_profile')
            : context.tr('complete_your_profile'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.white, AppTheme.beige.withValues(alpha: 0.2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header (only show in setup mode, not edit mode)
              if (!widget.isEditMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    children: [
                      // Profile Photo
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                image: _profileImage != null
                                    ? DecorationImage(
                                        image: FileImage(_profileImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _profileImage == null
                                  ? const Icon(Icons.person_outline, size: 48, color: AppTheme.primary)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('complete_your_profile'),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('tell_us_about_yourself'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: widget.isEditMode ? 16 : 24),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        
                        // 1. Full Name
                        _buildField(
                          controller: _nameController,
                          label: context.tr('full_name'),
                          icon: Icons.person_outline,
                          validator: (v) => v!.trim().isEmpty ? context.tr('name_required') : null,
                        ),
                        const SizedBox(height: 20),

                        // 2. Mobile — mandatory for all users
                        _buildMobileField(),
                        const SizedBox(height: 20),

                        // 3. City/District/Village
                        _buildField(
                          controller: _cityController,
                          label: context.tr('city_district_village'),
                          icon: Icons.location_city_outlined,
                          validator: (v) => v!.trim().isEmpty ? context.tr('city_required') : null,
                        ),
                        const SizedBox(height: 16),

                        // 4. Gender
                        _buildDropdownField(
                          label: context.tr('gender'),
                          icon: Icons.wc_outlined,
                          value: _selectedGender,
                          items: ['Male', 'Female', 'Other'],
                          onChanged: (v) => setState(() => _selectedGender = v),
                        ),
                        const SizedBox(height: 16),

                        // 5. Age
                        _buildField(
                          controller: _ageController,
                          label: context.tr('age_in_years'),
                          icon: Icons.cake_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          validator: (v) {
                            if (v!.isEmpty) return context.tr('age_required');
                            final age = int.tryParse(v);
                            if (age == null || age < 5 || age > 120) {
                              return context.tr('age_must_be_valid');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 6. Profession
                        _buildField(
                          controller: _professionController,
                          label: context.tr('your_profession'),
                          icon: Icons.work_outline,
                          validator: (v) => v!.trim().isEmpty ? context.tr('profession_required') : null,
                        ),
                        const SizedBox(height: 16),

                        // 7. Preferred Language
                        _buildDropdownField(
                          label: context.tr('preferred_language'),
                          icon: Icons.language_outlined,
                          value: _selectedLanguage,
                          items: _languages,
                          onChanged: (v) => setState(() => _selectedLanguage = v),
                        ),
                        const SizedBox(height: 16),

                        // 8. How did you know about SKS?
                        _buildDropdownField(
                          label: context.tr('how_did_you_know_sks'),
                          icon: Icons.info_outline,
                          value: _selectedReferralSource,
                          items: _referralSources,
                          onChanged: (v) => setState(() => _selectedReferralSource = v),
                        ),
                        if (_selectedReferralSource == 'Other') ...[
                          const SizedBox(height: 16),
                          _buildField(
                            controller: _referralOtherController,
                            label: context.tr('please_specify'),
                            icon: Icons.edit_outlined,
                            validator: (v) => v!.trim().isEmpty ? context.tr('please_specify_other') : null,
                          ),
                        ],
                        const SizedBox(height: 16),

                        // 9. Referrer Name & Mobile
                        Text(
                          context.tr('referrer_info'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildField(
                          controller: _referrerNameController,
                          label: context.tr('referrer_name'),
                          icon: Icons.person_add_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _referrerMobileController,
                          label: context.tr('referrer_mobile'),
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 10. Country
                        _buildDropdownField(
                          label: context.tr('country'),
                          icon: Icons.public_outlined,
                          value: _selectedCountry,
                          items: _countries,
                          onChanged: (v) => setState(() => _selectedCountry = v),
                        ),
                        if (_selectedCountry == 'Others') ...[
                          const SizedBox(height: 16),
                          _buildField(
                            controller: _countryOtherController,
                            label: context.tr('please_specify_country'),
                            icon: Icons.edit_outlined,
                            validator: (v) => v!.trim().isEmpty ? context.tr('country_required') : null,
                          ),
                        ],
                        const SizedBox(height: 16),

                        // 11. Full Address (mandatory)
                        _buildField(
                          controller: _fullAddressController,
                          label: context.tr('full_address'),
                          icon: Icons.home_outlined,
                          maxLines: 3,
                          validator: (v) => v!.trim().isEmpty ? context.tr('address_required') : null,
                        ),
                        const SizedBox(height: 16),

                        // 12. Comments (optional)
                        _buildField(
                          controller: _commentsController,
                          label: '${context.tr('questions_comments')} (${context.tr('optional')})',
                          icon: Icons.comment_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    context.tr('continue'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileField() {
    if (_mobileEditable) {
      // Google user with no phone — must enter one (mandatory)
      return _buildField(
        controller: _mobileController,
        label: context.tr('mobile'),
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        validator: (v) {
          if (v == null || v.trim().isEmpty) return context.tr('mobile_required');
          if (v.trim().length < 10) return context.tr('mobile_must_be_valid');
          return null;
        },
      );
    }
    // Phone/existing user — show read-only (already verified)
    return _buildField(
      controller: TextEditingController(text: _authState.user?.mobile ?? ''),
      label: context.tr('mobile'),
      icon: Icons.phone_outlined,
      readOnly: true,
      enabled: false,
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    bool enabled = true,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.softShadow],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        readOnly: readOnly,
        enabled: enabled,
        onTap: onTap,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.softShadow],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        borderRadius: BorderRadius.circular(16),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      ),
    );
  }
}
