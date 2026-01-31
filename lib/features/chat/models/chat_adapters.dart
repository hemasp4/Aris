import 'package:hive/hive.dart';
import '../providers/chat_provider.dart';

class ChatSessionAdapter extends TypeAdapter<ChatSession> {
  @override
  final int typeId = 1;

  @override
  ChatSession read(BinaryReader reader) {
    return ChatSession(
      id: reader.readString(),
      title: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      isPinned: reader.readBool(),
      isArchived: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatSession obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
    writer.writeBool(obj.isPinned);
    writer.writeBool(obj.isArchived);
  }
}

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 2;

  @override
  ChatMessage read(BinaryReader reader) {
    return ChatMessage(
      id: reader.readString(),
      role: reader.readString(),
      content: reader.readString(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      isStreaming: false, // Don't persist streaming state
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.role);
    writer.writeString(obj.content);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
  }
}
