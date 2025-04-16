import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

final AudioPlayer audioPlayerInstance = AudioPlayer();

String currentPlaybackSource = '';

class SongCards extends StatefulWidget {
  const SongCards({super.key});

  @override
  State<SongCards> createState() => _SongCardsState();
}

class _SongCardsState extends State<SongCards> {
  List<Map<String, dynamic>> songData = [];
  List<Map<String, dynamic>> randomItems = [];
  List<Map<String, dynamic>> remainingSongs = [];
  bool isLoading = true;

  late final AudioPlayer _audioPlayer = audioPlayerInstance;

  @override
  void initState() {
    super.initState();
    fetchSongsFromFirestore();

    _audioPlayer.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        if (remainingSongs.isNotEmpty) {
          ////////////////////// Play remaining songs when the initial playlist ends
          await playRemainingSongs();
        }
      }
    });
  }

  Future<void> fetchSongsFromFirestore() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('songs').get();

      setState(() {
        songData = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['title'] ?? 'Unknown Title',
            'artist': doc['artist'] ?? 'Unknown',
            'image': doc['image'] ?? 'images/icon_broken.png',
            'audioUrl': doc['audioUrl'] ?? '',
          };
        }).toList();

        // Shuffle and split songs into selected and remaining
        songData.shuffle();
        randomItems = songData.take(8).toList();
        remainingSongs = songData.skip(8).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> playRemainingSongs() async {
    List<AudioSource> audioSources = remainingSongs.map((song) {
      return AudioSource.uri(
        Uri.parse(song['audioUrl']),
        tag: MediaItem(
          id: song['audioUrl'],
          album: song['name'],
          title: song['name'],
          artUri: Uri.parse(song['image'] ?? ''),
        ),
      );
    }).toList();

    var newPlaylist = ConcatenatingAudioSource(children: audioSources);
    await _audioPlayer.setAudioSource(newPlaylist);
    await _audioPlayer.play();
  }

  Future<void> playSelectedSong(int index) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Create a new document for each played song
        await FirebaseFirestore.instance
            .collection('LastPlayedSong')
            .doc(userId)
            .collection('songs')
            .add({
          'song': randomItems[index],
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error saving last played song: $e');
    }

    List<UriAudioSource> audioSources = randomItems
        .map((song) {
          return AudioSource.uri(
            Uri.parse(song['audioUrl']),
            tag: MediaItem(
              id: song['audioUrl'],
              album: song['name'],
              title: song['name'],
              artist: song['artist'],
              artUri: Uri.parse(song['image'] ?? ''),
            ),
          );
        })
        .toList()
        .cast<UriAudioSource>();

    await _audioPlayer.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: index,
    );
    await _audioPlayer.play();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: SizedBox(
          height: 250,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 55,
            ),
            itemBuilder: (context, i) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(5.0),
                ),
              );
            },
          ),
        ),
      );
    }

    if (randomItems.isEmpty) {
      return const Center(child: Text('No songs available'));
    }

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: SizedBox(
        height: 250,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 55,
          ),
          itemCount: randomItems.length,
          itemBuilder: (context, i) {
            currentPlaybackSource == 'SongCards';
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: MaterialButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  await playSelectedSong(i);
                },
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5.0),
                      child: Image.network(
                        randomItems[i]['image'] ?? 'images/icon_broken.png',
                        fit: BoxFit.cover,
                        height: 55,
                        width: 55,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.broken_image,
                            size: 55,
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          randomItems[i]['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (currentPlaybackSource == 'SongCards') {
      currentPlaybackSource = '';
    }
    super.dispose();
  }
}

//------------------------------------------------------------------------------
class SongCards_1 extends StatefulWidget {
  const SongCards_1({super.key});

  @override
  State<SongCards_1> createState() => _SongCards_1State();
}

class _SongCards_1State extends State<SongCards_1> {
  List<Map<String, dynamic>> songData = [];
  List<Map<String, dynamic>> randomItems = [];
  bool isLoading = true;
  Map<String, bool> likedSongs = {};
  late final AudioPlayer _audioPlayer = audioPlayerInstance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> lastPlayedSongs = [];

  // Add these new variables at the top of the class
  String? currentlyPlayingSongId;
  StreamSubscription<PlaybackEvent>? playbackEventSubscription;

  @override
  void initState() {
    super.initState();
    fetchSongsFromFirestore();
    loadLikedSongs();
    fetchLastPlayedSong();

    // Update listener for real-time updates
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _firestore
          .collection('LastPlayedSong')
          .doc(userId)
          .collection('songs')
          .orderBy('timestamp', descending: true)
          .limit(4)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          lastPlayedSongs = snapshot.docs
              .map((doc) => doc.data()['song'] as Map<String, dynamic>)
              .toList();
        });
      });
    }

    // Add this listener to track the currently playing song
    playbackEventSubscription =
        _audioPlayer.playbackEventStream.listen((event) {
      if (_audioPlayer.sequence != null && _audioPlayer.sequence!.isNotEmpty) {
        var currentItem =
            _audioPlayer.sequence![_audioPlayer.currentIndex ?? 0];
        setState(() {
          currentlyPlayingSongId = (currentItem.tag as MediaItem).id;
        });
      }
    });
  }

  Future<void> fetchSongsFromFirestore() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('songs').get();

      setState(() {
        songData = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['title'] ?? 'Unknown Title',
            'artist': doc['artist'] ?? 'Unknown',
            'image': doc['image'] ?? 'images/icon_broken.png',
            'audioUrl': doc['audioUrl'] ?? '',
          };
        }).toList();

        var tempList = List<Map<String, dynamic>>.from(songData);
        tempList.shuffle();
        randomItems = tempList.take(4).toList();

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadLikedSongs() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final querySnapshot = await _firestore
        .collection('LikedSongs')
        .where('userId', isEqualTo: userId)
        .get();

    setState(() {
      for (var doc in querySnapshot.docs) {
        likedSongs[doc.data()['name']] = true;
      }
    });
  }

  Future<void> addToLikedSongs(Map<String, dynamic> song) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to like songs')),
        );
        return;
      }

      final querySnapshot = await _firestore
          .collection('LikedSongs')
          .where('userId', isEqualTo: userId)
          .where('name', isEqualTo: song['name'])
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
        setState(() {
          likedSongs[song['name']] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from Liked Songs')),
        );
      } else {
        await _firestore.collection('LikedSongs').add({
          'userId': userId,
          'name': song['name'],
          'artist': song['artist'],
          'image': song['image'],
          'url': song['audioUrl'],
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() {
          likedSongs[song['name']] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to Liked Songs')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update Liked Songs')),
      );
    }
  }

  Future<void> fetchLastPlayedSong() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final querySnapshot = await _firestore
            .collection('LastPlayedSong')
            .doc(userId)
            .collection('songs')
            .orderBy('timestamp', descending: true)
            .limit(4)
            .get();

        setState(() {
          lastPlayedSongs = querySnapshot.docs
              .map((doc) => doc.data()['song'] as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching last played songs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding:
            const EdgeInsets.only(left: 10, right: 10, top: 18, bottom: 10),
        child: SizedBox(
          height: 250,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 70,
            ),
            itemBuilder: (context, i) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: MaterialButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {},
                ),
              );
            },
          ),
        ),
      );
    }

    if (songData.isEmpty) {
      return const Center(child: Text('No songs available'));
    }

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 18, bottom: 10),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 70,
        ),
        itemCount: 4, // Always show 4 items
        itemBuilder: (context, i) {
          // If we have a last played song for this index, show it
          if (i < lastPlayedSongs.length) {
            return buildSongContainer(lastPlayedSongs[i], true);
          }
          // Otherwise show random items
          return buildSongContainer(randomItems[i % randomItems.length], false);
        },
      ),
    );
  }

  Widget buildSongContainer(Map<String, dynamic> song, bool isLastPlayed) {
    bool isPlaying = currentlyPlayingSongId == song['audioUrl'];

    return Container(
      decoration: BoxDecoration(
        color: isPlaying ? Colors.white24 : Colors.grey[900],
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: MaterialButton(
        padding: EdgeInsets.zero,
        onPressed: () async {
          setState(() {
            currentlyPlayingSongId = song['audioUrl'];
          });
          var audioSource = AudioSource.uri(
            Uri.parse(song['audioUrl']),
            tag: MediaItem(
              id: song['audioUrl'],
              album: song['name'],
              title: song['name'],
              artUri: Uri.parse(song['image'] ?? ''),
            ),
          );
          await _audioPlayer.setAudioSource(audioSource);
          await _audioPlayer.play();
        },
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Image.network(
                song['image'],
                fit: BoxFit.cover,
                height: 55,
                width: 55,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.broken_image,
                    size: 55,
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song['artist'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: IconButton(
                onPressed: () {
                  showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Container(
                          height: 300,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                            color: Colors.grey[900],
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Icon(
                                  likedSongs[song['name']] == true
                                      ? Icons.remove_circle_outline
                                      : Icons.add_circle_outline,
                                  color: likedSongs[song['name']] == true
                                      ? const Color.fromARGB(255, 47, 58, 107)
                                      : Colors.white,
                                ),
                                title: Text(
                                  likedSongs[song['name']] == true
                                      ? 'Remove from Liked Songs'
                                      : 'Add to Liked Songs',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onTap: () {
                                  addToLikedSongs(song);
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                leading:
                                    Icon(Icons.download, color: Colors.white),
                                title: Text('Download',
                                    style: TextStyle(color: Colors.white)),
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
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    playbackEventSubscription?.cancel();
    super.dispose();
  }
}
