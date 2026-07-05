class User {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isAdmin,
    required this.isRestaurant,
    required this.isActive,
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isAdmin;
  final bool isRestaurant;
  final bool isActive;

  /// L'app est réservée aux clients (ni admin ni restaurateur).
  bool get isClient => !isAdmin && !isRestaurant;

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      isAdmin: json['isAdmin'] as bool? ?? false,
      isRestaurant: json['isRestaurant'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'isAdmin': isAdmin,
        'isRestaurant': isRestaurant,
        'isActive': isActive,
      };
}
