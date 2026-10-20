import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:komnotmorng2/constants/api_constant.dart';
import 'package:komnotmorng2/data/local_storage.dart';
import 'package:komnotmorng2/models/schedules/schedules_model.dart';
// Adjust this path to wherever you saved schedule_model.dart

class SelectScheduleVM extends GetxController {
  final Dio dio = Dio();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;
  final schedules = <Schedule>[].obs;

  /// GET {baseUrl}/create/:user_id
  /// If your router is mounted under a prefix in app.js
  /// (e.g. app.use("/schedules", router)), add it here.
  String _url(int userId) => "${ApiConstants.baseUrl}/selectallsche/$userId";


  Future<void> fetchSchedules() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';
      schedules.clear();
      final userId = await LocalStorage.getId();
      final response = await dio.get(_url(userId));
      if (response.statusCode == 201) {
        debugPrint('Schedules retrieved successfully: ${response.data}');
        final result = ScheduleResponse.fromJson(response.data);
        successMessage.value = result.message;
        schedules.addAll(result.data);
        debugPrint(schedules.string);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      errorMessage.value = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'An error occurred while fetching schedules';
      debugPrint(errorMessage.value);
      debugPrint('URL: ${e.requestOptions.uri}');
      debugPrint('Method: ${e.requestOptions.method}');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Body: ${e.response?.data}');
      debugPrint('kdmh');
    } catch (e) {
      errorMessage.value = e.toString();
      debugPrint('Unexpected error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
