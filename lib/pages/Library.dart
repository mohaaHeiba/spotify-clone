import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:music_app/pages/album_page.dart';
import 'package:music_app/pages/LikedSongs.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  Stream<List<Map<String, dynamic>>> getLikedAlbumsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('liked_albums')
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> likedAlbums = [];

      for (var doc in snapshot.docs) {
        final albumId = doc.data()['albumId'] as String?;
        if (albumId == null) continue;

        final albumDoc = await FirebaseFirestore.instance
            .collection('albums')
            .doc(albumId)
            .get();

        if (albumDoc.exists && albumDoc.data() != null) {
          final albumData = albumDoc.data()!;
          likedAlbums.add({
            'id': albumDoc.id,
            'title': albumData['title'] ?? 'Unknown Album',
            'artist': albumData['artist'] ?? 'Unknown Artist',
            'image': albumData['image'] ?? 'https://placeholder.com/300',
            'songIds': albumData['songIds'] ?? [],
          });
        }
      }
      return likedAlbums;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 75),
            child: Column(
              children: [
                //////////////////////// Liked Songs Section
                MaterialButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LikedSongs(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.only(
                        left: 3, right: 3, top: 10, bottom: 10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.asset(
                            'images/1.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Liked Songs',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Your liked songs',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                ///////////// Liked Albums Section
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: getLikedAlbumsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white)),
                      );
                    }

                    final likedAlbums = snapshot.data ?? [];

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 80,
                      ),
                      itemCount: likedAlbums.length,
                      itemBuilder: (context, index) {
                        final album = likedAlbums[index];
                        return MaterialButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AlbumPage(album: album),
                              ),
                            );
                          },
                          onLongPress: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.grey[900],
                              builder: (context) => Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.white,
                                      ),
                                      title: const Text(
                                        'Remove from Liked Albums',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onTap: () async {
                                        final user =
                                            FirebaseAuth.instance.currentUser;
                                        if (user != null) {
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(user.uid)
                                              .collection('liked_albums')
                                              .where('albumId',
                                                  isEqualTo: album['id'])
                                              .get()
                                              .then((snapshot) {
                                            for (var doc in snapshot.docs) {
                                              doc.reference.delete();
                                            }
                                          });
                                        }
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(2),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Image.network(
                                    album['image'],
                                    fit: BoxFit.cover,
                                    height: 80,
                                    width: 80,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'images/icon_broken.png',
                                        fit: BoxFit.cover,
                                        height: 80,
                                        width: 80,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 5, bottom: 5),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        album['title'] ?? 'Unknown Album',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1, // Prevents overflow
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        album['artist'],
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 14,
                                        ),
                                        maxLines: 1, // Prevents overflow
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            )));
  }
}
