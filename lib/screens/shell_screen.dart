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
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const BillingScreen(),
    const ProductsScreen(),
    const StockScreen(),
    const ReportsScreen(),
  ];

  final List<String> _titles = [
    'Billing',
    'Products',
    'Stock Inventory',
    'Reports',
  ];

  void _showAdminLoginDialog() {
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
            onSubmitted: (val) => _submitPin(pinController.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _submitPin(pinController.text),
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitPin(String pin) async {
    final success = await ref.read(authProvider.notifier).verifyPin(pin);
    if (mounted) {
      Navigator.pop(context); // Close dialog
      if (success) {
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

  @override
  Widget build(BuildContext context) {
    final isAuth = ref.watch(authProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          if (!isAuth)
            TextButton.icon(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              label: const Text('Admin', style: TextStyle(color: Colors.white)),
              onPressed: _showAdminLoginDialog,
            )
          else
            TextButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(color: Colors.white)),
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                setState(() {
                  _selectedIndex = 0; // Redirect to billing
                });
              },
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'POS System',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text('Billing'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.icecream),
              title: const Text('Products Search'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            if (isAuth) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text('Admin Only', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.inventory),
                title: const Text('Stock Inventory'),
                selected: _selectedIndex == 2,
                onTap: () {
                  setState(() => _selectedIndex = 2);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Reports'),
                selected: _selectedIndex == 3,
                onTap: () {
                  setState(() => _selectedIndex = 3);
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}
