import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Recent extends StatefulWidget {
  const Recent({super.key});

  @override
  State<Recent> createState() => _RecentState();
}

class _RecentState extends State<Recent> {
  List<Map<String, dynamic>> recentItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecentItems();
  }

  Future<void> fetchRecentItems() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Fetch recent albums
        final albumSnapshot = await FirebaseFirestore.instance
            .collection('LastPlayedAlbum')
            .doc(userId)
            .collection('albums')
            .orderBy('timestamp', descending: true)
            .get();

        // Fetch recent songs
        final songSnapshot = await FirebaseFirestore.instance
            .collection('LastPlayedSong')
            .doc(userId)
            .collection('songs')
            .orderBy('timestamp', descending: true)
            .get();

        // Combine and sort albums and songs by timestamp
        List<Map<String, dynamic>> allItems = [];

        allItems.addAll(albumSnapshot.docs.map((doc) => {
              'type': 'album',
              'data': doc.data()['album'] as Map<String, dynamic>,
              'timestamp': doc.data()['timestamp'] as Timestamp,
            }));

        allItems.addAll(songSnapshot.docs.map((doc) => {
              'type': 'song',
              'data': doc.data()['song'] as Map<String, dynamic>,
              'timestamp': doc.data()['timestamp'] as Timestamp,
            }));

        // Sort by timestamp
        allItems.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        setState(() {
          recentItems = allItems;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching recent items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we can pop before showing back button
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Recently Played',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[900]!,
                Colors.black,
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      );
    }

    if (recentItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'No Recent Activity',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: recentItems.length,
      itemBuilder: (context, index) {
        final item = recentItems[index];
        final data = item['data'] as Map<String, dynamic>;
        final bool isAlbum = item['type'] == 'album';
        final timestamp = item['timestamp'] as Timestamp;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[900],
          elevation: 2,
          child: InkWell(
            onTap: () {
              // Handle tap event if needed
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Hero(
                    tag: '${item['type']}_${data['id']}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data['image'] ?? '',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isAlbum ? Icons.album : Icons.music_note,
                            size: 35,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAlbum ? data['title'] : data['name'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAlbum ? Icons.album : Icons.music_note,
                                    size: 12,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAlbum ? 'Album' : 'Song',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isAlbum) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['artist'] ?? 'Unknown Artist',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTimeAgo(timestamp),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
