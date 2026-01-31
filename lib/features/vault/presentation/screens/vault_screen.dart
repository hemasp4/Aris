import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/theme/app_colors.dart';
import '../../services/vault_service.dart';

/// Private Space screen - Secure vault with PIN/biometric unlock
class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _pinController = TextEditingController();
  
  VaultStatus? _status;
  List<VaultItem> _items = [];
  bool _isLoading = true;
  bool _isUnlocked = false;
  String? _error;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    
    final status = await vaultService.getStatus(); // Keep this line to get status
    
    if (mounted) {
      // Skip biometric check on web to avoid MissingPluginException
      bool canCheck = false;
      try {
        if (!kIsWeb) {
            final auth = LocalAuthentication();
            canCheck = await auth.canCheckBiometrics && await auth.isDeviceSupported();
        }
      } catch (_) {}

      setState(() {
        _status = status; // Keep this to update _status
        _isLoading = false;
        _isUnlocked = status.unlocked;
        // _hasPin is covered by _status.hasPin
        _canUseBiometrics = canCheck;
      });
    }
    if (_isUnlocked) {
      await _loadItems();
    }
  }

  Future<void> _loadItems() async {
    final items = await vaultService.getItems();
    setState(() => _items = items);
  }

  Future<void> _unlockWithPin() async {
    if (_pinController.text.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits');
      return;
    }
    
    setState(() => _isLoading = true);
    
    final success = await vaultService.unlockWithPin(_pinController.text);
    
    if (success) {
      setState(() {
        _isUnlocked = true;
        _error = null;
      });
      await _loadItems();
    } else {
      setState(() => _error = 'Invalid PIN');
    }
    
    setState(() => _isLoading = false);
    _pinController.clear();
  }

  Future<void> _unlockWithBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock your Private Space',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      if (authenticated) {
        final success = await vaultService.unlockWithBiometric();
        if (success) {
          setState(() => _isUnlocked = true);
          await _loadItems();
        }
      }
    } on PlatformException catch (e) {
      setState(() => _error = 'Biometric failed: ${e.message}');
    }
  }

  Future<void> _setupVault() async {
    final pin = _pinController.text;
    if (pin.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits');
      return;
    }
    
    setState(() => _isLoading = true);
    
    final success = await vaultService.setupVault(pin);
    
    if (success) {
      setState(() {
        _isUnlocked = true;
        _status = VaultStatus(enabled: true, unlocked: true, hasPin: true);
      });
    } else {
      setState(() => _error = 'Failed to setup Private Space');
    }
    
    setState(() => _isLoading = false);
    _pinController.clear();
  }

  Future<void> _lockVault() async {
    await vaultService.lock();
    setState(() {
      _isUnlocked = false;
      _items = [];
    });
  }

  void _showAddNoteDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Add Private Note', style: TextStyle(color: AppColors.textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              style: const TextStyle(color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Secret content',
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final item = await vaultService.addItem(
                title: titleController.text,
                content: contentController.text,
              );
              if (item != null) {
                setState(() => _items.insert(0, item));
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Not set up
    if (_status == null || !_status!.enabled) {
      return _buildSetupScreen();
    }

    // Locked
    if (!_isUnlocked) {
      return _buildUnlockScreen();
    }

    // Unlocked - show items
    return _buildVaultScreen();
  }

  Widget _buildSetupScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => context.go('/chat'),
        ),
        title: const Text('Private Space'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.privateSpace.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppColors.privateSpace,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Create Private Space',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Protect your private chats and notes with a PIN or biometrics',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 8,
                style: const TextStyle(color: AppColors.textDark, fontSize: 24, letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '••••',
                  hintStyle: TextStyle(color: AppColors.textMuted, letterSpacing: 8),
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _error,
                  errorStyle: TextStyle(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a 4-8 digit PIN',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _setupVault,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.privateSpace,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Private Space',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
      ),
    );
  }

  Widget _buildUnlockScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => context.go('/chat'),
        ),
        title: const Text('Private Space'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.privateSpace.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  size: 64,
                  color: AppColors.privateSpace,
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(
                duration: 2.seconds,
                color: AppColors.privateSpace.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 32),
              Text(
                'Unlock Private Space',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 8,
                style: const TextStyle(color: AppColors.textDark, fontSize: 24, letterSpacing: 8),
                textAlign: TextAlign.center,
                onSubmitted: (_) => _unlockWithPin(),
                decoration: InputDecoration(
                  hintText: '••••',
                  hintStyle: TextStyle(color: AppColors.textMuted, letterSpacing: 8),
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _error,
                  errorStyle: TextStyle(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _unlockWithPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.privateSpace,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Unlock',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (_canUseBiometrics) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.dividerDark)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    Expanded(child: Divider(color: AppColors.dividerDark)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _unlockWithBiometric,
                    icon: const Icon(Icons.fingerprint, size: 24),
                    label: const Text('Use Biometrics'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: BorderSide(color: AppColors.inputBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildVaultScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => context.go('/chat'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, color: AppColors.privateSpace, size: 20),
            const SizedBox(width: 8),
            const Text('Private Space'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.lock_open, color: AppColors.textMuted),
            onPressed: _lockVault,
            tooltip: 'Lock',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        backgroundColor: AppColors.privateSpace,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.note_add_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No private notes yet',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first private note',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.settingsCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.privateSpace.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.itemType == 'password' ? Icons.key : Icons.note,
                        color: AppColors.privateSpace,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(color: AppColors.textDark),
                    ),
                    subtitle: Text(
                      item.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: AppColors.textMuted),
                      onPressed: () async {
                        final success = await vaultService.deleteItem(item.id);
                        if (success) {
                          setState(() => _items.removeAt(index));
                        }
                      },
                    ),
                    onTap: () => _showItemDetails(item),
                  ),
                ).animate().fadeIn(delay: (50 * index).ms);
              },
            ),
    );
  }

  void _showItemDetails(VaultItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(item.title, style: const TextStyle(color: AppColors.textDark)),
        content: SelectableText(
          item.content,
          style: const TextStyle(color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: item.content));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Copied to clipboard'),
                  backgroundColor: AppColors.surfaceDarkElevated,
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
