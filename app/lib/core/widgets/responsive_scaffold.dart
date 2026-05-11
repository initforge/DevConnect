import 'package:flutter/material.dart';

import '../navigation/feature_destination.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.body,
    required this.currentRoute,
    this.appBar,
    this.floatingActionButton,
    this.onDestinationSelected,
    this.onCreateSelected,
    this.showBottomNav = true,
  });

  final Widget body;
  final String currentRoute;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final ValueChanged<FeatureDestination>? onDestinationSelected;
  final VoidCallback? onCreateSelected;
  final bool showBottomNav;

  @override
  Widget build(BuildContext context) {
    final device = ResponsiveUtils.getDeviceType(context);
    if (device == DeviceType.mobile) {
      return _buildMobile(context);
    }
    return _buildWithSidebar(context, expanded: device == DeviceType.desktop);
  }

  Widget _buildWithSidebar(BuildContext context, {required bool expanded}) {
    final sidebarWidth = ResponsiveUtils.getSidebarWidth(context);
    final maxWidth = ResponsiveUtils.getContentMaxWidth(context);

    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          Container(
            width: sidebarWidth,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                _SidebarHeader(expanded: expanded),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _buildSidebarSections(expanded),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: body,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  List<Widget> _buildSidebarSections(bool expanded) {
    final groups = <FeatureDestinationGroup, List<FeatureDestination>>{};
    for (final item in FeatureDestinations.sidebar) {
      groups.putIfAbsent(item.group, () => <FeatureDestination>[]).add(item);
    }

    return groups.entries.expand((entry) {
      final widgets = <Widget>[];
      if (expanded && entry.key != FeatureDestinationGroup.primary) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Text(
              FeatureDestinations.groupLabel(entry.key).toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        );
      } else if (!expanded && entry.key != FeatureDestinationGroup.primary) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Divider(height: 1),
        ));
      }
      widgets.addAll(entry.value.map((item) {
        final selected = item.matchesRoute(currentRoute);
        return _SidebarItem(
          destination: item,
          selected: selected,
          expanded: expanded,
          onTap: () => onDestinationSelected?.call(item),
        );
      }));
      return widgets;
    }).toList();
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: null,
      bottomNavigationBar: showBottomNav ? _MobileNav(
        currentRoute: currentRoute,
        onDestinationSelected: onDestinationSelected,
        onCreateSelected: onCreateSelected,
      ) : null,
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(expanded ? 20 : 14),
      child: Row(
        mainAxisAlignment:
            expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.code, color: Colors.white, size: 22),
          ),
          if (expanded) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'DevConnect',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final FeatureDestination destination;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = selected ? destination.activeIcon : destination.icon;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Tooltip(
        message: expanded ? '' : destination.label,
        child: Material(
          color: selected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? 16 : 12,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment:
                    expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (destination.status == FeatureDestinationStatus.preview)
                      const _PreviewBadge(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({
    required this.currentRoute,
    this.onDestinationSelected,
    this.onCreateSelected,
  });

  final String currentRoute;
  final ValueChanged<FeatureDestination>? onDestinationSelected;
  final VoidCallback? onCreateSelected;

  @override
  Widget build(BuildContext context) {
    final destinations = FeatureDestinations.mobile;
    final selectedIndex = _selectedIndex(destinations);

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (index == 2) {
          onCreateSelected?.call();
          return;
        }
        final destination = index < 2 ? destinations[index] : destinations[index - 1];
        onDestinationSelected?.call(destination);
      },
      destinations: [
        NavigationDestination(
          icon: Icon(destinations[0].icon),
          selectedIcon: Icon(destinations[0].activeIcon),
          label: destinations[0].label,
        ),
        NavigationDestination(
          icon: Icon(destinations[1].icon),
          selectedIcon: Icon(destinations[1].activeIcon),
          label: destinations[1].label,
        ),
        const NavigationDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle),
          label: 'Post',
        ),
        NavigationDestination(
          icon: Icon(destinations[2].icon),
          selectedIcon: Icon(destinations[2].activeIcon),
          label: destinations[2].label,
        ),
        NavigationDestination(
          icon: Icon(destinations[3].icon),
          selectedIcon: Icon(destinations[3].activeIcon),
          label: destinations[3].label,
        ),
      ],
    );
  }

  int _selectedIndex(List<FeatureDestination> destinations) {
    if (currentRoute.startsWith('/create-post')) return 2;
    if (destinations[0].matchesRoute(currentRoute)) return 0;
    if (destinations[1].matchesRoute(currentRoute)) return 1;
    if (destinations[2].matchesRoute(currentRoute)) return 3;
    if (currentRoute.startsWith('/more')) return 4;
    return 4;
  }
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Text(
        'Preview',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFFC2410C),
        ),
      ),
    );
  }
}

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => mobile,
      tablet: (_) => tablet,
      desktop: (_) => desktop,
    );
  }
}
