import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/routes.dart';

class BottomNavigationShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavigationShell({super.key, required this.navigationShell});

  @override
  State<BottomNavigationShell> createState() => _BottomNavigationShellState();
}

class _NavItemData {
  final IconData icon;
  final String label;
  const _NavItemData(this.icon, this.label);
}

class _BottomNavigationShellState extends State<BottomNavigationShell> {
  static const double _webBreakpoint = 1024;

  bool _sideNavCollapsed = false;

  static const List<_NavItemData> _navItems = [
    _NavItemData(Icons.home_filled, 'Home'),
    _NavItemData(Icons.calendar_month_outlined, 'Calendar'),
    _NavItemData(Icons.share_arrival_time, 'Attendance'),
    _NavItemData(Icons.mail_outline, 'Mail'),
    _NavItemData(Icons.person_rounded, 'Profile'),
  ];

  void _onItemTapped(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final currentIndex = widget.navigationShell.currentIndex;
    final isWeb = screenWidth >= _webBreakpoint;

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
        child: isWeb
            ? _buildWebLayout(context, currentIndex)
            : _buildMobileLayout(
            context, currentIndex, screenWidth, screenHeight),
      ),
    );
  }

  // ================== MOBILE (bottom nav bar) ==================

  Widget _buildMobileLayout(
      BuildContext context,
      int currentIndex,
      double screenWidth,
      double screenHeight,
      ) {
    return Scaffold(
      body: widget.navigationShell,
      extendBody: true,
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            return _buildBottomNavItem(
              context,
              index,
              item.icon,
              item.label,
              currentIndex,
              screenWidth,
              screenHeight,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
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

    // icon & font dibatasi (clamp) supaya tidak membesar berlebihan
    // di layar lebar (mis. tablet mendekati breakpoint web).
    final iconSize = (screenWidth * 0.07).clamp(20.0, 26.0);
    final fontSize = (screenWidth * 0.032).clamp(11.0, 13.0);

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
                size: iconSize,
              ),
              SizedBox(height: screenHeight * 0.006),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: fontSize,
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

  // ================== WEB (side nav + hamburger) ==================

  Widget _buildWebLayout(BuildContext context, int currentIndex) {
    final sidebarWidth = _sideNavCollapsed ? 72.0 : 220.0;

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            // ClipRect + LayoutBuilder: layout item mengikuti LEBAR ANIMASI
            // yang sebenarnya, bukan langsung mengikuti state boolean.
            // Ini mencegah padding/teks "meloncat" ke ukuran expanded
            // sebelum ruangnya cukup -> mencegah RenderFlex overflow saat
            // proses uncollapse.
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool visuallyCollapsed = constraints.maxWidth < 150;

                  return Column(
                    children: [
                      SizedBox(
                        height: 64,
                        child: Row(
                          mainAxisAlignment: visuallyCollapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.menu),
                              tooltip: _sideNavCollapsed ? 'Perluas' : 'Ciutkan',
                              onPressed: () => setState(
                                    () => _sideNavCollapsed = !_sideNavCollapsed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _navItems.length,
                          itemBuilder: (context, index) {
                            final item = _navItems[index];
                            return _buildSideNavItem(
                              context,
                              index,
                              item.icon,
                              item.label,
                              currentIndex,
                              visuallyCollapsed,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }

  Widget _buildSideNavItem(
      BuildContext context,
      int index,
      IconData icon,
      String label,
      int currentIndex,
      bool collapsed, // <-- diganti dari _sideNavCollapsed
      ) {
    final isActive = index == currentIndex;
    final activeColor = const Color(0xff007AFF);
    final inactiveColor = Colors.grey.shade600;

    final content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _onItemTapped(context, index),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : 16,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment:
              collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isActive ? activeColor : inactiveColor,
                  size: 22,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isActive ? activeColor : inactiveColor,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return collapsed ? Tooltip(message: label, child: content) : content;
  }
}