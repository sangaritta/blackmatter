// ignore_for_file: non_constant_identifier_names

class UserModel {
  int accountType;
  String displayName;
  String email;
  final String uid;

  UserModel({
    required this.accountType,
    required this.displayName,
    required this.email,
    required this.uid,
  });
}
