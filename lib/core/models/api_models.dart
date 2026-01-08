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
    final first = (json['firstName'] ?? '').toString().trim();
    final last = (json['lastName'] ?? '').toString().trim();
    final derivedName = ('$first $last').trim();
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: (json['name'] ?? derivedName ?? '').toString(),
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
  final String code;
  final String description;
  final String category;
  final String vehicleType;
  final VehicleCapacity vehicleCapacity;
  final VehiclePricing pricing;
  final String? icon;
  final String? iconSideView;
  final String? iconTopView;
  final String? iconFrontView;
  final bool isActive;
  final int order;
  
  VehicleType({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.category,
    required this.vehicleType,
    required this.vehicleCapacity,
    required this.pricing,
    this.icon,
    this.iconSideView,
    this.iconTopView,
    this.iconFrontView,
    required this.isActive,
    required this.order,
  });
  
  // Legacy getters for backward compatibility
  double get baseFare => pricing.baseFare;
  double get perKmRate => pricing.perKmRate;
  double get perMinuteRate => pricing.perMinuteRate;
  int get capacity => vehicleCapacity.passengers;
  
  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      vehicleCapacity: VehicleCapacity.fromJson(json['capacity'] ?? {}),
      pricing: VehiclePricing.fromJson(json['pricing'] ?? {}),
      icon: json['icon'],
      iconSideView: json['iconSideView'],
      iconTopView: json['iconTopView'],
      iconFrontView: json['iconFrontView'],
      isActive: json['isActive'] ?? false,
      order: json['order'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'code': code,
      'description': description,
      'category': category,
      'vehicleType': vehicleType,
      'capacity': vehicleCapacity.toJson(),
      'pricing': pricing.toJson(),
      'icon': icon,
      'iconSideView': iconSideView,
      'iconTopView': iconTopView,
      'iconFrontView': iconFrontView,
      'isActive': isActive,
      'order': order,
    };
  }
}

class VehicleCapacity {
  final int passengers;
  final int luggage;

  VehicleCapacity({
    required this.passengers,
    required this.luggage,
  });

  factory VehicleCapacity.fromJson(Map<String, dynamic> json) {
    return VehicleCapacity(
      passengers: json['passengers'] ?? 1,
      luggage: json['luggage'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'passengers': passengers,
      'luggage': luggage,
    };
  }
}

class VehiclePricing {
  final double baseFare;
  final double perKmRate;
  final double perMinuteRate;
  final double minimumFare;
  final double bookingFee;
  final double cancellationFee;
  final double basePrice;
  final double pricePerKm;
  final double pricePerKg;
  final double minimumPrice;

  VehiclePricing({
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.minimumFare,
    required this.bookingFee,
    required this.cancellationFee,
    required this.basePrice,
    required this.pricePerKm,
    required this.pricePerKg,
    required this.minimumPrice,
  });

  factory VehiclePricing.fromJson(Map<String, dynamic> json) {
    return VehiclePricing(
      baseFare: (json['baseFare'] ?? 0).toDouble(),
      perKmRate: (json['perKmRate'] ?? 0).toDouble(),
      perMinuteRate: (json['perMinuteRate'] ?? 0).toDouble(),
      minimumFare: (json['minimumFare'] ?? 0).toDouble(),
      bookingFee: (json['bookingFee'] ?? 0).toDouble(),
      cancellationFee: (json['cancellationFee'] ?? 0).toDouble(),
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      pricePerKm: (json['pricePerKm'] ?? 0).toDouble(),
      pricePerKg: (json['pricePerKg'] ?? 0).toDouble(),
      minimumPrice: (json['minimumPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'perMinuteRate': perMinuteRate,
      'minimumFare': minimumFare,
      'bookingFee': bookingFee,
      'cancellationFee': cancellationFee,
      'basePrice': basePrice,
      'pricePerKm': pricePerKm,
      'pricePerKg': pricePerKg,
      'minimumPrice': minimumPrice,
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
    final userId = json['userId'];
    final driverId = json['driverId'];
    final fareRaw = json['fare'] ?? json['estimatedFare'];
    return Ride(
      id: json['_id'] ?? json['id'] ?? '',
      userId: userId is String ? userId : (userId?['_id'] ?? userId?['id'] ?? '').toString(),
      driverId: driverId is String ? driverId : (driverId?['_id'] ?? driverId?['id'])?.toString(),
      vehicleType: json['vehicleType'] ?? '',
      pickup: Location.fromJson((json['pickupLocation'] ?? json['pickup'] ?? {}) as Map<String, dynamic>),
      dropoff: Location.fromJson((json['dropoffLocation'] ?? json['dropoff'] ?? {}) as Map<String, dynamic>),
      status: (json['status'] ?? 'pending').toString(),
      fare: fareRaw != null ? (fareRaw as num).toDouble() : null,
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
    final coords = json['coordinates'];
    double lat = 0;
    double lng = 0;
    if (coords is List && coords.length >= 2) {
      // GeoJSON: [longitude, latitude]
      lng = (coords[0] as num).toDouble();
      lat = (coords[1] as num).toDouble();
    } else {
      lat = (json['latitude'] ?? json['lat'] ?? 0).toDouble();
      lng = (json['longitude'] ?? json['lng'] ?? 0).toDouble();
    }
    return Location(
      latitude: lat,
      longitude: lng,
      address: json['address']?.toString(),
      name: json['name']?.toString(),
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

