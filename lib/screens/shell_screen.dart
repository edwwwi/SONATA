import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/providers/auth_provider.dart';
import 'package:ice_cream_pos/screens/billing_screen.dart';
import 'package:ice_cream_pos/screens/products_screen.dart';
import 'package:ice_cream_pos/screens/stock_screen.dart';
import 'package:ice_cream_pos/screens/reports_screen.dart';
import 'package:ice_cream_pos/screens/stock_history_screen.dart';
import 'package:ice_cream_pos/screens/settings_screen.dart';
import 'package:ice_cream_pos/screens/analytics_dashboard_screen.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _selectedIndex = 0; // 0 is Billing by default

  final List<Widget> _screens = [
    const BillingScreen(),
    const ProductsScreen(),
    const AnalyticsDashboardScreen(),
    const StockScreen(),
    const StockHistoryScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  void _showAdminLoginDialog(int targetIndex) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Admin Login'),
          content: TextField(
            controller: pinController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Enter PIN',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
            onSubmitted: (val) => _submitPin(pinController.text, targetIndex),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _submitPin(pinController.text, targetIndex),
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitPin(String pin, int targetIndex) async {
    final success = await ref.read(authProvider.notifier).verifyPin(pin);
    if (mounted) {
      Navigator.pop(context);
      if (success) {
        setState(() {
          _selectedIndex = targetIndex;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin access granted', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid PIN', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onMenuTapped(int index, bool requiresAuth, bool isAuth) {
    if (requiresAuth && !isAuth) {
      _showAdminLoginDialog(index);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildNavItem(String title, IconData icon, int index, {bool isSubItem = false, bool isExpandable = false}) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: isExpandable ? null : () {
        // Mocking auth requirement for Admin items (indices >= 2)
        final requiresAuth = index >= 2;
        final isAuth = ref.read(authProvider).value ?? false;
        _onMenuTapped(index, requiresAuth, isAuth);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: isSubItem ? 32 : 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent, // Dark slate if selected
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            if (isExpandable) Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = ref.watch(authProvider).value ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Container(
        decoration: BoxDecoration(
          border: isAuth ? Border.all(color: Colors.red, width: 4) : null,
        ),
        child: Row(
          children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                // Logo Section
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Image.asset('assets/images/sonata-icecream-logo.png', height: 40, width: 40, fit: BoxFit.contain),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sonata POS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Cashier Daily Assistant', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildNavItem('Billing', Icons.point_of_sale, 0),
                      _buildNavItem('Products', Icons.inventory, 1),
                    const Divider(height: 32, color: Colors.grey),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text('ADMINISTRATION', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    _buildNavItem('Analytics Dashboard', Icons.analytics, 2),
                    _buildNavItem('Stock Entry', Icons.add_box, 3),
                    _buildNavItem('Stock History', Icons.history, 4),
                    _buildNavItem('Sales Reports', Icons.bar_chart, 5),
                    _buildNavItem('Settings', Icons.settings, 6),
                    ],
                  ),
                ),
                // Footer (Logout)
                if (isAuth) ...[
                  const Divider(),
                  InkWell(
                    onTap: () {
                      ref.read(authProvider.notifier).logout();
                      setState(() {
                        _selectedIndex = 0; // Revert to billing
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.logout, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          
          // Main Content Area
          Expanded(
            child: _screens[_selectedIndex >= 0 && _selectedIndex < _screens.length ? _selectedIndex : 0],
          ),
        ],
      ),
      ),
    );
  }
}
