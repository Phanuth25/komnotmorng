import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:komnotmorng2/constants/api_constant.dart';
import 'package:komnotmorng2/models/categories/select_cate_model.dart';

class SelectCateVM extends GetxController {
  final Dio dio = Dio();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;
  final categories = <CategoryModel>[].obs;

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';
      categories.clear();

      final response = await dio.get("${ApiConstants.baseUrl}/selectallcate");
      if (response.statusCode == 200) {
        debugPrint('Categories retrieved successfully: ${response.data}');
        final result = CategoryResponse.fromJson(response.data);
        successMessage.value = result.message;
        categories.addAll(result.categories);
        debugPrint(categories.string);
      }
    } on DioException catch (e) {
      errorMessage.value =
          e.response?.data['message'] ??
          'An error occurred while fetching categories';
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
