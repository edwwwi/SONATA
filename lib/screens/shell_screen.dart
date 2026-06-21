import 'package:flutter/material.dart';
import 'package:ice_cream_pos/screens/billing_screen.dart';
import 'package:ice_cream_pos/screens/products_screen.dart';
import 'package:ice_cream_pos/screens/stock_screen.dart';
import 'package:ice_cream_pos/screens/reports_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const BillingScreen(),
    const ProductsScreen(),
    const StockScreen(),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            minExtendedWidth: 200,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.point_of_sale, size: 36),
                label: Text('Billing', style: TextStyle(fontSize: 18)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.icecream, size: 36),
                label: Text('Products', style: TextStyle(fontSize: 18)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory, size: 36),
                label: Text('Stock', style: TextStyle(fontSize: 18)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart, size: 36),
                label: Text('Reports', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
