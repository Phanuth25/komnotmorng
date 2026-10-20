import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:komnotmorng2/constants/api_constant.dart';
import 'package:komnotmorng2/data/local_storage.dart';

class ScheduleVm extends GetxController {
  final Dio dio = Dio();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;
  final statusCode = ''.obs;

  /// Returns true if the task was created (HTTP 201).
  Future<bool> createTask({
    // ignore: non_constant_identifier_names
    required int? category_id,
    required String title,
    required String date, // e.g. 2026-10-18
    required String start, // e.g. 09:33:00
    required String end, // e.g. 09:50:00
    String? priority,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';
      statusCode.value = '';

      final userId = await LocalStorage.getId();

      // Same checks as the backend, so we fail fast without a request
      if (userId == 0) {
        errorMessage.value = 'You are not logged in';
        return false;
      }
      if (category_id == null || title.trim().isEmpty) {
        errorMessage.value = 'Missing required fields';
        return false;
      }

      final body = {
        'user_id': userId,
        'category_id': category_id,
        'title': title.trim(),
        'date': date,
        'start': start,
        'end': end,
        if (priority != null && priority.isNotEmpty) 'priority': priority,
      };
      debugPrint('Creating task: $body');

      final response = await dio.post(
        "${ApiConstants.baseUrl}/create", // adjust to your mount path
        data: body,
      );

      statusCode.value = response.statusCode.toString();
      if (response.statusCode == 201) {
        successMessage.value =
            response.data['message'] ?? 'Task created successfully';
        return true;
      }
      return false;
    } on DioException catch (e) {
      statusCode.value = e.response?.statusCode.toString() ?? 'Unknown';
      final data = e.response?.data;
      errorMessage.value =
          (data is Map ? data['message'] : null) ?? 'An error occurred';
      debugPrint('URL: ${e.requestOptions.uri}');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Body: ${e.response?.data}');
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}