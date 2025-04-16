import 'package:flutter/material.dart';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_app/pages/album_page.dart' show currentPlaybackSource;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlaySongs extends StatefulWidget {
  final AudioPlayer? audioPlayer;
  final Map<String, dynamic> song;
  final List<Map<String, dynamic>> songs;
  final bool autoPlay;

  const PlaySongs({
    super.key,
    this.audioPlayer,
    required this.song,
    required this.songs,
    this.autoPlay = false,
  });

  @override
  State<PlaySongs> createState() => _PlaySongsState();
}

class _PlaySongsState extends State<PlaySongs> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  double progress = 0.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  List<Map<String, dynamic>> _songs = [];
  int _currentSongIndex = 0;
  late Map<String, dynamic> _currentSong;
  bool isRepeatEnabled = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();

    _audioPlayer = widget.audioPlayer ?? AudioPlayer();
    _songs = widget.songs;
    _currentSongIndex =
        _songs.indexWhere((song) => song['id'] == widget.song['id']);
    _currentSong = Map<String, dynamic>.from(widget.song);

    // Check if we're using an existing player
    if (widget.audioPlayer != null) {
      // Sync with existing player state
      _syncPlayerState();
    } else {
      // Initialize new player with background audio support
      _initializeBackgroundAudio();
    }

    currentPlaybackSource = 'AlbumPage';

    _checkIfSongIsLiked();
  }

  void _syncPlayerState() {
    setState(() {
      isPlaying = _audioPlayer.playing;
      _position = _audioPlayer.position;
      _duration = _audioPlayer.duration ?? Duration.zero;
      progress = _duration.inMilliseconds > 0
          ? (_position.inMilliseconds / _duration.inMilliseconds)
              .clamp(0.0, 1.0)
          : 0.0;
    });

    _setupPlayerStreams();
  }

  void _setupPlayerStreams() {
    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
          progress = _duration.inMilliseconds > 0
              ? (position.inMilliseconds / _duration.inMilliseconds)
                  .clamp(0.0, 1.0)
              : 0.0;
        });
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
        });

        if (state.processingState == ProcessingState.completed) {
          _nextSong();
        }
      }
    });
  }

  void _initializeBackgroundAudio() async {
    try {
      // Create audio sources for the entire playlist with background metadata
      List<AudioSource> audioSources = _songs.map((song) {
        return AudioSource.uri(
          Uri.parse(song['audioUrl'] ?? 'https://example.com/default.mp3'),
          tag: MediaItem(
            id: song['id'] ?? song['audioUrl'] ?? '',
            album: song['album'] ?? 'Unknown Album',
            title: song['name'] ?? 'Unknown',
            artist: song['artist'] ?? 'Unknown Artist',
            artUri:
                Uri.parse(song['image'] ?? 'https://example.com/default.jpg'),
            extras: {
              'url': song['audioUrl'],
              'albumId': song['albumId'],
              'artist': song['artist'] ?? 'Unknown Artist',
            },
          ),
        );
      }).toList();

      // Create a playlist with all songs
      final playlist = ConcatenatingAudioSource(children: audioSources);

      // Set the audio source with the current song index
      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: _currentSongIndex,
        preload: true,
      );

      await _audioPlayer.setLoopMode(LoopMode.all);

      if (widget.autoPlay) {
        await _audioPlayer.play();
      }

      // Setup streams for background playback
      _setupBackgroundPlayback();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing audio: ${e.toString()}')),
      );
    }
  }

  void _setupBackgroundPlayback() {
    // Listen to sequence state changes
    _audioPlayer.sequenceStateStream.listen((sequenceState) async {
      if (sequenceState == null || !mounted) return;

      final currentItem = sequenceState.currentSource?.tag as MediaItem?;
      if (currentItem != null) {
        final songIndex = _songs.indexWhere((song) =>
            song['audioUrl'] == currentItem.extras?['url'] ||
            song['id'] == currentItem.id);

        if (songIndex != -1) {
          setState(() {
            _currentSongIndex = songIndex;
            _currentSong = _songs[songIndex];
          });
        } else {
          setState(() {
            _currentSongIndex = sequenceState.currentIndex;
            _currentSong = {
              'id': currentItem.id,
              'name': currentItem.title,
              'artist': currentItem.artist ??
                  currentItem.extras?['artist'] ??
                  'Unknown Artist',
              'album': currentItem.album,
              'image': currentItem.artUri.toString(),
              'audioUrl': currentItem.extras?['url'],
              'albumId': currentItem.extras?['albumId'],
            };
          });
        }

        await _checkIfSongIsLiked();
      }
    });

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
        });

        if (state.processingState == ProcessingState.completed) {
          _handlePlaybackCompletion();
        }
      }
    });
  }

  void _handlePlaybackCompletion() async {
    if (isRepeatEnabled) {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } else {
      await _audioPlayer.seek(Duration.zero, index: 0);
      await _audioPlayer.play();
    }
  }

  Future<void> _nextSong() async {
    if (!mounted) return;
    await _audioPlayer.seekToNext();

    // Get current MediaItem from the player
    final currentItem =
        _audioPlayer.sequenceState?.currentSource?.tag as MediaItem?;
    if (currentItem != null && mounted) {
      setState(() {
        _currentSongIndex = (_currentSongIndex + 1) % _songs.length;
        _currentSong = {
          'id': currentItem.id,
          'name': currentItem.title,
          'artist': currentItem.artist,
          'album': currentItem.album,
          'image': currentItem.artUri.toString(),
          'audioUrl': currentItem.extras?['url'],
          'albumId': currentItem.extras?['albumId'],
        };
      });

      await _checkIfSongIsLiked();
    }
    await _audioPlayer.play();
  }

  Future<void> _previousSong() async {
    if (!mounted) return;
    if (_position.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
    } else {
      await _audioPlayer.seekToPrevious();

      // Get current MediaItem from the player
      final currentItem =
          _audioPlayer.sequenceState?.currentSource?.tag as MediaItem?;
      if (currentItem != null && mounted) {
        setState(() {
          _currentSongIndex =
              _currentSongIndex > 0 ? _currentSongIndex - 1 : _songs.length - 1;
          _currentSong = {
            'id': currentItem.id,
            'name': currentItem.title,
            'artist': currentItem.artist,
            'album': currentItem.album,
            'image': currentItem.artUri.toString(),
            'audioUrl': currentItem.extras?['url'],
            'albumId': currentItem.extras?['albumId'],
          };
        });

        await _checkIfSongIsLiked();
      }
    }
    await _audioPlayer.play();
  }

  void _playPauseSong() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  void _toggleRepeat() async {
    setState(() {
      isRepeatEnabled = !isRepeatEnabled;
    });

    if (isRepeatEnabled) {
      await _audioPlayer.setLoopMode(LoopMode.one);
    } else {
      await _audioPlayer.setLoopMode(LoopMode.all);
    }
  }

  Future<void> _checkIfSongIsLiked() async {
    if (userId == null) return;

    final querySnapshot = await _firestore
        .collection('LikedSongs')
        .where('userId', isEqualTo: userId)
        .where('name', isEqualTo: _currentSong['name'])
        .get();

    setState(() {
      isLiked = querySnapshot.docs.isNotEmpty;
    });
  }

  Future<void> _toggleLike() async {
    try {
      final likedSongRef = _firestore.collection('LikedSongs').doc();

      setState(() {
        isLiked = !isLiked;
      });

      if (isLiked) {
        // Add to liked songs with artist field
        await likedSongRef.set({
          'userId': userId,
          'name': _currentSong['name'],
          'artist': _currentSong['artist'] ?? 'Unknown Artist',
          'image': _currentSong['image'],
          'url': _currentSong['audioUrl'],
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to Liked Songs')),
        );
      } else {
        // Find and remove from liked songs
        final querySnapshot = await _firestore
            .collection('LikedSongs')
            .where('userId', isEqualTo: userId)
            .where('name', isEqualTo: _currentSong['name'])
            .get();

        for (var doc in querySnapshot.docs) {
          await doc.reference.delete();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from Liked Songs')),
        );
      }
    } catch (e) {
      setState(() {
        isLiked = !isLiked;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    if (widget.audioPlayer == null) {
      _audioPlayer.dispose();
    }
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color.fromARGB(255, 19, 47, 88),
                  Color.fromARGB(255, 46, 72, 110),
                  Colors.black12
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 8, left: 8, top: 40, bottom: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const Text(
                          "Playing",
                          style: TextStyle(color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.keyboard_arrow_down,
                              size: 30, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _currentSong['image'] ??
                              'https://th.bing.com/th/id/OIP.SU-4gYVybiUKK2fbKpyC-wHaEK?w=282&h=180&c=7&r=0&o=5&pid=1.7',
                          width: 500,
                          height: 320,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, size: 320);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Replace the existing buttons with new ones
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _toggleLike,
                                  icon: Icon(
                                    isLiked
                                        ? Icons.remove_circle_outline
                                        : Icons.add_circle_outline,
                                    size: 38,
                                    color: isLiked
                                        ? const Color.fromARGB(255, 47, 63, 131)
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),

                            Padding(padding: EdgeInsets.only(right: 30)),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: SizedBox(
                                    height: 68,
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    _currentSong['name'] ??
                                                        'Unknown',
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            _currentSong['artist'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      ],
                                    )),
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape:
                                RoundSliderThumbShape(enabledThumbRadius: 6.0),
                            valueIndicatorShape:
                                PaddleSliderValueIndicatorShape(),
                            valueIndicatorTextStyle: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            activeColor: Colors.blueAccent,
                            inactiveColor: Colors.grey,
                            label: _formatDuration(_position),
                            onChanged: (value) {
                              final newPosition =
                                  (_duration.inMilliseconds * value).round();
                              _audioPlayer
                                  .seek(Duration(milliseconds: newPosition));
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 10, left: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                              Text(
                                _formatDuration(_duration),
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.shuffle,
                                  size: 30, color: Colors.white),
                            ),
                            IconButton(
                              onPressed: _previousSong,
                              icon: const Icon(Icons.skip_previous,
                                  size: 40, color: Colors.white),
                            ),
                            IconButton(
                              onPressed: _playPauseSong,
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              onPressed: _nextSong,
                              icon: const Icon(Icons.skip_next,
                                  size: 40, color: Colors.white),
                            ),
                            IconButton(
                              onPressed: _toggleRepeat,
                              icon: Icon(
                                Icons.replay,
                                size: 38,
                                color: isRepeatEnabled
                                    ? Colors.blueAccent
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
