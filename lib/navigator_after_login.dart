import 'package:flutter/material.dart';
import 'package:flutter_application_1/profile.dart';
import 'package:flutter_application_1/dashboard.dart';
import 'package:flutter_application_1/map.dart';

class NavigatorAfterLogin extends StatefulWidget {
  const NavigatorAfterLogin({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NavigatorAfterLoginState createState() => _NavigatorAfterLoginState();
}

class _NavigatorAfterLoginState extends State<NavigatorAfterLogin> {
  int _currentIndex = 0;
  final List<Widget> _pages = [Dashboard(), MapPage(), ProfileScreen()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
