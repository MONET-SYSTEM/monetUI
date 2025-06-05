import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 1)
class UserModel{
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String email;

  @HiveField(3)
  DateTime? emailVerifiedAt;

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  late DateTime updatedAt;

  @HiveField(6)
  late String token;

  @HiveField(7)
  String? pin;

  @HiveField(8)
  String? phone;

  @HiveField(9)
  String? bio;

  @HiveField(10)
  String? avatar;

  @HiveField(11)
  DateTime? dateOfBirth;

  @HiveField(12)
  String? gender;

  @HiveField(13)
  String? country;

  @HiveField(14)
  String? city;

  @HiveField(15)
  String? timezone;

  static String userBox = 'users';

  UserModel();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel()
      ..id = json['id'] ?? json['uuid'] ?? ''
      ..name = json['name'] ?? ''
      ..email = json['email'] ?? ''
      ..emailVerifiedAt = json['email_verified_at'] != null ? DateTime.tryParse(json['email_verified_at']) : null
      ..createdAt = DateTime.parse(json['created_at'])
      ..updatedAt = DateTime.parse(json['updated_at'])
      ..token = json['token'] ?? ''
      ..pin = json['pin']
      ..phone = json['phone']
      ..bio = json['bio']
      ..avatar = json['avatar']
      ..dateOfBirth = json['date_of_birth'] != null ? DateTime.tryParse(json['date_of_birth']) : null
      ..gender = json['gender']
      ..country = json['country']
      ..city = json['city']
      ..timezone = json['timezone'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'token': token,
      'pin': pin,
      'phone': phone,
      'bio': bio,
      'avatar': avatar,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'country': country,
      'city': city,
      'timezone': timezone,
    };
  }
}