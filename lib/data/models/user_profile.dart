class UserProfile {
  final String id;
  final String? email;
  final String? phoneNumber;
  final String fullName;
  final String? avatarUrl;
  final String currency;
  final int initialBalance;

  const UserProfile({
    required this.id,
    this.email,
    this.phoneNumber,
    required this.fullName,
    this.avatarUrl,
    this.currency = 'UZS',
    this.initialBalance = 0,
  });

  String? get phone => phoneNumber;

  factory UserProfile.guest() {
    return const UserProfile(
      id: '',
      fullName: 'Foydalanuvchi',
      currency: 'UZS',
      initialBalance: 0,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      fullName: json['fullName']?.toString() ?? 'Foydalanuvchi',
      avatarUrl: json['avatarUrl']?.toString(),
      currency: json['currency']?.toString() ?? 'UZS',
      initialBalance: (json['initialBalance'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'currency': currency,
      'initialBalance': initialBalance,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? fullName,
    String? avatarUrl,
    String? currency,
    int? initialBalance,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
    );
  }
}
