import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import 'auth_state.dart';

const List<String> _indianStates = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
  'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
  'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
  'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  'Delhi', 'Jammu & Kashmir', 'Ladakh', 'Puducherry',
];

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthState _authState = AuthState();
  final ApiService _apiService = ApiService();

  final _nameController    = TextEditingController();
  final _dobController     = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();

  String? _selectedGender;
  String? _selectedState;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnim  = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();

    // Pre-fill name if available (Google sign-in)
    final user = _authState.user;
    if (user != null && user.name.isNotEmpty) {
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dobController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      _showSnackBar('Please select your gender');
      return;
    }
    if (_selectedState == null) {
      _showSnackBar('Please select your state');
      return;
    }

    setState(() => _isLoading = true);

    // Calculate age from date of birth
    int age = 10; // Default age
    if (_dobController.text.isNotEmpty) {
      try {
        final parts = _dobController.text.split('/');
        if (parts.length == 3) {
          final year = int.parse(parts[2]);
          age = DateTime.now().year - year;
        }
      } catch (e) {
        debugPrint('Error calculating age: $e');
      }
    }

    // Call backend API to save profile
    final result = await _apiService.completeProfile(
      name: _nameController.text.trim(),
      gender: _selectedGender!,
      age: age,
      city: _addressController.text.trim().isNotEmpty 
          ? _addressController.text.trim() 
          : 'Not specified',
      profession: 'Not specified',
      preferredLanguage: 'English',
      country: 'India',
      dateOfBirth: _dobController.text.isNotEmpty ? _dobController.text : null,
      address: _addressController.text.trim().isNotEmpty 
          ? _addressController.text.trim() 
          : null,
      state: _selectedState,
      pincode: _pincodeController.text.trim().isNotEmpty 
          ? _pincodeController.text.trim() 
          : null,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Update local state
      final userData = result['user'] as Map<String, dynamic>;
      final updated = _authState.user!.copyWith(
        name: userData['name'] as String?,
        gender: userData['gender'] as String?,
        dateOfBirth: userData['date_of_birth'] as String?,
        address: userData['address'] as String?,
        state: userData['state'] as String?,
        pincode: userData['pincode'] as String?,
        isProfileComplete: userData['is_profile_complete'] as bool? ?? true,
      );

      _authState.updateProfile(updated);

      if (mounted) context.go('/profile-selection');
    } else {
      _showSnackBar(result['message'] ?? 'Failed to save profile. Please try again.');
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.white, AppTheme.beige.withOpacity(0.2)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withOpacity(0.1),
                          ),
                          child: Icon(Icons.person_outline, size: 36, color: AppTheme.primary),
                        ),
                        const SizedBox(height: 16),
                        Text('Complete Your Profile',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: AppTheme.primary,
                          )),
                        const SizedBox(height: 6),
                        Text('Tell us a little about yourself',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              validator: (v) => v!.trim().isEmpty ? 'Please enter your full name' : null,
                            ),
                            const SizedBox(height: 16),

                            // Gender
                            _buildDropdownField(
                              label: 'Gender',
                              icon: Icons.wc_outlined,
                              value: _selectedGender,
                              items: const ['Male', 'Female', 'Other'],
                              onChanged: (v) => setState(() => _selectedGender = v),
                            ),
                            const SizedBox(height: 16),

                            // Date of Birth
                            _buildField(
                              controller: _dobController,
                              label: 'Date of Birth',
                              icon: Icons.cake_outlined,
                              readOnly: true,
                              onTap: _pickDob,
                              validator: (v) => v!.isEmpty ? 'Please select your date of birth' : null,
                            ),
                            const SizedBox(height: 16),

                            _buildField(
                              controller: _addressController,
                              label: 'Address',
                              icon: Icons.home_outlined,
                              maxLines: 2,
                              validator: (v) => v!.trim().isEmpty ? 'Please enter your address' : null,
                            ),
                            const SizedBox(height: 16),

                            // State
                            _buildDropdownField(
                              label: 'State',
                              icon: Icons.map_outlined,
                              value: _selectedState,
                              items: _indianStates,
                              onChanged: (v) => setState(() => _selectedState = v),
                            ),
                            const SizedBox(height: 16),

                            _buildField(
                              controller: _pincodeController,
                              label: 'Pincode',
                              icon: Icons.pin_drop_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              validator: (v) {
                                if (v!.isEmpty) return 'Please enter your pincode';
                                if (v.length != 6) return 'Pincode must be 6 digits';
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            // Submit
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
                                    ? const SizedBox(width: 22, height: 22,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : const Text('Continue',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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
        ),
      ),
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
          fillColor: Colors.white,
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
