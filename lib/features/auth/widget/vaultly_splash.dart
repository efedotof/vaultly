import 'package:flutter/material.dart';
import 'package:gif/gif.dart';

class VaultlySplash extends StatelessWidget {
  const VaultlySplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Gif(
        image: const AssetImage('assets/kal_prod.gif'),
        autostart: Autostart.loop,
        width: MediaQuery.of(context).size.width * 0.2,
        height: MediaQuery.of(context).size.height * 0.2,
        fit: BoxFit.contain,
      ),
    );
  }
}
