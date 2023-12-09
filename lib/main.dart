import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(MyApp());
}

FlutterTts flutterTts = FlutterTts();

Future<void> configureTts() async {
  await flutterTts.setLanguage('en-US');
  await flutterTts.setSpeechRate(0.5);
  await flutterTts.setVolume(1.0);
}

void speakText(String text) async {
  await flutterTts.speak(text);
}

void stopSpeaking() async {
  await flutterTts.stop();
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
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(seedColor: Colors.blueAccent.shade100),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var favorites = <WordPair>[];
  var deleted = <WordPair>[];

  void getNext(isSpeakEnabled) {
    current = WordPair.random();
    if (isSpeakEnabled) {
      speakText(current.first + " " + current.second);
    }
    notifyListeners();
  }

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  void deleteFavorite(pair) {
    if (favorites.contains(pair)) {
      favorites.remove(pair);
      deleted.add(pair);
    }
    notifyListeners();
  }

  void backToFavorite(pair) {
    if (deleted.contains(pair)) {
      deleted.remove(pair);
      favorites.add(pair);
    }
    notifyListeners();
  }

  void emptyTrash() {
    if (deleted.isNotEmpty) {
      deleted.clear();
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      case 1:
        page = FavoritesPage();
      case 2:
        page = TrashPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: false,
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite),
                  label: Text('Favorites'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.delete_rounded),
                  label: Text('Deleted'),
                ),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
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

class GeneratorPage extends StatefulWidget {
  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  bool speakSwitched = true;

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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Speak the words"),
              Switch(
                value: speakSwitched,
                onChanged: (bool value) {
                  setState(() {
                    speakSwitched = value;
                  });
                },
              ),
            ],
          ),
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext(speakSwitched);
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

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );
    final style2 = theme.textTheme.displayMedium!.copyWith(
      color: Color.fromRGBO(120, 250, 20, 100),
      fontWeight: FontWeight.w900,
    );
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              pair.first,
              style: style,
              semanticsLabel: pair.asPascalCase,
            ),
            Text(
              pair.second,
              style: style2,
              semanticsLabel: pair.asPascalCase,
            ),
          ],
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.favorites.length} favorites:'),
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: IconButton(
              color: Colors.red,
              onPressed: () {
                appState.deleteFavorite(pair);
              },
              icon: Icon(Icons.delete),
            ),
            title: Text(pair.asLowerCase),
          ),
      ],
    );
  }
}

class TrashPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.deleted.isEmpty) {
      return Center(
        child: Text('No deleted item.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.deleted.length} deleted. You can add them back into favorites:'),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 50, right: 50),
          child: ElevatedButton(
            onPressed: () {
              appState.emptyTrash();
            },
            child: ListTile(
              leading: Icon(
                Icons.delete_forever_sharp,
              ),
              title: Text("Delete Forever"),
            ),
          ),
        ),
        for (var pair in appState.deleted)
          ListTile(
            leading: IconButton(
              color: Colors.green,
              onPressed: () {
                appState.backToFavorite(pair);
              },
              icon: Icon(Icons.restore),
            ),
            title: Text(pair.asLowerCase),
          ),
      ],
    );
  }
}
