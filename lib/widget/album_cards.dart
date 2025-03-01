import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:music_app/pages/album_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlbumCards extends StatefulWidget {
  const AlbumCards({super.key});

  @override
  State<AlbumCards> createState() => _AlbumCardsState();
}

class _AlbumCardsState extends State<AlbumCards> {
  final List<bool> _scale = List.generate(10, (_) => false);
  List<Map<String, dynamic>> albumData = [];
  bool isLoading = true;
  List<Map<String, dynamic>> randomItems = [];

  @override
  void initState() {
    super.initState();
    fetchAlbumsFromFirestore();
  }

  Future<void> fetchAlbumsFromFirestore() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('albums').get();

    if (mounted) {
      setState(() {
        albumData = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'title': doc['title'] ?? 'Unknown Title',
            'image': doc['image'] ?? 'assets/default_cover.jpg',
            'artist': doc['artist'] ?? 'Unknown Artist',
          };
        }).toList();
        randomItems = (List<Map<String, dynamic>>.from(albumData)..shuffle())
            .take(8)
            .toList();
        isLoading = false;
      });
    }
  }

  void onAlbumTap(Map<String, dynamic> album) async {
    // Store the played album before navigation
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('LastPlayedAlbum')
            .doc(userId)
            .collection('albums')
            .add({
          'album': album,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error saving last played album: $e');
    }

    // Navigate to album page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumPage(album: album),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    width: 150,
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          children: [
            SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: randomItems.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: SizedBox(
                      width: 150,
                      child: GestureDetector(
                        onTap: () => onAlbumTap(randomItems[i]),
                        onLongPress: () {
                          if (mounted) {
                            setState(() {
                              _scale[i] = true;
                            });
                          }
                        },
                        onLongPressUp: () {
                          if (mounted) {
                            setState(() {
                              _scale[i] = false;
                            });
                          }
                          showBottomSheet(context, album: randomItems[i]);
                        },
                        child: AnimatedScale(
                          scale: _scale[i] ? 0.95 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Card(
                            color: Colors.black38,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5.0),
                                  child: Image.network(
                                    randomItems[i]['image'] ?? '',
                                    fit: BoxFit.cover,
                                    height:
                                        MediaQuery.of(context).size.width * 0.4,
                                    width:
                                        MediaQuery.of(context).size.width * 0.4,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                            Icons.broken_image,
                                            size: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.4),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    randomItems[i]['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      overflow: TextOverflow.ellipsis,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//-----------------------------------------------------------------------------------

class AlbumCards_1 extends StatefulWidget {
  const AlbumCards_1({super.key});

  @override
  State<AlbumCards_1> createState() => _AlbumCards_1State();
}

class _AlbumCards_1State extends State<AlbumCards_1> {
  final List<bool> _scale = List.generate(10, (_) => false);
  List<Map<String, dynamic>> albumData = [];
  List<Map<String, dynamic>> lastPlayedAlbums = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAlbumsFromFirestore();
    fetchLastPlayedAlbums();

    // Add listener for real-time updates
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      FirebaseFirestore.instance
          .collection('LastPlayedAlbum')
          .doc(userId)
          .collection('albums')
          .orderBy('timestamp', descending: true)
          .limit(8)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          lastPlayedAlbums = snapshot.docs
              .map((doc) => doc.data()['album'] as Map<String, dynamic>)
              .toList();
        });
      });
    }
  }

  Future<void> fetchAlbumsFromFirestore() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('albums').get();

    if (mounted) {
      setState(() {
        albumData = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'title': doc['title'] ?? 'Unknown Title',
            'artist': doc['artist'] ?? 'Unknown Artist',
            'image': doc['image'] ?? 'assets/default_cover.jpg',
          };
        }).toList();
        isLoading = false;
      });
    }
  }

  Future<void> fetchLastPlayedAlbums() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('LastPlayedAlbum')
            .doc(userId)
            .collection('albums')
            .orderBy('timestamp', descending: true)
            .limit(4)
            .get();

        setState(() {
          lastPlayedAlbums = querySnapshot.docs
              .map((doc) => doc.data()['album'] as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching last played albums: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: SizedBox(
            height: 145,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    width: 130,
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          children: [
            SizedBox(
              height: 145,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 8, // Always show 4 items
                itemBuilder: (context, i) {
                  // Determine if we should show a last played album or random album
                  final album = i < lastPlayedAlbums.length
                      ? lastPlayedAlbums[i]
                      : albumData[i % albumData.length];
                  return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: SizedBox(
                      width: 130,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlbumPage(album: album),
                            ),
                          );
                        },
                        onLongPress: () {
                          if (mounted) {
                            setState(() {
                              _scale[i] = true;
                            });
                          }
                        },
                        onLongPressUp: () {
                          if (mounted) {
                            setState(() {
                              _scale[i] = false;
                            });
                          }
                          showBottomSheet(context, album: album);
                        },
                        child: AnimatedScale(
                          scale: _scale[i] ? 0.95 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Card(
                            color: Colors.black38,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5.0),
                                  child: Image.network(
                                    album['image'],
                                    fit: BoxFit.cover,
                                    height: 120,
                                    width: 180,
                                    errorBuilder: (context, error,
                                            stackTrace) =>
                                        Image.asset('images/icon_broken.png',
                                            fit: BoxFit.cover,
                                            height: 120,
                                            width: 180),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    album['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      overflow: TextOverflow.ellipsis,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add this function to check if album is liked
Future<bool> isAlbumLiked(String albumId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final querySnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('liked_albums')
      .where('albumId', isEqualTo: albumId)
      .get();

  return querySnapshot.docs.isNotEmpty;
}

// Updated bottom sheet function
void showBottomSheet(BuildContext context,
    {required Map<String, dynamic> album}) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            height: 300,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              color: Colors.grey[900],
            ),
            child: Column(
              children: [
                FutureBuilder<bool>(
                  future: isAlbumLiked(album['id']),
                  builder: (context, snapshot) {
                    final isLiked = snapshot.data ?? false;
                    return ListTile(
                      leading: Icon(
                        isLiked
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline,
                        color: isLiked
                            ? const Color.fromARGB(255, 47, 58, 107)
                            : Colors.white,
                      ),
                      title: Text(
                        isLiked
                            ? 'Remove from Liked Songs'
                            : 'Add to Liked Songs',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () async {
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            if (isLiked) {
                              // Remove from liked albums
                              final querySnapshot = await FirebaseFirestore
                                  .instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('liked_albums')
                                  .where('albumId', isEqualTo: album['id'])
                                  .get();

                              for (var doc in querySnapshot.docs) {
                                await doc.reference.delete();
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Removed from Liked Songs')),
                              );
                            } else {
                              // Add to liked albums
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('liked_albums')
                                  .add({
                                'albumId': album['id'],
                                'timestamp': FieldValue.serverTimestamp(),
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added to Liked Songs')),
                              );
                            }

                            // Update the UI
                            setModalState(() {});
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Failed to update Liked Songs')),
                          );
                        }
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.download, color: Colors.white),
                  title:
                      Text('Download', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    // Download logic
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
