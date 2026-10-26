import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:komnotmorng2/constants/api_constant.dart';
import 'package:komnotmorng2/data/local_storage.dart';
import 'package:komnotmorng2/viewmodels/schedules/select_sche_vm.dart';

class DeleteScheduleVM extends GetxController {
  final Dio dio = Dio();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Reuse the registered instance, or create one
  final SelectScheduleVM selectVm = Get.isRegistered<SelectScheduleVM>()
      ? Get.find<SelectScheduleVM>()
      : Get.put(SelectScheduleVM());

  /// DELETE {baseUrl}/deleteschedule/:id?user_id=...
  /// Returns true if deleted (HTTP 200). The schedule list is reloaded after.
  Future<bool> deleteSchedule(int id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final userId = await LocalStorage.getId();
      final response = await dio.delete(
        "${ApiConstants.baseUrl}/deleteschedule/$id",
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        selectVm.fetchSchedules();
        return true;
      }
      return false;
    } on DioException catch (e) {
      final data = e.response?.data;
      errorMessage.value = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Could not delete the task';
      debugPrint('Delete failed: ${e.response?.statusCode} ${e.response?.data}');
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}