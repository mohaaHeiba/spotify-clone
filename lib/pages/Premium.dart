import 'package:flutter/material.dart';
import 'dart:math';

class Premium extends StatefulWidget {
  const Premium({super.key});

  @override
  State<Premium> createState() => _PremiumState();
}

class _PremiumState extends State<Premium> {
  final List<Color> _colors = [
    Color(0xFF393E46),
    Color(0xFF4A4E57),
    Color(0xFF8FC1C3),
    Color(0xFFF5F5F5),
    Color.fromARGB(255, 58, 30, 30),
    Color.fromARGB(255, 40, 44, 68),
    Color.fromARGB(255, 19, 47, 88),
    Color.fromARGB(255, 51, 30, 102),
  ];

  Color _getRandomColor() {
    final random = Random();
    return _colors[random.nextInt(_colors.length)];
  }

  Widget _buildRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 15),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Color randomColor = _getRandomColor();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 350,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          randomColor.withOpacity(0.6),
                          randomColor.withOpacity(0.8),
                          Colors.black.withOpacity(1.0),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 50),
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            const Text(
                              'Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 20, top: 30),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'The offer ends soon:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Subscribe now to premium for free',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'For 3 months',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 180,
              color: Colors.black,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('We have error now in the system')),
                    ),
                    child: Container(
                      height: 55,
                      width: 310,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color(0xFF76ABAE),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF76ABAE).withOpacity(0.8),
                            spreadRadius: 2,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "With a Premium subscription, enjoy uninterrupted music streaming with no , the ability to download your favorite tracks for offline listening.",
                      textWidthBasis: TextWidthBasis.parent,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 4,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30, bottom: 42),
              child: Column(
                children: [
                  _buildCard(
                    title: "Abas",
                    content: [
                      _buildRow(Icons.music_note, "Ad-Free Experience"),
                      _buildRow(Icons.download, "Offline Listening"),
                      _buildRow(Icons.headset, "High-Quality Sound"),
                      _buildRow(Icons.devices, "Multi-Device Support"),
                    ],
                  ),
                  _buildCard(
                    title: "Sherif",
                    content: [
                      _buildRow(Icons.download, "Offline Listening"),
                      _buildRow(Icons.headset, "High-Quality Sound"),
                      _buildRow(Icons.devices, "Multi-Device Support"),
                    ],
                  ),
                  _buildCard(
                    title: "Shaker",
                    content: [
                      _buildRow(Icons.download, "Offline Listening"),
                      _buildRow(Icons.headset, "High-Quality Sound"),
                      _buildRow(Icons.devices, "Multi-Device Support"),
                      for (int i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _buildRow(
                              Icons.access_alarm, "Additional Benefit $i"),
                        ),
                    ],
                  ),
                  _buildCard(
                    title: "Heiba",
                    content: [
                      _buildRow(Icons.download, "Offline Listening"),
                      _buildRow(Icons.headset, "High-Quality Sound"),
                      _buildRow(Icons.devices, "Multi-Device Support"),
                      _buildRow(Icons.language, "Unique Content for Heiba"),
                      _buildRow(Icons.lightbulb_outline, "Creative Ideas"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> content}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF31363F),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFFEEEEEE),
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white54),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              children: content,
            ),
          ),
        ],
      ),
    );
  }
}
