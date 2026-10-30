import 'package:flutter/material.dart';

class AddFiles extends StatelessWidget {
  const AddFiles({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      bottom: 20,
      child: Container(
        width: 44.0,
        height: 44.0,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF43416d),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {},
            child: const Icon(Icons.add, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
