import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/routes.dart';

class BottomNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavigationShell({super.key, required this.navigationShell});

  void _onItemTapped(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final currentIndex = navigationShell.currentIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        final String currentLocation = GoRouterState.of(context).uri.path;

        if (currentLocation == AppRoutes.attendance) {
          Navigator.of(context).pop();
        } else {
          if (GoRouter.of(context).canPop()) {
            GoRouter.of(context).pop();
          } else {
            context.go(AppRoutes.attendance);
          }
        }
      },
      child: SafeArea(
        top: false,
        child: Scaffold(
          body: navigationShell,
          extendBody: true,
          bottomNavigationBar: Container(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                    context,
                    0,
                    Icons.home_filled,
                    'Home',
                    currentIndex,
                    screenWidth,
                    screenHeight
                ),
                _buildNavItem(
                  context,
                  1,
                  Icons.calendar_month_outlined,
                  'Calendar',
                  currentIndex,
                  screenWidth,
                    screenHeight
                ),
                _buildNavItem(
                    context,
                    2,
                    Icons.share_arrival_time,
                    'Attendance',
                    currentIndex,
                    screenWidth,
                    screenHeight
                ),

                _buildNavItem(
                  context,
                  3,
                  Icons.mail_outline,
                  'Mail',
                  currentIndex,
                  screenWidth,
                    screenHeight
                ),
                _buildNavItem(
                  context,
                  4,
                  Icons.person_rounded,
                  'Profile',
                  currentIndex,
                  screenWidth,
                  screenHeight
                ),
              ],
            ),
          ),
        ),
      ),

    );
  }

  Widget _buildNavItem(
      BuildContext context,
      int index,
      IconData icon,
      String label,
      int currentIndex,
      double screenWidth,
      double screenHeight,
      ) {
    final isActive = index == currentIndex;
    final activeColor = const Color(0xff007AFF);
    final inactiveColor = Colors.grey.shade600;

    return SizedBox(
      width: screenWidth / 5,
      child: GestureDetector(
        onTap: () => _onItemTapped(context, index),
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.008),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: screenWidth * 0.07,
              ),
              SizedBox(height: screenHeight * 0.006),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: screenWidth * 0.032,   // sedikit diperkecil agar muat
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

}