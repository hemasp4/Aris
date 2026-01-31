import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/dio_client.dart';

/// Model info from Ollama
class OllamaModel {
  final String name;
  final double sizeGb;
  final int size;

  OllamaModel({
    required this.name,
    this.sizeGb = 0,
    this.size = 0,
  });

  factory OllamaModel.fromJson(Map<String, dynamic> json) {
    return OllamaModel(
      name: json['name'] ?? '',
      sizeGb: (json['size_gb'] ?? 0).toDouble(),
      size: json['size'] ?? 0,
    );
  }
}

/// State for model selection
class ModelState {
  final List<OllamaModel> models;
  final String? selectedModel;
  final bool isLoading;
  final bool geminiAvailable;
  final String? error;

  const ModelState({
    this.models = const [],
    this.selectedModel,
    this.isLoading = false,
    this.geminiAvailable = false,
    this.error,
  });

  ModelState copyWith({
    List<OllamaModel>? models,
    String? selectedModel,
    bool? isLoading,
    bool? geminiAvailable,
    String? error,
  }) {
    return ModelState(
      models: models ?? this.models,
      selectedModel: selectedModel ?? this.selectedModel,
      isLoading: isLoading ?? this.isLoading,
      geminiAvailable: geminiAvailable ?? this.geminiAvailable,
      error: error,
    );
  }
}

/// Model notifier for managing Ollama model selection
class ModelNotifier extends StateNotifier<ModelState> {
  ModelNotifier() : super(const ModelState()) {
    loadModels();
  }

  final _client = DioClient();

  /// Load lightweight models (under 3.2GB)
  Future<void> loadModels() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _client.dio.get('/models/lightweight');
      final data = response.data;
      
      final List modelsList = data['models'] ?? [];
      final models = modelsList
          .map((json) => OllamaModel.fromJson(json))
          .toList();
      
      // Set default model if none selected
      String? selected = state.selectedModel;
      if (selected == null && models.isNotEmpty) {
        // Prioritize Cloud Models (gpt-oss)
        final cloudIndex = models.indexWhere((m) => m.name.contains('gpt-oss'));
        if (cloudIndex != -1) {
          selected = models[cloudIndex].name;
        } else {
          selected = models.first.name;
        }
      }

      state = state.copyWith(
        models: models,
        selectedModel: selected,
        geminiAvailable: data['gemini_available'] ?? false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load models: $e',
      );
    }
  }

  /// Select a model
  void selectModel(String modelName) {
    state = state.copyWith(selectedModel: modelName);
  }

  /// Get current model for chat requests
  String get currentModel => state.selectedModel ?? 'gemini-2.0-flash';
}

/// Provider for model state
final modelProvider = StateNotifierProvider<ModelNotifier, ModelState>((ref) {
  return ModelNotifier();
});

/// Currently selected model
final selectedModelProvider = Provider<String>((ref) {
  return ref.watch(modelProvider).selectedModel ?? 'gemini-2.0-flash';
});

/// Available models list
final availableModelsProvider = Provider<List<OllamaModel>>((ref) {
  return ref.watch(modelProvider).models;
});

/// Is Gemini available for media tasks
final geminiAvailableProvider = Provider<bool>((ref) {
  return ref.watch(modelProvider).geminiAvailable;
});
