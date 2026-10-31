import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

//wrestler model. The app keeps a list of wrestlers, each with a name, weight class, and record.
class Wrestler {
  String name;
  int weight;
  int wins;
  int losses;

  Wrestler({
    required this.name,
    required this.weight,
    required this.wins,
    required this.losses,
  });
}

// A match result is a record of a match that has finished
class MatchResult {
  final Wrestler red;
  final Wrestler green;
  final int redScore;
  final int greenScore;

  MatchResult({
    required this.red,
    required this.green,
    required this.redScore,
    required this.greenScore,
  });

  Wrestler get winner => redScore > greenScore ? red : green;
  Wrestler get loser => redScore > greenScore ? green : red;
}

//Trivia question model. The API returns the correct answer and a list of wrong answers, which we combine and shuffle.
class TriviaQuestion {
  final String question;
  final String correctAnswer;
  final List<String> answers; // correct + wrong answers, shuffled

  TriviaQuestion({
    required this.question,
    required this.correctAnswer,
    required this.answers,
  });

  //I had to get help from AI to write this fromJson method.
  //It decodes the URL-encoded strings and shuffles the answers.

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) {
    String decode(String s) => Uri.decodeComponent(s);

    final String correct = decode(json['correct_answer'] as String);
    final List<String> answers =
        (json['incorrect_answers'] as List<dynamic>)
            .map((a) => decode(a as String))
            .toList()
          ..add(correct)
          ..shuffle();

    return TriviaQuestion(
      question: decode(json['question'] as String),
      correctAnswer: correct,
      answers: answers,
    );
  }
}

// The trivia screen shows one of four things depending on this status.
enum TriviaStatus { loading, error, empty, data }

// Provider model. Holds the roster, match history, scoreboard, clock, and trivia questions.
//All screens read from this model and call its methods to change data.
class WrestlingModel extends ChangeNotifier {
  // The list of wrestlers in the roster.
  final List<Wrestler> _roster = [
    Wrestler(name: 'Sebastian Hutchinson', weight: 197, wins: 0, losses: 0),
    Wrestler(name: 'Justice McGee', weight: 184, wins: 0, losses: 0),
    Wrestler(name: 'Aaron Garcia', weight: 285, wins: 0, losses: 0),
  ];

  // The list of past match results.
  final List<MatchResult> _history = [];
  Wrestler? _selectedWrestler;

  // The currently selected wrestler.
  UnmodifiableListView<Wrestler> get roster => UnmodifiableListView(_roster);
  UnmodifiableListView<MatchResult> get history =>
      UnmodifiableListView(_history);
  Wrestler? get selectedWrestler => _selectedWrestler;

  // Returns the roster sorted by the number of wins in descending order.
  List<Wrestler> get rosterByWins {
    final List<Wrestler> copy = List<Wrestler>.from(_roster);
    copy.sort((a, b) => b.wins.compareTo(a.wins));
    return copy;
  }

  // Adds a new wrestler to the roster.
  void addWrestler(String name, int weight) {
    _roster.add(Wrestler(name: name, weight: weight, wins: 0, losses: 0));
    notifyListeners();
  }

  // Selects a wrestler as the currently active wrestler.
  void selectWrestler(Wrestler wrestler) {
    _selectedWrestler = wrestler;
    notifyListeners();
  }

  // The duration of a match in seconds.
  static const int matchSeconds = 420;

  // The wrestlers on each side of the match, along with their scores and the remaining time.
  Wrestler? _redWrestler;
  Wrestler? _greenWrestler;
  int _redScore = 0;
  int _greenScore = 0;
  int _secondsLeft = matchSeconds;
  bool _running = false;
  Timer? _timer;

  // Getters for the wrestlers, scores, remaining time, and running status.
  Wrestler? get redWrestler => _redWrestler;
  Wrestler? get greenWrestler => _greenWrestler;
  int get redScore => _redScore;
  int get greenScore => _greenScore;
  int get secondsLeft => _secondsLeft;
  bool get running => _running;

  // Selects the wrestler on the red side of the match.
  void selectRed(Wrestler? wrestler) {
    _redWrestler = wrestler;
    notifyListeners();
  }

  // Selects the wrestler on the green side of the match.
  void selectGreen(Wrestler? wrestler) {
    _greenWrestler = wrestler;
    notifyListeners();
  }

  // Adds points to the red side of the match.
  void addRedPoints(int points) {
    _redScore += points;
    notifyListeners();
  }

  // Adds points to the green side of the match.
  void addGreenPoints(int points) {
    _greenScore += points;
    notifyListeners();
  }

  // Toggles the match clock between running and paused.
  void toggleClock() {
    if (_running) {
      _timer?.cancel();
      _running = false;
    } else {
      if (_secondsLeft == 0) return;
      _running = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_secondsLeft <= 1) {
          t.cancel();
          _secondsLeft = 0;
          _running = false;
        } else {
          _secondsLeft -= 1;
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  // Resets the match, clearing scores and stopping the clock.
  void resetMatch() {
    _timer?.cancel();
    _running = false;
    _secondsLeft = matchSeconds;
    _redScore = 0;
    _greenScore = 0;
    notifyListeners();
  }

  // Finishes the match, updates the wrestlers' records, and returns an error message if the match cannot be finished.
  String? finishMatch() {
    final Wrestler? red = _redWrestler;
    final Wrestler? green = _greenWrestler;

    if (red == null || green == null) {
      return 'Pick a wrestler for both sides first.';
    }
    if (red == green) {
      return 'Pick two different wrestlers.';
    }
    if (_redScore == _greenScore) {
      return 'The match cannot end tied.';
    }

    final MatchResult result = MatchResult(
      red: red,
      green: green,
      redScore: _redScore,
      greenScore: _greenScore,
    );
    result.winner.wins += 1;
    result.loser.losses += 1;
    _history.add(result);

    _redWrestler = null;
    _greenWrestler = null;
    resetMatch();
    return null;
  }

  //Trivia API data. The model holds the questions, the chosen answers, and the current status (loading, error, empty, or data).
  TriviaStatus _triviaStatus = TriviaStatus.loading;
  List<TriviaQuestion> _trivia = [];
  final Map<int, String> _chosen = {}; // question index -> answer picked

  TriviaStatus get triviaStatus => _triviaStatus;
  UnmodifiableListView<TriviaQuestion> get trivia =>
      UnmodifiableListView(_trivia);
  String? chosenAnswer(int index) => _chosen[index];

  int get triviaScore {
    int score = 0;
    _chosen.forEach((index, answer) {
      if (_trivia[index].correctAnswer == answer) score += 1;
    });
    return score;
  }

  void chooseAnswer(int index, String answer) {
    if (_chosen.containsKey(index)) return; // already answered
    _chosen[index] = answer;
    notifyListeners();
  }

  // Called when the trivia screen opens: shows the spinner first.
  Future<void> loadTrivia() async {
    _trivia = [];
    _chosen.clear();
    _triviaStatus = TriviaStatus.loading;
    notifyListeners();

    final bool ok = await _fetchTrivia();
    if (!ok) {
      _triviaStatus = TriviaStatus.error;
      notifyListeners();
    }
  }

  // Called by pull-to-refresh. Returns false if it failed. If we already
  // have questions we keep showing them instead of an error screen.
  Future<bool> refreshTrivia() async {
    final bool ok = await _fetchTrivia();
    if (!ok && _trivia.isEmpty) {
      _triviaStatus = TriviaStatus.error;
      notifyListeners();
    }
    return ok;
  }

  // Does the actual request. Returns true on success, false on failure.
  Future<bool> _fetchTrivia() async {
    try {
      // Fetch trivia questions from the Open Trivia Database API.
      final http.Response response = await http
          .get(
            Uri.parse(
              'https://opentdb.com/api.php?amount=10&category=21&type=multiple&encode=url3986',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return false;

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;

      // 0 = success, 1 = no results. Anything else (like 5, too many
      // requests) counts as a failure.
      final int code = body['response_code'] as int;
      if (code != 0 && code != 1) return false;

      // Parse the list of trivia questions from the API response.
      final List<dynamic> results = body['results'] as List<dynamic>;
      _trivia = results
          .map((item) => TriviaQuestion.fromJson(item as Map<String, dynamic>))
          .toList();
      _chosen.clear();
      _triviaStatus = _trivia.isEmpty ? TriviaStatus.empty : TriviaStatus.data;
      notifyListeners();
      return true;
    } catch (_) {
      // Handle any exceptions that occur during the API request or parsing.
      return false;
    }
  }

  // Stance in motion: drill timer (up to 10 minutes)
  static const int stanceMinSeconds = 15;
  static const int stanceMaxSeconds = 600; // 10:00

  int _stanceDuration = 60;
  int _stanceSecondsLeft = 60;
  bool _stanceRunning = false;
  Timer? _stanceTimer;

  int get stanceDuration => _stanceDuration;
  int get stanceSecondsLeft => _stanceSecondsLeft;
  bool get stanceRunning => _stanceRunning;

  // Sets the duration of the stance drill. Only allowed while the timer is stopped.
  void setStanceDuration(int seconds) {
    if (_stanceRunning) return;
    _stanceDuration = seconds.clamp(stanceMinSeconds, stanceMaxSeconds).toInt();
    _stanceSecondsLeft = _stanceDuration;
    notifyListeners();
  }

  // Toggles the stance drill between running and paused.
  void toggleStance() {
    if (_stanceRunning) {
      _stanceTimer?.cancel();
      _stanceRunning = false;
    } else {
      if (_stanceSecondsLeft == 0) {
        _stanceSecondsLeft = _stanceDuration; // start over after finishing
      }
      _stanceRunning = true;
      _stanceTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_stanceSecondsLeft <= 1) {
          t.cancel();
          _stanceSecondsLeft = 0;
          _stanceRunning = false;
        } else {
          _stanceSecondsLeft -= 1;
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  // Resets the stance drill, stopping the timer and clearing the remaining time.
  void resetStance() {
    _stanceTimer?.cancel();
    _stanceRunning = false;
    _stanceSecondsLeft = _stanceDuration;
    notifyListeners();
  }

  // Cleans up the stance drill timer when the model is disposed.
  @override
  void dispose() {
    _timer?.cancel();
    _stanceTimer?.cancel();
    super.dispose();
  }
}

// This is the entry point of the application.
// It initializes the WrestlingModel and runs the WrestlingApp widget.
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => WrestlingModel(),
      child: const WrestlingApp(),
    ),
  );
}

// The main application widget.
// It sets up the MaterialApp with the theme and home page.
class WrestlingApp extends StatelessWidget {
  const WrestlingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wrestling App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFB71C1C), // deep red
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

// The home page of the application.
// It displays the welcome message, news cards, and navigation tiles.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final WrestlingModel model = context.watch<WrestlingModel>();
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Wrestling App'), centerTitle: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back', style: TextStyle(fontSize: 16)),
                Text(
                  'Wrestling App',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _newsCard('News 1', screenWidth),
                _newsCard('News 2', screenWidth),
                _newsCard('News 3', screenWidth),
                _newsCard('News 4', screenWidth),
                _newsCard('News 5', screenWidth),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _navTile(
                  Icons.timer,
                  'Score Board / Clock\n'
                  '${model.history.length} matches recorded',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScoreboardPage(),
                      ),
                    );
                  },
                ),
                _navTile(
                  Icons.groups,
                  'Team Roster\n'
                  '${model.roster.length} wrestlers',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RosterPage(),
                      ),
                    );
                  },
                ),
                _navTile(
                  Icons.accessibility_new,
                  'Stance in Motion\n'
                  'Drill timer, up to 10 minutes',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StanceInMotionPage(),
                      ),
                    );
                  },
                ),
                _navTile(
                  Icons.bar_chart,
                  'Stats\n'
                  'Records and match history',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }
}

// This widget represents a news card in the home page.
Widget _newsCard(String label, double screenWidth) {
  return Container(
    width: screenWidth * 0.3,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: Colors.grey.shade300,
    padding: const EdgeInsets.all(8),
    alignment: Alignment.bottomLeft,
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}

Widget _navTile(IconData icon, String label, VoidCallback onTap) {
  return ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
}

// This widget represents a bottom navigation icon in the home page.
Widget _bottomIcon(
  IconData icon,
  String label,
  Color color, {
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    ),
  );
}

// Opens a page. Used by the ribbon buttons below.
void _open(BuildContext context, Widget page) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => page));
}

Widget _buildBottomBar(BuildContext context) {
  return Container(
    height: 70,
    color: Colors.black,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // The green Trivia button opens the Trivia (API) screen.
        _bottomIcon(
          Icons.quiz,
          'Trivia',
          Colors.green,
          onTap: () {
            // Tell the model to start loading, then open the screen.
            context.read<WrestlingModel>().loadTrivia();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TriviaPage()),
            );
          },
        ),
        _bottomIcon(
          Icons.event,
          'Events',
          Colors.green,
          onTap: () => _open(context, const EventsPage()),
        ),
        _bottomIcon(
          Icons.local_fire_department,
          'Streak',
          Colors.white,
          onTap: () => _open(context, const StreakPage()),
        ),
        _bottomIcon(
          Icons.forum,
          'Forum',
          Colors.red,
          onTap: () => _open(context, const ForumPage()),
        ),
        _bottomIcon(
          Icons.settings,
          'Account',
          Colors.red,
          onTap: () => _open(context, const AccountPage()),
        ),
      ],
    ),
  );
}

// The scoreboard page of the application.
// It allows users to select wrestlers, update scores, and finish matches.
class ScoreboardPage extends StatelessWidget {
  const ScoreboardPage({super.key});

  String _formatTime(int secondsLeft) {
    final int minutes = secondsLeft ~/ 60;
    final int seconds = secondsLeft % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _finishMatch(BuildContext context) {
    final String? problem = context.read<WrestlingModel>().finishMatch();
    if (problem != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
    } else {
      Navigator.pop(context); // nothing is returned; Home reads the model
    }
  }

  Widget _wrestlerPicker(
    String label,
    List<Wrestler> roster,
    Wrestler? selected,
    ValueChanged<Wrestler?> onChanged,
  ) {
    return DropdownButton<Wrestler>(
      value: selected,
      isExpanded: true,
      hint: Text('$label wrestler'),
      items: roster
          .map(
            (w) => DropdownMenuItem<Wrestler>(
              value: w,
              child: Text('${w.name} (${w.weight})'),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _scorePanel(
    String label,
    Color color,
    int score,
    VoidCallback onPlus1,
    VoidCallback onPlus2,
    VoidCallback onPlus3,
    VoidCallback onPlus4,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: color.withValues(alpha: 0.15),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            '$score',
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 6,
            children: [
              ElevatedButton(onPressed: onPlus1, child: const Text('+1')),
              ElevatedButton(onPressed: onPlus2, child: const Text('+2')),
              ElevatedButton(onPressed: onPlus3, child: const Text('+3')),
              ElevatedButton(onPressed: onPlus4, child: const Text('+4')),
            ],
          ),
        ],
      ),
    );
  }

  // Builds the main layout of the scoreboard page.
  // It includes the wrestler pickers, the clock, and the score panels.
  @override
  Widget build(BuildContext context) {
    final WrestlingModel model = context.watch<WrestlingModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Score Board / Clock')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _wrestlerPicker(
                    'Red',
                    model.roster,
                    model.redWrestler,
                    (w) => context.read<WrestlingModel>().selectRed(w),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _wrestlerPicker(
                    'Green',
                    model.roster,
                    model.greenWrestler,
                    (w) => context.read<WrestlingModel>().selectGreen(w),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _formatTime(model.secondsLeft),
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => context.read<WrestlingModel>().toggleClock(),
                  child: Text(model.running ? 'Pause' : 'Start'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.read<WrestlingModel>().resetMatch(),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _scorePanel(
                    model.redWrestler?.name ?? 'Red',
                    Colors.red,
                    model.redScore,
                    () => context.read<WrestlingModel>().addRedPoints(1),
                    () => context.read<WrestlingModel>().addRedPoints(2),
                    () => context.read<WrestlingModel>().addRedPoints(3),
                    () => context.read<WrestlingModel>().addRedPoints(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _scorePanel(
                    model.greenWrestler?.name ?? 'Green',
                    Colors.green,
                    model.greenScore,
                    () => context.read<WrestlingModel>().addGreenPoints(1),
                    () => context.read<WrestlingModel>().addGreenPoints(2),
                    () => context.read<WrestlingModel>().addGreenPoints(3),
                    () => context.read<WrestlingModel>().addGreenPoints(4),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _finishMatch(context),
                child: const Text('Finish Match & Save Result'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// The roster page of the application.
// It displays the list of wrestlers from the model and allows users to view details or add new wrestlers.
class RosterPage extends StatelessWidget {
  const RosterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final WrestlingModel model = context.watch<WrestlingModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Team Roster')),
      body: ListView.builder(
        itemCount: model.roster.length,
        itemBuilder: (context, index) {
          final Wrestler w = model.roster[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${w.weight}')),
            title: Text(w.name),
            subtitle: Text('Record: ${w.wins}-${w.losses}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.read<WrestlingModel>().selectWrestler(w);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WrestlerDetailPage(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddWrestlerPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// The add wrestler page of the application.
// It allows users to input a new wrestler's name and weight class, then save it to the model.
class AddWrestlerPage extends StatefulWidget {
  const AddWrestlerPage({super.key});

  @override
  State<AddWrestlerPage> createState() => _AddWrestlerPageState();
}

// The state of the add wrestler page.
// It manages the text field for the wrestler's name and the dropdown for selecting the weight class.
class _AddWrestlerPageState extends State<AddWrestlerPage> {
  final TextEditingController nameController = TextEditingController();
  final List<int> weightClasses = [
    125,
    133,
    141,
    149,
    157,
    165,
    174,
    184,
    197,
    285,
  ];
  int selectedWeight = 157;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _save() {
    final String name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a name.')));
      return;
    }
    context.read<WrestlingModel>().addWrestler(name, selectedWeight);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Wrestler')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Wrestler name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Weight class'),
            DropdownButton<int>(
              value: selectedWeight,
              isExpanded: true,
              items: weightClasses
                  // Map each weight class to a dropdown menu item.
                  .map(
                    (w) =>
                        DropdownMenuItem<int>(value: w, child: Text('$w lbs')),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedWeight = value);
                }
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}

// The wrestler detail page of the application.
// It displays the selected wrestler's name, weight class, and statistics (wins and losses).
class WrestlerDetailPage extends StatelessWidget {
  const WrestlerDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Wrestler? wrestler = context.watch<WrestlingModel>().selectedWrestler;

    if (wrestler == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wrestler')),
        body: const Center(child: Text('No wrestler selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(wrestler.name)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              wrestler.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Weight class: ${wrestler.weight} lbs'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _statBox('Wins', wrestler.wins, Colors.green)),
                const SizedBox(width: 12),
                Expanded(
                  child: _statBox('Losses', wrestler.losses, Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: color.withValues(alpha: 0.15),
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          Text(label),
        ],
      ),
    );
  }
}

// The stats page of the application.
// It displays team records and match history from the model.
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final WrestlingModel model = context.watch<WrestlingModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Team Records',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          for (final w in model.rosterByWins)
            ListTile(
              title: Text(w.name),
              subtitle: Text('${w.weight} lbs'),
              trailing: Text(
                '${w.wins}-${w.losses}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 4),
            child: Text(
              'Match History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          if (model.history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No matches yet. Finish a match on the scoreboard.'),
            ),
          for (final m in model.history.reversed)
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: Text('${m.winner.name} defeated ${m.loser.name}'),
              subtitle: Text(
                '${m.redScore} - ${m.greenScore}  (${m.red.name} vs ${m.green.name})',
              ),
            ),
        ],
      ),
    );
  }
}

// The trivia page of the application.
// It allows users to answer trivia questions and provides feedback on their answers.
class TriviaPage extends StatelessWidget {
  const TriviaPage({super.key});

  // Pull-to-refresh handler for the trivia page.
  // Refreshes the trivia questions from the model.
  Future<void> _refresh(BuildContext context) async {
    final WrestlingModel model = context.read<WrestlingModel>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    final bool ok = await model.refreshTrivia();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't get new questions. Try again in a few seconds.",
          ),
        ),
      );
    }
  }

  Widget _answerButton(
    BuildContext context,
    WrestlingModel model,
    int index,
    TriviaQuestion q,
    String answer,
  ) {
    final String? chosen = model.chosenAnswer(index);

    // Answer button for a trivia question.
    // It changes color based on whether the answer is correct or if it was the chosen answer.
    Color? color;
    if (chosen != null) {
      if (answer == q.correctAnswer) {
        color = Colors.green;
      } else if (answer == chosen) {
        color = Colors.red;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: chosen == null
              ? () => context.read<WrestlingModel>().chooseAnswer(index, answer)
              : null,
          style: color == null
              ? null
              : OutlinedButton.styleFrom(
                  disabledBackgroundColor: color.withValues(alpha: 0.2),
                  disabledForegroundColor: Theme.of(context)
                      .colorScheme
                      .onSurface,
                ),
          child: Text(answer),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final WrestlingModel model = context.watch<WrestlingModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trivia'),
        actions: [
          if (model.triviaStatus == TriviaStatus.data)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Score: ${model.triviaScore}/${model.trivia.length}',
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, model),
    );
  }

  Widget _buildBody(BuildContext context, WrestlingModel model) {
    switch (model.triviaStatus) {
      // 1. Loading state for the trivia page.
      case TriviaStatus.loading:
        return const Center(child: CircularProgressIndicator());

      // 2. Error state for the trivia page.
      case TriviaStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 56),
                const SizedBox(height: 12),
                const Text(
                  "Couldn't load trivia.\nCheck your internet connection.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.read<WrestlingModel>().loadTrivia(),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        );

      // 3. Empty state for the trivia page (still pull-to-refresh, so the list must be scrollable).
      case TriviaStatus.empty:
        return RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 160),
              Icon(Icons.help_outline, size: 56),
              SizedBox(height: 12),
              Center(child: Text('No questions found. Pull down to refresh.')),
            ],
          ),
        );

      // 4. Data state for the trivia page.
      case TriviaStatus.data:
        return RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: model.trivia.length,
            itemBuilder: (context, index) {
              final TriviaQuestion q = model.trivia[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${q.question}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final answer in q.answers)
                        _answerButton(context, model, index, q, answer),
                    ],
                  ),
                ),
              );
            },
          ),
        );
    }
  }
}

// The stance in motion page of the application.
// It allows users to set a duration for a stance drill and provides a countdown timer.
class StanceInMotionPage extends StatelessWidget {
  const StanceInMotionPage({super.key});

  String _formatTime(int secondsLeft) {
    final int minutes = secondsLeft ~/ 60;
    final int seconds = secondsLeft % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final WrestlingModel model = context.watch<WrestlingModel>();
    final bool finished = model.stanceSecondsLeft == 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Stance in Motion')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              finished ? 'Time!' : 'Drill time',
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              _formatTime(model.stanceSecondsLeft),
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Set the time'),
            ),
            // Slider to set the duration of the stance drill.
            Slider(
              value: model.stanceDuration.toDouble(),
              min: WrestlingModel.stanceMinSeconds.toDouble(),
              max: WrestlingModel.stanceMaxSeconds.toDouble(),
              divisions: 39, // steps of 15 seconds: (600 - 15) / 15
              // The slider is disabled while the stance drill is running.
              label: _formatTime(model.stanceDuration),
              onChanged: model.stanceRunning
                  ? null
                  : (value) => context.read<WrestlingModel>().setStanceDuration(
                      value.round(),
                    ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('0:15'), Text('10:00')],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: () =>
                      context.read<WrestlingModel>().toggleStance(),
                  child: Text(
                    model.stanceRunning
                        ? 'Pause'
                        : (finished ? 'Restart' : 'Start'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.read<WrestlingModel>().resetStance(),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The events page of the application.
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Events')),
      body: const Center(child: Text('Events coming soon')),
    );
  }
}

/// The streak tracker page of the application.
class StreakPage extends StatelessWidget {
  const StreakPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Streak Tracker')),
      body: const Center(child: Text('Streak tracker coming soon')),
    );
  }
}

/// The forum page of the application.
class ForumPage extends StatelessWidget {
  const ForumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forum')),
      body: const Center(child: Text('Forum coming soon')),
    );
  }
}

/// The account settings page of the application.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: const Center(child: Text('Account settings coming soon')),
    );
  }
}
