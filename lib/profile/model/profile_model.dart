/*
class Profile {
  final String? name;
  final String? username;
  final String? mobileNumber;
  final String? role;
  final String? aadharNumber;
  final String? address;

  Profile({
    this.name,
    this.username,
    this.mobileNumber,
    this.role,
    this.aadharNumber,
    this.address,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'] as String?,
      username: json['username'] as String?,
      mobileNumber: json['mobile_number'] as String?,
      role: json['role'] as String?,
      aadharNumber: json['aadhar_number'] as String?,
      address: json['address'] as String?,
    );
  }
}
*/
class Profile {
  final String? name;
  final String? username;
  final String? mobileNumber;
  final String? role;
  final String? aadharNumber;
  final String? address;
  final String? password;

  Profile({
    this.name,
    this.username,
    this.mobileNumber,
    this.role,
    this.aadharNumber,
    this.address,
    this.password
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'] as String?,
      username: json['username'] as String?,
      mobileNumber: json['mobile_number'] as String?,
      role: json['role'] as String?,
      aadharNumber: json['aadhar_number'] as String?,
      address: json['address'] as String?,
      password: json['password'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'number': mobileNumber,
      'role': role,
      'aadhar_number': aadharNumber,
      'address': address,
      'password':password,
    };
  }
}