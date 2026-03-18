import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiChatbotService {
  GenerativeModel? _model;
  ChatSession? _chatSession;
  String? _initError;

  bool get isAvailable => _model != null;
  String? get initError => _initError;

  GeminiChatbotService() {
    String? apiKey;
    try {
      apiKey = dotenv.env['GEMINI_API_KEY'];
    } catch (e) {
      _initError = 'Dotenv chưa được khởi tạo: $e';
      debugPrint('[Chatbot][ERROR] $_initError');
      return;
    }

    if (apiKey == null || apiKey.isEmpty) {
      _initError = 'GEMINI_API_KEY not found in .env file';
      debugPrint('[Chatbot][ERROR] $_initError');
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: apiKey,
      systemInstruction: Content.system(_buildSystemPrompt()),
    );
  }

  /// Initialize a new chat session
  void startNewSession() {
    if (_model == null) {
      return;
    }

    _chatSession = _model!.startChat(history: []);
    debugPrint('[Chatbot] New chat session started');
  }

  /// Send a message to the chatbot
  Future<String> sendMessage(String message) async {
    if (_model == null) {
      if (_initError != null && _initError!.contains('GEMINI_API_KEY')) {
        return 'Lỗi: Chưa cấu hình GEMINI_API_KEY trong file .env';
      }
      return 'Lỗi: Dịch vụ chatbot chưa sẵn sàng. Vui lòng kiểm tra cấu hình .env và khởi động lại ứng dụng.';
    }

    try {
      if (_chatSession == null) {
        startNewSession();
      }

      debugPrint('[Chatbot] Sending message: $message');

      final response = await _chatSession!.sendMessage(Content.text(message));

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      debugPrint(
        '[Chatbot] Received response: ${text.substring(0, text.length > 100 ? 100 : text.length)}...',
      );
      return text;
    } catch (e) {
      debugPrint('[Chatbot][ERROR] Failed to send message: $e');

      if (e.toString().contains('API_KEY_INVALID')) {
        return 'Lỗi: API Key không hợp lệ. Vui lòng kiểm tra lại file .env';
      } else if (e.toString().contains('QUOTA_EXCEEDED')) {
        return 'Lỗi: Đã vượt quá giới hạn API. Vui lòng thử lại sau.';
      } else if (e.toString().contains('timeout')) {
        return 'Lỗi: Kết nối timeout. Vui lòng kiểm tra internet và thử lại.';
      }

      return 'Xin lỗi, tôi gặp sự cố kỹ thuật. Vui lòng thử lại sau.';
    }
  }

  /// Clear chat history and start fresh
  void clearHistory() {
    startNewSession();
    debugPrint('[Chatbot] Chat history cleared');
  }

  /// Build system prompt for financial advisor
  String _buildSystemPrompt() {
    return '''
Bạn là trợ lý tài chính thông minh của ứng dụng FinTracker - một ứng dụng quản lý chi tiêu cá nhân.

VAI TRÒ:
- Tư vấn về quản lý tài chính cá nhân
- Giúp người dùng lập kế hoạch chi tiêu hợp lý
- Đưa ra lời khuyên về tiết kiệm và đầu tư
- Phân tích thói quen chi tiêu
- Tư vấn về ngân sách và mục tiêu tài chính

NGUYÊN TẮC:
1. Luôn thân thiện, tích cực và khuyến khích
2. Đưa ra lời khuyên thực tế, dễ áp dụng cho người Việt Nam
3. Sử dụng tiếng Việt tự nhiên, dễ hiểu
4. Đề xuất cụ thể với ví dụ số liệu nếu có thể
5. Tôn trọng hoàn cảnh tài chính của từng người
6. Không đưa ra lời khuyên đầu tư rủi ro cao
7. Ưu tiên tính an toàn và bền vững trong tài chính

LĨNH VỰC CHUYÊN MÔN:
- Lập kế hoạch ngân sách hàng tháng
- Phương pháp tiết kiệm hiệu quả (50/30/20, 6 bình...)
- Quản lý nợ và thẻ tín dụng
- Xây dựng quỹ khẩn cấp
- Phân tích chi tiêu theo danh mục
- Đặt và theo dõi mục tiêu tài chính
- Tối ưu hóa chi tiêu sinh hoạt
- Lời khuyên về bảo hiểm cơ bản
- Kiến thức đầu tư căn bản (tiết kiệm, trái phiếu, quỹ...)

PHONG CÁCH TRẢ LỜI:
- Ngắn gọn nhưng đầy đủ thông tin
- Có cấu trúc rõ ràng (sử dụng bullet points khi cần)
- Emoji phù hợp để tạo cảm giác thân thiện 💰 📊 💡
- Đặt câu hỏi ngược để hiểu rõ hơn nhu cầu người dùng
- Khuyến khích người dùng chia sẻ thêm thông tin để tư vấn tốt hơn

LƯU Ý:
- Nếu không có đủ thông tin, hãy hỏi thêm
- Không đưa ra lời khuyên pháp lý hay thuế (khuyên tìm chuyên gia)
- Luôn nhắc nhở tính cá nhân hóa của mỗi tình huống tài chính
''';
  }
}
