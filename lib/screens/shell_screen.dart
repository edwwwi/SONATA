import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/providers/auth_provider.dart';
import 'package:ice_cream_pos/screens/billing_screen.dart';
import 'package:ice_cream_pos/screens/products_screen.dart';
import 'package:ice_cream_pos/screens/stock_screen.dart';
import 'package:ice_cream_pos/screens/reports_screen.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _selectedIndex = 1; // 1 is Menu Order (Billing) by default

  final List<Widget> _screens = [
    const Center(child: Text('Dashboard Placeholder')), // 0: Dashboard
    const BillingScreen(),                              // 1: Menu Order
    const ReportsScreen(),                              // 2: Analytics
    const StockScreen(),                                // 3: Withdrawal (Stock)
    const Center(child: Text('Manage Table')),          // 4: Manage Table
    const ProductsScreen(),                             // 5: Manage Dish (Products)
    const Center(child: Text('Manage Payment')),        // 6: Manage Payment
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
        // Mocking auth requirement for Analytics(2), Stock(3), Products(5)
        final requiresAuth = (index == 2 || index == 3 || index == 5);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light background like Pospay
      body: Row(
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
                      _buildNavItem('Dashboard', Icons.grid_view, 0),
                      _buildNavItem('Menu Order', Icons.restaurant_menu, 1),
                      _buildNavItem('Analytics', Icons.bar_chart, 2),
                      _buildNavItem('Withdrawal', Icons.account_balance_wallet_outlined, 3),
                      const SizedBox(height: 16),
                      _buildNavItem('Manage Table', Icons.table_restaurant_outlined, 4, isExpandable: true),
                      // Mocking sub items visually
                      _buildNavItem('Booked', Icons.circle, -1, isSubItem: true),
                      _buildNavItem('Actived', Icons.check_circle_outline, -2, isSubItem: true),
                      _buildNavItem('Running Order', Icons.list_alt, -3, isSubItem: true),
                      
                      const SizedBox(height: 16),
                      _buildNavItem('Manage Dish', Icons.fastfood_outlined, 5, isExpandable: true),
                      _buildNavItem('Manage Payment', Icons.payment_outlined, 6),
                    ],
                  ),
                ),
                // Footer (Settings & Logout)
                const Divider(),
                _buildNavItem('Settings', Icons.settings_outlined, 7),
                InkWell(
                  onTap: () {
                    ref.read(authProvider.notifier).logout();
                    setState(() {
                      _selectedIndex = 1; // Revert to menu order
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 12),
                        Text('Logout', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // Main Content Area
          Expanded(
            child: _screens[_selectedIndex >= 0 && _selectedIndex < _screens.length ? _selectedIndex : 1],
          ),
        ],
      ),
    );
  }
}
