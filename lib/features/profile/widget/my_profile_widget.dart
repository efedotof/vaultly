import 'package:flutter/material.dart';

class MyProfileWidget extends StatelessWidget {
  const MyProfileWidget({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF43416d),
        actions: [TextButton(onPressed: onPressed, child: Text('Done'))],
      ),
      backgroundColor: Color(0xFF1d3687),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              CircleAvatar(),
              Container(
                child: Column(
                  children: [
                    TextField(), //firsName
                    TextField(), //LastName
                    TextField(), //email
                  ],
                ),
              ),

              Container(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("двухфакторная аутентификация TOTP"),
                        Switch(value: false, onChanged: (value) {}),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("создать seed-фразу"),
                        Switch(value: true, onChanged: (value) {}),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
