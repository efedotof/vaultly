import 'package:flutter/material.dart';

enum NavAvatarPosition { none, left, right }

class MyNavButton extends StatelessWidget {
  const MyNavButton({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.avatar,
    this.avatarPosition = NavAvatarPosition.none,
    this.avatarRadius = 14,
    this.avatarBorderColor,
    this.avatarBorderWidth = 2,
    this.onAvatarTap,
    this.gap = 6,
    this.iconSize = 24,
    this.baseSize = 40,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget? avatar;
  final NavAvatarPosition avatarPosition;
  final double avatarRadius;
  final Color? avatarBorderColor;
  final double avatarBorderWidth;
  final VoidCallback? onAvatarTap;
  final double gap;
  final double iconSize;
  final double baseSize;

  @override
  Widget build(BuildContext context) {
    final hasAvatar =
        avatar != null && avatarPosition != NavAvatarPosition.none;

    final button = IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: selected ? Colors.white : Colors.white54),
      iconSize: iconSize,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: baseSize,
        minHeight: baseSize,
        maxWidth: baseSize,
        maxHeight: baseSize,
      ),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );

    if (!hasAvatar) return button;

    final avatarDiameter = avatarRadius * 2;
    final sidePadding = avatarDiameter + gap;

    final avatarWidget = GestureDetector(
      onTap: onAvatarTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: avatarBorderColor ?? Colors.transparent,
            width: avatarBorderWidth,
          ),
        ),
        child: CircleAvatar(
          radius: avatarRadius,
          backgroundColor: Colors.grey.shade300,
          child: avatar,
        ),
      ),
    );

    return SizedBox(
      width: baseSize + sidePadding,
      height: baseSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: avatarPosition == NavAvatarPosition.left ? sidePadding : 0,
              right: avatarPosition == NavAvatarPosition.right
                  ? sidePadding
                  : 0,
            ),
            child: button,
          ),
          Positioned(
            left: avatarPosition == NavAvatarPosition.left ? 0 : null,
            right: avatarPosition == NavAvatarPosition.right ? 0 : null,
            child: avatarWidget,
          ),
        ],
      ),
    );
  }
}
