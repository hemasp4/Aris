import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';

import '../../services/vault_service.dart';

/// Vault screen with PIN/biometric unlock
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
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
    
    final status = await vaultService.getStatus();
    final canBio = await _localAuth.canCheckBiometrics;
    
    setState(() {
      _status = status;
      _isUnlocked = status.unlocked;
      _canUseBiometrics = canBio;
      _isLoading = false;
    });
    
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
        localizedReason: 'Unlock your secret vault',
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
      setState(() => _error = 'Failed to setup vault');
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

  void _showAddItemDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Secret Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Secret Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final item = await vaultService.addItem(
                title: titleController.text,
                content: contentController.text,
              );
              if (item != null) {
                setState(() => _items.insert(0, item));
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Not set up
    if (_status == null || !_status!.enabled) {
      return _buildSetupScreen(theme);
    }

    // Locked
    if (!_isUnlocked) {
      return _buildUnlockScreen(theme);
    }

    // Unlocked - show items
    return _buildVaultScreen(theme);
  }

  Widget _buildSetupScreen(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secret Vault')),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Create Your Secret Vault',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Protect your private notes and passwords with a PIN',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: 'Create PIN (4-8 digits)',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _setupVault,
                icon: const Icon(Icons.lock),
                label: const Text('Create Vault'),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
      ),
    );
  }

  Widget _buildUnlockScreen(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secret Vault')),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock,
                size: 80,
                color: theme.colorScheme.primary,
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
              const SizedBox(height: 24),
              Text(
                'Unlock Your Vault',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 8,
                onSubmitted: (_) => _unlockWithPin(),
                decoration: InputDecoration(
                  labelText: 'Enter PIN',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _unlockWithPin,
                  ),
                ),
              ),
              if (_canUseBiometrics) ...[
                const SizedBox(height: 24),
                const Text('or'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _unlockWithBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use Biometrics'),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildVaultScreen(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secret Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: _lockVault,
            tooltip: 'Lock vault',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.note_add, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No secrets yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first secret',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.itemType == 'password' ? Icons.key : Icons.note,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(item.title),
                    subtitle: Text(
                      item.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
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
        title: Text(item.title),
        content: SelectableText(item.content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: item.content));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
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
