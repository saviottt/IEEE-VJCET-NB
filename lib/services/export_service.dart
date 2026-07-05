import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';

class ExportService {
  static final ExportService instance = ExportService._internal();
  ExportService._internal();

  // Export Events list to CSV format and trigger browser download
  Future<void> exportToCSV(List<Event> events) async {
    final List<List<String>> rows = [
      [
        'Title',
        'Description',
        'Venue',
        'Organizer',
        'Start Date & Time',
        'End Date & Time',
        'Category',
        'Registration Link',
        'Max Participants',
        'Pinned'
      ]
    ];

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    for (final event in events) {
      rows.add([
        event.title,
        event.description ?? '',
        event.venue,
        event.organizer,
        dateFormat.format(event.startDatetime),
        dateFormat.format(event.endDatetime),
        event.category?.name ?? 'Other',
        event.registrationLink ?? '',
        event.maxParticipants?.toString() ?? 'Unlimited',
        event.isPinned ? 'Yes' : 'No'
      ]);
    }

    // Convert to CSV string (handling quotes and commas)
    final csvContent = rows.map((row) {
      return row.map((field) {
        // Escape quotes
        final escaped = field.replaceAll('"', '""');
        return '"$escaped"';
      }).join(',');
    }).join('\n');

    try {
      final bytes = utf8.encode(csvContent);
      
      if (kIsWeb) {
        final base64Csv = base64.encode(bytes);
        final url = 'data:text/csv;base64,$base64Csv';
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (kDebugMode) print('Could not launch CSV download URL');
        }
      } else {
        // Use the printing package to share the CSV bytes natively on mobile/desktop
        await Printing.sharePdf(
          bytes: Uint8List.fromList(bytes),
          filename: 'IEEE_Calender_Events_Schedule.csv',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error exporting CSV: $e');
    }
  }

  // Export Events to a beautiful PDF report and trigger printing/saving
  Future<void> exportToPDF(List<Event> events, String title) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('EEE, MMM d, yyyy • h:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // PDF Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'IEEE Calender',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#6366F1'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 1, color: PdfColor.fromHex('#E2E8F0')),
            pw.SizedBox(height: 16),

            // Event List
            pw.ListView.builder(
              itemCount: events.length,
              itemBuilder: (pw.Context context, int index) {
                final event = events[index];
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 16),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              event.title,
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#0F172A'),
                              ),
                            ),
                          ),
                          if (event.category != null)
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex(event.category!.color).shade(0.1),
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                              ),
                              child: pw.Text(
                                event.category!.name,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex(event.category!.color),
                                ),
                              ),
                            ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Text(
                            'When: ',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          ),
                          pw.Text(
                            '${dateFormat.format(event.startDatetime)} - ${dateFormat.format(event.endDatetime)}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Venue: ',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          ),
                          pw.Text(event.venue, style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Organizer: ',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                          ),
                          pw.Text(event.organizer, style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      if (event.description != null && event.description!.isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.Text(
                          event.description!,
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ];
        },
      ),
    );

    // Print / Save PDF via native sharing
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'IEEE_Calender_Events_Schedule.pdf',
    );
  }
}
