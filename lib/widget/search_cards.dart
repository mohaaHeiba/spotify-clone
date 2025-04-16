import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:music_app/pages/album_page.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_app/widget/song_cards.dart';

class SearchCards extends StatefulWidget {
  const SearchCards({super.key});

  @override
  State<SearchCards> createState() => _SearchCardsState();
}

class _SearchCardsState extends State<SearchCards> {
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = true;
  final AudioPlayer _audioPlayer = audioPlayerInstance;

  @override
  void initState() {
    super.initState();
    fetchSearchResults();
  }

  Future<void> fetchSearchResults() async {
    try {
      final songsSnapshot =
          await FirebaseFirestore.instance.collection('songs').get();
      final albumsSnapshot =
          await FirebaseFirestore.instance.collection('albums').get();

      List<Map<String, dynamic>> results = [];

      results.addAll(songsSnapshot.docs.map((doc) => {
            'id': doc.id,
            'name': doc['title'] ?? 'Unknown Title',
            'artist': doc['artist'] ?? 'Unknown Artist',
            'image': doc['image'] ?? 'images/icon_broken.png',
            'audioUrl': doc['audioUrl'] ?? '',
            'type': 'song',
          }));

      results.addAll(albumsSnapshot.docs.map((doc) => {
            'id': doc.id,
            'name': doc['title'] ?? 'Unknown Title',
            'image': doc['image'] ?? 'images/icon_broken.png',
            'type': 'album',
          }));

      results.shuffle();

      setState(() {
        searchResults = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> playSong(Map<String, dynamic> song) async {
    var audioSource = AudioSource.uri(
      Uri.parse(song['audioUrl']),
      tag: MediaItem(
        id: song['audioUrl'],
        album: song['name'],
        title: song['name'],
        artist: song['artist'],
        artUri: Uri.parse(song['image'] ?? ''),
      ),
    );
    await _audioPlayer.setAudioSource(audioSource);
    await _audioPlayer.play();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(10),
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.only(bottom: 50),
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              mainAxisExtent: 80,
            ),
            itemCount: searchResults.length,
            itemBuilder: (context, i) {
              final item = searchResults[i];
              return GestureDetector(
                onTap: () {
                  if (item['type'] == 'song') {
                    playSong(item);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlbumPage(album: item),
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color.fromARGB(255, 0, 0, 0),
                        Color.fromARGB(255, 79, 175, 180),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item['type'] == 'song')
                                Text(
                                  item['artist'],
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ),
                      Transform.rotate(
                        angle: 0.3,
                        child: Container(
                          decoration: const BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54,
                                offset: Offset(3, 3),
                                blurRadius: 5,
                              )
                            ],
                          ),
                          child: Image.network(
                            item['image'],
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.broken_image,
                                color: Colors.white,
                                size: 40,
                              );
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
