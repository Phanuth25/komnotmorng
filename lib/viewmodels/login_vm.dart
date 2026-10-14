import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:get/get.dart';
import 'package:komnotmorng2/constants/api_constant.dart';
import 'package:komnotmorng2/data/local_storage.dart';

class LoginViewModel extends GetxController {
  final Dio dio = Dio();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;
  final userName = ''.obs;
  final statusCode = ''.obs;
  Future<void> login(String email, String password) async {
    try {
      // Store the password in the controller
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';
      statusCode.value = '';
      userName.value = '';
      final response = await dio.post(
        "${ApiConstants.baseUrl}/login",
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        statusCode.value = response.statusCode.toString();
        debugPrint('User logged in successfully: ${response.data}');
        successMessage.value = response.data['message'] ?? 'Login successful';
        debugPrint('User name: ${userName.value}');
        userName.value = response.data['data'] ?? '';
        debugPrint('User name: ${userName.value}');
        await LocalStorage.saveEmail(email);
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
  Future<void> logout() async {
    try {
      await LocalStorage.removeEmail();
      debugPrint('User logged out successfully');
      Get.toNamed('/LoginScreen'); // Navigate to the login screen
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }
}
