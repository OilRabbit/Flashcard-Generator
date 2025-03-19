import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

void main() {
  runApp(FlashcardApp());
}

class FlashcardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashcards',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FlashcardScreen(),
    );
  }
}

class FlashcardScreen extends StatefulWidget {
  @override
  _FlashcardScreenState createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  List<List<dynamic>> _flashcards = [];
  int _currentIndex = 0;
  bool _showAnswer = false;

  String _selectedChapter = "All";
  String _selectedType = "All";
  String _selectedDifficulty = "All";

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickAndLoadCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String rawData = await file.readAsString();
      List<List<dynamic>> csvData = const CsvToListConverter().convert(rawData);

      setState(() {
        _flashcards = csvData.sublist(1); // Remove header row
        _currentIndex = 0; // Reset flashcards index
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("CSV file loaded successfully!")),
      );
    }
  }

  List<List<dynamic>> getFilteredFlashcards() {
    return _flashcards.where((card) {
      bool chapterMatch = _selectedChapter == "All" || card[0].toString() == _selectedChapter;
      bool typeMatch = _selectedType == "All" || card[1].toString() == _selectedType;
      bool difficultyMatch = _selectedDifficulty == "All" || card[2].toString() == _selectedDifficulty;
      return chapterMatch && typeMatch && difficultyMatch;
    }).toList();
  }

  void _nextFlashcard() {
    setState(() {
      _showAnswer = false;
      _currentIndex = (_currentIndex + 1) % getFilteredFlashcards().length;
    });
  }

  void _prevFlashcard() {
    setState(() {
      _showAnswer = false;
      _currentIndex = (_currentIndex - 1) % getFilteredFlashcards().length;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<List<dynamic>> filteredFlashcards = getFilteredFlashcards();

    return Scaffold(
      appBar: AppBar(title: Text("Flashcards")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _pickAndLoadCSV,
                  child: Text("Upload CSV File"),
                ),
                DropdownButton<String>(
                  value: _selectedChapter,
                  items: ["All", "1", "2", "3", "4"]
                      .map((ch) => DropdownMenuItem(value: ch, child: Text("Chapter $ch")))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedChapter = value!;
                      _currentIndex = 0;
                    });
                  },
                ),
                DropdownButton<String>(
                  value: _selectedType,
                  items: ["All", "Derivation", "Concept"]
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                      _currentIndex = 0;
                    });
                  },
                ),
                DropdownButton<String>(
                  value: _selectedDifficulty,
                  items: ["All", "Easy", "Intermediate", "Advanced"]
                      .map((diff) => DropdownMenuItem(value: diff, child: Text(diff)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDifficulty = value!;
                      _currentIndex = 0;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredFlashcards.isEmpty
                ? Center(child: Text("No flashcards match your criteria"))
                : GestureDetector(
                    onTap: () => setState(() => _showAnswer = !_showAnswer),
                    child: Card(
                      margin: EdgeInsets.all(20),
                      elevation: 5,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            _showAnswer
                                ? filteredFlashcards[_currentIndex][4].toString()
                                : filteredFlashcards[_currentIndex][3].toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: _prevFlashcard, child: Text("Previous")),
              ElevatedButton(onPressed: _nextFlashcard, child: Text("Next")),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

