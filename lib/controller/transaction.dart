import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:monet/models/result.dart';
import 'package:monet/models/transaction.dart';
import 'package:monet/services/api.dart';
import 'package:monet/services/api_routes.dart';
import 'package:monet/services/transaction_service.dart';

class TransactionController {
  static Future<Result<List<TransactionModel>>> loadTransactions() async {
    try {
      final response = await ApiService.get(ApiRoutes.transactionUrl, {});
      print("Transaction API Response: ${response.data}");

      if (response.data == null) {
        return Result<List<TransactionModel>>(
          isSuccess: false,
          message: "Empty response from server",
          results: [],
        );
      }

      // Handle different response structures with comprehensive parsing
      List<dynamic> transactionsList = [];

      if (response.data is Map) {
        Map<String, dynamic> responseMap = response.data;

        // Try multiple possible paths to find transactions data
        if (responseMap['results'] != null && responseMap['results'] is List) {
          transactionsList = responseMap['results'];
        }
        // Try data field
        else if (responseMap['data'] != null && responseMap['data'] is List) {
          transactionsList = responseMap['data'];
        }
        // Try direct transactions field
        else if (responseMap['transactions'] != null && responseMap['transactions'] is List) {
          transactionsList = responseMap['transactions'];
        }
        // Handle case where the response itself is a single transaction
        else if (responseMap.containsKey('id') || responseMap.containsKey('amount')) {
          transactionsList = [responseMap];
        }
        // Try to find any list in the response that might contain transactions
        else {
          responseMap.forEach((key, value) {
            if (value is List && value.isNotEmpty && value[0] is Map) {
              transactionsList = value;
            }
          });
        }
      }
      // Handle case where response.data is directly a list
      else if (response.data is List) {
        transactionsList = response.data;
      }

      print("Found ${transactionsList.length} transactions to process");

      if (transactionsList.isEmpty) {
        print("No transactions found in response structure: ${response.data}");
        return Result<List<TransactionModel>>(
          isSuccess: true,
          message: "No transactions found",
          results: [],
        );
      }

      // Process transactions with duplicate prevention
      Map<String, Map<String, dynamic>> uniqueTransactions = {};

      for (var transaction in transactionsList) {
        if (transaction is Map<String, dynamic> && transaction.containsKey('id')) {
          String id = transaction['id']?.toString() ?? '';
          if (id.isNotEmpty && !uniqueTransactions.containsKey(id)) {
            uniqueTransactions[id] = transaction;
          }
        }
      }

      // Convert to transaction models
      List<TransactionModel> transactions = [];
      for (var transactionData in uniqueTransactions.values) {
        try {
          final model = await TransactionService.create(transactionData);
          transactions.add(model);
        } catch (e) {
          print("Error creating transaction model: $e");
        }
      }

      return Result<List<TransactionModel>>(
          isSuccess: true,
          message: response.data is Map && response.data['message'] != null
              ? response.data['message']
              : "Transactions loaded successfully",
          results: transactions
      );
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      print("DioException loading transactions: $message");
      print("Response status: ${e.response?.statusCode}");
      print("Response data: ${e.response?.data}");

      return Result<List<TransactionModel>>(
          isSuccess: false,
          message: message,
          errors: e.response?.data?['errors']
      );
    } catch (e) {
      print("Error loading transactions: $e");
      print("Stack trace: ${StackTrace.current}");

      return Result<List<TransactionModel>>(
          isSuccess: false,
          message: "Failed to load transactions: $e"
      );
    }
  }

  static Future<Result<TransactionModel>> saveTransaction({
    required String accountId,
    required String type,
    required double amount,
    String? categoryId,
    String? description,
    String? transaction_date,
    bool? is_reconciled,
    bool repeat = false,
  }) async {
    try {
      // Prepare transaction date - use current date if not provided
      String formattedDate = transaction_date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Prepare form data
      Map<String, dynamic> formFields = {
        'account_id': accountId,
        'type': type,
        'amount': amount.toString(), // Convert to string for form data
        'transaction_date': formattedDate,
        'is_reconciled': (is_reconciled ?? false) ? '1' : '0', // Convert bool to string
        'repeat': repeat ? '1' : '0', // Convert bool to string
      };

      // Add optional fields only if they have values
      if (categoryId != null && categoryId.isNotEmpty) {
        formFields['category_id'] = categoryId;
      }
      if (description != null && description.isNotEmpty) {
        formFields['description'] = description;
      }

      // Create FormData
      FormData formData = FormData.fromMap(formFields);

      print("Sending transaction request with data: $formFields");

      // Send the request
      final response = await ApiService.postFormData(ApiRoutes.transactionUrl, formData);
      print("Server response: ${response.data}");

      if (response.data == null) {
        return Result<TransactionModel>(isSuccess: false, message: "Empty response from server");
      }

      // Extract transaction data from response
      Map<String, dynamic>? transactionData;

      if (response.data is Map) {
        Map<String, dynamic> responseMap = response.data;

        // Check for success indicators
        bool isSuccess = responseMap['success'] == true ||
            responseMap['status'] == 'success' ||
            response.statusCode == 200 ||
            response.statusCode == 201;

        if (!isSuccess && responseMap['message'] != null) {
          return Result<TransactionModel>(
              isSuccess: false,
              message: responseMap['message'],
              errors: responseMap['errors']
          );
        }

        // Try to extract transaction data from various response structures
        if (responseMap['results'] != null) {
          var results = responseMap['results'];
          if (results is Map<String, dynamic>) {
            transactionData = results;
          } else if (results is List && results.isNotEmpty) {
            transactionData = results.first;
          }
        } else if (responseMap['data'] != null) {
          var data = responseMap['data'];
          if (data is Map<String, dynamic> && data.containsKey('id')) {
            transactionData = data;
          } else if (data is List && data.isNotEmpty) {
            transactionData = data.first;
          }
        } else if (responseMap['transaction'] != null) {
          transactionData = responseMap['transaction'];
        } else if (responseMap.containsKey('id')) {
          transactionData = responseMap;
        }
      }

      // Handle missing transaction data - create a fallback
      if (transactionData == null || !transactionData.containsKey('id')) {
        // If the server doesn't return the transaction data but indicates success,
        // create a basic transaction object
        if (response.statusCode == 200 || response.statusCode == 201) {
          transactionData = {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'account_id': accountId,
            'type': type,
            'amount': amount,
            'category_id': categoryId,
            'description': description,
            'transaction_date': formattedDate,
            'is_reconciled': is_reconciled ?? false,
            'repeat': repeat,
          };

          print("Created fallback transaction data: $transactionData");
        } else {
          return Result<TransactionModel>(
            isSuccess: false,
            message: "Transaction saved but no transaction data returned",
          );
        }
      }

      // Clean transaction data for storage
      Map<String, dynamic> cleanedTransaction = Map<String, dynamic>.from(transactionData);

      // Remove problematic fields
      cleanedTransaction.remove('created_at');
      cleanedTransaction.remove('updated_at');

      // Ensure amount is double
      if (cleanedTransaction['amount'] is String) {
        cleanedTransaction['amount'] = double.tryParse(cleanedTransaction['amount']) ?? amount;
      }

      // Create and store transaction
      final transactionModel = await TransactionService.create(cleanedTransaction);

      return Result<TransactionModel>(
          isSuccess: true,
          message: response.data['message'] ?? "Transaction saved successfully",
          results: transactionModel
      );
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      print("DioException saving transaction: $message");
      print("Response data: ${e.response?.data}");

      return Result<TransactionModel>(
          isSuccess: false,
          message: message,
          errors: e.response?.data?['errors']
      );
    } catch (e) {
      print("Transaction saving error: $e");
      return Result<TransactionModel>(
          isSuccess: false,
          message: "Failed to save transaction: $e"
      );
    }
  }
}