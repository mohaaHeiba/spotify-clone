import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_app/widget/song_cards.dart';

String currentPlaybackSource = '';

class AlbumPage extends StatefulWidget {
  final Map<String, dynamic> album;

  const AlbumPage({super.key, required this.album});

  @override
  _AlbumPageState createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  static const double _maxImageSize = 240.0;
  static const List<Color> _colors = [
    Color.fromARGB(255, 19, 47, 88),
    Color.fromARGB(255, 46, 72, 110),
    Color.fromARGB(255, 108, 58, 143),
    Color.fromARGB(255, 22, 22, 184),
    Color(0xFF008080),
    Color.fromARGB(255, 27, 88, 27),
    Color.fromARGB(255, 104, 88, 63),
    Color.fromARGB(255, 91, 21, 16),
    Color.fromARGB(255, 75, 39, 100),
  ];

  static const EdgeInsets _padding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const SizedBox _sizedBox20 = SizedBox(height: 20);
  static const SizedBox _sizedBox30 = SizedBox(height: 30);

  double imageSize = _maxImageSize;
  Color currentColor = Colors.purple;
  late ScrollController scrollController;
  late Future<List<Map<String, dynamic>>> _songList;
  late final AudioPlayer _audioPlayer = audioPlayerInstance;
  bool isPlaying = false;
  bool isShuffling = false;
  int? _currentlyPlayingIndex;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _currentIndexSubscription;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController()
      ..addListener(() {
        if (!mounted) return;
        final newSize = _maxImageSize - scrollController.offset;
        if (newSize > 190 && newSize <= _maxImageSize) {
          setState(() {
            imageSize = newSize;
          });
        }
      });

    currentColor = _colors[DateTime.now().millisecond % _colors.length];

    _songList = fetchSongsFromFirestore(widget.album['id']);

    // Check if current playback is from this specific album
    if (_audioPlayer.sequence?.isNotEmpty ?? false) {
      var currentItem = _audioPlayer.sequence?[_audioPlayer.currentIndex ?? 0];
      if (currentItem?.tag?.album == widget.album['title']) {
        currentPlaybackSource = 'AlbumPage';
        _currentlyPlayingIndex = _audioPlayer.currentIndex;
      }
    }

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
        });
      }
    });

    _currentIndexSubscription = _audioPlayer.currentIndexStream.listen((index) {
      if (mounted) {
        setState(() {
          // Check if current playing song is from this album
          var currentItem = _audioPlayer.sequence?[index ?? 0];
          if (currentItem?.tag?.album == widget.album['title']) {
            currentPlaybackSource = 'AlbumPage';
            _currentlyPlayingIndex = index;
          } else {
            _currentlyPlayingIndex = null;
          }
        });
      }
    });

    // Reset the currently playing index when the album changes
    if (currentPlaybackSource != 'AlbumPage') {
      _currentlyPlayingIndex = null;
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();

    if (currentPlaybackSource == 'AlbumPage') {
      _currentlyPlayingIndex = null;
      currentPlaybackSource = '';
    }
    scrollController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchSongsFromFirestore(
      String albumId) async {
    try {
      DocumentSnapshot albumSnapshot = await FirebaseFirestore.instance
          .collection('albums')
          .doc(albumId)
          .get();

      List<dynamic> songIds = albumSnapshot['songIds'] ?? [];
      if (songIds.isEmpty) {
        throw 'No songs in this album';
      }

      List<Map<String, dynamic>> songs = [];
      for (var songId in songIds) {
        DocumentSnapshot songSnapshot = await FirebaseFirestore.instance
            .collection('songs')
            .doc(songId)
            .get();

        if (songSnapshot.exists) {
          songs.add({
            'title': songSnapshot['title'],
            'artist': songSnapshot['artist'],
            'audioUrl': songSnapshot['audioUrl'],
          });
        }
      }

      return songs;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: currentColor,
        elevation: 0,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.album['title'] ?? 'Unknown Album',
              style: const TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 50),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(color: currentColor),
          SafeArea(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _songList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingIndicator();
                }

                if (snapshot.hasError) {
                  return _buildErrorText();
                }

                final songs = snapshot.data ?? [];

                return SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      _buildGradientHeader(context, currentColor, widget.album),
                      _buildControlButtons(), // Moved here
                      _buildSongList(songs),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorText() {
    return Center(
      child: Text(
        'Error loading songs',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildGradientHeader(
      BuildContext context, Color currentColor, Map<String, dynamic> album) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            currentColor.withOpacity(0.7),
            currentColor.withOpacity(0.5),
            Colors.black.withOpacity(0.9),
            Colors.black,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Column(
        children: [
          _sizedBox20,
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: currentColor.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                album['image'] ?? '',
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.broken_image, size: imageSize);
                },
              ),
            ),
          ),
          _sizedBox30,
        ],
      ),
    );
  }

  Widget _buildSongList(List<Map<String, dynamic>> songs) {
    if (songs.isEmpty) {
      return Container(
          color: Colors.black,
          height: MediaQuery.of(context).size.height * 0.5,
          padding: _padding,
          child: Center(
            child: Text("no songs availabe ",
                style: TextStyle(color: Colors.white)),
          ));
    }
    return SingleChildScrollView(
        child: Container(
      decoration: const BoxDecoration(color: Colors.black),
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: songs.length,
        itemBuilder: (context, i) {
          var song = songs[i];
          bool isPlaying = _currentlyPlayingIndex == i &&
              _audioPlayer
                      .sequence?[_audioPlayer.currentIndex ?? 0]?.tag?.album ==
                  widget.album['title'];

          return GestureDetector(
            onTap: () async {
              currentPlaybackSource =
                  'AlbumPage'; // Set the source to AlbumPage
              setState(() {
                _currentlyPlayingIndex = i;
              });
              List<AudioSource> audioSources = songs.map((song) {
                return AudioSource.uri(
                  Uri.parse(song['audioUrl']),
                  tag: MediaItem(
                    id: song['audioUrl'],
                    album: widget.album['title'],
                    title: song['title'],
                    artist: song['artist'],
                    artUri: Uri.parse(widget.album['image'] ?? ''),
                  ),
                );
              }).toList();

              var playlist = ConcatenatingAudioSource(children: audioSources);
              await _audioPlayer.setAudioSource(playlist, initialIndex: i);
              await _audioPlayer.play();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isPlaying
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.03),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  song['title'],
                  style: TextStyle(
                    color: isPlaying ? Colors.amber : Colors.white,
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  song['artist'],
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
            ),
          );
        },
      ),
    ));
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment
            .spaceBetween, // Changed from start to spaceBetween
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () async {
                  if (isPlaying) {
                    _audioPlayer.pause();
                  } else {
                    if (_currentlyPlayingIndex == null) {
                      List<AudioSource> audioSources =
                          (await _songList).map((song) {
                        return AudioSource.uri(
                          Uri.parse(song['audioUrl']),
                          tag: MediaItem(
                            id: song['audioUrl'],
                            album: widget.album['name'],
                            title: song['name'],
                            artUri: Uri.parse(widget.album['image'] ?? ''),
                          ),
                        );
                      }).toList();

                      var playlist =
                          ConcatenatingAudioSource(children: audioSources);
                      await _audioPlayer.setAudioSource(playlist,
                          initialIndex: 0);
                    }
                    _audioPlayer.play();
                  }
                },
              ),
              IconButton(
                icon: Icon(
                  isShuffling ? Icons.shuffle_on : Icons.shuffle,
                  color: Colors.white,
                ),
                onPressed: () async {
                  setState(() {
                    isShuffling = !isShuffling;
                  });
                  await _audioPlayer.setShuffleModeEnabled(isShuffling);
                  if (isShuffling) {
                    await _audioPlayer.shuffle();
                    var randomIndex = (await _songList).isNotEmpty
                        ? (await _songList).length > 1
                            ? (await _songList).length - 1
                            : 0
                        : 0;
                    await _audioPlayer.seek(Duration.zero, index: randomIndex);
                    await _audioPlayer.play();
                    setState(() {
                      _currentlyPlayingIndex = randomIndex;
                    });
                  }
                },
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              widget.album['artist'] ?? 'Unknown Artist',
              style: const TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
