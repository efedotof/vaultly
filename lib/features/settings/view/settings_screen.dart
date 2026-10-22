import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey,
                ),
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    CircleAvatar(),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("first name + last name"),
                        Text("premium"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey,
                ),
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    ListTile(title: Text("Безопасность")),
                    ListTile(title: Text("Безопасность")),
                    ListTile(title: Text("Безопасность")),
                    ListTile(title: Text("Безопасность")),
                    ListTile(title: Text("Безопасность")),
                  ],
                ),
              ),

              OutlinedButton(onPressed: () {}, child: Text("Выйти")),

              Text("v1.0.13"),
            ],
          ),
        ),
      ),
    );
  }
}
