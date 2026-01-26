import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/receipt_data.dart';
import 'gemini_ocr_service.dart';

/// OCR service using Gemini Vision API
class OcrService {
  final GeminiOcrService _geminiService;

  OcrService() : _geminiService = GeminiOcrService() {
    if (!GeminiOcrService.isConfigured()) {
      throw Exception(
        '⚠️ Gemini API not configured. Please add GEMINI_API_KEY to .env file',
      );
    }
  }

  /// Initialize OCR service (no-op for Gemini)
  Future<void> initialize() async {
    debugPrint('✅ OCR Service initialized (Gemini Vision API)');
  }

  /// Scan receipt using Gemini OCR
  Future<ReceiptData?> scanReceipt(File imageFile) async {
    try {
      debugPrint('🤖 Scanning receipt with Gemini Vision API...');
      return await _geminiService.scanReceipt(imageFile);
    } catch (e) {
      debugPrint('❌ OCR Error: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    // Clean up if needed
  }
}
