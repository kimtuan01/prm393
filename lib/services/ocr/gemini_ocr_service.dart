import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../models/receipt_data.dart';

class GeminiOcrService {
  static const String _apiUrl = 'https://api-ocr-production.up.railway.app';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  GeminiOcrService();

  /// Scan receipt image and extract transaction data
  Future<ReceiptData> scanReceipt(File imageFile) async {
    final totalSw = Stopwatch()..start();
    try {
      debugPrint('[OCR] Starting scan...');

      final apiSw = Stopwatch()..start();
      final response = await _uploadImageToOcr(imageFile);
      apiSw.stop();
      debugPrint('[OCR] API call took ${apiSw.elapsedMilliseconds}ms');

      final parseSw = Stopwatch()..start();
      final receiptData = _parseOcrResponse(response);
      parseSw.stop();
      debugPrint('[OCR] Parse took ${parseSw.elapsedMilliseconds}ms');

      totalSw.stop();
      debugPrint(
        '[OCR] Total scanReceipt duration ${totalSw.elapsedMilliseconds}ms',
      );
      return receiptData;
    } catch (e, stack) {
      totalSw.stop();
      debugPrint(
        '[OCR][ERROR] Scan failed after ${totalSw.elapsedMilliseconds}ms',
      );
      debugPrint('[OCR][ERROR] Exception: $e');
      debugPrint('[OCR][ERROR] Stack: $stack');

      // Return default data instead of rethrowing to prevent app crash
      String errorMessage = 'Scan failed';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Timeout - Server không phản hồi. Vui lòng thử lại.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Không có kết nối internet. Vui lòng kiểm tra kết nối.';
      } else if (e.toString().contains('404')) {
        errorMessage = 'API endpoint không tìm thấy.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Lỗi server. Vui lòng thử lại sau.';
      } else {
        errorMessage = 'Lỗi: ${e.toString()}';
      }

      return ReceiptData(
        merchant: 'Error',
        amount: 0,
        date: DateTime.now(),
        category: 'Other',
        items: [],
        confidence: 0.0,
        notes: errorMessage,
      );
    }
  }

  /// Upload image to OCR API and get response
  Future<Map<String, dynamic>> _uploadImageToOcr(File imageFile) async {
    Exception? lastException;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint('[OCR] API call attempt $attempt/$_maxRetries');
        debugPrint('[OCR] Uploading to: $_apiUrl/api/ocr');

        // Create multipart request
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_apiUrl/api/ocr'),
        );

        // Add image file
        final imageBytes = await imageFile.readAsBytes();
        debugPrint('[OCR] Image size: ${imageBytes.length} bytes');

        // Determine content type from file extension
        final fileName = imageFile.path.toLowerCase();
        String mimeType = 'image/jpeg';
        if (fileName.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (fileName.endsWith('.webp')) {
          mimeType = 'image/webp';
        }

        final multipartFile = http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'receipt.jpg',
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);

        debugPrint('[OCR] Sending request...');
        // Send request
        final streamedResponse = await request.send().timeout(
          Duration(seconds: 30),
          onTimeout: () {
            debugPrint('[OCR] Request timeout!');
            throw Exception('Request timeout after 30 seconds');
          },
        );

        debugPrint(
          '[OCR] Got response with status: ${streamedResponse.statusCode}',
        );

        // Get response
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          debugPrint('[OCR] Success! Response: ${response.body}');
          final jsonResponse =
              jsonDecode(response.body) as Map<String, dynamic>;
          return jsonResponse;
        } else {
          debugPrint(
            '[OCR] API error ${response.statusCode}: ${response.body}',
          );
          throw Exception(
            'API error: ${response.statusCode} - ${response.body}',
          );
        }
      } catch (e, stackTrace) {
        lastException = Exception('OCR API error: $e');
        debugPrint('[OCR] ❌ Error (attempt $attempt/$_maxRetries): $e');
        debugPrint('[OCR] Error type: ${e.runtimeType}');
        if (attempt == 1) {
          debugPrint('[OCR] Stack trace: $stackTrace');
        }

        if (attempt < _maxRetries) {
          debugPrint(
            '[OCR] Retrying in ${_retryDelay.inSeconds * attempt} seconds...',
          );
          await Future.delayed(_retryDelay * attempt);
        }
      }
    }

    debugPrint('[OCR] ❌ All $_maxRetries attempts failed!');
    throw lastException ??
        Exception('Failed to call OCR API after $_maxRetries attempts');
  }

  /// Parse OCR API response to ReceiptData
  ReceiptData _parseOcrResponse(Map<String, dynamic> json) {
    try {
      debugPrint('[OCR] Parsing response: $json');

      // Extract data from response
      final success = json['success'] as bool? ?? false;
      if (!success) {
        throw Exception('API returned success: false');
      }

      // Get the actual data object
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('No data field in response');
      }

      // Parse merchant name
      final merchant = data['merchant_name'] as String? ?? 'Unknown';

      // Parse total amount
      final totalAmount = data['total_amount'];
      double amount = 0;
      if (totalAmount is num) {
        amount = totalAmount.toDouble();
      } else if (totalAmount is String) {
        amount = double.tryParse(totalAmount) ?? 0;
      }

      // Parse date
      DateTime date = DateTime.now();
      final dateStr = data['date'] as String?;
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          // Expected format: dd/mm/yyyy
          final parts = dateStr.split('/');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            date = DateTime(year, month, day);
          }
        } catch (e) {
          debugPrint('[OCR] Error parsing date: $e');
        }
      }

      // Parse items
      final itemsList = <String>[];
      final itemsJson = data['items'] as List<dynamic>?;
      if (itemsJson != null) {
        for (var item in itemsJson) {
          if (item is Map<String, dynamic>) {
            final name = item['name'] as String?;
            if (name != null && name.isNotEmpty) {
              itemsList.add(name);
            }
          }
        }
      }

      // Determine category based on items or default to Other
      String category = _determineCategoryFromItems(itemsList);

      // Parse additional metadata for notes (excluding payment method)
      final invoiceNumber = data['invoice_number'] as String? ?? '';
      final address = data['address'] as String? ?? '';

      String notes = '';
      if (invoiceNumber.isNotEmpty) {
        if (notes.isNotEmpty) notes += '\n';
        notes += 'Số hóa đơn: $invoiceNumber';
      }
      if (address.isNotEmpty) {
        if (notes.isNotEmpty) notes += '\n';
        notes += 'Địa chỉ: $address';
      }

      debugPrint(
        '[OCR] ✅ Parsed successfully: $merchant - $amountđ - ${itemsList.length} items',
      );

      return ReceiptData(
        merchant: merchant,
        amount: amount,
        date: date,
        category: category,
        items: itemsList,
        confidence:
            0.9, // High confidence since it comes from dedicated OCR service
        notes: notes.isNotEmpty ? notes : null,
      );
    } catch (e, stack) {
      debugPrint('[OCR] Error parsing response: $e');
      debugPrint('[OCR] Stack: $stack');
      debugPrint('[OCR] Raw response: $json');

      // Return default data with low confidence
      return ReceiptData(
        merchant: 'Unknown',
        amount: 0,
        date: DateTime.now(),
        category: 'Other',
        items: [],
        confidence: 0.0,
        notes: 'Failed to parse receipt: $e',
      );
    }
  }

  /// Determine category from items (simple heuristic)
  String _determineCategoryFromItems(List<String> items) {
    if (items.isEmpty) return 'Other';

    final allItems = items.join(' ').toLowerCase();

    // Food & Drink keywords
    if (allItems.contains('cơm') ||
        allItems.contains('phở') ||
        allItems.contains('nước') ||
        allItems.contains('cafe') ||
        allItems.contains('trà')) {
      return 'Food & Drink';
    }

    // Shopping keywords
    if (allItems.contains('áo') ||
        allItems.contains('quần') ||
        allItems.contains('giày')) {
      return 'Shopping';
    }

    // Transport keywords
    if (allItems.contains('xăng') ||
        allItems.contains('xe') ||
        allItems.contains('taxi')) {
      return 'Transport';
    }

    return 'Other';
  }

  /// Check if OCR service is available
  static bool isConfigured() {
    return true; // OCR service is always available via API
  }
}
