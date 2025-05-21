import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsVerbTensesScreen extends StatefulWidget {
  const SettingsVerbTensesScreen({super.key});

  @override
  State<SettingsVerbTensesScreen> createState() =>
      _SettingsVerbTensesScreenState();
}

class _SettingsVerbTensesScreenState extends State<SettingsVerbTensesScreen> {
  final List<String> _allTenses = [
    'présent',
    'passé composé',
    'futur',
    'futur antérieur',
    'imparfait',
    'plus que parfait',
    'passé simple',
    'conditionnel présent',
    'conditionnel passé',
    'subjonctif présent',
    'subjonctif passé',
    'impératif',
    'impératif négatif',
  ];

  Set<String> _selectedTenses = {};

  @override
  void initState() {
    super.initState();
    _loadSelectedTenses();
  }

  Future<void> _loadSelectedTenses() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedTenses = prefs.getStringList('selected_verb_tenses');
    setState(() {
      _selectedTenses = selectedTenses?.toSet() ?? _allTenses.toSet();
    });
  }

  Future<void> _toggleTense(String tense) async {
    setState(() {
      if (_selectedTenses.contains(tense)) {
        _selectedTenses.remove(tense);
      } else {
        _selectedTenses.add(tense);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_verb_tenses', _selectedTenses.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Temps verbaux',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: [
                  const Text(
                    'Sélectionne les temps que tu souhaites apprendre',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._allTenses.map((tense) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            tense,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          value: _selectedTenses.contains(tense),
                          onChanged: (bool? value) {
                            if (value != null) {
                              _toggleTense(tense);
                            }
                          },
                          activeColor: Colors.blue,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
