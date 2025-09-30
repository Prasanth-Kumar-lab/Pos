import 'package:http/http.dart' as http;
import 'dart:convert';

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
  Future<Map<String, dynamic>> saveSettings() async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://erpapp.in/mart_print/mart_print_apis/system_settings_api.php'),
      );

      // Add form-data fields
      request.fields.addAll(toJson());

      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);

      // Debug: Log raw response
      print('API Raw Response Body: ${responseBody.body}');
      print('API Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody.body);
        final status = responseData['status'].toString().toLowerCase(); // Case-insensitive check

        // Debug: Log parsed status
        print('Parsed Status (lowercase): $status');

        if (status == 'success' || status == 'updated') {
          return {
            'status': 'success',
            'message': responseData['message'] ?? 'System settings updated successfully',
            'data': responseData['data'] ?? toJson(), // Use API data if provided, else form data
          };
        } else {
          return {
            'status': 'error',
            'message': responseData['message'] ?? 'Unexpected status: ${responseData['status']}. Failed to save settings.',
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Failed to save settings: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'An error occurred: $e',
      };
    }
  }
}