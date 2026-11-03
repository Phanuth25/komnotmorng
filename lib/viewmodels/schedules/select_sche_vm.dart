import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:komnotmorng2/constants/api_constant.dart';
import 'package:komnotmorng2/data/local_storage.dart';
import 'package:komnotmorng2/models/schedules/schedules_model.dart';

class SelectScheduleVM extends GetxController {
  final Dio dio = Dio();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;
  final schedules = <Schedule>[].obs;

  /// GET all schedules of the logged-in user
  Future<void> fetchSchedules() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';
      final userId = await LocalStorage.getId();
      final response = await dio.get(
        "${ApiConstants.baseUrl}/selectallsche/$userId",
      );
      if (response.statusCode == 201) {
        final result = ScheduleResponse.fromJson(response.data);
        successMessage.value = result.message;
        schedules.assignAll(result.data); // replaces the list in one step
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        schedules.clear(); // 404 = no schedules yet, not an error
        return;
      }
      final data = e.response?.data;
      errorMessage.value = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'An error occurred while fetching schedules';
      debugPrint('Fetch failed: ${e.response?.statusCode} ${e.response?.data}');
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}