import 'package:flutter/material.dart';
import 'package:music_app/widget/album_cards.dart';
import 'package:music_app/widget/song_cards.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
          child: Column(
        children: [
          Padding(padding: EdgeInsets.only(top: 10)),
          SongCards(),
          const Padding(
            padding: EdgeInsetsDirectional.fromSTEB(10, 20, 10, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Made for you",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          AlbumCards(),
          const Padding(
            padding: EdgeInsetsDirectional.fromSTEB(10, 28, 10, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recently Played",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SongCards_1(),
          const Padding(
            padding: EdgeInsetsDirectional.fromSTEB(10, 20, 10, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Jump back in",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          AlbumCards_1(),
          Padding(padding: EdgeInsets.only(bottom: 75))
        ],
      )),
    );
  }
}
