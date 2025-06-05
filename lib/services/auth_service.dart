import 'package:bcrypt/bcrypt.dart';
import 'package:hive/hive.dart';
import 'package:monet/models/user.dart';

class AuthService {

  static Future<UserModel> create(Map<String, dynamic> user, String token) async {
    final userBox = await Hive.openBox(UserModel.userBox);
    await userBox.clear();

    // Ensure token is set in the user map
    user['token'] = token;
    var userModel = UserModel.fromJson(user);
    await userBox.put(0, userModel);
    return userModel;
  }

  static Future<UserModel> update(Map<String, dynamic> user) async {
    final userBox = await Hive.openBox(UserModel.userBox);
    if(userBox.isEmpty) throw Exception("User does not exist");

    // Use fromJson to update all fields
    var userModel = UserModel.fromJson(user);
    await userBox.put(0, userModel);
    return userModel;
  }

  static Future<UserModel> setPin(String pin) async {
    final userBox = await Hive.openBox(UserModel.userBox);
    if(userBox.isEmpty) throw Exception("User does not exist");

    var userModel = userBox.get(0);

    final hashed = BCrypt.hashpw(pin, BCrypt.gensalt());
    userModel.pin = hashed;

    await userBox.put(0, userModel);
    return userModel;
  }

  static Future<UserModel?> get() async {
    final userBox = await Hive.openBox(UserModel.userBox);
    if(userBox.isEmpty) return null;

    final userModel = await userBox.getAt(0);
    return userModel as UserModel?;
  }

  static Future delete() async {
    final userBox = await Hive.openBox(UserModel.userBox);
    await userBox.clear();
  }
}