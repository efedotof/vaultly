import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: RefreshIndicator.adaptive(
              onRefresh: () async {},
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                          spacing: 10,
                          children: List.generate(
                            10,
                            (_) => Row(
                              children: [
                                Icon(Icons.folder),
                                const SizedBox(width: 10),
                                Text('name'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      Text("Последние файлы"),
                      const SizedBox(height: 15),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                          children: List.generate(
                            10,
                            (_) => Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: EdgeInsets.all(10),
                                  child: ClipOval(child: Placeholder()),
                                ),

                                Text("file name"),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Мои заметки"),

                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.keyboard_arrow_down),
                          ),
                        ],
                      ),
                      Column(
                        children: List.generate(
                          10,
                          (index) => ListTile(
                            leading: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.rectangle,
                              ),
                            ),
                            title: Text("name file"),
                          ),
                        ),
                      ),

                      Text("Все файлы"),

                      Wrap(
                        children: List.generate(
                          20,
                          (_) => Column(
                            children: [
                              Container(
                                width: 80,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: EdgeInsets.all(10),
                                child: ClipOval(child: Placeholder()),
                              ),

                              Text("file name"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(10),
              child: Text("состояние"),
            ),
          ),
        ],
      ),
    );
  }
}
