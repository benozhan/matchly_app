import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

// ── Config ────────────────────────────────────────────────────────────────────

/// Base URL of the KuponBot VPS API.
/// Override with your actual VPS IP / domain.
const String _kBaseUrl = 'http://167.172.182.128:8001';

const Duration _kTimeout = Duration(seconds: 8);

// ── Model ─────────────────────────────────────────────────────────────────────

class MatchResult {
  final String id;
  final String home;
  final String away;
  final String league;
  final String time;

  const MatchResult({
    required this.id,
    required this.home,
    required this.away,
    required this.league,
    required this.time,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) => MatchResult(
        id:     json['id']     as String? ?? '',
        home:   json['home']   as String? ?? '',
        away:   json['away']   as String? ?? '',
        league: json['league'] as String? ?? '',
        time:   json['time']   as String? ?? '',
      );

  /// Display label shown in search results: "Home – Away".
  String get matchLabel => '$home – $away';

  /// Short label for league + time chip.
  String get metaLabel => '$league · $time';

  @override
  String toString() => 'MatchResult($home vs $away, $league, $time)';
}

// ── Service ───────────────────────────────────────────────────────────────────

class MatchSearchService {
  MatchSearchService._();
  static final MatchSearchService instance = MatchSearchService._();

  final http.Client _client = http.Client();

  /// Search for matches by query string.
  /// Pass an empty string to get upcoming matches.
  /// Throws [MatchSearchException] on network / parse errors.
  Future<List<MatchResult>> search(String query) async {
    final uri = Uri.parse('$_kBaseUrl/api/matches/search')
        .replace(queryParameters: query.trim().isEmpty ? {} : {'q': query.trim()});

    try {
      final response = await _client.get(uri).timeout(_kTimeout);

      if (response.statusCode != 200) {
        throw MatchSearchException(
          'Server returned ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> body = jsonDecode(response.body) as List<dynamic>;
      return body
          .cast<Map<String, dynamic>>()
          .map(MatchResult.fromJson)
          .toList();
    } on MatchSearchException {
      rethrow;
    } on SocketException catch (e) {
      throw MatchSearchException('No connection: ${e.message}');
    } on HttpException catch (e) {
      throw MatchSearchException('HTTP error: ${e.message}');
    } catch (e) {
      throw MatchSearchException('Unexpected error: $e');
    }
  }

  void dispose() => _client.close();
}

// ── Exception ─────────────────────────────────────────────────────────────────

class MatchSearchException implements Exception {
  final String message;
  final int? statusCode;
  const MatchSearchException(this.message, {this.statusCode});

  @override
  String toString() => 'MatchSearchException: $message';
}

// ── Live Match Model ──────────────────────────────────────────────────────────

class LiveMatch {
  final String id;
  final String home;
  final String away;
  final String homeScore;
  final String awayScore;
  final String minute;
  final String status;
  final String league;

  const LiveMatch({
    required this.id,
    required this.home,
    required this.away,
    required this.homeScore,
    required this.awayScore,
    required this.minute,
    required this.status,
    required this.league,
  });

  factory LiveMatch.fromJson(Map<String, dynamic> json) => LiveMatch(
        id: json['id'] as String? ?? '',
        home: json['home'] as String? ?? '',
        away: json['away'] as String? ?? '',
        homeScore: json['home_score'] as String? ?? '-',
        awayScore: json['away_score'] as String? ?? '-',
        minute: json['minute'] as String? ?? '',
        status: json['status'] as String? ?? '',
        league: json['league'] as String? ?? '',
      );

  bool get isLive => status == 'live';
  bool get isPre => status == 'pre';
  bool get isPost => status == 'post';

  String get scoreText => isLive || isPost ? '$homeScore - $awayScore' : 'vs';
}

// ── Live Match Service ────────────────────────────────────────────────────────

extension LiveMatchService on MatchSearchService {
  Future<List<LiveMatch>> getLiveMatches() async {
    final uri = Uri.parse('$_kBaseUrl/api/matches/live');
    try {
      final response = await _client.get(uri).timeout(_kTimeout);
      if (response.statusCode != 200) return [];
      final List<dynamic> body = jsonDecode(response.body) as List<dynamic>;
      return body.cast<Map<String, dynamic>>().map(LiveMatch.fromJson).toList();
    } catch (e) {
      return [];
    }
  }
}
