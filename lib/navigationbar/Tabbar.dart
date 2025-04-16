import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:music_app/loginandregister/LoginScreen.dart';
import 'package:music_app/navigationbar/Recent.dart';
import 'package:music_app/navigationbar/settings.dart';
import 'package:music_app/pages/HomeView.dart';
import 'package:music_app/pages/Library.dart';
import 'package:music_app/pages/Premium.dart';
import 'package:music_app/pages/Search.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/widget/mini_player_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:music_app/widget/song_cards.dart';

class Tabbar extends StatefulWidget {
  const Tabbar({super.key});

  @override
  State<Tabbar> createState() => _TabbarState();
}

class _TabbarState extends State<Tabbar> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedTab = 0;
  final AudioPlayer _audioPlayer = audioPlayerInstance;
  List<Map<String, dynamic>> _songs = [];

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('songs').get();
    setState(() {
      _songs = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['title'] ?? 'Unknown Title',
          'artist': doc['artist'] ?? 'Unknown',
          'image': doc['image'] ?? 'images/icon_broken.png',
          'audioUrl': doc['audioUrl'] ?? '',
        };
      }).toList();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _selectedTab == 1 || _selectedTab == 3
          ? null
          : PreferredSize(
              preferredSize: const Size(double.infinity, 50),
              child: AppBar(
                backgroundColor: Colors.black.withOpacity(0.9),
                elevation: 0,
                leading: GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 5, top: 5),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 65, 108, 173),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _auth.currentUser?.email?.substring(0, 1) ?? "L",
                          style: const TextStyle(
                            color: Color(0xFFEEEEEE),
                            fontSize: 23,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(left: 70, top: 5, bottom: 5),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCategoryChip("All"),
                          _buildCategoryChip("Summary"),
                          _buildCategoryChip("Podcast"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      drawer: Drawer(
        child: Container(
          color: const Color.fromARGB(255, 0, 0, 0),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 41, 41, 41),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30.0),
                      child: Image.network(
                        'https://th.bing.com/th/id/R.760cba092e85eee63cf5df4fc9de602c?rik=YsOQzsXGTpP3yA&pid=ImgRaw&r=0',
                        fit: BoxFit.cover,
                        width: 60,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${_auth.currentUser?.email}",
                            style: const TextStyle(
                                fontSize: 18, color: Color(0xFFEEEEEE)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "${_auth.currentUser?.displayName}",
                            style: const TextStyle(color: Color(0xFF76ABAE)),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerListItem(
                Icons.add,
                "Add another account",
                () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
              ),
              _buildDrawerListItem(Icons.settings, "Settings", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      onUpdate: () {
                        Future.microtask(() => setState(() {}));
                      },
                    ),
                  ),
                );
              }),
              _buildDrawerListItem(Icons.access_time_filled, "Recent", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Recent(),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: const [
                    HomeView(),
                    Search(),
                    Library(),
                    Premium(),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MiniPlayerBar(
                  audioPlayer: _audioPlayer,
                  songs: _songs,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(1),
                        Colors.black.withOpacity(1),
                      ],
                    ),
                  ),
                  child: BottomNavigationBar(
                    backgroundColor: Colors.transparent,
                    selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
                    unselectedItemColor: Colors.grey,
                    type: BottomNavigationBarType.fixed,
                    currentIndex: _selectedTab,
                    onTap: (index) {
                      setState(() {
                        _selectedTab = index;
                      });
                    },
                    items: const [
                      BottomNavigationBarItem(
                          icon: Icon(Icons.home_outlined),
                          activeIcon: Icon(Icons.home_filled),
                          label: "Home"),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.search_outlined),
                          activeIcon: Icon(Icons.search),
                          label: "Search"),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.library_music_outlined),
                          activeIcon: Icon(Icons.library_music),
                          label: "Your Library"),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.person_outline),
                          activeIcon: Icon(Icons.person),
                          label: "Premium"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Under construction")));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 35,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF76ABAE), Color(0xFFEEEEEE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF222831),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  ListTile _buildDrawerListItem(
      IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFFEEEEEE)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, color: Color(0xFFEEEEEE)),
      ),
      onTap: onTap,
    );
  }

  IgnorePointer renderView(int tabIndex, Widget view) {
    return IgnorePointer(
      ignoring: _selectedTab != tabIndex,
      child: Opacity(
        opacity: _selectedTab == tabIndex ? 1 : 0,
        child: view,
      ),
    );
  }
}
