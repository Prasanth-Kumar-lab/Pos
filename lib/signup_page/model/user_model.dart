class UserModelSignUp {
  final String name;
  final String mobileNumber;
  final String username;
  final String password;
  final String role;
  final String? adminId;
  final String? aadharNumber;
  final String? address;

  UserModelSignUp({
    required this.name,
    required this.mobileNumber,
    required this.username,
    required this.password,
    required this.role,
    this.adminId,
    this.aadharNumber,
    this.address,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'mobile_number': mobileNumber,
    'username': username,
    'password': password,
    'role': role,
    if (adminId != null) 'admin_id': adminId,
    if (aadharNumber != null) 'aadhar_number': aadharNumber,
    if (address != null) 'address': address,
  };
}