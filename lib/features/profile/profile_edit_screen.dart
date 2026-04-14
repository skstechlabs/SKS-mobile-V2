import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/widgets/auth_guard.dart';
import '../auth/auth_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        _nameController.text = user.displayName ?? '';
        _phoneController.text = user.phoneNumber ?? '';
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Only send name, not phone number
      final response = await _apiService.updateProfile({
        'name': _nameController.text.trim(),
      });

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('profile_updated')),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? context.tr('failed_update_profile')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('network_error_check_connection')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('edit_profile')),
          actions: [
            if (!_isLoading && !_isSaving)
              TextButton(
                onPressed: _saveProfile,
                child: Text(
                  context.tr('save'),
                  style: const TextStyle(
                    color: AppTheme.saffron,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: context.tr('full_name'),
                          hintText: context.tr('enter_full_name'),
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.darkBrown.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.saffron,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('please_enter_name');
                          }
                          if (value.trim().length < 2) {
                            return context.tr('name_min_2_chars');
                          }
                          return null;
                        },
                        enabled: !_isSaving,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Phone Field (Read-only)
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: context.tr('phone_number'),
                          hintText: context.tr('enter_phone_number'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                          suffixIcon: const Icon(Icons.lock_outline, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.darkBrown.withValues(alpha: 0.2),
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          helperText: context.tr('mobile_cannot_change'),
                          helperStyle: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        enabled: false, // Make it non-editable
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.saffron,
                            disabledBackgroundColor: AppTheme.saffron.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  context.tr('save_changes'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
