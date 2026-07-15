import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/login_gate.dart';

/// Meditation Journey page — replaces the old history page.
/// Shows 3 tabs: Journey (stats + history), Leaderboard, Achievements.
class MeditationJourneyPage extends StatefulWidget {
  const MeditationJourneyPage({Key? key}) : super(key: key);

  @override
  State<MeditationJourneyPage> createState() => _MeditationJourneyPageState();
}

class _MeditationJourneyPageState extends State<MeditationJourneyPage>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabs;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _loadingStats    = true;
  bool _loadingSessions = true;
  bool _loadingLB       = true;

  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _sessions   = [];
  List<Map<String, dynamic>> _leaderboard = [];
  String _lbType = 'total_duration';

  bool get _isLoggedIn {
    try { return FirebaseAuth.instance.currentUser != null; } catch (_) { return false; }
  }

  // ── Computed helpers ──────────────────────────────────────────────────────
  int get _currentStreak  => _parseI(_stats?['current_streak'] ?? _stats?['streak']?['current']);
  int get _longestStreak  => _parseI(_stats?['longest_streak'] ?? _stats?['streak']?['longest']);
  int get _totalSessions  => _parseI(_stats?['lifetime']?['total_sessions'] ?? _stats?['summary']?['total_sessions']);
  int get _totalSeconds   => _parseI(_stats?['lifetime']?['total_duration_seconds'] ?? _stats?['summary']?['total_duration_seconds']);
  int get _totalDays      => _parseI(_stats?['lifetime']?['total_meditation_days']);

  List<dynamic> get _daily   => (_stats?['daily']   as List?) ?? [];
  List<dynamic> get _weekly  => (_stats?['weekly']  as List?) ?? [];
  List<dynamic> get _monthly => (_stats?['monthly'] as List?) ?? [];
  List<dynamic> get _yearly  => (_stats?['yearly']  as List?) ?? [];

  String get _motivationalMsg {
    if (_currentStreak >= 30) return '🌟 Incredible! 30+ days of dedication!';
    if (_currentStreak >= 21) return '🎯 21 days — you\'ve built a solid habit!';
    if (_currentStreak >= 14) return '💪 Two weeks strong! Keep going!';
    if (_currentStreak >= 7)  return '🔥 One week streak — you\'re on fire!';
    if (_currentStreak >= 3)  return '✨ Great start! Keep building your practice!';
    if (_totalSessions > 0)   return '🌱 Every session counts. Keep growing!';
    return '🧘 Begin your journey to inner peace today!';
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() { if (_tabs.indexIsChanging && _tabs.index == 1) _loadLeaderboard(); });
    if (_isLoggedIn) _loadAll();
    else setState(() { _loadingStats = false; _loadingSessions = false; _loadingLB = false; });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadAll() => Future.wait([_loadStats(), _loadSessions(), _loadLeaderboard()]);

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final r = await _api.getMeditationStats();
      if (mounted) setState(() { _stats = r['success'] == true ? r : null; _loadingStats = false; });
    } catch (_) { if (mounted) setState(() { _loadingStats = false; }); }
  }

  Future<void> _loadSessions() async {
    setState(() => _loadingSessions = true);
    try {
      // Always load last 10 on the Journey tab — lightweight
      final r = await _api.getMeditationSessions(limit: 10, page: 1);
      if (mounted) setState(() {
        _sessions = r['success'] == true ? List<Map<String, dynamic>>.from(r['sessions'] ?? []) : [];
        _loadingSessions = false;
      });
    } catch (_) { if (mounted) setState(() => _loadingSessions = false); }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loadingLB = true);
    try {
      final now   = DateTime.now();
      final extra = _lbType == 'monthly'
          ? {'month': now.month, 'year': now.year}
          : _lbType == 'weekly'
              ? {'weekStart': _getMonday(now)}
              : <String, dynamic>{};
      final r = await _api.getMeditationLeaderboard(
        type:      _lbType,
        limit:     50,
        year:      extra['year'] as int?,
        month:     extra['month'] as int?,
        weekStart: extra['weekStart'] as String?,
        myRank:    true,
      );
      if (mounted) setState(() {
        _leaderboard = r['success'] == true
            ? List<Map<String, dynamic>>.from(r['leaderboard'] ?? [])
            : [];
        _loadingLB = false;
      });
    } catch (_) { if (mounted) setState(() => _loadingLB = false); }
  }

  String _getMonday(DateTime d) {
    final monday = d.subtract(Duration(days: d.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(monday);
  }

  // ── Formatters ────────────────────────────────────────────────────────────
  int _parseI(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _fmtDur(int secs) {
    final h = secs ~/ 3600; final m = (secs % 3600) ~/ 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  String _fmtDurSecs(int secs) {
    final h = secs ~/ 3600; final m = (secs % 3600) ~/ 60; final s = secs % 60;
    return h > 0
        ? '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}'
        : '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) return _buildLoginGate();

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
        title: const Text('Meditation Journey',
            style: TextStyle(color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.self_improvement, color: AppTheme.primary, size: 22),
            onPressed: () => context.push('/meditation/timer'),
            tooltip: 'Meditate Now',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.timeline), text: 'Journey'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Stats'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: TabBarView(
          controller: _tabs,
          children: [
            _buildJourneyTab(),
            _buildLeaderboardTab(),
            _buildStatsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/meditation/timer'),
        backgroundColor: AppTheme.saffron,
        icon: const Icon(Icons.self_improvement),
        label: const Text('Meditate Now'),
      ),
    );
  }

  // ═══════════════ JOURNEY TAB ═══════════════════════════════════════════════
  Widget _buildJourneyTab() {
    if (_loadingStats && _loadingSessions) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(children: [
        _buildMotivationalBanner(),
        const SizedBox(height: 16),
        _buildStreakRow(),
        const SizedBox(height: 16),
        _buildQuickStats(),
        const SizedBox(height: 16),
        _buildWeeklyChart(),
        const SizedBox(height: 16),
        _buildMonthlyChart(),
        const SizedBox(height: 16),
        _buildRecentSessions(),
        const SizedBox(height: 80),
      ]),
    );
  }

  Widget _buildMotivationalBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.saffron, AppTheme.saffron.withValues(alpha: 0.75)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppTheme.saffron.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0,8))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.emoji_events, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(_motivationalMsg,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4))),
      ]),
    );
  }

  Widget _buildStreakRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(child: _streakCard('Current Streak', _currentStreak, Icons.local_fire_department, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _streakCard('Longest Streak', _longestStreak, Icons.emoji_events, Colors.amber)),
        const SizedBox(width: 12),
        Expanded(child: _streakCard('Days Meditated', _totalDays, Icons.calendar_today, Colors.green)),
      ]),
    );
  }

  Widget _streakCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text('$value', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        Row(children: [
          Expanded(child: _statCard('Total Time',  _fmtDur(_totalSeconds),   Icons.timer_outlined,      AppTheme.saffron)),
          const SizedBox(width: 12),
          Expanded(child: _statCard('Sessions',    '$_totalSessions',         Icons.self_improvement,    Colors.purple)),
        ]),
      ]),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.softGray),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ]),
      ]),
    );
  }

  // ── Weekly bar chart (last 7 days from daily summary) ─────────────────────
  Widget _buildWeeklyChart() {
    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));

    final Map<String, double> dm = { for (var d in days) DateFormat('yyyy-MM-dd').format(d): 0.0 };

    for (final row in _daily) {
      final key = (row['meditation_date'] as String?)?.split('T').first ?? '';
      if (dm.containsKey(key)) {
        dm[key] = (dm[key]! + (_parseI(row['total_duration_seconds']) / 60));
      }
    }
    // Also pull from sessions if daily is empty
    if (_daily.isEmpty) {
      for (final s in _sessions) {
        final st = s['started_at'] as String? ?? s['start_time'] as String?;
        if (st == null) continue;
        try {
          final key = st.split('T').first;
          if (dm.containsKey(key)) dm[key] = dm[key]! + (_parseI(s['duration_seconds']) / 60);
        } catch (_) {}
      }
    }

    final maxY = dm.values.isEmpty ? 10.0 : (dm.values.reduce((a,b)=>a>b?a:b)*1.25).ceilToDouble().clamp(10.0, double.infinity);

    return _chartCard(
      title: 'Last 7 Days (minutes)',
      child: SizedBox(
        height: 180,
        child: BarChart(BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (g, gi, rod, ri) =>
                  BarTooltipItem('${rod.toY.toInt()}m', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
              final i = v.toInt();
              return i >= 0 && i < days.length
                  ? Padding(padding: const EdgeInsets.only(top: 4),
                      child: Text(DateFormat('E').format(days[i]), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)))
                  : const SizedBox();
            })),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
                getTitlesWidget: (v, _) => Text('${v.toInt()}m', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)))),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.softGray, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(days.length, (i) {
            final key    = DateFormat('yyyy-MM-dd').format(days[i]);
            final mins   = dm[key] ?? 0;
            final isToday = DateFormat('yyyy-MM-dd').format(now) == key;
            return BarChartGroupData(x: i, barRods: [BarChartRodData(
              toY: mins,
              gradient: LinearGradient(
                colors: isToday ? [AppTheme.saffron, AppTheme.saffron.withValues(alpha: 0.7)]
                    : [Colors.deepPurple, Colors.deepPurple.withValues(alpha: 0.6)],
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
              ),
              width: 22, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            )]);
          }),
        )),
      ),
    );
  }

  // ── Monthly chart (last 6 months from monthly summary) ───────────────────
  Widget _buildMonthlyChart() {
    if (_monthly.isEmpty) return const SizedBox();
    final last6 = _monthly.take(6).toList().reversed.toList();
    final maxY  = last6.map((r) => _parseI(r['total_duration_seconds']) / 3600.0)
        .fold(0.0, (a, b) => a > b ? a : b);

    return _chartCard(
      title: 'Monthly Hours',
      child: SizedBox(
        height: 160,
        child: BarChart(BarChartData(
          maxY: (maxY * 1.2).ceilToDouble().clamp(1.0, double.infinity),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= last6.length) return const SizedBox();
              final monthNames = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
              final m = _parseI(last6[i]['month']);
              return Padding(padding: const EdgeInsets.only(top: 4),
                  child: Text(monthNames[m], style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)));
            })),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32,
                getTitlesWidget: (v, _) => Text('${v.toInt()}h', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)))),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.softGray, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(last6.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(
            toY: _parseI(last6[i]['total_duration_seconds']) / 3600.0,
            color: AppTheme.primary.withValues(alpha: 0.8),
            width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          )])),
        )),
      ),
    );
  }

  Widget _chartCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softGray),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  // ── Recent sessions list (last 10 only, lightweight) ──────────────────────
  Widget _buildRecentSessions() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          children: [
            const Text('Recent Sessions',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const Spacer(),
            // "View All" button → dedicated sessions page with filters + pagination
            GestureDetector(
              onTap: () => context.push('/meditation/sessions'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Text('View All',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppTheme.primary),
                ]),
              ),
            ),
          ],
        ),
      ),
      if (_loadingSessions)
        const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
      else if (_sessions.isEmpty)
        Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Column(children: [
            Icon(Icons.self_improvement, size: 56, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text('No sessions yet', style: TextStyle(color: AppTheme.textSecondary)),
          ])),
        )
      else
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _sessions.length,
          itemBuilder: (_, i) => _sessionCard(_sessions[i]),
        ),
    ]);
  }

  Widget _sessionCard(Map<String, dynamic> s) {
    final dur   = _parseI(s['duration_seconds']);
    final stRaw = s['started_at'] as String? ?? s['start_time'] as String?;
    final notes = s['notes'] as String? ?? s['remarks'] as String?;
    DateTime? dt;
    try { dt = stRaw != null ? DateTime.parse(stRaw) : null; } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.softGray),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.saffron, AppTheme.saffron.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.self_improvement, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_fmtDurSecs(dur),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(dt != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(dt) : '—',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(notes, style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ])),
        const Icon(Icons.check_circle, color: Colors.green, size: 20),
      ]),
    );
  }

  // ═══════════════ LEADERBOARD TAB ══════════════════════════════════════════
  Widget _buildLeaderboardTab() {
    return Column(children: [
      // ── Type selector ─────────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        color: Colors.white,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _lbChip('All Time',       'total_duration'),
            _lbChip('Sessions',       'total_sessions'),
            _lbChip('Most Days',      'total_days'),
            _lbChip('This Week',      'weekly'),
            _lbChip('This Month',     'monthly'),
          ]),
        ),
      ),
      // ── List ──────────────────────────────────────────────────────────────
      Expanded(child: _loadingLB
          ? const Center(child: CircularProgressIndicator())
          : _leaderboard.isEmpty
              ? _emptyState('No data yet for this category')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _leaderboard.length,
                  itemBuilder: (_, i) => _lbCard(_leaderboard[i], i),
                )),
    ]);
  }

  Widget _lbChip(String label, String type) {
    final sel = _lbType == type;
    return GestureDetector(
      onTap: () { setState(() => _lbType = type); _loadLeaderboard(); },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:        sel ? AppTheme.primary : AppTheme.tagBg,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: sel ? AppTheme.primary : AppTheme.softGray),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: sel ? Colors.white : AppTheme.textSecondary,
        )),
      ),
    );
  }

  Widget _lbCard(Map<String, dynamic> entry, int index) {
    final rank     = _parseI(entry['rank'] ?? (index + 1));
    final name     = entry['user_name'] as String? ?? 'Anonymous';
    final photo    = entry['user_photo'] as String?;
    final secs     = _parseI(entry['total_duration_seconds']);
    final sessions = _parseI(entry['total_sessions']);
    final days     = _parseI(entry['total_meditation_days']);

    Color rankColor = AppTheme.textSecondary;
    IconData? rankIcon;
    if (rank == 1) { rankColor = const Color(0xFFFFD700); rankIcon = Icons.emoji_events; }
    else if (rank == 2) { rankColor = const Color(0xFFC0C0C0); rankIcon = Icons.emoji_events; }
    else if (rank == 3) { rankColor = const Color(0xFFCD7F32); rankIcon = Icons.emoji_events; }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        rank <= 3 ? rankColor.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: rank <= 3 ? rankColor.withValues(alpha: 0.4) : AppTheme.softGray),
      ),
      child: Row(children: [
        // Rank badge
        SizedBox(width: 36, child: rankIcon != null
            ? Icon(rankIcon, color: rankColor, size: 28)
            : Text('#$rank', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: rankColor))),
        const SizedBox(width: 8),
        // Avatar
        CircleAvatar(
          radius: 22,
          backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: photo == null || photo.isEmpty
              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('$sessions sessions • $days days', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ])),
        // Duration badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_fmtDur(secs),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ),
      ]),
    );
  }

  // ═══════════════ STATS TAB ════════════════════════════════════════════════
  Widget _buildStatsTab() {
    if (_loadingStats) return const Center(child: CircularProgressIndicator());
    if (_stats == null) return _emptyState('No stats available yet');

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Lifetime totals ──────────────────────────────────────────────────
        _sectionTitle('Lifetime'),
        _lifetimeGrid(),
        const SizedBox(height: 20),
        // ── Yearly breakdown ─────────────────────────────────────────────────
        if (_yearly.isNotEmpty) ...[
          _sectionTitle('Yearly Breakdown'),
          ..._yearly.map((y) => _yearCard(y)),
          const SizedBox(height: 20),
        ],
        // ── Monthly breakdown ────────────────────────────────────────────────
        if (_monthly.isNotEmpty) ...[
          _sectionTitle('Monthly Breakdown (recent)'),
          ..._monthly.take(6).map((m) => _monthCard(m)),
          const SizedBox(height: 20),
        ],
      ]),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
  );

  Widget _lifetimeGrid() {
    final lt = _stats?['lifetime'] as Map<String,dynamic>?;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.4,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _miniStat('Total Time',    _fmtDur(_totalSeconds),     Icons.timer_outlined,      AppTheme.saffron),
        _miniStat('Sessions',      '$_totalSessions',           Icons.self_improvement,    Colors.purple),
        _miniStat('Days',          '$_totalDays',               Icons.calendar_today,      Colors.green),
        _miniStat('Current Streak','$_currentStreak days',      Icons.local_fire_department,Colors.orange),
        _miniStat('Best Streak',   '$_longestStreak days',      Icons.emoji_events,        Colors.amber),
        _miniStat('First Session', _fmtDate(lt?['first_meditation_date']), Icons.flag, Colors.blue),
      ],
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.softGray),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ])),
      ]),
    );
  }

  Widget _yearCard(Map<String, dynamic> y) {
    final year = _parseI(y['year']);
    final secs = _parseI(y['total_duration_seconds']);
    final sess = _parseI(y['total_sessions']);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.softGray)),
      child: Row(children: [
        Text('$year', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_fmtDur(secs), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          Text('$sess sessions', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ])),
      ]),
    );
  }

  Widget _monthCard(Map<String, dynamic> m) {
    final monthNames = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final mon  = _parseI(m['month']);
    final year = _parseI(m['year']);
    final secs = _parseI(m['total_duration_seconds']);
    final sess = _parseI(m['total_sessions']);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.softGray)),
      child: Row(children: [
        SizedBox(width: 52, child: Text('${monthNames[mon]}\n$year',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary), textAlign: TextAlign.center)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_fmtDur(secs), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Text('$sess sessions', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ])),
      ]),
    );
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '—';
    try { return DateFormat('MMM dd, yyyy').format(DateTime.parse(v.toString())); } catch (_) { return '—'; }
  }

  Widget _emptyState(String msg) => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.self_improvement, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.35)),
      const SizedBox(height: 16),
      Text(msg, style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
    ]),
  ));

  // ── Login gate ────────────────────────────────────────────────────────────
  Widget _buildLoginGate() => LoginGate(
    title: 'Meditation Journey',
    featureHint: '🧘 Track streaks, stats and compete on the leaderboard',
    showBackButton: true,
  );
}
