import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: widget.navigationShell,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _onTap,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Colors.blue),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.medical_services_outlined),
              selectedIcon: Icon(Icons.medical_services, color: Colors.blue),
              label: 'Gejala',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Colors.blue),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
