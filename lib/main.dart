import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:namer_app/screens/login_page.dart';
import 'package:namer_app/services/auth_service.dart'; // Import AuthService
import 'package:namer_app/models/user_model.dart'; // Import User model
//import 'package:namer_app/screens/register_page.dart'; // To navigate to register page

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
        // Start with a consumer to decide initial page based on login status
        home: Consumer<MyAppState>(
          builder: (context, appState, child) {
            if (appState.currentUser != null) {
              return MyHomePage(); // Show main app if logged in
            } else {
              return LoginPage(); // Show login page if not logged in
            }
          },
        ),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  final String _baseUrl = 'https://api.donbhagy.com/api'; // Your backend URL
  late final AuthService _authService; // Declare AuthService

  User? _currentUser; // To hold the current logged-in user
  User? get currentUser => _currentUser;

  MyAppState() {
    _authService = AuthService(_baseUrl); // Initialize AuthService
    _initializeUser(); // Check for existing user on startup
    fetchFavorites(); // Fetch favorites when the app starts
  }

  Future<void> _initializeUser() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  // --- Authentication Methods (delegated to AuthService) ---
  Future<void> login(String username, String password) async {
    try {
      _currentUser = await _authService.login(
        username: username,
        password: password,
      );
      notifyListeners();
      // After successful login, you might want to fetch user-specific data like favorites
      fetchFavorites();
    } catch (e) {
      // Rethrow to be caught by the UI
      rethrow;
    }
  }

  Future<void> register(String username, String email, String password) async {
    try {
      // In a typical flow, after registration, the user might be automatically logged in
      // or redirected to the login page. For now, we'll just register.
      await _authService.register(
        username: username,
        email: email,
        password: password,
      );
    } catch (e) {
      // Rethrow to be caught by the UI
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    favorites.clear(); // Clear favorites on logout
    notifyListeners();
  }

  // --- Existing Word Pair and Favorite Methods ---

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  // Use a Set for faster lookups and to prevent duplicates
  var favorites = <WordPair>{};

  Future<void> fetchFavorites() async {
    if (_currentUser == null) {
      // If no user is logged in, clear favorites and do not fetch
      favorites.clear();
      notifyListeners();
      return;
    }
    // You'll need to modify your backend to return user-specific favorites
    // and include the user's token in the request headers.
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/favorites'),
        headers: {
          'Authorization': 'Bearer ${_currentUser!.token}', // Send token
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        favorites = data
            .map((item) => WordPair(item['first_word'], item['second_word']))
            .toSet();
        notifyListeners();
      } else {
        print('Failed to load favorites: ${response.statusCode}');
        // Optionally handle cases like token expiry here (e.g., auto-logout)
      }
    } catch (e) {
      print('Error fetching favorites: $e');
    }
  }

  Future<void> toggleFavorite() async {
    if (_currentUser == null) {
      // Optionally show a message to log in first
      print('Please log in to manage favorites.');
      return;
    }
    if (favorites.contains(current)) {
      await removeFavorite(current);
    } else {
      await addFavorite(current);
    }
  }

  Future<void> addFavorite(WordPair pair) async {
    if (_currentUser == null) return;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_currentUser!.token}', // Send token
        },
        body: json.encode({'firstWord': pair.first, 'secondWord': pair.second}),
      );

      if (response.statusCode == 201) {
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
    if (_currentUser == null) return;
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_currentUser!.token}', // Send token
        },
        body: json.encode({'firstWord': pair.first, 'secondWord': pair.second}),
      );

      if (response.statusCode == 200) {
        favorites.remove(pair);
        notifyListeners();
        print('Removed favorite: ${pair.asLowerCase}');
      } else if (response.statusCode == 404) {
        print(
          'Favorite not found on server (already removed?): ${pair.asLowerCase}',
        );
        favorites.remove(pair);
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

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  var extended = false;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>(); // Watch MyAppState
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
      appBar: AppBar(
        title: const Text('Namer App'),
        actions: [
          if (appState.currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text('Logged in as: ${appState.currentUser!.username}'),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await appState.logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: extended,
              destinations: const [
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
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                  child: Icon(icon, key: ValueKey<IconData>(icon)),
                ),
                label: const Text('Like'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: const Text('Next'),
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
    var favoritesList = appState.favorites.toList();

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
            leading: const Icon(Icons.favorite),
            title: Text(
              pair.asLowerCase,
              semanticsLabel: "${pair.first} ${pair.second}",
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                appState.removeFavorite(pair);
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
