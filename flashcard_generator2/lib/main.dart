import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_math_fork/flutter_math.dart';

void main() {
  runApp(FlashcardApp());
}

class FlashcardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashcard App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String? filePath;
  String? fileName;
  List<List<dynamic>> csvData = [];
  String selectedChapter = "All";
  String selectedType = "All";
  List<String> selectedDifficulties = [];
  List<String> difficultyLevels = ["Easy", "Intermediate", "Advanced"];
  final Random _random = Random();

  Future<void> pickCSVFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null) {
      setState(() {
        filePath = result.files.single.path;
        fileName = result.files.single.name;
      });
      await saveFilePath(filePath!);
      loadCSVData();
    }
  }

  Future<void> saveFilePath(String path) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('csvFilePath', path);
  }

  Future<void> loadCSVData() async {
    if (filePath == null) return;
    final file = File(filePath!);
    final rawData = await file.readAsString();
    List<List<dynamic>> parsedData = const CsvToListConverter().convert(rawData);
    setState(() {
      csvData = parsedData.sublist(1);
    });
  }

  void startFlashcards() {
    if (csvData.isNotEmpty) {
      List<List<dynamic>> filteredData = csvData.where((row) {
        bool chapterMatch = selectedChapter == "All" || row[0].toString() == selectedChapter;
        bool typeMatch = selectedType == "All" || row[1].toString() == selectedType;
        bool difficultyMatch = selectedDifficulties.isEmpty || selectedDifficulties.contains(row[2].toString());
        return chapterMatch && typeMatch && difficultyMatch;
      }).toList();

      filteredData.shuffle(_random);

      if (filteredData.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashcardScreen(flashcards: filteredData),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> chapters = ["All", ...csvData.map((row) => row[0].toString()).toSet().toList()];

    return Scaffold(
      appBar: AppBar(title: Text('Flashcard App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: pickCSVFile,
              child: Text('Upload CSV File'),
            ),
            if (fileName != null) Text("Selected: $fileName"),
            DropdownButton<String>(
              value: selectedChapter,
              items: chapters.map((chapter) => DropdownMenuItem(
                value: chapter,
                child: Text(chapter),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  selectedChapter = value!;
                });
              },
            ),
            DropdownButton<String>(
              value: selectedType,
              items: ["All", "Concept", "Derivation"].map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            ),
            Column(
              children: difficultyLevels.map((difficulty) => CheckboxListTile(
                title: Text(difficulty),
                value: selectedDifficulties.contains(difficulty),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      selectedDifficulties.add(difficulty);
                    } else {
                      selectedDifficulties.remove(difficulty);
                    }
                  });
                },
              )).toList(),
            ),
            ElevatedButton(
              onPressed: startFlashcards,
              child: Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

class FlashcardScreen extends StatefulWidget {
  final List<List<dynamic>> flashcards;
  FlashcardScreen({required this.flashcards});

  @override
  _FlashcardScreenState createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  int currentIndex = 0;
  bool showAnswer = false;

  Widget renderContent(String content) {
    if (content.trim().startsWith('\$\$') && content.trim().endsWith('\$\$')) {
      String tex = content.trim().substring(2, content.length - 2);
      return Math.tex(tex, textStyle: TextStyle(fontSize: 18));
    } else {
      return Text(content, style: TextStyle(fontSize: 18));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCard = widget.flashcards[currentIndex];
    return Scaffold(
      appBar: AppBar(title: Text('Flashcards')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${currentIndex + 1}/${widget.flashcards.length}"),
            Text("Chapter: ${currentCard[0]}", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Type: ${currentCard[1]}", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Difficulty: ${currentCard[2]}", style: TextStyle(fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () {
                setState(() {
                  showAnswer = !showAnswer;
                });
              },
              child: Card(
                elevation: 5,
                child: Container(
                  width: 500,
                  height: 200,
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: renderContent(showAnswer ? currentCard[4].toString() : currentCard[3].toString()),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentIndex > 0
                      ? () {
                          setState(() {
                            currentIndex--;
                            showAnswer = false;
                          });
                        }
                      : null,
                  child: Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: currentIndex < widget.flashcards.length - 1
                      ? () {
                          setState(() {
                            currentIndex++;
                            showAnswer = false;
                          });
                        }
                      : null,
                  child: Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

