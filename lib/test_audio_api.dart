import 'package:flutter/material.dart';
import 'core/repositories/audio_repository.dart';
import 'core/constants/app_env.dart';

void main() {
  runApp(const AudioAPITestApp());
}

class AudioAPITestApp extends StatelessWidget {
  const AudioAPITestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio API Test',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const AudioAPITestPage(),
    );
  }
}

class AudioAPITestPage extends StatefulWidget {
  const AudioAPITestPage({Key? key}) : super(key: key);

  @override
  State<AudioAPITestPage> createState() => _AudioAPITestPageState();
}

class _AudioAPITestPageState extends State<AudioAPITestPage> {
  final AudioRepository _audioRepo = AudioRepository();
  String _status = 'Ready to test';
  List<String> _logs = [];
  bool _isTesting = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
    debugPrint(message);
  }

  Future<void> _testAPI() async {
    setState(() {
      _isTesting = true;
      _logs.clear();
      _status = 'Testing...';
    });

    try {
      _addLog('=== Audio API Test Started ===');
      _addLog('Base URL: ${AppEnv.apiBaseUrl}');
      _addLog('');

      // Test 1: Fetch all audios
      _addLog('Test 1: Fetching all audios...');
      final allAudios = await _audioRepo.fetchAllAudios();
      _addLog('✓ Found ${allAudios.length} total audios');
      for (var audio in allAudios) {
        _addLog('  - ${audio.title} (${audio.category}, ${audio.language})');
      }
      _addLog('');

      // Test 2: Fetch bhajans
      _addLog('Test 2: Fetching bhajans...');
      final bhajans = await _audioRepo.fetchBhajans();
      _addLog('✓ Found ${bhajans.length} bhajans');
      for (var bhajan in bhajans) {
        _addLog('  - ${bhajan.title} by ${bhajan.artist}');
      }
      _addLog('');

      // Test 3: Fetch meditation music
      _addLog('Test 3: Fetching meditation music...');
      final meditation = await _audioRepo.fetchMeditationMusic();
      _addLog('✓ Found ${meditation.length} meditation tracks');
      for (var track in meditation) {
        _addLog('  - ${track.title} (${track.durationSeconds}s)');
      }
      _addLog('');

      // Test 4: Search
      _addLog('Test 4: Searching for "sivoham"...');
      final searchResults = await _audioRepo.searchAudios('sivoham');
      _addLog('✓ Found ${searchResults.length} results');
      for (var result in searchResults) {
        _addLog('  - ${result.title}');
      }
      _addLog('');

      _addLog('=== All Tests Passed! ===');
      setState(() {
        _status = '✓ All tests passed! Found ${allAudios.length} audios';
      });
    } catch (e) {
      _addLog('');
      _addLog('✗ ERROR: $e');
      setState(() {
        _status = '✗ Test failed: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio API Test'),
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _status.contains('✓')
                  ? Colors.green[50]
                  : _status.contains('✗')
                      ? Colors.red[50]
                      : Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _status.contains('✓')
                    ? Colors.green
                    : _status.contains('✗')
                        ? Colors.red
                        : Colors.blue,
              ),
            ),
            child: Text(
              _status,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _status.contains('✓')
                    ? Colors.green[900]
                    : _status.contains('✗')
                        ? Colors.red[900]
                        : Colors.blue[900],
              ),
            ),
          ),

          // Test Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _testAPI,
                icon: _isTesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isTesting ? 'Testing...' : 'Run API Test'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Click "Run API Test" to start',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            log,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: log.contains('✓')
                                  ? Colors.green[700]
                                  : log.contains('✗')
                                      ? Colors.red[700]
                                      : log.contains('===')
                                          ? Colors.blue[700]
                                          : Colors.black87,
                              fontWeight: log.contains('===') ||
                                      log.contains('✓') ||
                                      log.contains('✗')
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ℹ️ Prerequisites:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Backend must be running\n'
                  '2. Database must have audio records\n'
                  '3. Check .env.json for API_BASE_URL',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
