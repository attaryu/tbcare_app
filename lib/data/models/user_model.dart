class UserModel {
  final int id;
  final String name;
  final String email;
  final String? telephoneNumber;
  final String? photoUrl;
  final String? authUserId;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.telephoneNumber,
    this.photoUrl,
    this.authUserId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      telephoneNumber: json['telephone_number'],
      photoUrl: json['photo_url'],
      authUserId: json['auth_user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'telephone_number': telephoneNumber,
      'photo_url': photoUrl,
      'auth_user_id': authUserId,
    };
  }
}
