import 'dart:io';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:monet/models/result.dart';
import 'package:monet/models/transaction.dart';
import 'package:monet/models/transaction_attachment.dart';
import 'package:monet/services/api.dart';
import 'package:monet/services/api_routes.dart';
import 'package:monet/services/transaction_service.dart';
import 'package:monet/services/transaction_attachment_service.dart';
import 'package:http_parser/http_parser.dart';

class TransactionController {
  static Future<Result<List<TransactionModel>>> loadTransactions() async {
    try {
      final response = await ApiService.get(ApiRoutes.transactionUrl, {});
      print("Transaction API Response: ${response.data}");

      if (response.data == null) {
        return Result<List<TransactionModel>>(
            isSuccess: false,
            message: "Empty response from server"
        );
      }

      // Handle different response structures with comprehensive parsing
      List<dynamic> transactionsList = [];

      if (response.data is Map) {
        Map<String, dynamic> responseMap = response.data;

        // Try multiple possible paths to find transactions data
        if (responseMap['results'] != null) {
          var results = responseMap['results'];

          if (results is Map) {
            // Handle nested structure: results.transactions
            if (results['transactions'] is List) {
              transactionsList = results['transactions'];
            }
            // Handle case where results itself contains transaction data
            else if (results.containsKey('id') || results.containsKey('amount')) {
              transactionsList = [results];
            }
          }
          // Handle case where results is directly a list
          else if (results is List) {
            transactionsList = results;
          }
        }
        // Try data field
        else if (responseMap['data'] != null) {
          var data = responseMap['data'];

          if (data is List) {
            transactionsList = data;
          } else if (data is Map) {
            if (data['transactions'] is List) {
              transactionsList = data['transactions'];
            } else if (data.containsKey('id') || data.containsKey('amount')) {
              transactionsList = [data];
            }
          }
        }
        // Try direct transactions field
        else if (responseMap['transactions'] is List) {
          transactionsList = responseMap['transactions'];
        }
        // Handle case where the response itself is a single transaction
        else if (responseMap.containsKey('id') || responseMap.containsKey('amount')) {
          transactionsList = [responseMap];
        }
        // Try to find any list in the response that might contain transactions
        else {
          for (var key in responseMap.keys) {
            var value = responseMap[key];
            if (value is List && value.isNotEmpty) {
              // Check if the first item looks like a transaction
              var firstItem = value.first;
              if (firstItem is Map &&
                  (firstItem.containsKey('id') ||
                      firstItem.containsKey('amount') ||
                      firstItem.containsKey('transaction_date'))) {
                transactionsList = value;
                print("Found transactions in field: $key");
                break;
              }
            }
          }
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
            results: []
        );
      }

      // Process transactions with duplicate prevention
      Map<String, Map<String, dynamic>> uniqueTransactions = {};

      for (var item in transactionsList) {
        if (item == null || item is! Map) {
          print("Skipping invalid transaction item: $item");
          continue;
        }

        try {
          // Make a clean copy to avoid reference issues
          Map<String, dynamic> transaction = Map<String, dynamic>.from(item);

          // Remove non-serializable fields or fields that cause Hive issues
          transaction.remove('created_at');
          transaction.remove('updated_at');

          // Ensure required fields exist
          if (!transaction.containsKey('id')) {
            // Generate a temporary ID if missing
            transaction['id'] = '${transaction['account_id']}_${DateTime.now().millisecondsSinceEpoch}_${transactionsList.indexOf(item)}';
            print("Generated ID for transaction: ${transaction['id']}");
          }

          // Ensure amount is properly parsed as double
          if (transaction['amount'] != null) {
            if (transaction['amount'] is num) {
              transaction['amount'] = (transaction['amount'] as num).toDouble();
            } else {
              try {
                transaction['amount'] = double.parse(transaction['amount'].toString());
              } catch (e) {
                print("Error parsing amount for transaction ${transaction['id']}: ${transaction['amount']}");
                transaction['amount'] = 0.0;
              }
            }
          } else {
            transaction['amount'] = 0.0;
          }

          // Ensure transaction_date is properly formatted
          if (transaction['transaction_date'] == null || transaction['transaction_date'].toString().isEmpty) {
            transaction['transaction_date'] = DateTime.now().toString().substring(0, 10);
          } else {
            // Ensure date format is YYYY-MM-DD
            try {
              DateTime parsedDate = DateTime.parse(transaction['transaction_date'].toString());
              transaction['transaction_date'] = DateFormat('yyyy-MM-dd').format(parsedDate);
            } catch (e) {
              print("Error parsing date for transaction ${transaction['id']}: ${transaction['transaction_date']}");
              transaction['transaction_date'] = DateTime.now().toString().substring(0, 10);
            }
          }

          // Ensure account_id exists
          if (transaction['account_id'] == null) {
            print("Warning: Transaction ${transaction['id']} has no account_id");
            transaction['account_id'] = '';
          }

          // Ensure type exists
          if (transaction['type'] == null) {
            print("Warning: Transaction ${transaction['id']} has no type");
            transaction['type'] = 'expense'; // Default to expense
          }

          // Handle boolean fields
          if (transaction['is_reconciled'] != null) {
            if (transaction['is_reconciled'] is String) {
              transaction['is_reconciled'] = transaction['is_reconciled'].toString().toLowerCase() == 'true' ||
                  transaction['is_reconciled'].toString() == '1';
            } else if (transaction['is_reconciled'] is num) {
              transaction['is_reconciled'] = transaction['is_reconciled'] != 0;
            }
          } else {
            transaction['is_reconciled'] = false;
          }

          // Use ID as unique key, fallback to composite key if ID is missing
          String uniqueKey = transaction['id']?.toString() ??
              "${transaction['account_id']}_${transaction['amount']}_${transaction['transaction_date']}";

          uniqueTransactions[uniqueKey] = transaction;

        } catch (e) {
          print("Error processing transaction item: $e");
          print("Transaction data: $item");
          continue; // Skip this transaction but continue with others
        }
      }

      print("Processed ${uniqueTransactions.length} unique transactions");

      // Convert back to list
      List<Map<String, dynamic>> cleanedTransactionsList = uniqueTransactions.values.toList();

      // Sort by date (newest first) before saving
      cleanedTransactionsList.sort((a, b) {
        String dateA = a['transaction_date'] ?? '';
        String dateB = b['transaction_date'] ?? '';
        return dateB.compareTo(dateA); // Descending order
      });

      // Create transaction models
      final transactionModels = await TransactionService.createTransactions(cleanedTransactionsList);

      print("Successfully created ${transactionModels.length} transaction models");

      return Result<List<TransactionModel>>(
          isSuccess: true,
          message: response.data is Map ?
          (response.data['message'] ?? "Transactions loaded successfully") :
          "Transactions loaded successfully",
          results: transactionModels
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
    File? attachment,
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

      // Add attachment to request if provided
      if (attachment != null && await attachment.exists()) {
        try {
          String fileName = attachment.path.split('/').last;

          // Get file extension to set proper content type
          String fileExtension = fileName.split('.').last.toLowerCase();
          String contentType = _getContentType(fileExtension);

          formData.files.add(MapEntry(
            'attachment',
            await MultipartFile.fromFile(
              attachment.path,
              filename: fileName,
              contentType: MediaType.parse(contentType),
            ),
          ));

          print("Added attachment: $fileName (${contentType})");
        } catch (e) {
          print("Error adding attachment: $e");
          // Continue without attachment rather than failing
        }
      }

      print("Sending transaction request with data: $formFields");
      print("Has attachment: ${attachment != null}");

      // Send the request - FIXED: Pass formData directly, not !formData
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
            if (results['transaction'] != null) {
              transactionData = results['transaction'];
            } else if (results.containsKey('id')) {
              transactionData = results;
            }
          }
        } else if (responseMap['data'] != null) {
          var data = responseMap['data'];
          if (data is Map<String, dynamic> && data.containsKey('id')) {
            transactionData = data;
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
            'id': DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
            'account_id': accountId,
            'type': type,
            'amount': amount,
            'category_id': categoryId,
            'description': description,
            'transaction_date': formattedDate,
            'is_reconciled': is_reconciled ?? false,
          };

          print("Created fallback transaction data: $transactionData");
        } else {
          return Result<TransactionModel>(
              isSuccess: false,
              message: "Cannot parse transaction from server response",
              errors: {'response_format': 'Server response does not contain expected transaction data'}
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

  // Upload attachment to an existing transaction
  static Future<Result<TransactionAttachmentModel>> uploadAttachment({
    required String transactionId,
    required File file,
    String? description,
  }) async {
    try {
      // Validate file size (max 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        return Result<TransactionAttachmentModel>(
          isSuccess: false,
          message: "File size exceeds 10MB limit",
          errors: {'file': 'File size exceeds 10MB limit'}
        );
      }

      // Get file metadata
      String fileName = file.path.split('/').last;
      String fileExtension = fileName.split('.').last.toLowerCase();
      String contentType = _getContentType(fileExtension);

      // Check if file extension is allowed
      List<String> allowedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'gif', 'txt', 'csv', 'xls', 'xlsx'];
      if (!allowedExtensions.contains(fileExtension)) {
        return Result<TransactionAttachmentModel>(
          isSuccess: false,
          message: "File type not allowed",
          errors: {'file': 'Only PDF, DOC, DOCX, JPG, JPEG, PNG, GIF, TXT, CSV, XLS, and XLSX files are allowed'}
        );
      }

      FormData formData = FormData();

      // Add file to form data with the correct field name 'file' to match backend expectation
      formData.files.add(
        MapEntry(
          'file', // Changed from 'attachment' to 'file' to match backend API
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
            contentType: MediaType.parse(contentType),
          ),
        ),
      );

      // Add description if provided
      if (description != null && description.isNotEmpty) {
        formData.fields.add(MapEntry('description', description));
      }

      print("Uploading attachment for transaction $transactionId: $fileName ($contentType)");
      print("Form data files: ${formData.files.map((f) => '${f.key}:${f.value.filename}').join(', ')}");

      // Send request to upload attachment
      final response = await ApiService.postFormData(
        '${ApiRoutes.transactionUrl}/$transactionId/attachment',
        formData
      );

      print("Attachment upload response: ${response.data}");

      if (response.data == null) {
        return Result<TransactionAttachmentModel>(
          isSuccess: false,
          message: "Empty response from server"
        );
      }

      // Process response data
      if (response.data is Map &&
          (response.data['status'] == 'success' || response.data['success'] == true || response.statusCode == 200 || response.statusCode == 201)) {
        Map<String, dynamic>? attachmentData;

        // Detect various response formats
        if (response.data['data'] != null) {
          attachmentData = response.data['data'];
        } else if (response.data['results'] != null) {
          attachmentData = response.data['results'];
        } else if (response.data['attachment'] != null) {
          attachmentData = response.data['attachment'];
        }

        if (attachmentData != null) {
          // Ensure the transaction_id field exists
          attachmentData['transaction_id'] = transactionId;

          // Create and store attachment model
          final attachmentModel = await TransactionAttachmentService.create(attachmentData);

          return Result<TransactionAttachmentModel>(
            isSuccess: true,
            message: response.data['message'] ?? "Attachment uploaded successfully",
            results: attachmentModel
          );
        }
      }

      // If we get here, there was an error in the response
      String errorMessage = "Failed to upload attachment";
      if (response.data is Map) {
        errorMessage = response.data['message'] ?? errorMessage;
        if (response.data['error'] != null) {
          errorMessage += ": ${response.data['error']}";
        }
      }

      return Result<TransactionAttachmentModel>(
        isSuccess: false,
        message: errorMessage,
        errors: response.data is Map ? response.data['errors'] : null
      );

    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      print("DioException uploading attachment: $message");
      print("Response data: ${e.response?.data}");

      return Result<TransactionAttachmentModel>(
        isSuccess: false,
        message: message,
        errors: e.response?.data?['errors']
      );
    } catch (e) {
      print("Error uploading attachment: $e");
      return Result<TransactionAttachmentModel>(
        isSuccess: false,
        message: "Failed to upload attachment: $e"
      );
    }
  }

  // Get attachments for a transaction
  static Future<Result<List<TransactionAttachmentModel>>> getTransactionAttachments(String transactionId) async {
    try {
      // First check local storage
      final localAttachments = await TransactionAttachmentService.getAttachmentsByTransactionId(transactionId);

      // Try to get from server
      final response = await ApiService.get('${ApiRoutes.transactionUrl}/$transactionId/attachments', {});

      if (response.data == null) {
        // If server request fails but we have local data, return that
        if (localAttachments.isNotEmpty) {
          return Result<List<TransactionAttachmentModel>>(
            isSuccess: true,
            message: "Retrieved local attachments",
            results: localAttachments
          );
        }
        return Result<List<TransactionAttachmentModel>>(
          isSuccess: false,
          message: "Empty response from server"
        );
      }

      // Process attachments from server response
      List<dynamic> attachmentsList = [];

      if (response.data is Map) {
        if (response.data['data'] != null && response.data['data'] is List) {
          attachmentsList = response.data['data'];
        } else if (response.data['attachments'] != null && response.data['attachments'] is List) {
          attachmentsList = response.data['attachments'];
        } else if (response.data['results'] != null) {
          var results = response.data['results'];
          if (results is List) {
            attachmentsList = results;
          } else if (results is Map && results['attachments'] is List) {
            attachmentsList = results['attachments'];
          }
        }
      }

      // If no attachments found on server, return local attachments
      if (attachmentsList.isEmpty) {
        return Result<List<TransactionAttachmentModel>>(
          isSuccess: true,
          message: "No attachments found",
          results: localAttachments
        );
      }

      // Process and store new attachments
      List<TransactionAttachmentModel> attachmentModels = [];

      for (var item in attachmentsList) {
        if (item == null) continue;

        // Ensure the item is a proper Map copy to avoid reference issues
        Map<String, dynamic> attachment = Map<String, dynamic>.from(item);

        // Ensure transaction_id field exists
        attachment['transaction_id'] = transactionId;

        // Create and store attachment model
        final attachmentModel = await TransactionAttachmentService.create(attachment);
        attachmentModels.add(attachmentModel);
      }

      return Result<List<TransactionAttachmentModel>>(
        isSuccess: true,
        message: response.data['message'] ?? "Attachments retrieved successfully",
        results: attachmentModels
      );

    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      print("DioException getting attachments: $message");

      // If API call fails but we have local data, return that
      final localAttachments = await TransactionAttachmentService.getAttachmentsByTransactionId(transactionId);
      if (localAttachments.isNotEmpty) {
        return Result<List<TransactionAttachmentModel>>(
          isSuccess: true,
          message: "Retrieved local attachments",
          results: localAttachments
        );
      }

      return Result<List<TransactionAttachmentModel>>(
        isSuccess: false,
        message: message,
        errors: e.response?.data?['errors']
      );
    } catch (e) {
      print("Error getting attachments: $e");

      // If there's an error but we have local data, return that
      final localAttachments = await TransactionAttachmentService.getAttachmentsByTransactionId(transactionId);
      if (localAttachments.isNotEmpty) {
        return Result<List<TransactionAttachmentModel>>(
          isSuccess: true,
          message: "Retrieved local attachments",
          results: localAttachments
        );
      }

      return Result<List<TransactionAttachmentModel>>(
        isSuccess: false,
        message: "Failed to retrieve attachments: $e"
      );
    }
  }

  // Delete an attachment
  static Future<Result<bool>> deleteAttachment(String transactionId, String attachmentId) async {
    try {
      final response = await ApiService.delete('${ApiRoutes.transactionUrl}/$transactionId/attachments/$attachmentId', {});

      // Delete from local storage regardless of server response
      await TransactionAttachmentService.delete(attachmentId);

      if (response.data == null) {
        return Result<bool>(
          isSuccess: true,
          message: "Attachment deleted locally",
          results: true
        );
      }

      if (response.data is Map &&
         (response.data['status'] == 'success' || response.data['success'] == true)) {
        return Result<bool>(
          isSuccess: true,
          message: response.data['message'] ?? "Attachment deleted successfully",
          results: true
        );
      }

      return Result<bool>(
        isSuccess: false,
        message: response.data['message'] ?? "Failed to delete attachment on server",
        results: false
      );

    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      print("DioException deleting attachment: $message");

      // Delete locally even if server request fails
      await TransactionAttachmentService.delete(attachmentId);

      return Result<bool>(
        isSuccess: true,
        message: "Attachment deleted locally, but server sync failed: $message",
        results: true
      );
    } catch (e) {
      print("Error deleting attachment: $e");

      // Delete locally even if there's an error
      try {
        await TransactionAttachmentService.delete(attachmentId);
        return Result<bool>(
          isSuccess: true,
          message: "Attachment deleted locally, but server sync failed",
          results: true
        );
      } catch (localError) {
        return Result<bool>(
          isSuccess: false,
          message: "Failed to delete attachment: $e"
        );
      }
    }
  }

  // Helper method to determine content type based on file extension
  static String _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
