import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:pikkar/core/services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final AppTheme _appTheme = AppTheme();
  bool _loading = false;
  String? _error;
  double _balance = 0;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _appTheme.addListener(_onThemeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWallet());
  }

  @override
  void dispose() {
    _appTheme.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _loadWallet() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        PikkarApi.wallet.getBalance(),
        PikkarApi.wallet.getTransactions(limit: 20, skip: 0),
      ]);
      final bal = results[0] as Map<String, dynamic>;
      final tx = results[1] as List<dynamic>;

      if (!mounted) return;
      setState(() {
        _balance = (bal['balance'] ?? bal['amount'] ?? 0).toDouble();
        _transactions = tx;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load wallet';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _appTheme.textDirection,
      child: Scaffold(
        backgroundColor: _appTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: _appTheme.cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              _appTheme.rtlEnabled ? Icons.arrow_forward : Icons.arrow_back,
              color: _appTheme.textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Wallet',
            style: TextStyle(
              color: _appTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: RefreshIndicator(
          color: _appTheme.brandRed,
          onRefresh: _loadWallet,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_loading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: _appTheme.brandRed,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _appTheme.brandRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _appTheme.brandRed.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: _appTheme.brandRed),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: _appTheme.textColor),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadWallet,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              // Wallet Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_appTheme.brandRed, _appTheme.brandRed.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${_balance.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Add money to wallet
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Add Money',
                        style: TextStyle(
                          color: _appTheme.brandRed,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              _buildSectionTitle('Quick Actions'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Add Money',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.history,
                      title: 'Transaction History',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Payment Methods
              _buildSectionTitle('Payment Methods'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: _appTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _appTheme.dividerColor, width: 1),
                ),
                child: Column(
                  children: [
                    _buildPaymentMethod(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet',
                      subtitle: '₹0 available',
                      isSelected: true,
                      onTap: () {},
                    ),
                    Divider(height: 1, color: _appTheme.dividerColor),
                    _buildPaymentMethod(
                      icon: Icons.money,
                      title: 'Cash',
                      subtitle: 'Pay directly to driver',
                      isSelected: false,
                      onTap: () {},
                    ),
                    Divider(height: 1, color: _appTheme.dividerColor),
                    _buildPaymentMethod(
                      icon: Icons.add_circle_outline,
                      title: 'Add Payment Method',
                      subtitle: 'UPI, Cards & more',
                      isSelected: false,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Transactions
              _buildSectionTitle('Recent Transactions'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: _appTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _appTheme.dividerColor, width: 1),
                ),
                child: _transactions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(
                            color: _appTheme.textGrey,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        children: _transactions.take(5).map((t) {
                          final m = t is Map ? t : const {};
                          final title = (m['type'] ?? m['status'] ?? 'Transaction').toString();
                          final amount = (m['amount'] ?? 0).toString();
                          return ListTile(
                            title: Text(title, style: TextStyle(color: _appTheme.textColor)),
                            subtitle: Text(
                              (m['createdAt'] ?? '').toString(),
                              style: TextStyle(color: _appTheme.textGrey, fontSize: 12),
                            ),
                            trailing: Text(
                              '₹$amount',
                              style: TextStyle(
                                color: _appTheme.textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _appTheme.textColor,
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _appTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _appTheme.dividerColor, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: _appTheme.textGrey, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _appTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _appTheme.iconBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _appTheme.textColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _appTheme.textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: _appTheme.textGrey,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: _appTheme.textGrey)
          : Icon(
              _appTheme.rtlEnabled ? Icons.chevron_left : Icons.chevron_right,
              color: _appTheme.textGrey,
            ),
      onTap: onTap,
    );
  }
}

