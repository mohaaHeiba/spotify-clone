import 'package:flutter/material.dart';
import 'package:music_app/widget/search_cards.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_app/pages/album_page.dart';
import 'package:music_app/widget/song_cards.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                return FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.only(left: 10, bottom: 10, right: 10),
                  title: SizedBox(
                    height: 38,
                    child: TextButton(
                      onPressed: () {
                        showSearch(
                          context: context,
                          delegate: SearchDelegateExample(),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(padding: EdgeInsets.only(right: 10)),
                          Icon(Icons.search, color: Colors.black, size: 20),
                          SizedBox(width: 10),
                          Text(
                            "Search",
                            style:
                                TextStyle(color: Colors.black45, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            backgroundColor: Colors.black,
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SearchCards(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchDelegateExample extends SearchDelegate {
  List<Map<String, dynamic>> searchResults = [];
  List<String> recentSearches = [];
  bool isLoading = true;
  final AudioPlayer _audioPlayer = audioPlayerInstance;

  // Add SharedPreferences constant key
  static const String RECENT_SEARCHES_KEY = 'recent_searches';

  SearchDelegateExample() {
    // Initialize by fetching data and loading recent searches
    fetchSearchResults();
    loadRecentSearches();
  }

  // Add method to load recent searches
  Future<void> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    recentSearches = prefs.getStringList(RECENT_SEARCHES_KEY) ?? [];
  }

  // Add method to save recent searches
  Future<void> saveSearch(String query) async {
    if (query.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    recentSearches.remove(query);
    recentSearches.insert(0, query);

    // Keep only last 10 searches
    if (recentSearches.length > 10) {
      recentSearches = recentSearches.sublist(0, 10);
    }

    await prefs.setStringList(RECENT_SEARCHES_KEY, recentSearches);
  }

  Future<void> fetchSearchResults() async {
    try {
      final songsSnapshot =
          await FirebaseFirestore.instance.collection('songs').get();
      final albumsSnapshot =
          await FirebaseFirestore.instance.collection('albums').get();

      searchResults.clear();

      // Add songs
      searchResults.addAll(songsSnapshot.docs.map((doc) => {
            'id': doc.id,
            'name': doc['title'] ?? 'Unknown Title',
            'artist': doc['artist'] ?? 'Unknown Artist',
            'image': doc['image'] ?? 'images/icon_broken.png',
            'audioUrl': doc['audioUrl'] ?? '',
            'type': 'song',
          }));

      // Add albums
      searchResults.addAll(albumsSnapshot.docs.map((doc) => {
            'id': doc.id,
            'name': doc['title'] ?? 'Unknown Title',
            'image': doc['image'] ?? 'images/icon_broken.png',
            'type': 'album',
          }));

      isLoading = false;
    } catch (e) {
      isLoading = false;
    }
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return ListView.builder(
        itemCount: recentSearches.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.history, color: Colors.white54),
            title: Text(
              recentSearches[index],
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              query = recentSearches[index];
              showResults(context);
            },
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.white54),
              onPressed: () async {
                if (index >= 0 && index < recentSearches.length) {
                  recentSearches.removeAt(index);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setStringList(
                      RECENT_SEARCHES_KEY, recentSearches);

                  query = query + ' ';
                  query = query.trim();
                }
              },
            ),
          );
        },
      );
    }
    return _buildSearchList(context);
  }

// Save search when showing results
  @override
  Widget buildResults(BuildContext context) {
    saveSearch(query);
    return _buildSearchList(context);
  }

  Widget _buildSearchList(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredResults = searchResults.where((item) {
      final nameLower = item['name'].toString().toLowerCase();
      final artistLower = (item['artist'] ?? '').toString().toLowerCase();
      final queryLower = query.toLowerCase();

      return nameLower.contains(queryLower) || artistLower.contains(queryLower);
    }).toList();

    if (filteredResults.isEmpty) {
      return Center(
        child: Text(
          query.isEmpty ? 'Start typing to search' : 'No results found',
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredResults.length,
      itemBuilder: (context, index) {
        final item = filteredResults[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              item['image'],
              height: 50,
              width: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 50,
                  width: 50,
                  color: Colors.grey[900],
                  child: const Icon(Icons.broken_image, color: Colors.white),
                );
              },
            ),
          ),
          title: Text(
            item['name'],
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: item['type'] == 'song'
              ? Text(
                  item['artist'],
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                )
              : Text(
                  'Album',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
          trailing: item['type'] == 'song'
              ? IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  onPressed: () async {
                    var audioSource = AudioSource.uri(
                      Uri.parse(item['audioUrl']),
                      tag: MediaItem(
                        id: item['audioUrl'],
                        album: item['name'],
                        title: item['name'],
                        artist: item['artist'],
                        artUri: Uri.parse(item['image']),
                      ),
                    );
                    await _audioPlayer.setAudioSource(audioSource);
                    await _audioPlayer.play();
                  },
                )
              : const Icon(Icons.album, color: Colors.white),
          onTap: () {
            if (item['type'] == 'album') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlbumPage(album: item),
                ),
              );
            }
          },
        );
      },
    );
  }
}
