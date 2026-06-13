import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/app_models.dart';
import '../state/app_controller.dart';

enum ReportGroupBy { daily, monthly }

const _navy       = PdfColor.fromInt(0xFF0D1B2A);
const _blue       = PdfColor.fromInt(0xFF1565C0);
const _lightBlue  = PdfColor.fromInt(0xFFE3F2FD);
const _accentBlue = PdfColor.fromInt(0xFF42A5F5);
const _white      = PdfColors.white;
const _borderGrey = PdfColor.fromInt(0xFFDDE3EE);
const _textDark   = PdfColor.fromInt(0xFF0D1B2A);
const _textMid    = PdfColor.fromInt(0xFF4A5568);
const _textLight  = PdfColor.fromInt(0xFF8A9BB0);
const _rowAlt     = PdfColor.fromInt(0xFFF0F4FA);

String _fmt(DateTime d) {
  const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${d.day.toString().padLeft(2,'0')} ${m[d.month-1]} ${d.year}';
}

String _fmtTs(String? ts) {
  if (ts == null || ts.isEmpty) return 'Never';
  final d = DateTime.tryParse(ts)?.toLocal();
  return d == null ? ts : _fmt(d);
}

String _dur(int s) {
  if (s < 60) return '${s}s';
  if (s < 3600) return '${s ~/ 60}m ${s % 60}s';
  return '${s ~/ 3600}h ${(s % 3600) ~/ 60}m';
}

String _formatPeriodKey(String key, ReportGroupBy groupBy) {
  if (groupBy == ReportGroupBy.daily) {
    final d = DateTime.tryParse(key);
    return d == null ? key : _fmt(d);
  }
  final parts = key.split('-');
  if (parts.length < 2) return key;
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final month = int.tryParse(parts[1]) ?? 1;
  return '${months[month - 1]} ${parts[0]}';
}

class ReportPdfService {
  static Future<Uint8List> generateClientReport({
    required ClientProfile client,
    required AppController controller,
    required DateTime startDate,
    required DateTime endDate,
    required ReportGroupBy groupBy,
    Map<String, Uint8List>? videoThumbnails,
  }) async {
    final pdf = pw.Document();

    // Load logo — skip if it fails
    pw.ImageProvider? logoImage;
    try {
      final data = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    // Use end-of-day so same-day stats with timestamp are included
    final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final mediaSummaries = controller.mediaSummariesForClient(client.id, from: startDate, to: endOfDay);
    final screens    = controller.screens;
    final totalPlays = mediaSummaries.fold<int>(0, (s, m) => s + m.playCount);
    final totalSecs  = mediaSummaries.fold<int>(0, (s, m) => s + m.playTimeSeconds);
    final dateStr    = '${_fmt(startDate)} to ${_fmt(endDate)}';

    // Screen breakdown
    final screenRows = <({ScreenDevice screen, int plays, int secs})>[];
    for (final screen in screens) {
      int p = 0, sec = 0;
      for (final summary in mediaSummaries) {
        for (final stat in controller.playbackForScreen(screen.id, from: startDate, to: endOfDay)) {
          if (stat.mediaId == summary.media.id) {
            p += stat.playCount;
            sec += stat.playCount * summary.media.durationSeconds;
          }
        }
      }
      if (p > 0) screenRows.add((screen: screen, plays: p, secs: sec));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        footer: (_) => _footer(),
        build: (ctx) {
          final widgets = <pw.Widget>[];

          widgets.add(_headerBar(logoImage, client, dateStr));
          widgets.add(pw.SizedBox(height: 20));

          widgets.add(_statRow(mediaSummaries.length, totalPlays, totalSecs));
          widgets.add(pw.SizedBox(height: 24));

          if (screenRows.isNotEmpty) {
            widgets.add(_sectionTitle('SCREEN BREAKDOWN'));
            widgets.add(pw.SizedBox(height: 10));
            widgets.add(pw.Table.fromTextArray(
              headers: ['SCREEN', 'LOCATION', 'PLAYS', 'PLAY TIME'],
              data: screenRows.map((r) => [
                r.screen.name,
                r.screen.location.isEmpty ? '—' : r.screen.location,
                '${r.plays}',
                _dur(r.secs),
              ]).toList(),
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _white),
              headerDecoration: const pw.BoxDecoration(color: _navy),
              cellStyle: const pw.TextStyle(fontSize: 10, color: _textDark),
              oddRowDecoration: const pw.BoxDecoration(color: _rowAlt),
              border: pw.TableBorder.all(color: _borderGrey, width: 0.5),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
              },
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ));
            widgets.add(pw.SizedBox(height: 24));
          }

          widgets.add(_sectionTitle('MEDIA BREAKDOWN'));
          widgets.add(pw.SizedBox(height: 10));

          for (int i = 0; i < mediaSummaries.length; i++) {
            final summary = mediaSummaries[i];
            final item    = summary.media;

            String? latestTs(String? a, String? b) {
              final da = DateTime.tryParse(a ?? '');
              final db = DateTime.tryParse(b ?? '');
              if (da == null) return b;
              if (db == null) return a;
              return db.isAfter(da) ? b : a;
            }

            // Per-screen stats
            final byScreen = <String, ({int plays, String? last})>{};
            for (final stat in controller.playbackForMedia(item.id, from: startDate, to: endOfDay)) {
              final cur = byScreen[stat.screenId];
              byScreen[stat.screenId] = (
                plays: (cur?.plays ?? 0) + stat.playCount,
                last: latestTs(cur?.last, stat.lastPlayedAt),
              );
            }

            final screenLines = <String>[];
            for (final screen in screens) {
              final stat = byScreen[screen.id];
              if (stat == null || stat.plays <= 0) continue;
              screenLines.add('${screen.name}: ${stat.plays} plays  |  last: ${_fmtTs(stat.last)}');
            }

            // Period breakdown — prefer playDate, fall back to lastPlayedAt date part
            final Map<String, int> periodPlays = {};
            for (final stat in controller.playbackForMedia(item.id, from: startDate, to: endOfDay)) {
              final raw = (stat.playDate != null && stat.playDate!.isNotEmpty)
                  ? stat.playDate!
                  : (stat.lastPlayedAt ?? '');
              if (raw.isEmpty) continue;
              final d = DateTime.tryParse(raw)?.toLocal();
              if (d == null) continue;
              final key = groupBy == ReportGroupBy.daily
                  ? '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}'
                  : '${d.year}-${d.month.toString().padLeft(2,'0')}';
              periodPlays[key] = (periodPlays[key] ?? 0) + stat.playCount;
            }
            final sortedPeriods = periodPlays.keys.toList()..sort();

            widgets.add(pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _borderGrey, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: const pw.BoxDecoration(
                      color: _navy,
                      borderRadius: pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(5),
                        topRight: pw.Radius.circular(5),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${item.kind == MediaKind.video ? 'VIDEO' : 'IMAGE'} ${i + 1}  —  ${item.title}',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _white),
                        ),
                        pw.Text(
                          '${summary.playCount} plays  |  ${_dur(summary.playTimeSeconds)}',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _accentBlue),
                        ),
                      ],
                    ),
                  ),
                  if (screenLines.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.fromLTRB(14, 10, 14, 0),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: screenLines.map((line) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Text(line, style: const pw.TextStyle(fontSize: 9, color: _textDark)),
                        )).toList(),
                      ),
                    ),
                  if (sortedPeriods.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.fromLTRB(14, 10, 14, 12),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            groupBy == ReportGroupBy.daily ? 'Daily Breakdown' : 'Monthly Breakdown',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _textMid),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Table.fromTextArray(
                            headers: [groupBy == ReportGroupBy.daily ? 'DATE' : 'MONTH', 'PLAYS'],
                            data: sortedPeriods.map((k) => [_formatPeriodKey(k, groupBy), '${periodPlays[k]}']).toList(),
                            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _white),
                            headerDecoration: const pw.BoxDecoration(color: _blue),
                            cellStyle: const pw.TextStyle(fontSize: 9, color: _textDark),
                            oddRowDecoration: const pw.BoxDecoration(color: _rowAlt),
                            border: pw.TableBorder.all(color: _borderGrey, width: 0.4),
                            cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.center},
                            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          ),
                        ],
                      ),
                    )
                  else
                    pw.SizedBox(height: 10),
                ],
              ),
            ));
          }

          widgets.add(pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: _lightBlue,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'This report provides the summary of TV advertisement playback across screens during the selected period.',
                    style: const pw.TextStyle(fontSize: 9, color: _textMid),
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Thank you!',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _navy)),
                    pw.Text('for choosing Brand Slots',
                        style: pw.TextStyle(fontSize: 9, color: _blue)),
                  ],
                ),
              ],
            ),
          ));

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _headerBar(pw.ImageProvider? logo, ClientProfile client, String dateStr) {
    return pw.Container(
      height: 130,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            width: 180,
            color: _white,
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (logo != null)
                  pw.Image(logo, width: 80, height: 44, fit: pw.BoxFit.contain)
                else
                  pw.Text('BRAND SLOTS',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _navy)),
                pw.SizedBox(height: 8),
                pw.Text('THE SMARTEST WAY TO GROW YOUR BRAND',
                    style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: _textMid)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              color: _navy,
              padding: const pw.EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('TV ADVERTISEMENT',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _white)),
                  pw.Text('PLAYBACK REPORT',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _accentBlue)),
                  pw.SizedBox(height: 12),
                  pw.Text('PERIOD: $dateStr',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _accentBlue)),
                  pw.SizedBox(height: 4),
                  pw.Text('CLIENT: ${client.name}',
                      style: const pw.TextStyle(fontSize: 9, color: _white)),
                  if (client.contactName.isNotEmpty)
                    pw.Text('CONTACT: ${client.contactName}',
                        style: const pw.TextStyle(fontSize: 9, color: _white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _statRow(int media, int plays, int secs) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderGrey, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        children: [
          _statCell('TOTAL MEDIA', '$media'),
          pw.Container(width: 0.8, height: 50, color: _borderGrey),
          _statCell('TOTAL PLAYS', '$plays'),
          pw.Container(width: 0.8, height: 50, color: _borderGrey),
          _statCell('TOTAL PLAY TIME', _dur(secs)),
        ],
      ),
    );
  }

  static pw.Widget _statCell(String label, String value) {
    return pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _textMid)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _textDark)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Row(
      children: [
        pw.Container(width: 4, height: 18, color: _blue),
        pw.SizedBox(width: 8),
        pw.Text(title,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _textDark)),
      ],
    );
  }

  static pw.Widget _footer() {
    return pw.Container(
      color: _navy,
      padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('+91 7356 506 639', style: const pw.TextStyle(fontSize: 8, color: _white)),
          pw.Text('+91 8593 945 350', style: const pw.TextStyle(fontSize: 8, color: _white)),
          pw.Text('Ads.brandslots@gmail.com', style: const pw.TextStyle(fontSize: 8, color: _white)),
          pw.Text('brand_slots_', style: const pw.TextStyle(fontSize: 8, color: _white)),
          pw.Text('Brand Slots', style: const pw.TextStyle(fontSize: 8, color: _white)),
        ],
      ),
    );
  }
}
