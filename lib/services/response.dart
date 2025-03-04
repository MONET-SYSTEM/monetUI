import 'package:json_annotation/json_annotation.dart';

part 'response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class Response<T> {
  final bool isSuccess;
  final String message;
  T? results;

  Response({required this.isSuccess, required this.message, this.results});

  // Connect the generated _$ResponseFromJson function to the 'fromJson' factory.
  factory Response.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) => _$ResponseFromJson(json, fromJsonT);

  // Connect the generated _$ResponseToJson function to the 'toJson' method.
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => _$ResponseToJson(this, toJsonT);
}