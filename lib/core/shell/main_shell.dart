import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../ui/features/auth/view_models/auth_view_model.dart';
import '../theme/app_color.dart';

class _NavItem {
  final int branchIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.branchIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  void _onTap(int branchIndex) {
    widget.navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final isSupervisor = authViewModel.roleSlug == 'pengawas';

    final items = isSupervisor
        ? const [
            _NavItem(
              branchIndex: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
            ),
            _NavItem(
              branchIndex: 3,
              icon: Icons.people_outline,
              activeIcon: Icons.people,
              label: 'Pasien',
            ),
            _NavItem(
              branchIndex: 4,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profil',
            ),
          ]
        : const [
            _NavItem(
              branchIndex: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
            ),
            _NavItem(
              branchIndex: 1,
              icon: Icons.history,
              activeIcon: Icons.history,
              label: 'Riwayat',
            ),
            _NavItem(
              branchIndex: 2,
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment,
              label: 'Log Gejala',
            ),
            _NavItem(
              branchIndex: 4,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profil',
            ),
          ];

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: AppColor.primary,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) => _buildNavItem(item)).toList(),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item) {
    final isSelected = widget.navigationShell.currentIndex == item.branchIndex;
    
    if (isSelected) {
      return GestureDetector(
        onTap: () => _onTap(item.branchIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.activeIcon, color: AppColor.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: const TextStyle(
                  color: AppColor.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return IconButton(
      onPressed: () => _onTap(item.branchIndex),
      icon: Icon(item.icon, color: AppColor.white, size: 28),
    );
  }
}

