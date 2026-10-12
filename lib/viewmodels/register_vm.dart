import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData;
import 'package:komnotmorng2/constants/api_constant.dart';

class RegisterViewModel extends GetxController {
  final Dio dio = Dio();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;
  final user = ''.obs;
  final statusCode = ''.obs;
  Future<void> register(String name, String email, String password) async {
    try {
      // Store the password in the controller
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';
      statusCode.value = '';
      final response = await dio.post(
        "${ApiConstants.baseUrl}/register",
        data: {'name': name, 'email': email, 'password': password},
      );
      if (response.statusCode == 201) {
        statusCode.value = response.statusCode.toString();
        debugPrint('User registered successfully: ${response.data}');
        successMessage.value =
            response.data['message'] ?? 'Registration successful';
      } else if (response.statusCode == 409) {
        debugPrint('Registration failed: ${response.data['message']}');
        errorMessage.value = 'Email already exists';
      } else {
        debugPrint(
          'Unexpected response: ${response.statusCode} - ${response.data}',
        );
        statusCode.value = response.statusCode.toString();
      }
    } on DioException catch (e) {
      statusCode.value = e.response?.statusCode.toString() ?? 'Unknown';
      debugPrint('URL: ${e.requestOptions.uri}');
      debugPrint('Method: ${e.requestOptions.method}');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Body: ${e.response?.data}');
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
