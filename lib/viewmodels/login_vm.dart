import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:get/get.dart';
import 'package:komnotmorng2/constants/api_constant.dart';

class LoginViewModel extends GetxController {
  final Dio dio = Dio();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;
  final user = ''.obs;
  final statusCode = ''.obs;
  Future<void> login(String email, String password) async {
    try {
      // Store the password in the controller
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';
      statusCode.value = '';
      final response = await dio.post(
        "${ApiConstants.baseUrl}/login",
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        statusCode.value = response.statusCode.toString();
        debugPrint('User logged in successfully: ${response.data}');
        successMessage.value = response.data['message'] ?? 'Login successful';
      }
    } on DioException catch (e) {
      statusCode.value = e.response?.statusCode.toString() ?? 'Unknown';
      errorMessage.value = e.response?.data['message'] ?? 'An error occurred';
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
