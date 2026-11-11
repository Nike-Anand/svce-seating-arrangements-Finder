import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/seating_models.dart';

class LocalDataService {
  final Dio _dio = Dio();
  List<SeatingResult> _cachedData = [];
  DateTime? _lastUpdated;

  Future<void> refreshData() async {
    try {
      _dio.options.headers = {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36',
      };
      _dio.options.connectTimeout = const Duration(seconds: 30);
      _dio.options.receiveTimeout = const Duration(seconds: 60);

      final response =
          await _dio.get('https://www.svce.ac.in/coe-ims/files.php');
      final document = parse(response.data);

      final rows = document.querySelectorAll('tbody tr');
      final List<SeatingResult> allResults = [];

      // Limit to first 5 PDFs for testing to avoid timeout
      final maxPdfs = rows.length > 5 ? 5 : rows.length;

      for (int i = 0; i < maxPdfs; i++) {
        final row = rows[i];
        final cells = row.querySelectorAll('td');
        if (cells.length >= 4) {
          final date = cells[1].text.trim();
          final session = cells[2].text.trim();
          final link = cells[3].querySelector('a');

          if (link != null) {
            final href = link.attributes['href'];
            if (href != null) {
              final fullUrl = 'https://www.svce.ac.in/coe-ims/$href';

              try {
                final pdfResults =
                    await _downloadAndParsePdf(fullUrl, date, session);
                allResults.addAll(pdfResults);
              } catch (e) {
                continue;
              }
            }
          }
        }
      }

      if (allResults.isEmpty) {
        throw Exception('No data could be extracted from any PDF files');
      }

      _cachedData = allResults;
      _lastUpdated = DateTime.now();
      await _saveToLocal();
    } catch (e) {
      throw Exception('Failed to refresh data: $e');
    }
  }

  Future<List<SeatingResult>> _downloadAndParsePdf(
      String url, String date, String session) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.data == null || response.data.isEmpty) {
        throw Exception('Empty PDF data received');
      }

      final document = PdfDocument(inputBytes: response.data);
      final List<SeatingResult> results = [];

      try {
        final textExtractor = PdfTextExtractor(document);
        final fullText = textExtractor.extractText();

        if (fullText.isEmpty) {
          throw Exception('No text could be extracted from PDF');
        }

        final regex = RegExp(
          r'(\d{13})' // Register number: exactly 13 digits
          r'\s*' // Optional whitespace
          r'([\d-]+)' // Hall number: digits and dashes
          r'(.+?)' // Hall description: any characters (non-greedy)
          r'([A-Z]\d{1,2})' // Seat position (e.g., C5, A2, L10)
          r'\s+(\d+)' // Serial number
        );

        final matches = regex.allMatches(fullText);

        for (final match in matches) {
          final registerNo = match.group(1)!;
          final hallNo = match.group(2) ?? '';
          final hallDesc = match.group(3) ?? '';
          final seat = match.group(4) ?? 'N/A';
          // Group 5 is the serial number (not used but validates the match)

          // Combine hall number and description, clean up whitespace
          String hall = '$hallNo - ${hallDesc.trim().replaceAll(RegExp(r'\s+'), ' ')}';

          results.add(SeatingResult(
            registerNo: registerNo,
            hall: hall,
            seat: seat,
            examDate: date,
            session: session,
            pdfUrl: url,
          ));
        }
      } finally {
        document.dispose();
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveToLocal() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/seating_data.json');

    final data = {
      'last_updated': _lastUpdated?.toIso8601String(),
      'total_entries': _cachedData.length,
      'data': _cachedData
          .map((e) => {
                'register_no': e.registerNo,
                'hall': e.hall,
                'seat': e.seat,
                'exam_date': e.examDate,
                'session': e.session,
                'pdf_url': e.pdfUrl,
              })
          .toList(),
    };

    await file.writeAsString(json.encode(data));
  }

  Future<void> _loadFromLocal() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/seating_data.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content);

        _lastUpdated = data['last_updated'] != null
            ? DateTime.parse(data['last_updated'])
            : null;

        _cachedData = (data['data'] as List)
            .map((e) => SeatingResult.fromJson(e))
            .toList();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<SearchResponse> searchRegister(String registerNo) async {
    if (_cachedData.isEmpty) {
      await _loadFromLocal();
    }

    final results = _cachedData
        .where(
            (e) => e.registerNo.toUpperCase().contains(registerNo.toUpperCase()))
        .toList();

    return SearchResponse(
      registerNo: registerNo,
      found: results.isNotEmpty,
      results: results,
      lastUpdated: _lastUpdated?.toIso8601String() ?? '',
    );
  }

  Future<StatsResponse> getStats() async {
    if (_cachedData.isEmpty) {
      await _loadFromLocal();
    }

    return StatsResponse(
      lastUpdated: _lastUpdated?.toIso8601String(),
      totalEntries: _cachedData.length,
      available: _cachedData.isNotEmpty,
    );
  }
}