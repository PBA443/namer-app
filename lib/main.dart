import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // For JSON encoding/decoding

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  final String _baseUrl = 'https://api.donbhagy.com/api'; // Your backend URL

  MyAppState() {
    fetchFavorites(); // Fetch favorites when the app starts
  }

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  // Use a Set for faster lookups and to prevent duplicates
  var favorites = <WordPair>{}; // Changed to Set

  // --- Backend Interaction Methods ---

  Future<void> fetchFavorites() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/favorites'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        favorites = data
            .map((item) => WordPair(item['first_word'], item['second_word']))
            .toSet(); // Convert back to WordPair and Set
        notifyListeners();
      } else {
        print('Failed to load favorites: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching favorites: $e');
    }
  }

  Future<void> toggleFavorite() async {
    // Check if it's already a favorite on the frontend
    if (favorites.contains(current)) {
      // If it is, attempt to remove it from the backend
      await removeFavorite(current);
    } else {
      // If not, attempt to add it to the backend
      await addFavorite(current);
    }
  }

  Future<void> addFavorite(WordPair pair) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/favorites'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'firstWord': pair.first, 'secondWord': pair.second}),
      );

      if (response.statusCode == 201) {
        // Only add to local state if backend operation was successful
        favorites.add(pair);
        notifyListeners();
        print('Added favorite: ${pair.asLowerCase}');
      } else {
        print(
          'Failed to add favorite: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error adding favorite: $e');
    }
  }

  Future<void> removeFavorite(WordPair pair) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/favorites'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'firstWord': pair.first, 'secondWord': pair.second}),
      );

      if (response.statusCode == 200) {
        favorites.remove(
          pair,
        ); // Only remove from local state if backend successful
        notifyListeners();
        print('Removed favorite: ${pair.asLowerCase}');
      } else if (response.statusCode == 404) {
        print(
          'Favorite not found on server (already removed?): ${pair.asLowerCase}',
        );
        favorites.remove(pair); // Sync frontend if not found on backend
        notifyListeners();
      } else {
        print(
          'Failed to remove favorite: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error removing favorite: $e');
    }
  }
}

// (The rest of your UI widgets like MyHomePage, GeneratorPage, FavoritesPage, BigCard remain mostly the same,
// but ensure they call the new async methods in MyAppState.)

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  var extended = false;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      //break;
      case 1:
        page = FavoritesPage();
      //break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: extended,
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite),
                  label: Text('Favorites'),
                ),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                  extended = false;
                });
                // Optional: Re-fetch favorites when navigating to the Favorites tab
                if (value == 1) {
                  Provider.of<MyAppState>(
                    context,
                    listen: false,
                  ).fetchFavorites();
                }
              },
              trailing: IconButton(
                onPressed: () {
                  setState(() {
                    extended = !extended;
                  });
                },
                icon: Icon(extended ? Icons.arrow_back : Icons.arrow_forward),
                tooltip: extended ? 'Collapse menu' : 'Expand menu',
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: page,
            ),
          ),
        ],
      ),
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite(); // Calls async method
                },
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                  child: Icon(icon, key: ValueKey<IconData>(icon)),
                ),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var favoritesList = appState.favorites
        .toList(); // Convert Set to List for ListView

    if (favoritesList.isEmpty) {
      return Center(
        child: Text(
          'No favorites yet. Go to the Home tab and like some word pairs!',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'You have ${favoritesList.length} favorites:',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        for (var pair in favoritesList)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(
              pair.asLowerCase,
              semanticsLabel: "${pair.first} ${pair.second}",
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: () {
                appState.removeFavorite(pair); // Calls async method
              },
              tooltip: 'Remove from favorites',
            ),
          ),
      ],
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({super.key, required this.pair});

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
      fontWeight: FontWeight.bold,
    );
    return Card(
      color: theme.colorScheme.primary,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}
