/// 📱 PIKKAR API USAGE EXAMPLES
/// 
/// This file contains practical examples of how to use the Pikkar API
/// in your Flutter widgets and screens.
/// 
/// DO NOT import this file in your app - it's for reference only!

import 'package:flutter/material.dart';
import 'core/services/api_service.dart';

// ============================================
// EXAMPLE 1: Login Screen with Email/Password
// ============================================

class ExampleLoginScreen extends StatefulWidget {
  const ExampleLoginScreen({super.key});

  @override
  State<ExampleLoginScreen> createState() => _ExampleLoginScreenState();
}

class _ExampleLoginScreenState extends State<ExampleLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    
    try {
      // Call login API
      final response = await PikkarApi.auth.login(
        email: _emailController.text,
        password: _passwordController.text,
        role: 'user',
      );
      
      // Save token and user data
      await PikkarApi.saveToken(response['token']);
      await PikkarApi.saveUserData(response['user']);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome ${response['user']['name']}!')),
        );
        
        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on ApiException catch (e) {
      // Handle API errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Handle other errors (network, etc.)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// EXAMPLE 2: Ride Booking
// ============================================

class ExampleRideBooking {
  Future<void> bookRide() async {
    try {
      final ride = await PikkarApi.rides.create(
        vehicleType: 'bike_001',
        pickup: {
          'latitude': 17.4065,
          'longitude': 78.4772,
          'address': 'Charminar, Hyderabad',
          'name': 'My Location',
        },
        dropoff: {
          'latitude': 17.4400,
          'longitude': 78.4983,
          'address': 'Hitech City, Hyderabad',
          'name': 'Office',
        },
        paymentMethod: 'wallet',
        notes: 'Please call when you arrive',
        passengers: 1,
      );
      
      print('Ride booked successfully!');
      print('Ride ID: ${ride['_id']}');
      print('Status: ${ride['status']}');
      print('Fare: ₹${ride['fare']}');
    } on ApiException catch (e) {
      print('Booking failed: ${e.message}');
    }
  }
}

// ============================================
// EXAMPLE 3: Vehicle Selection with Fare Calculation
// ============================================

class ExampleVehicleSelection extends StatefulWidget {
  const ExampleVehicleSelection({super.key});

  @override
  State<ExampleVehicleSelection> createState() => _ExampleVehicleSelectionState();
}

class _ExampleVehicleSelectionState extends State<ExampleVehicleSelection> {
  List<dynamic> _vehicles = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }
  
  Future<void> _loadVehicles() async {
    try {
      final vehicles = await PikkarApi.vehicleTypes.getActive();
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      print('Error loading vehicles: ${e.message}');
    }
  }
  
  Future<void> _calculateFare(String vehicleId) async {
    try {
      final fareData = await PikkarApi.vehicleTypes.calculateFare(
        vehicleId: vehicleId,
        distanceKm: 5.5,
        timeMinutes: 15,
      );
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Estimated Fare'),
            content: Text('₹${fareData['fare']}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on ApiException catch (e) {
      print('Fare calculation failed: ${e.message}');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return ListView.builder(
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        return ListTile(
          title: Text(vehicle['name']),
          subtitle: Text('Base fare: ₹${vehicle['baseFare']}'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _calculateFare(vehicle['_id']),
        );
      },
    );
  }
}

// ============================================
// EXAMPLE 4: Wallet Management
// ============================================

class ExampleWalletScreen extends StatefulWidget {
  const ExampleWalletScreen({super.key});

  @override
  State<ExampleWalletScreen> createState() => _ExampleWalletScreenState();
}

class _ExampleWalletScreenState extends State<ExampleWalletScreen> {
  double _balance = 0.0;
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }
  
  Future<void> _loadWalletData() async {
    try {
      // Load balance
      final wallet = await PikkarApi.wallet.getBalance();
      
      // Load transactions
      final transactions = await PikkarApi.wallet.getTransactions(limit: 10);
      
      setState(() {
        _balance = (wallet['balance'] ?? 0).toDouble();
        _transactions = transactions;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      print('Error loading wallet: ${e.message}');
    }
  }
  
  Future<void> _addMoney() async {
    try {
      final result = await PikkarApi.wallet.addMoney(
        amount: 500.0,
        paymentMethod: 'card',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ₹${result['amount']} to wallet')),
        );
        _loadWalletData(); // Reload wallet data
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        // Balance Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('Wallet Balance'),
                Text(
                  '₹$_balance',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: _addMoney,
                  child: const Text('Add Money'),
                ),
              ],
            ),
          ),
        ),
        // Transactions List
        Expanded(
          child: ListView.builder(
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final transaction = _transactions[index];
              return ListTile(
                title: Text(transaction['type']),
                subtitle: Text(transaction['date']),
                trailing: Text('₹${transaction['amount']}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================
// EXAMPLE 5: Promo Code Application
// ============================================

class ExamplePromoCode {
  Future<void> applyPromoCode(String code, double amount) async {
    try {
      // Validate promo code first
      await PikkarApi.promo.validate(code);
      
      // Apply promo code
      final result = await PikkarApi.promo.apply(
        code: code,
        amount: amount,
      );
      
      print('Promo applied successfully!');
      print('Original: ₹$amount');
      print('Discount: ₹${result['discount']}');
      print('Final: ₹${result['finalAmount']}');
    } on ApiException catch (e) {
      print('Promo code error: ${e.message}');
    }
  }
  
  Future<void> loadAvailablePromos() async {
    try {
      final promos = await PikkarApi.promo.getAvailable();
      
      for (var promo in promos) {
        print('${promo['code']} - ${promo['description']}');
      }
    } on ApiException catch (e) {
      print('Error loading promos: ${e.message}');
    }
  }
}

// ============================================
// EXAMPLE 6: Real-time Location Update
// ============================================

class ExampleLocationService {
  Future<void> updateUserLocation(double lat, double lng) async {
    try {
      await PikkarApi.user.updateLocation(
        latitude: lat,
        longitude: lng,
      );
      print('Location updated successfully');
    } on ApiException catch (e) {
      print('Location update failed: ${e.message}');
    }
  }
  
  // Call this periodically during an active ride
  void startLocationUpdates() {
    // Using Timer for periodic updates
    // Timer.periodic(const Duration(seconds: 10), (timer) async {
    //   // Get current position
    //   final position = await Geolocator.getCurrentPosition();
    //   await updateUserLocation(position.latitude, position.longitude);
    // });
  }
}

// ============================================
// EXAMPLE 7: Ride History with Ratings
// ============================================

class ExampleRideHistory extends StatefulWidget {
  const ExampleRideHistory({super.key});

  @override
  State<ExampleRideHistory> createState() => _ExampleRideHistoryState();
}

class _ExampleRideHistoryState extends State<ExampleRideHistory> {
  List<dynamic> _rides = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadRides();
  }
  
  Future<void> _loadRides() async {
    try {
      final rides = await PikkarApi.rides.getMyRides(status: 'completed');
      setState(() {
        _rides = rides;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      print('Error loading rides: ${e.message}');
    }
  }
  
  Future<void> _rateRide(String rideId) async {
    try {
      await PikkarApi.rides.rate(
        rideId: rideId,
        rating: 5,
        review: 'Great ride!',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your rating!')),
        );
      }
    } on ApiException catch (e) {
      print('Rating failed: ${e.message}');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return ListView.builder(
      itemCount: _rides.length,
      itemBuilder: (context, index) {
        final ride = _rides[index];
        return Card(
          child: ListTile(
            title: Text('${ride['pickup']['address']} → ${ride['dropoff']['address']}'),
            subtitle: Text('₹${ride['fare']}'),
            trailing: IconButton(
              icon: const Icon(Icons.star),
              onPressed: () => _rateRide(ride['_id']),
            ),
          ),
        );
      },
    );
  }
}

