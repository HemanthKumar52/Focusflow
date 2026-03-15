import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/neumorphic_theme.dart';

/// Primary navigation destinations shown in bottom nav / side rail.
class _NavDestination {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;

  const _NavDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
}

const _primaryDestinations = [
  _NavDestination(
    label: 'Today',
    icon: CupertinoIcons.calendar_today,
    activeIcon: CupertinoIcons.calendar_today,
    path: '/today',
  ),
  _NavDestination(
    label: 'Todos',
    icon: CupertinoIcons.checkmark_square,
    activeIcon: CupertinoIcons.checkmark_square_fill,
    path: '/todos',
  ),
  _NavDestination(
    label: 'Notes',
    icon: CupertinoIcons.doc_text,
    activeIcon: CupertinoIcons.doc_text_fill,
    path: '/notes',
  ),
  _NavDestination(
    label: 'Tasks',
    icon: CupertinoIcons.list_bullet_below_rectangle,
    activeIcon: CupertinoIcons.list_bullet_below_rectangle,
    path: '/tasks',
  ),
];

/// Secondary destinations surfaced through the "More" tab or in the expanded
/// side drawer.
class _MoreDestination {
  final String label;
  final IconData icon;
  final String path;
  final Color color;

  const _MoreDestination({
    required this.label,
    required this.icon,
    required this.path,
    required this.color,
  });
}

const _moreDestinations = [
  _MoreDestination(
    label: 'Projects',
    icon: CupertinoIcons.folder,
    path: '/projects',
    color: AppColors.primary,
  ),
  _MoreDestination(
    label: 'Study',
    icon: CupertinoIcons.book,
    path: '/study',
    color: AppColors.secondary,
  ),
  _MoreDestination(
    label: 'Habits',
    icon: CupertinoIcons.flame,
    path: '/habits',
    color: AppColors.warning,
  ),
  _MoreDestination(
    label: 'Calendar',
    icon: CupertinoIcons.calendar,
    path: '/calendar',
    color: AppColors.info,
  ),
  _MoreDestination(
    label: 'Analytics',
    icon: CupertinoIcons.chart_bar,
    path: '/analytics',
    color: AppColors.success,
  ),
  _MoreDestination(
    label: 'Graph',
    icon: CupertinoIcons.circle_grid_hex,
    path: '/graph',
    color: AppColors.primaryLight,
  ),
  _MoreDestination(
    label: 'Voice Notes',
    icon: CupertinoIcons.mic,
    path: '/voice',
    color: AppColors.danger,
  ),
  _MoreDestination(
    label: 'Sync',
    icon: CupertinoIcons.arrow_2_squarepath,
    path: '/sync',
    color: AppColors.secondary,
  ),
  _MoreDestination(
    label: 'Backup',
    icon: CupertinoIcons.cloud_download,
    path: '/backup',
    color: AppColors.statusPending,
  ),
  _MoreDestination(
    label: 'Settings',
    icon: CupertinoIcons.gear,
    path: '/settings',
    color: AppColors.statusArchived,
  ),
];

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppSizes.compactMax) {
          return _CompactShell(child: child);
        } else if (constraints.maxWidth < AppSizes.mediumMax) {
          return _MediumShell(child: child);
        } else {
          return _ExpandedShell(child: child);
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Compact layout (< 600 px): bottom navigation bar + FAB
// ---------------------------------------------------------------------------

class _CompactShell extends StatelessWidget {
  final Widget child;

  const _CompactShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _resolveBottomNavIndex(location);

    return Scaffold(
      key: const ValueKey('compact_shell'),
      body: child,
      bottomNavigationBar: _NeuBottomBar(
        isDark: isDark,
        selectedIndex: selectedIndex,
        onTap: (index) => _onBottomNavTap(context, index),
      ),
    );
  }

  /// Maps current location to bottom nav index (0-4). Index 4 = More.
  static int _resolveBottomNavIndex(String location) {
    for (var i = 0; i < _primaryDestinations.length; i++) {
      if (location.startsWith(_primaryDestinations[i].path)) return i;
    }
    // If the current route is one of the "more" destinations, highlight More.
    for (final dest in _moreDestinations) {
      if (location.startsWith(dest.path)) return 4;
    }
    return 0;
  }

  static void _onBottomNavTap(BuildContext context, int index) {
    if (index < _primaryDestinations.length) {
      context.go(_primaryDestinations[index].path);
    } else {
      // "More" tapped -- show the grid.
      _showMoreSheet(context);
    }
  }
}

// ---------------------------------------------------------------------------
// Medium layout (600-1000 px): side navigation rail (icons only) + FAB
// ---------------------------------------------------------------------------

class _MediumShell extends StatelessWidget {
  final Widget child;

  const _MediumShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _resolveRailIndex(location);

    return Scaffold(
      key: const ValueKey('medium_shell'),
      body: Row(
        children: [
          _NeuSideRail(
            isDark: isDark,
            selectedIndex: selectedIndex,
            onTap: (index) => _onRailTap(context, index),
            expanded: false,
          ),
          VerticalDivider(
            width: 1,
            color: isDark
                ? AppColors.textTertiaryDark.withValues(alpha: 0.15)
                : AppColors.textTertiaryLight.withValues(alpha: 0.15),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  static int _resolveRailIndex(String location) {
    final all = [
      ..._primaryDestinations.map((d) => d.path),
      ..._moreDestinations.map((d) => d.path),
    ];
    for (var i = 0; i < all.length; i++) {
      if (location.startsWith(all[i])) return i;
    }
    return 0;
  }

  static void _onRailTap(BuildContext context, int index) {
    final all = [
      ..._primaryDestinations.map((d) => d.path),
      ..._moreDestinations.map((d) => d.path),
    ];
    if (index >= 0 && index < all.length) {
      context.go(all[index]);
    }
  }
}

// ---------------------------------------------------------------------------
// Expanded layout (> 1000 px): full side drawer (icons + labels) + FAB
// ---------------------------------------------------------------------------

class _ExpandedShell extends StatelessWidget {
  final Widget child;

  const _ExpandedShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _MediumShell._resolveRailIndex(location);

    return Scaffold(
      key: const ValueKey('expanded_shell'),
      body: Row(
        children: [
          _NeuSideRail(
            isDark: isDark,
            selectedIndex: selectedIndex,
            onTap: (index) => _MediumShell._onRailTap(context, index),
            expanded: true,
          ),
          VerticalDivider(
            width: 1,
            color: isDark
                ? AppColors.textTertiaryDark.withValues(alpha: 0.15)
                : AppColors.textTertiaryLight.withValues(alpha: 0.15),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ============================================================================
// Shared widgets
// ============================================================================

// ---------------------------------------------------------------------------
// Neumorphic bottom navigation bar
// ---------------------------------------------------------------------------

class _NeuBottomBar extends StatelessWidget {
  final bool isDark;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _NeuBottomBar({
    required this.isDark,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNeon = AppColors.isNeonTheme(context);
    final bg = isNeon ? AppColors.surfaceNeon : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final activeColor = isNeon ? AppColors.primaryNeon : (isDark ? AppColors.primaryLight : AppColors.primary);
    final inactiveColor =
        isNeon ? AppColors.textTertiaryNeon : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight);

    // 5 items: 4 primary + More
    final items = [
      ..._primaryDestinations,
      const _NavDestination(
        label: 'More',
        icon: CupertinoIcons.ellipsis_circle,
        activeIcon: CupertinoIcons.ellipsis_circle_fill,
        path: '',
      ),
    ];

    return Container(
      decoration: NeumorphicDecoration.raised(
        isDark: isDark,
        isNeon: isNeon,
        borderRadius: 0,
        color: bg,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: isActive
                            ? BoxDecoration(
                                color: activeColor.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusFull),
                              )
                            : null,
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: AppSizes.iconMd,
                          color: isActive ? activeColor : inactiveColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: AppSizes.caption,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? activeColor : inactiveColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Side rail / drawer (shared between medium + expanded layouts)
// ---------------------------------------------------------------------------

class _NeuSideRail extends StatelessWidget {
  final bool isDark;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool expanded;

  const _NeuSideRail({
    required this.isDark,
    required this.selectedIndex,
    required this.onTap,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final isNeon = AppColors.isNeonTheme(context);
    final bg = isNeon ? AppColors.surfaceNeon : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final activeColor = isNeon ? AppColors.primaryNeon : (isDark ? AppColors.primaryLight : AppColors.primary);
    final inactiveColor =
        isNeon ? AppColors.textTertiaryNeon : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight);
    final textColor =
        isNeon ? AppColors.textSecondaryNeon : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    // Combine primary and more destinations into a single list.
    final allItems = <_SideRailItem>[
      ..._primaryDestinations.map((d) => _SideRailItem(
            label: d.label,
            icon: d.icon,
            activeIcon: d.activeIcon,
          )),
      ..._moreDestinations.map((d) => _SideRailItem(
            label: d.label,
            icon: d.icon,
            activeIcon: d.icon,
          )),
    ];

    final railWidth = expanded ? 220.0 : 72.0;

    return Container(
      width: railWidth,
      decoration: NeumorphicDecoration.raised(
        isDark: isDark,
        isNeon: isNeon,
        borderRadius: 0,
        color: bg,
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const SizedBox(height: AppSizes.lg),
            // App branding
            if (expanded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: const Icon(
                        CupertinoIcons.bolt_fill,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      'FocusFlow',
                      style: TextStyle(
                        fontSize: AppSizes.heading4,
                        fontWeight: FontWeight.w700,
                        color: isNeon
                            ? AppColors.textPrimaryNeon
                            : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(
                  CupertinoIcons.bolt_fill,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            const SizedBox(height: AppSizes.xl),

            // Primary destinations
            ...List.generate(_primaryDestinations.length, (i) {
              return _buildRailItem(
                item: allItems[i],
                index: i,
                isActive: selectedIndex == i,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                textColor: textColor,
              );
            }),

            // Divider before secondary items
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? AppSizes.md : AppSizes.sm,
                vertical: AppSizes.sm,
              ),
              child: Divider(
                height: 1,
                color: inactiveColor.withValues(alpha: 0.3),
              ),
            ),

            // Secondary destinations
            ...List.generate(_moreDestinations.length, (i) {
              final globalIndex = _primaryDestinations.length + i;
              return _buildRailItem(
                item: allItems[globalIndex],
                index: globalIndex,
                isActive: selectedIndex == globalIndex,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                textColor: textColor,
              );
            }),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildRailItem({
    required _SideRailItem item,
    required int index,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required Color textColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? AppSizes.sm : AppSizes.xs,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          onTap: () => onTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? AppSizes.md : 0,
              vertical: AppSizes.sm + 2,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: expanded
                ? Row(
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        size: AppSizes.iconMd,
                        color: isActive ? activeColor : inactiveColor,
                      ),
                      const SizedBox(width: AppSizes.md),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: AppSizes.body,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive ? activeColor : textColor,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(
                      isActive ? item.activeIcon : item.icon,
                      size: AppSizes.iconMd,
                      color: isActive ? activeColor : inactiveColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SideRailItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _SideRailItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

// ---------------------------------------------------------------------------
// "More" bottom sheet (compact layout only)
// ---------------------------------------------------------------------------

void _showMoreSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isNeon = AppColors.isNeonTheme(context);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: BoxDecoration(
        color: isNeon ? AppColors.backgroundNeon : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSizes.sm),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isNeon
                        ? AppColors.textTertiaryNeon
                        : (isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Text(
                    'More',
                    style: TextStyle(
                      fontSize: AppSizes.heading4,
                      fontWeight: FontWeight.w600,
                      color: isNeon
                          ? AppColors.textPrimaryNeon
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.lg, 0, AppSizes.lg, AppSizes.lg),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSizes.md,
                    crossAxisSpacing: AppSizes.md,
                    childAspectRatio: 2.5,
                    children: _moreDestinations.map((dest) {
                      return _MoreGridTile(
                        label: dest.label,
                        icon: dest.icon,
                        color: dest.color,
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(dest.path);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _MoreGridTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _MoreGridTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNeon = AppColors.isNeonTheme(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: NeumorphicDecoration.raised(
          isDark: isDark,
          isNeon: isNeon,
          borderRadius: AppSizes.radiusMd,
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(icon, color: color, size: AppSizes.iconMd),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.body,
                  fontWeight: FontWeight.w500,
                  color: isNeon
                      ? AppColors.textPrimaryNeon
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
