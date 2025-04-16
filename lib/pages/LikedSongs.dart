import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:music_app/widget/song_cards.dart';

String currentPlaybackSource = '';

class LikedSongs extends StatefulWidget {
  const LikedSongs({super.key});

  @override
  State<LikedSongs> createState() => _LikedSongsState();
}

class _LikedSongsState extends State<LikedSongs> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  String? _currentSongUrl;
  List<Map<String, dynamic>> _allSongs = [];
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = audioPlayerInstance;
    _audioPlayer.playerStateStream.listen((playerState) {
      setState(() {
        _isPlaying = playerState.playing;
      });
    });
    _audioPlayer.sequenceStateStream.listen((sequenceState) {
      if (sequenceState?.currentIndex != null) {
        setState(() {});
      }
    });
  }

  Future<void> _playPauseSong(
      String? songUrl, Map<String, dynamic> songData) async {
    if (songUrl == null || songUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid song URL")),
      );
      return;
    }

    try {
      currentPlaybackSource = 'LikedSongs';

      if (_currentSongUrl != songUrl) {
        // Create playlist only when playing a new song
        List<AudioSource> audioSources = _allSongs
            .where((song) =>
                song['audioUrl'] != null && song['audioUrl'].isNotEmpty)
            .map((song) {
          return AudioSource.uri(
            Uri.parse(song['audioUrl']),
            tag: MediaItem(
              id: song['audioUrl'],
              album: 'My Library',
              title: song['name'] ?? 'Unknown Song',
              artUri:
                  song['image'] != null && song['image'].toString().isNotEmpty
                      ? Uri.parse(song['image'])
                      : null,
              artist: song['artist'] ?? 'Unknown Artist',
            ),
          );
        }).toList();

        if (audioSources.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No valid songs to play")),
          );
          return;
        }

        await _audioPlayer.stop();
        await _audioPlayer.setAudioSource(
          ConcatenatingAudioSource(children: audioSources),
          initialIndex:
              _allSongs.indexWhere((song) => song['audioUrl'] == songUrl),
        );
        _currentSongUrl = songUrl;
        await _audioPlayer.play();
      } else {
        if (_isPlaying) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to play song: ${e.toString()}")),
      );
    }
  }

  Future<void> _deleteSong(String songId) async {
    try {
      await FirebaseFirestore.instance
          .collection('LikedSongs')
          .doc(songId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Song deleted from your library")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete song")),
      );
      print("Error deleting song: $e");
    }
  }

  @override
  void dispose() {
    if (currentPlaybackSource == 'AlbumPage') {
      _audioPlayer.stop();
      _audioPlayer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('LikedSongs')
                .where('userId', isEqualTo: user!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (_isFirstLoad &&
                  snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasData) {
                _isFirstLoad = false;
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                          SliverAppBar(
                            expandedHeight: 250.0,
                            pinned: true,
                            floating: false,
                            backgroundColor: Colors.black,
                            centerTitle: false,
                            flexibleSpace: FlexibleSpaceBar(
                              titlePadding:
                                  const EdgeInsets.only(left: 16, bottom: 16),
                              title: const Text(
                                'Liked Songs',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              background: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset('images/1.png',
                                      fit: BoxFit.cover),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                    body: Center(
                      child: Text(
                        'No liked songs found',
                        style: TextStyle(color: Colors.white),
                      ),
                    ));
              }

              final dataLikedSongs = snapshot.data!.docs;
              _allSongs = dataLikedSongs
                  .map((song) => {
                        'audioUrl': song['url'],
                        'name': song['name'],
                        'image': song['image'],
                      })
                  .toList();

              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    expandedHeight: 250.0,
                    pinned: true,
                    floating: false,
                    backgroundColor: Colors.black,
                    centerTitle: false,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                      title: const Text(
                        'Liked Songs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset('images/1.png', fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                body: ListView.builder(
                  itemCount: dataLikedSongs.length,
                  itemBuilder: (context, i) {
                    final songData = dataLikedSongs[i];
                    return GestureDetector(
                      onTap: () => _playPauseSong(songData['url'] ?? '', {
                        'id': songData.id,
                        'name': songData['name'],
                        'image': songData['image'],
                      }),
                      child: Container(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: songData['image'] != null &&
                                    songData['image'] != ''
                                ? Image.network(
                                    songData['image'],
                                    fit: BoxFit.cover,
                                    width: 50,
                                    height: 50,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.music_note,
                                                color: Colors.white),
                                  )
                                : const Icon(Icons.music_note,
                                    color: Colors.white),
                          ),
                          title: Text(
                            songData['name'] ?? 'Unknown Song',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            songData['artist'] ?? 'Unknown Artist',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return Container(
                                      height: 300,
                                      width: MediaQuery.of(context).size.width,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20)),
                                        color: Colors.grey[900],
                                      ),
                                      child: Column(
                                        children: [
                                          ListTile(
                                            leading: Icon(
                                                Icons.remove_circle_outline,
                                                color: const Color.fromARGB(
                                                    255, 72, 44, 199)),
                                            title: Text(
                                                'Remove from Liked Songs',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            onTap: () {
                                              // Add to liked songs logic
                                              _deleteSong(songData.id);
                                              Navigator.pop(context);
                                            },
                                          ),
                                          ListTile(
                                            leading: Icon(Icons.download,
                                                color: Colors.white),
                                            title: Text('Download',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            onTap: () {
                                              // Download logic
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  });
                            },
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
