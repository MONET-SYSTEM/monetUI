import 'package:dio/dio.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/services/auth_service.dart';

class ApiService {
  static final dio = Dio();

  // post - Updated to handle both Map<String, dynamic> and FormData
  static Future<Response> post(String url, dynamic data) async {
    final user = await AuthService.get();

    Map<String, String> headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${user?.token}'
    };

    if (data is! FormData) {
      headers['Content-Type'] = 'application/json';
    }

    final response = await dio.post(
        url,
        data: data,
        options: Options(headers: headers)
    );

    return response;
  }

  // Alternative: Create a separate method for file uploads
  static Future<Response> postFormData(String url, FormData formData) async {
    final user = await AuthService.get();
    final response = await dio.post(
        url,
        data: formData,
        options: Options(headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${user?.token}',
          // Don't set Content-Type - let Dio handle it for FormData
        })
    );

    return response;
  }

  // get
  static Future<Response> get(String url, Map<String, dynamic> params) async {
    final user = await AuthService.get();
    print('[ApiService] Using token: \'${user?.token}\''); // Debug print
    final response = await dio.get(url, queryParameters: params, options: Options(headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${user?.token}'
    }));

    return response;
  }

  static Future<Response> put(String url, Map<String, dynamic> data, {Map<String, dynamic>? queryParameters}) async {
    final user = await AuthService.get();
    final response = await dio.put(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${user?.token}',
          'Content-Type': 'application/json',
        })
    );

    return response;
  }

  static Future<Response> patch(String url, Map<String, dynamic> data, {Map<String, dynamic>? queryParameters}) async {
    final user = await AuthService.get();
    final response = await dio.patch(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${user?.token}',
          'Content-Type': 'application/json',
        })
    );

    return response;
  }

  static Future<Response> delete(String url, Map<String, dynamic> data) async {
    final user = await AuthService.get();
    final response = await dio.delete(
        url,
        data: data,
        options: Options(headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${user?.token}',
          'Content-Type': 'application/json',
        })
    );

    return response;
  }

  static String errorMessage(DioException dioException) {
    final internetErrors = [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout
    ];

    return (internetErrors.contains(dioException.type))
        ? AppStrings.noInternetAccess
        : (dioException.response?.data['message'] ?? AppStrings.anErrorOccurredTryAgain);
  }
}