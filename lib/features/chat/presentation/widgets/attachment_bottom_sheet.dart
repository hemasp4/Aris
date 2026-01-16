import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/model_provider.dart';

/// ChatGPT-exact attachment bottom sheet
/// Matches reference image: Camera/Photos/Files top row with teal backgrounds
/// Model, Create image, Deep research, Shopping research, Web search tiles
class AttachmentBottomSheet extends ConsumerWidget {
  final VoidCallback? onCamera;
  final VoidCallback? onPhotos;
  final VoidCallback? onFiles;
  final VoidCallback? onCreateImage;
  final VoidCallback? onDeepResearch;
  final VoidCallback? onWebSearch;

  const AttachmentBottomSheet({
    super.key,
    this.onCamera,
    this.onPhotos,
    this.onFiles,
    this.onCreateImage,
    this.onDeepResearch,
    this.onWebSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedModel = ref.watch(selectedModelProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.secondaryText.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Media options row (Camera, Photos, Files with teal backgrounds)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildMediaOption(
                  context,
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  backgroundColor: const Color(0xFF115E59), // Teal-900
                  onTap: () {
                    Navigator.pop(context);
                    onCamera?.call();
                  },
                ),
                const SizedBox(width: 12),
                _buildMediaOption(
                  context,
                  icon: Icons.photo_library_outlined,
                  label: 'Photos',
                  backgroundColor: const Color(0xFF115E59),
                  onTap: () {
                    Navigator.pop(context);
                    onPhotos?.call();
                  },
                ),
                const SizedBox(width: 12),
                _buildMediaOption(
                  context,
                  icon: Icons.folder_outlined,
                  label: 'Files',
                  backgroundColor: const Color(0xFF115E59),
                  onTap: () {
                    Navigator.pop(context);
                    onFiles?.call();
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Divider(color: AppColors.borderSubtle, height: 1),
          
          // Feature options
          _buildFeatureTile(
            icon: Icons.auto_awesome,
            title: 'Model',
            subtitle: selectedModel,
            onTap: () {
              Navigator.pop(context);
              _showModelSelector(context, ref);
            },
          ),
          _buildFeatureTile(
            icon: Icons.auto_fix_high_outlined,
            title: 'Create image',
            subtitle: 'Visualize anything',
            onTap: () {
              Navigator.pop(context);
              onCreateImage?.call();
            },
          ),
          _buildFeatureTile(
            icon: Icons.science_outlined,
            title: 'Deep research',
            subtitle: 'Get a detailed report',
            onTap: () {
              Navigator.pop(context);
              onDeepResearch?.call();
            },
          ),
          _buildFeatureTile(
            icon: Icons.shopping_bag_outlined,
            title: 'Shopping research',
            subtitle: 'Get an in-depth guide',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildFeatureTile(
            icon: Icons.language,
            title: 'Web search',
            subtitle: 'Find real-time news and info',
            onTap: () {
              Navigator.pop(context);
              onWebSearch?.call();
            },
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    ).animate().slideY(begin: 0.2, end: 0, duration: 180.ms, curve: Curves.easeOut);
  }

  Widget _buildMediaOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryText, size: 22),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: AppColors.primaryText,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          color: AppColors.secondaryText,
          fontSize: 13,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    );
  }

  void _showModelSelector(BuildContext context, WidgetRef ref) {
    final models = ref.read(availableModelsProvider);
    final currentModel = ref.read(selectedModelProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.secondaryText.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select Model',
            style: GoogleFonts.inter(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...models.map((model) => ListTile(
            leading: Icon(
              Icons.auto_awesome,
              color: model.name == currentModel 
                  ? AppColors.accent 
                  : AppColors.secondaryText,
            ),
            title: Text(
              model.name,
              style: GoogleFonts.inter(
                color: model.name == currentModel 
                    ? AppColors.accent 
                    : AppColors.primaryText,
                fontWeight: model.name == currentModel 
                    ? FontWeight.w600 
                    : FontWeight.normal,
              ),
            ),
            trailing: model.name == currentModel 
                ? Icon(Icons.check, color: AppColors.accent)
                : null,
            onTap: () {
              ref.read(modelProvider.notifier).selectModel(model.name);
              Navigator.pop(context);
            },
          )),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

/// Show the attachment bottom sheet
void showAttachmentSheet(
  BuildContext context, {
  VoidCallback? onCamera,
  VoidCallback? onPhotos,
  VoidCallback? onFiles,
  VoidCallback? onCreateImage,
  VoidCallback? onDeepResearch,
  VoidCallback? onWebSearch,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => AttachmentBottomSheet(
      onCamera: onCamera,
      onPhotos: onPhotos,
      onFiles: onFiles,
      onCreateImage: onCreateImage,
      onDeepResearch: onDeepResearch,
      onWebSearch: onWebSearch,
    ),
  );
}
