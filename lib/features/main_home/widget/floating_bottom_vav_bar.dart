import 'package:flutter/material.dart';
import 'nav_item.dart';

class FloatingBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FloatingBottomNavBar> createState() => _FloatingBottomNavBarState();
}

class _FloatingBottomNavBarState extends State<FloatingBottomNavBar> {
  final List<GlobalKey> _itemKeys = [GlobalKey(), GlobalKey(), GlobalKey()];

  Rect? _indicatorRect;
  bool _firstBuild = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateIndicatorPosition();
  }

  @override
  void didUpdateWidget(covariant FloatingBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _calculateIndicatorPosition();
    }
  }

  void _calculateIndicatorPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentContext = _itemKeys[widget.currentIndex].currentContext;
      if (currentContext != null) {
        final RenderBox box = currentContext.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);
        final size = box.size;
        setState(() {
          _indicatorRect = Rect.fromLTWH(
            position.dx,
            position.dy,
            size.width,
            size.height,
          );
          _firstBuild = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: SizedBox(
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.95,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            if (_indicatorRect != null && !_firstBuild)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: _indicatorRect!.left,
                top: _indicatorRect!.top,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _indicatorRect!.width,
                  height: _indicatorRect!.height,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  key: _itemKeys[0],
                  child: NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Главная',
                    isActive: widget.currentIndex == 0,
                    onTap: () => widget.onTap(0),
                  ),
                ),
                Container(
                  key: _itemKeys[1],
                  child: NavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Профиль',
                    isActive: widget.currentIndex == 1,
                    onTap: () => widget.onTap(1),
                  ),
                ),
                Container(
                  key: _itemKeys[2],
                  child: NavItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    label: 'Настройки',
                    isActive: widget.currentIndex == 2,
                    onTap: () => widget.onTap(2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
