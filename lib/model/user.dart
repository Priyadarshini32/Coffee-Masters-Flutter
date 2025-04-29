class User {
  final String? id;
  final String name;
  final String email;
  final String password;
  final String? phone;
  final String? address;
  final String? profileImage;
  final String createdAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.address,
    this.profileImage,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'address': address,
      'profileImage': profileImage,
      'createdAt': createdAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      profileImage: map['profileImage'] as String?,
      createdAt: map['createdAt'] as String,
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? phone,
    String? address,
    String? profileImage,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
