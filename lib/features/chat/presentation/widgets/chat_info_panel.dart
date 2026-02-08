import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// ChatGPT-exact right-side info panel
/// Hidden by default, slides in from right
/// Width: ~320px
/// Animation: 180-220ms, easeOutCubic
class ChatInfoPanel extends StatelessWidget {
  final String? chatTitle;
  final String modelName;
  final bool memoryEnabled;
  final VoidCallback onClearChat;
  final VoidCallback onNewChat;
  final VoidCallback onClose;
  final Function(String) onTitleChanged;
  final Function(bool) onMemoryToggled;

  const ChatInfoPanel({
    super.key,
    this.chatTitle,
    required this.modelName,
    required this.memoryEnabled,
    required this.onClearChat,
    required this.onNewChat,
    required this.onClose,
    required this.onTitleChanged,
    required this.onMemoryToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          left: BorderSide(
            color: AppColors.borderSubtle,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Chat Info',
                    style: GoogleFonts.inter(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close, color: AppColors.secondaryText),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            
            Divider(height: 1, color: AppColors.borderSubtle),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chat title
                    _buildSection(
                      'Title',
                      child: _EditableTitle(
                        title: chatTitle ?? 'New Chat',
                        onChanged: onTitleChanged,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Model info
                    _buildSection(
                      'Model',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: AppColors.accent,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                modelName,
                                style: GoogleFonts.inter(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.secondaryText,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Memory toggle
                    _buildSection(
                      'Memory',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.psychology_outlined,
                              color: memoryEnabled ? AppColors.accent : AppColors.secondaryText,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    memoryEnabled ? 'Enabled' : 'Disabled',
                                    style: GoogleFonts.inter(
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Chat remembers context',
                                    style: GoogleFonts.inter(
                                      color: AppColors.secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: memoryEnabled,
                              onChanged: onMemoryToggled,
                              activeTrackColor: AppColors.accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // System info
                    _buildSection(
                      'System',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: AppColors.secondaryText, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Chat ID',
                                  style: GoogleFonts.inter(
                                    color: AppColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chatTitle?.hashCode.toString() ?? 'New',
                              style: GoogleFonts.inter(
                                color: AppColors.primaryText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Divider(height: 1, color: AppColors.borderSubtle),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Export chat button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Export chat functionality
                      },
                      icon: Icon(Icons.download_outlined, size: 18, color: AppColors.primaryText),
                      label: Text('Export chat', style: GoogleFonts.inter(color: AppColors.primaryText)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.borderSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Clear chat button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onClearChat,
                      icon: Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                      label: Text('Clear chat', style: GoogleFonts.inter(color: AppColors.danger)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // New chat button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onNewChat,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('New Chat', style: GoogleFonts.inter()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _EditableTitle extends StatefulWidget {
  final String title;
  final Function(String) onChanged;

  const _EditableTitle({
    required this.title,
    required this.onChanged,
  });

  @override
  State<_EditableTitle> createState() => _EditableTitleState();
}

class _EditableTitleState extends State<_EditableTitle> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.title);
  }

  @override
  void didUpdateWidget(_EditableTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title && !_isEditing) {
      _controller.text = widget.title;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    widget.onChanged(_controller.text.trim());
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: _isEditing
          ? TextField(
              controller: _controller,
              autofocus: true,
              style: GoogleFonts.inter(color: AppColors.primaryText),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _save(),
            )
          : GestureDetector(
              onTap: () => setState(() => _isEditing = true),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ),
    );
  }
}
