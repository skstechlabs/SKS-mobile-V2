import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/login_gate.dart';

/// Full sessions list with year/month filters and infinite scroll pagination.
/// Security: server always scopes results to the authenticated user's UID.
class MeditationSessionsPage extends StatefulWidget {
  const MeditationSessionsPage({Key? key}) : super(key: key);

  @override
  State<MeditationSessionsPage> createState() => _MeditationSessionsPageState();
}

class _MeditationSessionsPageState extends State<MeditationSessionsPage> {
  final ApiService _api = ApiService();
  final ScrollController _scroll = ScrollController();

  bool get _isLoggedIn {
    try { return FirebaseAuth.instance.currentUser != null; } catch (_) { return false; }
  }

  // ── Filter state ───────────────────────────────────────────────────────────
  int? _selectedYear;
  int? _selectedMonth;

  // ── Pagination state ───────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _sessions = [];
  int  _currentPage  = 1;
  int  _totalPages   = 1;
  int  _total        = 0;
  bool _loading      = false;   // first load / filter change
  bool _loadingMore  = false;   // pagination append
  bool _hasMore      = false;

  static const int _pageSize = 10;

  // ── Year options (current year going back 5 years) ────────────────────────
  final int _currentYear = DateTime.now().year;
  List<int> get _yearOptions => List.generate(6, (i) => _currentYear - i);

  static const List<String> _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = _currentYear;
    _fetchPage(1, replace: true);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // ── Infinite scroll trigger ───────────────────────────────────────────────
  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        !_loadingMore && _hasMore) {
      _fetchPage(_currentPage + 1, replace: false);
    }
  }

  Future<void> _fetchPage(int page, {required bool replace}) async {
    if (replace) {
      setState(() { _loading = true; });
    } else {
      setState(() { _loadingMore = true; });
    }

    try {
      final r = await _api.getMeditationSessions(
        page:  page,
        limit: _pageSize,
        year:  _selectedYear,
        month: _selectedMonth,
      );

      if (!mounted) return;

      if (r['success'] == true) {
        final newSessions = List<Map<String, dynamic>>.from(r['sessions'] ?? []);
        final pagination  = r['pagination'] as Map<String, dynamic>? ?? {};
        final total       = (pagination['total'] as int?) ?? 0;
        final totalPages  = (pagination['totalPages'] as int?) ?? 1;
        final hasMore     = (pagination['hasMore'] as bool?) ?? false;

        setState(() {
          if (replace) _sessions.clear();
          _sessions.addAll(newSessions);
          _currentPage = page;
          _totalPages  = totalPages;
          _total       = total;
          _hasMore     = hasMore;
          _loading     = false;
          _loadingMore = false;
        });
      } else {
        setState(() { _loading = false; _loadingMore = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _loadingMore = false; });
    }
  }

  void _applyFilters() {
    _fetchPage(1, replace: true);
  }

  String _fmtDur(int secs) {
    final h = secs ~/ 3600; final m = (secs % 3600) ~/ 60; final s = secs % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginGate(
        title: 'My Sessions',
        featureHint: '📅 Browse all your meditation sessions with filters',
        showBackButton: true,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('My Sessions',
                style: TextStyle(color: AppTheme.primary, fontSize: 18, fontWeight: FontWeight.bold)),
            if (_total > 0)
              Text('$_total sessions found',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Filter bar ─────────────────────────────────────────────────────
          _buildFilterBar(),
          // ── Sessions list ──────────────────────────────────────────────────
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // ── Filter bar ─────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // Year dropdown
          Expanded(child: _dropdownField<int>(
            label:   'Year',
            value:   _selectedYear,
            items:   [
              const DropdownMenuItem<int>(value: null, child: Text('All Years')),
              ..._yearOptions.map((y) => DropdownMenuItem<int>(value: y, child: Text('$y'))),
            ],
            onChanged: (v) {
              setState(() { _selectedYear = v; _selectedMonth = null; });
              _applyFilters();
            },
          )),
          const SizedBox(width: 10),
          // Month dropdown — only shown when a year is selected
          Expanded(child: _dropdownField<int>(
            label:   'Month',
            value:   _selectedMonth,
            enabled: _selectedYear != null,
            items:   [
              const DropdownMenuItem<int>(value: null, child: Text('All Months')),
              ...List.generate(12, (i) => DropdownMenuItem<int>(
                value: i + 1,
                child: Text(_monthNames[i + 1]),
              )),
            ],
            onChanged: _selectedYear == null ? null : (v) {
              setState(() => _selectedMonth = v);
              _applyFilters();
            },
          )),
        ],
      ),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : AppTheme.tagBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.softGray),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value:       value,
          items:       items,
          onChanged:   enabled ? onChanged : null,
          isExpanded:  true,
          hint:        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          style:       const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          icon:        const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        ),
      ),
    );
  }

  // ── Sessions list ──────────────────────────────────────────────────────────
  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.self_improvement, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            const Text('No sessions found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(
              _selectedYear != null
                  ? 'No sessions in ${_selectedYear ?? ""}${_selectedMonth != null ? " · ${_monthNames[_selectedMonth!]}" : ""}'
                  : 'You haven\'t recorded any sessions yet.',
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchPage(1, replace: true),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _sessions.length + (_hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == _sessions.length) {
            // Loading spinner at the bottom while fetching next page
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _sessionCard(_sessions[i]);
        },
      ),
    );
  }

  Widget _sessionCard(Map<String, dynamic> s) {
    final dur    = (s['duration_seconds'] as num?)?.toInt() ?? 0;
    final stRaw  = s['started_at'] as String?;
    final date   = s['session_date'] as String?;
    final notes  = s['notes'] as String?;
    DateTime? dt;
    try { dt = stRaw != null ? DateTime.parse(stRaw) : null; } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.softGray),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.saffron, AppTheme.saffron.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.self_improvement, color: Colors.white, size: 24),
        ),
        title: Text(_fmtDur(dur),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        subtitle: Text(
          dt != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(dt) : (date ?? ''),
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: notes != null && notes.isNotEmpty
            ? Tooltip(
                message: notes,
                child: const Icon(Icons.edit_note_rounded, color: Colors.blueGrey, size: 20),
              )
            : const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
        onTap: notes != null && notes.isNotEmpty
            ? () => _showNotes(dt, dur, notes)
            : null,
      ),
    );
  }

  void _showNotes(DateTime? dt, int dur, String notes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.saffron, AppTheme.saffron.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.self_improvement, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_fmtDur(dur), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (dt != null) Text(DateFormat('MMM dd, yyyy').format(dt),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
          ]),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Row(children: [
            Icon(Icons.edit_note_rounded, color: Colors.blueGrey, size: 18),
            SizedBox(width: 8),
            Text('Journal Entry', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ]),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
            ),
            child: Text(notes, style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
        ]),
      ),
    );
  }
}
