import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/model_provider.dart';

/// Model switcher dropdown for AppBar
class ModelSwitcher extends ConsumerWidget {
  const ModelSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelState = ref.watch(modelProvider);
    final theme = Theme.of(context);

    if (modelState.isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (modelState.models.isEmpty) {
      return TextButton.icon(
        onPressed: () => ref.read(modelProvider.notifier).loadModels(),
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('No models'),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: modelState.selectedModel,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          items: [
            // Ollama models
            ...modelState.models.map((model) => DropdownMenuItem(
              value: model.name,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.smart_toy,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(model.name.split(':').first),
                  const SizedBox(width: 4),
                  Text(
                    '${model.sizeGb}GB',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(modelProvider.notifier).selectModel(value);
            }
          },
        ),
      ),
    );
  }
}

/// Compact model indicator for AppBar
class CompactModelIndicator extends ConsumerWidget {
  const CompactModelIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedModel = ref.watch(selectedModelProvider);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showModelPicker(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              selectedModel.split(':').first,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  void _showModelPicker(BuildContext context, WidgetRef ref) {
    final modelState = ref.read(modelProvider);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Select Model',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (modelState.geminiAvailable)
                    Chip(
                      avatar: Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      label: const Text('Gemini for media'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...modelState.models.map((model) => ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.smart_toy,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: Text(model.name),
              subtitle: Text('${model.sizeGb} GB'),
              trailing: modelState.selectedModel == model.name
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(modelProvider.notifier).selectModel(model.name);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
