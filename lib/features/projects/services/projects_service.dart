import '../../../core/services/dio_client.dart';

/// Service for managing projects (private workspaces)
class ProjectsService {
  final DioClient _client = DioClient();

  /// List all projects
  Future<List<Project>> getProjects() async {
    try {
      final response = await _client.dio.get('/projects');
      final List data = response.data;
      return data.map((json) => Project.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Create a new project
  Future<Project?> createProject({
    required String name,
    String? description,
    String color = '#4F46E5',
    String icon = 'folder',
  }) async {
    try {
      final response = await _client.dio.post('/projects', data: {
        'name': name,
        'description': description,
        'color': color,
        'icon': icon,
      });
      return Project.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  /// Update a project
  Future<Project?> updateProject(String projectId, {
    String? name,
    String? description,
    String? color,
    String? icon,
  }) async {
    try {
      final response = await _client.dio.patch('/projects/$projectId', data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
      });
      return Project.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  /// Delete a project
  Future<bool> deleteProject(String projectId) async {
    try {
      await _client.dio.delete('/projects/$projectId');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get chats in a project
  Future<List<ProjectChat>> getProjectChats(String projectId) async {
    try {
      final response = await _client.dio.get('/projects/$projectId/chats');
      final List data = response.data['chats'] ?? [];
      return data.map((json) => ProjectChat.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Create a chat in a project
  Future<ProjectChat?> createProjectChat(String projectId, {String title = 'New Chat'}) async {
    try {
      final response = await _client.dio.post('/projects/$projectId/chats', data: {
        'title': title,
      });
      return ProjectChat.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
}

/// Project model
class Project {
  final String id;
  final String name;
  final String? description;
  final String color;
  final String icon;
  final int chatCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.icon,
    required this.chatCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      color: json['color'] ?? '#4F46E5',
      icon: json['icon'] ?? 'folder',
      chatCount: json['chat_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// Project chat model
class ProjectChat {
  final String id;
  final String title;
  final String createdAt;

  ProjectChat({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  factory ProjectChat.fromJson(Map<String, dynamic> json) {
    return ProjectChat(
      id: json['id'],
      title: json['title'] ?? 'Untitled',
      createdAt: json['created_at'],
    );
  }
}

/// Global projects service
final projectsService = ProjectsService();
