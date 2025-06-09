import 'package:get/get.dart';
import '../chat/individual_chat_page.dart';
import '../chat/models/chat_model.dart';
import '../services/firestore_service.dart';

class ChatController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> initiateChat(String currentUserId, String selectedUserId) async {
    final chatId = await _firestoreService.getOrCreateChat(currentUserId, selectedUserId);
    Get.to(() => IndividualChatPage(chatId: chatId));
  }

  Future<List<ChatModel>> getUsersByRole(String role) async {
    return await _firestoreService.getUsersByRole(role);
  }
}
