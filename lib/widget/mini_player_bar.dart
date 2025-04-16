import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_app/widget/play_songs.dart';

class MiniPlayerBar extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final List<Map<String, dynamic>> songs;

  const MiniPlayerBar({
    super.key,
    required this.audioPlayer,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioPlayer.sequenceStateStream
          .map((state) => state?.currentSource?.tag as MediaItem?),
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;

        if (mediaItem == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            // Find the current song data from the songs list
            final currentSong = songs.firstWhere(
              (song) => song['audioUrl'] == mediaItem.id,
              orElse: () => songs.first,
            );

            // Custom slide-up transition
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    PlaySongs(
                  song: currentSong,
                  songs: songs,
                  autoPlay: true,
                  audioPlayer: audioPlayer,
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0); // Slide from bottom
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          child: Container(
            color: Colors.black,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<Duration>(
                  stream: audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: audioPlayer.durationStream,
                      builder: (context, durationSnapshot) {
                        final duration = durationSnapshot.data ?? Duration.zero;
                        return LinearProgressIndicator(
                          value: duration.inMilliseconds > 0
                              ? position.inMilliseconds /
                                  duration.inMilliseconds
                              : 0.0,
                          backgroundColor: Colors.black38,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 2,
                        );
                      },
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Image.network(
                        mediaItem.artUri?.toString() ??
                            'https://example.com/default.jpg',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.broken_image,
                            size: 50,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              mediaItem.title,
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              mediaItem.artist ?? 'Unknown',
                              style: const TextStyle(color: Colors.white70),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      StreamBuilder<PlayerState>(
                        stream: audioPlayer.playerStateStream,
                        builder: (context, snapshot) {
                          final playing = snapshot.data?.playing ?? false;
                          return IconButton(
                            icon: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (playing) {
                                audioPlayer.pause();
                              } else {
                                audioPlayer.play();
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
