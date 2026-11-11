class SeatingResult {
  final String registerNo;
  final String hall;
  final String seat;
  final String examDate;
  final String session;
  final String? pdfUrl;

  SeatingResult({
    required this.registerNo,
    required this.hall,
    required this.seat,
    required this.examDate,
    required this.session,
    this.pdfUrl,
  });

  factory SeatingResult.fromJson(Map<String, dynamic> json) {
    return SeatingResult(
      registerNo: json['register_no'] ?? '',
      hall: json['hall'] ?? 'N/A',
      seat: json['seat'] ?? 'N/A',
      examDate: json['exam_date'] ?? '',
      session: json['session'] ?? '',
      pdfUrl: json['pdf_url'],
    );
  }
}

class SearchResponse {
  final String registerNo;
  final bool found;
  final List<SeatingResult> results;
  final String lastUpdated;

  SearchResponse({
    required this.registerNo,
    required this.found,
    required this.results,
    required this.lastUpdated,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      registerNo: json['register_no'] ?? '',
      found: json['found'] ?? false,
      results: (json['results'] as List?)
          ?.map((e) => SeatingResult.fromJson(e))
          .toList() ?? [],
      lastUpdated: json['last_updated'] ?? '',
    );
  }
}

class StatsResponse {
  final String? lastUpdated;
  final int totalEntries;
  final bool available;

  StatsResponse({
    this.lastUpdated,
    required this.totalEntries,
    required this.available,
  });

  factory StatsResponse.fromJson(Map<String, dynamic> json) {
    return StatsResponse(
      lastUpdated: json['last_updated'],
      totalEntries: json['total_entries'] ?? 0,
      available: json['available'] ?? false,
    );
  }
}