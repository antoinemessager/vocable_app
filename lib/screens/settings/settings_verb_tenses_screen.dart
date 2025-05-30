import 'package:flutter/material.dart';
import '../../services/preferences_service.dart';

class SettingsVerbTensesScreen extends StatefulWidget {
  const SettingsVerbTensesScreen({super.key});

  @override
  State<SettingsVerbTensesScreen> createState() =>
      _SettingsVerbTensesScreenState();
}

class _SettingsVerbTensesScreenState extends State<SettingsVerbTensesScreen> {
  final List<Map<String, dynamic>> _tenses = [
    {
      'name': 'présent',
      'level': 'A1',
    },
    {
      'name': 'futur',
      'level': 'A2',
    },
    {
      'name': 'passé composé',
      'level': 'A2',
    },
    {
      'name': 'imparfait',
      'level': 'B1',
    },
    {
      'name': 'passé simple',
      'level': 'B1',
    },
    {
      'name': 'conditionnel présent',
      'level': 'B1',
    },
    {
      'name': 'subjonctif présent',
      'level': 'B2',
    },
    {
      'name': 'impératif',
      'level': 'B2',
    },
    {
      'name': 'impératif négatif',
      'level': 'B2',
    },
    {
      'name': 'subjonctif passé',
      'level': 'C1',
    },
    {
      'name': 'plus que parfait',
      'level': 'C1',
    },
    {
      'name': 'futur antérieur',
      'level': 'C1',
    },
    {
      'name': 'conditionnel passé',
      'level': 'C1',
    },
  ];

  Set<String> _selectedTenses = {};
  final PreferencesService _preferencesService = PreferencesService();

  @override
  void initState() {
    super.initState();
    _loadSelectedTenses();
  }

  Future<void> _loadSelectedTenses() async {
    final selectedTenses = await _preferencesService.getSelectedVerbTenses();
    setState(() {
      _selectedTenses = selectedTenses.toSet();
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

    await _preferencesService.setSelectedVerbTenses(_selectedTenses.toList());
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
                  ..._tenses.map((tense) => Container(
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
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tense['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                tense['level'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          value: _selectedTenses.contains(tense['name']),
                          onChanged: (bool? value) {
                            if (value != null) {
                              _toggleTense(tense['name']);
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
