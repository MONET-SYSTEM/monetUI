// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 1;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..email = fields[2] as String
      ..emailVerifiedAt = fields[3] as DateTime?
      ..createdAt = fields[4] as DateTime
      ..updatedAt = fields[5] as DateTime
      ..token = fields[6] as String
      ..pin = fields[7] as String?
      ..phone = fields[8] as String?
      ..bio = fields[9] as String?
      ..avatar = fields[10] as String?
      ..dateOfBirth = fields[11] as DateTime?
      ..gender = fields[12] as String?
      ..country = fields[13] as String?
      ..city = fields[14] as String?;
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.emailVerifiedAt)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.token)
      ..writeByte(7)
      ..write(obj.pin)
      ..writeByte(8)
      ..write(obj.phone)
      ..writeByte(9)
      ..write(obj.bio)
      ..writeByte(10)
      ..write(obj.avatar)
      ..writeByte(11)
      ..write(obj.dateOfBirth)
      ..writeByte(12)
      ..write(obj.gender)
      ..writeByte(13)
      ..write(obj.country)
      ..writeByte(14)
      ..write(obj.city);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
