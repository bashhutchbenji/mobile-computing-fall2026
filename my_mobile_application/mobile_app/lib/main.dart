import 'package:flutter/material.dart';

import 'dart:async';

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

void main() {
  runApp(const WrestlingApp());
}

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Wrestler> roster = [
    Wrestler(name: 'Sebastian Hutchinson', weight: 197, wins: 0, losses: 0),
    Wrestler(name: 'Justice McGee', weight: 184, wins: 0, losses: 0),
    Wrestler(name: 'Aaron Garcia', weight: 285, wins: 0, losses: 0),
  ];
  final List<MatchResult> history = [];

  Future<void> _openScoreboard() async {
    final MatchResult? result = await Navigator.push<MatchResult>(
      context,
      MaterialPageRoute(builder: (context) => ScoreboardPage(roster: roster)),
    );

    if (result != null) {
      setState(() {
        result.winner.wins += 1;
        result.loser.losses += 1;
        history.add(result);
      });
    }
  }

  Future<void> _openRoster() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RosterPage(roster: roster)),
    );
    setState(() {});
  }

  void _openStats() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsPage(roster: roster, history: history),
      ),
    );
  }

  void _openVideos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VideosPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  '${history.length} matches recorded',
                  _openScoreboard,
                ),
                _navTile(
                  Icons.groups,
                  'Team Roster\n'
                  '${roster.length} wrestlers',
                  _openRoster,
                ),
                _navTile(
                  Icons.play_circle_fill,
                  'Videos\n'
                  'Coming soon',
                  _openVideos,
                ),
                _navTile(
                  Icons.bar_chart,
                  'Stats\n'
                  'Records and match history',
                  _openStats,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
}

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

Widget _bottomIcon(IconData icon, String label, Color color) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: color),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 12, color: color)),
    ],
  );
}

Widget _buildBottomBar() {
  return Container(
    height: 70,
    color: Colors.black,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _bottomIcon(Icons.quiz, 'Trivia', Colors.green),
        _bottomIcon(Icons.event, 'Events', Colors.green),
        _bottomIcon(Icons.local_fire_department, 'Streak', Colors.white),
        _bottomIcon(Icons.forum, 'Forum', Colors.red),
        _bottomIcon(Icons.settings, 'Account', Colors.red),
      ],
    ),
  );
}

class ScoreboardPage extends StatefulWidget {
  final List<Wrestler> roster;

  const ScoreboardPage({super.key, required this.roster});

  @override
  State<ScoreboardPage> createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  Wrestler? red;
  Wrestler? green;
  int redScore = 0;
  int greenScore = 0;
  //int period = 1;

  int secondsLeft = 420;
  bool running = false;
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (running) {
      timer?.cancel();
      setState(() => running = false);
    } else {
      setState(() => running = true);
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (secondsLeft > 0) {
          timer.cancel();
          setState(() {
            secondsLeft = 0;
            running = false;
          });
        } else {
          setState(() => secondsLeft--);
        }
      });
    }
  }

  void _resetClock() {
    timer?.cancel();
    setState(() {
      secondsLeft = 360;
      running = false;
    });
  }

  String _formatTime() {
    final int minutes = secondsLeft ~/ 60;
    final int seconds = secondsLeft % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // SCOREBOARD -> HOME: pop with the result object as the return value.
  void _finishMatch() {
    if (red == null || green == null) {
      _showMessage('Pick a wrestler for both sides first.');
      return;
    }
    if (red == green) {
      _showMessage('Pick two different wrestlers.');
      return;
    }
    if (redScore == greenScore) {
      _showMessage('The match cannot end tied.');
      return;
    }
    timer?.cancel();
    Navigator.pop(
      context,
      MatchResult(
        red: red!,
        green: green!,
        redScore: redScore,
        greenScore: greenScore,
      ),
    );
  }

  Widget _wrestlerPicker(
    String label,
    Color color,
    Wrestler? selected,
    ValueChanged<Wrestler?> onChanged,
  ) {
    return DropdownButton<Wrestler>(
      value: selected,
      isExpanded: true,
      hint: Text('$label wrestler'),
      items: widget.roster
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
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    Colors.red,
                    red,
                    (w) => setState(() => red = w),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _wrestlerPicker(
                    'Green',
                    Colors.green,
                    green,
                    (w) => setState(() => green = w),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _formatTime(),
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _toggleTimer,
                  child: Text(running ? 'Pause' : 'Start'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _resetClock,
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
                    red?.name ?? 'Red',
                    Colors.red,
                    redScore,
                    () => setState(() => redScore += 1),
                    () => setState(() => redScore += 2),
                    () => setState(() => redScore += 3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _scorePanel(
                    green?.name ?? 'Green',
                    Colors.green,
                    greenScore,
                    () => setState(() => greenScore += 1),
                    () => setState(() => greenScore += 2),
                    () => setState(() => greenScore += 3),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _finishMatch,
                child: const Text('Finish Match & Save Result'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RosterPage extends StatefulWidget {
  final List<Wrestler> roster;

  const RosterPage({super.key, required this.roster});

  @override
  State<RosterPage> createState() => _RosterPageState();
}

class _RosterPageState extends State<RosterPage> {
  // ROSTER -> ADD WRESTLER, ADD WRESTLER -> ROSTER (returns a Wrestler)
  Future<void> _addWrestler() async {
    final Wrestler? newWrestler = await Navigator.push<Wrestler>(
      context,
      MaterialPageRoute(builder: (context) => const AddWrestlerPage()),
    );

    if (newWrestler != null) {
      setState(() {
        widget.roster.add(newWrestler);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team Roster')),
      body: ListView.builder(
        itemCount: widget.roster.length,
        itemBuilder: (context, index) {
          final Wrestler w = widget.roster[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${w.weight}')),
            title: Text(w.name),
            subtitle: Text('Record: ${w.wins}-${w.losses}'),
            trailing: const Icon(Icons.chevron_right),
            // ROSTER -> DETAIL (sends the tapped Wrestler object)
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WrestlerDetailPage(wrestler: w),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWrestler,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddWrestlerPage extends StatefulWidget {
  const AddWrestlerPage({super.key});

  @override
  State<AddWrestlerPage> createState() => _AddWrestlerPageState();
}

class _AddWrestlerPageState extends State<AddWrestlerPage> {
  final TextEditingController nameController = TextEditingController();
  final List<int> weightClasses = [
    106,
    113,
    120,
    126,
    132,
    138,
    144,
    150,
    157,
    165,
    175,
    190,
    215,
    285,
  ];
  int selectedWeight = 150;

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
    Navigator.pop(
      context,
      Wrestler(name: name, weight: selectedWeight, wins: 0, losses: 0),
    );
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

class WrestlerDetailPage extends StatelessWidget {
  final Wrestler wrestler;

  const WrestlerDetailPage({super.key, required this.wrestler});

  @override
  Widget build(BuildContext context) {
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

class StatsPage extends StatelessWidget {
  final List<Wrestler> roster;
  final List<MatchResult> history;

  const StatsPage({super.key, required this.roster, required this.history});

  @override
  Widget build(BuildContext context) {
    final List<Wrestler> sorted = List<Wrestler>.from(roster)
      ..sort((a, b) => b.wins.compareTo(a.wins));

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
          for (final w in sorted)
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
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No matches yet. Finish a match on the scoreboard.'),
            ),
          for (final m in history.reversed)
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

class VideosPage extends StatelessWidget {
  const VideosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Videos')),
      body: const Center(child: Text('Videos coming soon')),
    );
  }
}
