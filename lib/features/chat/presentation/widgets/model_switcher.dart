import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../providers/model_provider.dart';

/// AI model configuration for dropdown
class AIModelConfig {
  final String id;
  final String displayName;
  final String description;
  final IconData icon;
  final bool isPremium;

  const AIModelConfig({
    required this.id,
    required this.displayName,
    required this.description,
    required this.icon,
    this.isPremium = false,
  });
}

/// Available AI models with ChatGPT-style display names
const List<AIModelConfig> _availableModels = [
  AIModelConfig(
    id: 'aris-plus',
    displayName: 'Aris Plus',
    description: 'Our smartest model & more',
    icon: HugeIcons.strokeRoundedSparkles,
    isPremium: true,
  ),
  AIModelConfig(
    id: 'gpt-oss:120b-cloud',
    displayName: 'Aris 5.2',
    description: 'Flagship model for complex tasks',
    icon: HugeIcons.strokeRoundedAiBrain05,
  ),
  AIModelConfig(
    id: 'gpt-oss:20b-cloud',
    displayName: 'Aris 4o',
    description: 'Fast & efficient',
    icon: HugeIcons.strokeRoundedAiChat02,
  ),
];

/// ChatGPT-style model selector dropdown
/// 
/// Displays as a pill button with model name and dropdown arrow.
/// On tap, shows a dropdown with model options including:
/// - Sparkle icon for each model
/// - Model name and description
/// - Checkmark for selected model
/// - Premium option with upgrade button
class ModelSelector extends ConsumerStatefulWidget {
  const ModelSelector({super.key});

  @override
  ConsumerState<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends ConsumerState<ModelSelector> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Backdrop to close dropdown
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown positioned below the button
          Positioned(
            width: 280,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 8),
              child: Material(
                color: Colors.transparent,
                child: _ModelDropdown(
                  onSelect: (modelId) {
                    ref.read(modelProvider.notifier).selectModel(modelId);
                    _removeOverlay();
                  },
                  selectedModel: ref.read(modelProvider).selectedModel,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(String? modelId) {
    if (modelId == null) return 'Aris 4o';
    
    final model = _availableModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => _availableModels.last,
    );
    return model.displayName;
  }

  @override
  Widget build(BuildContext context) {
    final modelState = ref.watch(modelProvider);
    final theme = Theme.of(context);
    final displayName = _getDisplayName(modelState.selectedModel);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleDropdown,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isOpen
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                HugeIcon(
                  icon: _isOpen
                      ? HugeIcons.strokeRoundedArrowUp01
                      : HugeIcons.strokeRoundedArrowDown01,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dropdown content with model options
class _ModelDropdown extends StatelessWidget {
  const _ModelDropdown({
    required this.onSelect,
    required this.selectedModel,
  });

  final void Function(String modelId) onSelect;
  final String? selectedModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Model options
          for (int i = 0; i < _availableModels.length; i++) ...[
            _ModelOption(
              model: _availableModels[i],
              isSelected: selectedModel == _availableModels[i].id,
              onTap: () => onSelect(_availableModels[i].id),
            ),
            // Add divider except after last item
            if (i < _availableModels.length - 1)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),
          ],
        ],
      ),
    );
  }
}

/// Individual model option in dropdown
class _ModelOption extends StatelessWidget {
  const _ModelOption({
    required this.model,
    required this.isSelected,
    required this.onTap,
  });

  final AIModelConfig model;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: model.isPremium ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Model icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: model.isPremium
                    ? Colors.amber.withValues(alpha: 0.15)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: HugeIcon(
                  icon: model.icon,
                  color: model.isPremium
                      ? Colors.amber.shade700
                      : theme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Model name and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    model.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            // Checkmark or Upgrade button
            if (model.isPremium)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.shade700.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'Upgrade',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (isSelected)
              HugeIcon(
                icon: HugeIcons.strokeRoundedTick02,
                color: theme.colorScheme.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
