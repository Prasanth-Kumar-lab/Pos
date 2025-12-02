import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:task/api_endpoints.dart';

class SystemSettingsModel {
  final String billPrefix;
  final String quote;
  final String firmName;
  final String firmContact1;
  final String firmContact2;
  final String file;
  final String billAddress;
  final String billGstinNum;
  final String businessId;

  SystemSettingsModel({
    required this.billPrefix,
    required this.quote,
    required this.firmName,
    required this.firmContact1,
    required this.firmContact2,
    required this.file,
    required this.billAddress,
    required this.billGstinNum,
    required this.businessId,
  });

  // Convert model to map for API request
  Map<String, String> toJson() => {
    'bill_prefix': billPrefix,
    'quote': quote,
    'firm_name': firmName,
    'firm_contact1': firmContact1,
    'firm_contact2': firmContact2,
    'file': file,
    'bill_address': billAddress,
    'bill_gstin_num': billGstinNum,
    'business_id': businessId,
  };

  // API call to save system settings
  // API call to save system settings with image upload
  Future<Map<String, dynamic>> saveSettings({
    required String selectedImagePath, // Pass the actual file path
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.systemSettingsEndPoint),
      );

      // Add all text fields
      request.fields.addAll(toJson());

      // Only add file if a new image was picked
      if (selectedImagePath.isNotEmpty) {
        var file = await http.MultipartFile.fromPath(
          'file', // This must match the exact field name your backend expects (e.g., 'file', 'logo', 'bill_logo')
          selectedImagePath,
          filename: selectedImagePath.split('/').last,
        );
        request.files.add(file);
        print('Image attached: ${selectedImagePath.split('/').last}');
      } else {
        // Optional: Send old logo path or empty if no new image
        // Some backends allow keeping old image if no new one sent
        request.fields['file'] = file; // keep existing filename/path
      }

      print('Request Fields:57 ${request.fields}');
      print('Request Files: ${request.files.length}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('API Raw Response: ${response.body}');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        final status = (responseData['status'] ?? '').toString().toLowerCase();

        if (status == 'success' || status == 'updated') {
          return {
            'status': 'success',
            'message': responseData['message'] ?? 'Settings saved successfully',
            'data': responseData['data'] ?? {},
          };
        } else {
          return {
            'status': 'error',
            'message': responseData['message'] ?? 'Failed to save settings',
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Exception during save: $e');
      return {
        'status': 'error',
        'message': 'Network or file error: $e',
      };
    }
  }
}