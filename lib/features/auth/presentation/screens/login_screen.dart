import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// ChatGPT-EXACT Login Screen
/// Matches the exact UI from reference images:
/// - Back arrow top left
/// - Logo icon centered
/// - "Log in or sign up" title
/// - Email field with Continue button
/// - OR divider
/// - Continue with Google / Phone buttons
/// - Terms links at bottom
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  bool _biometricsAvailable = false;
  String _serverUrl = ApiConstants.baseUrl;
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadServerUrl();
  }

  Future<void> _loadServerUrl() async {
    final storedUrl = await _secureStorage.read(key: StorageKeys.baseUrl);
    if (storedUrl != null && storedUrl.isNotEmpty) {
      setState(() => _serverUrl = storedUrl);
      ApiConstants.setBaseUrl(storedUrl);
    }
  }

  Future<void> _checkBiometrics() async {
    final available = await authService.isBiometricsAvailable();
    final enabled = await authService.isBiometricLoginEnabled();
    if (mounted) {
      setState(() {
        _biometricsAvailable = available && enabled;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _continueWithEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your email'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
      return;
    }
    
    // Navigate to password screen or handle email-first auth
    // For now, show password dialog
    _showPasswordDialog(email);
  }

  void _showPasswordDialog(String email) {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Enter your password',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                email,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Password field
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () {
                      setModalState(() => obscurePassword = !obscurePassword);
                    },
                  ),
                ),
                onSubmitted: (_) => _doLogin(email, passwordController.text),
              ),
              
              const SizedBox(height: 16),
              
              // Continue button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _doLogin(email, passwordController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Forgot password?',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doLogin(String email, String password) async {
    Navigator.pop(context); // Close the password dialog
    
    // Auth provider will trigger router redirect automatically on success
    await ref.read(authProvider.notifier).login(
      username: email,
      password: password,
    );
  }

  Future<void> _signInWithGoogle() async {
    // Auth provider will trigger router redirect automatically on success
    await ref.read(authProvider.notifier).loginWithGoogle();
  }

  void _continueWithPhone() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Phone authentication coming soon'),
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }

  Future<void> _loginWithBiometrics() async {
    final success = await ref.read(authProvider.notifier).authenticateWithBiometrics();
    
    if (success && mounted) {
      context.go('/chat');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isAuthLoadingProvider);
    final error = ref.watch(authErrorProvider);
    
    // Use MediaQuery for responsive sizing
    final textScaler = MediaQuery.textScalerOf(context);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back button and server settings
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
                    ),
                    onPressed: () => context.canPop() ? context.pop() : null,
                    padding: EdgeInsets.zero,
                  ),
                  // Server settings button
                  IconButton(
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedSettings02,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                    ),
                    onPressed: () => _showServerUrlDialog(),
                    padding: EdgeInsets.zero,
                    tooltip: 'Server Settings',
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms),
            
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // ChatGPT-style logo icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderLight, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.auto_awesome,
                          color: AppColors.textPrimary,
                          size: 32,
                        ),
                      ),
                    ).animate().fadeIn().scale(delay: 100.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      'Log in or sign up',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: textScaler.scale(24),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms),
                    
                    const SizedBox(height: 12),
                    
                    // Subtitle
                    Text(
                      "You'll get smarter responses and can upload\nfiles, images and more.",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: textScaler.scale(14),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms),
                    
                    const SizedBox(height: 40),
                    
                    // Error message
                    if (error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, 
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, 
                                color: AppColors.error,
                                size: 18,
                              ),
                              onPressed: () {
                                ref.read(authProvider.notifier).clearError();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Email field - ChatGPT style with white bg and black text
                    TextField(
                      controller: _emailController,
                      style: TextStyle(
                        color: AppColors.textLight, // Dark text on white bg
                        fontSize: textScaler.scale(16),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: textScaler.scale(16),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _continueWithEmail(),
                    ).animate().fadeIn(delay: 400.ms),
                    
                    const SizedBox(height: 16),
                    
                    // Continue button - ChatGPT style (gray when empty, green when filled)
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _continueWithEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _emailController.text.isEmpty
                              ? AppColors.surfaceElevated
                              : AppColors.primary,
                          foregroundColor: _emailController.text.isEmpty
                              ? AppColors.textMuted
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: textScaler.scale(16),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ).animate().fadeIn(delay: 450.ms),
                    
                    const SizedBox(height: 24),
                    
                    // OR divider - ChatGPT style
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.borderLight)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.borderLight)),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Continue with Google - ChatGPT style with white bg
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _signInWithGoogle,
                        icon: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                          ),
                          child: const Icon(
                            Icons.g_mobiledata,
                            size: 24,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        label: Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: textScaler.scale(15),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: Colors.transparent,
                          side: const BorderSide(color: AppColors.borderLight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                    
                    const SizedBox(height: 12),
                    
                    // Continue with phone - ChatGPT style
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : _continueWithPhone,
                        icon: Icon(
                          Icons.phone_outlined,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                        label: Text(
                          'Continue with phone',
                          style: TextStyle(
                            fontSize: textScaler.scale(15),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          backgroundColor: Colors.transparent,
                          side: const BorderSide(color: AppColors.borderLight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 550.ms),
                    
                    if (_biometricsAvailable) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : _loginWithBiometrics,
                          icon: const Icon(Icons.fingerprint, size: 24),
                          label: Text(
                            'Use Biometrics',
                            style: TextStyle(
                              fontSize: textScaler.scale(15),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            backgroundColor: Colors.transparent,
                            side: const BorderSide(color: AppColors.borderLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                    ],
                    
                    const SizedBox(height: 24),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign up',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 620.ms),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Bottom Terms and Privacy links - ChatGPT style
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Terms of Use',
                      style: TextStyle(
                        color: AppColors.accentBlue,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.accentBlue,
                      ),
                    ),
                  ),
                  Text(
                    ' · ',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: AppColors.accentBlue,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.accentBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 650.ms),
          ],
        ),
      ),
    );
  }

  void _showServerUrlDialog() {
    final controller = TextEditingController(text: _serverUrl);
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCloud,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Server URL',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your backend server URL to connect.',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                    hintText: 'http://192.168.1.100:8000',
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedLink01,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Quick preset buttons
                Text(
                  'Quick presets:',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPresetChip('Localhost', 'http://localhost:8000', controller, setDialogState),
                    _buildPresetChip('Android Emu', 'http://10.0.2.2:8000', controller, setDialogState),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final url = controller.text.trim();
                if (url.isNotEmpty) {
                  // Update Dio client AND save to storage
                  // This ensures immediate effect without restart
                  await dioClient.setAndStoreBaseUrl(url);
                  
                  if (mounted) {
                    setState(() => _serverUrl = url);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Server URL updated to: $url'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String url, TextEditingController controller, StateSetter setDialogState) {
    return ActionChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 12,
        ),
      ),
      backgroundColor: AppColors.surfaceElevated,
      side: BorderSide(color: AppColors.borderLight),
      onPressed: () {
        controller.text = url;
        setDialogState(() {});
      },
    );
  }
}
