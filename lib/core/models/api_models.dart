/// API Models for Pikkar
/// Contains data models for API requests and responses

/// Auth Response Model
class AuthResponse {
  final String token;
  final User user;
  
  AuthResponse({
    required this.token,
    required this.user,
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}

/// User Model
class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? profilePicture;
  final DateTime? createdAt;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.profilePicture,
    this.createdAt,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'user',
      profilePicture: json['profilePicture'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profilePicture': profilePicture,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

/// Vehicle Type Model
class VehicleType {
  final String id;
  final String name;
  final String category;
  final double baseFare;
  final double perKmRate;
  final double perMinuteRate;
  final int capacity;
  final String? icon;
  final bool isActive;
  
  VehicleType({
    required this.id,
    required this.name,
    required this.category,
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.capacity,
    this.icon,
    required this.isActive,
  });
  
  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      baseFare: (json['baseFare'] ?? 0).toDouble(),
      perKmRate: (json['perKmRate'] ?? 0).toDouble(),
      perMinuteRate: (json['perMinuteRate'] ?? 0).toDouble(),
      capacity: json['capacity'] ?? 1,
      icon: json['icon'],
      isActive: json['isActive'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'perMinuteRate': perMinuteRate,
      'capacity': capacity,
      'icon': icon,
      'isActive': isActive,
    };
  }
}

/// Ride Model
class Ride {
  final String id;
  final String userId;
  final String? driverId;
  final String vehicleType;
  final Location pickup;
  final Location dropoff;
  final String status;
  final double? fare;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime? completedAt;
  
  Ride({
    required this.id,
    required this.userId,
    this.driverId,
    required this.vehicleType,
    required this.pickup,
    required this.dropoff,
    required this.status,
    this.fare,
    this.paymentMethod,
    required this.createdAt,
    this.completedAt,
  });
  
  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      driverId: json['driverId'],
      vehicleType: json['vehicleType'] ?? '',
      pickup: Location.fromJson(json['pickup'] ?? {}),
      dropoff: Location.fromJson(json['dropoff'] ?? {}),
      status: json['status'] ?? 'pending',
      fare: json['fare']?.toDouble(),
      paymentMethod: json['paymentMethod'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'driverId': driverId,
      'vehicleType': vehicleType,
      'pickup': pickup.toJson(),
      'dropoff': dropoff.toJson(),
      'status': status,
      'fare': fare,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}

/// Location Model
class Location {
  final double latitude;
  final double longitude;
  final String? address;
  final String? name;
  
  Location({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
  });
  
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: (json['latitude'] ?? json['lat'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? 0).toDouble(),
      address: json['address'],
      name: json['name'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'name': name,
    };
  }
}

/// Driver Model
class Driver {
  final String id;
  final String name;
  final String phone;
  final String vehicleType;
  final String vehicleNumber;
  final double rating;
  final int totalRides;
  final bool isAvailable;
  final Location? currentLocation;
  
  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.rating,
    required this.totalRides,
    required this.isAvailable,
    this.currentLocation,
  });
  
  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      totalRides: json['totalRides'] ?? 0,
      isAvailable: json['isAvailable'] ?? false,
      currentLocation: json['currentLocation'] != null 
          ? Location.fromJson(json['currentLocation']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'rating': rating,
      'totalRides': totalRides,
      'isAvailable': isAvailable,
      'currentLocation': currentLocation?.toJson(),
    };
  }
}

/// Payment Model
class Payment {
  final String id;
  final String userId;
  final String rideId;
  final double amount;
  final String method;
  final String status;
  final DateTime createdAt;
  
  Payment({
    required this.id,
    required this.userId,
    required this.rideId,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
  });
  
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      rideId: json['rideId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      method: json['method'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'rideId': rideId,
      'amount': amount,
      'method': method,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Wallet Model
class Wallet {
  final String id;
  final String userId;
  final double balance;
  final DateTime updatedAt;
  
  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.updatedAt,
  });
  
  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'balance': balance,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Promo Code Model
class PromoCode {
  final String id;
  final String code;
  final String type;
  final double value;
  final double? minAmount;
  final double? maxDiscount;
  final DateTime expiresAt;
  final bool isActive;
  
  PromoCode({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minAmount,
    this.maxDiscount,
    required this.expiresAt,
    required this.isActive,
  });
  
  factory PromoCode.fromJson(Map<String, dynamic> json) {
    return PromoCode(
      id: json['_id'] ?? json['id'] ?? '',
      code: json['code'] ?? '',
      type: json['type'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      minAmount: json['minAmount']?.toDouble(),
      maxDiscount: json['maxDiscount']?.toDouble(),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt']) 
          : DateTime.now(),
      isActive: json['isActive'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'value': value,
      'minAmount': minAmount,
      'maxDiscount': maxDiscount,
      'expiresAt': expiresAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}

