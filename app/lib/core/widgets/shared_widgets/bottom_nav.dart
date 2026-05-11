part of '../shared_widgets.dart';

class AppBottomNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String route;

  const AppBottomNavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.route,
  });
}

class AppBottomNavBar extends StatelessWidget {
  final List<AppBottomNavItem> items;
  final int selectedIndex;
  final String currentRoute;
  final bool centerCreate;
  final Map<int, int> badgeCounts;
  final VoidCallback? onCreateTap;

  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.currentRoute,
    this.centerCreate = false,
    this.badgeCounts = const {},
    this.onCreateTap,
  }) : assert(
         !centerCreate || items.length == 4,
         'centerCreate requires exactly 4 nav items.',
       );

  @override
  Widget build(BuildContext context) {
    // Navigation is now owned by ResponsiveScaffold. Keep this legacy widget as
    // a no-op so older feature screens do not render a second bottom bar.
    return const SizedBox.shrink();
  }

  Widget buildLegacy(BuildContext context) {
    void navigate(String route) {
      if (_isCurrentRoute(context, route)) return;
      context.go(route);
    }

    return Container(
      height: 78,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EAF2))),
      ),
      child:
          centerCreate
              ? Row(
                children: [
                  Expanded(
                    child: _AppBottomNavButton(
                      item: items[0],
                      selected: selectedIndex == 0,
                      badgeCount: badgeCounts[0] ?? 0,
                      onTap: () => navigate(items[0].route),
                    ),
                  ),
                  Expanded(
                    child: _AppBottomNavButton(
                      item: items[1],
                      selected: selectedIndex == 1,
                      badgeCount: badgeCounts[1] ?? 0,
                      onTap: () => navigate(items[1].route),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap:
                          onCreateTap ??
                          () => context.push(AppRoutes.createPost),
                      child: Center(
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _AppBottomNavButton(
                      item: items[2],
                      selected: selectedIndex == 2,
                      badgeCount: badgeCounts[2] ?? 0,
                      onTap: () => navigate(items[2].route),
                    ),
                  ),
                  Expanded(
                    child: _AppBottomNavButton(
                      item: items[3],
                      selected: selectedIndex == 3,
                      badgeCount: badgeCounts[3] ?? 0,
                      onTap: () => navigate(items[3].route),
                    ),
                  ),
                ],
              )
              : Row(
                children: List.generate(items.length, (index) {
                  return Expanded(
                    child: _AppBottomNavButton(
                      item: items[index],
                      selected: selectedIndex == index,
                      badgeCount: badgeCounts[index] ?? 0,
                      onTap: () => navigate(items[index].route),
                    ),
                  );
                }),
              ),
    );
  }

  bool _isCurrentRoute(BuildContext context, String route) {
    final current = currentRoute;
    if (route == AppRoutes.home) {
      return current.startsWith(AppRoutes.home);
    }
    if (route == AppRoutes.explore) {
      return current.startsWith(AppRoutes.explore);
    }
    if (route == AppRoutes.profile) {
      return current.startsWith(AppRoutes.profile);
    }
    return current.startsWith(route);
  }
}

class _AppBottomNavButton extends StatelessWidget {
  final AppBottomNavItem item;
  final bool selected;
  final int badgeCount;
  final VoidCallback? onTap;

  const _AppBottomNavButton({
    required this.item,
    required this.selected,
    this.badgeCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : const Color(0xFF98A2B3);
    final icon = selected ? (item.selectedIcon ?? item.icon) : item.icon;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Badge(
            isLabelVisible: badgeCount > 0,
            label: Text(
              badgeCount > 99 ? '99+' : '$badgeCount',
              style: const TextStyle(fontSize: 10),
            ),
            backgroundColor: AppColors.error,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
