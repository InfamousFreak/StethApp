import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_profile.dart';
import 'package:intl/intl.dart';

class PdfReportService {
  static Future<File> generateMedicalReport(
    UserProfile profile, {
    int? riskPercentage,
    String? recommendation,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),

            // Patient Information
            _buildSectionTitle('Patient Information'),
            pw.SizedBox(height: 10),
            _buildInfoRow('Name:', profile.name),
            _buildInfoRow('Age:', '${profile.age} years'),
            _buildInfoRow('Sex:', profile.sex),
            pw.SizedBox(height: 20),

            // Medical History
            _buildSectionTitle('Medical Conditions'),
            pw.SizedBox(height: 10),
            if (profile.medicalProblems.isEmpty)
              pw.Text('No pre-existing conditions reported',
                  style: const pw.TextStyle(fontSize: 12))
            else
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: profile.medicalProblems
                    .map((problem) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 5),
                          child: pw.Row(
                            children: [
                              pw.Text('• ', style: const pw.TextStyle(fontSize: 12)),
                              pw.Text(problem, style: const pw.TextStyle(fontSize: 12)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            pw.SizedBox(height: 20),

            // Risk Assessment
            if (riskPercentage != null) ...[
              _buildSectionTitle('Risk Assessment'),
              pw.SizedBox(height: 10),
              _buildRiskAssessment(riskPercentage, recommendation),
              pw.SizedBox(height: 20),
            ],

            // Latest Diagnosis
            if (profile.lastDiagnosis != null) ...[
              _buildSectionTitle('Latest Diagnosis'),
              pw.SizedBox(height: 10),
              _buildInfoRow('Diagnosis:', profile.lastDiagnosis!),
              if (profile.lastHeartRate != null)
                _buildInfoRow('Heart Rate:', '${profile.lastHeartRate!.toStringAsFixed(1)} BPM'),
              if (profile.lastDiagnosisDate != null)
                _buildInfoRow(
                  'Date:',
                  DateFormat('MMM dd, yyyy HH:mm').format(profile.lastDiagnosisDate!),
                ),
              pw.SizedBox(height: 20),
            ],

            // Diagnosis History
            if (profile.diagnosisHistory.isNotEmpty) ...[
              _buildSectionTitle('Diagnosis History'),
              pw.SizedBox(height: 10),
              _buildDiagnosisTable(profile.diagnosisHistory),
              pw.SizedBox(height: 20),
            ],

            // Statistics
            if (profile.diagnosisHistory.isNotEmpty) ...[
              _buildSectionTitle('Statistics'),
              pw.SizedBox(height: 10),
              _buildStatistics(profile),
            ],

            // Footer
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 10),
            _buildFooter(),
          ];
        },
      ),
    );

    // Save the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/medical_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'AI Stethoscope',
          style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Medical Diagnosis Report',
          style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Generated: ${DateFormat('MMMM dd, yyyy - HH:mm').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue900,
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRiskAssessment(int riskPercentage, String? recommendation) {
    final riskColor = riskPercentage <= 5 ? PdfColors.green700 : PdfColors.orange700;
    final riskLevel = riskPercentage <= 5 ? 'Low Risk' : 'Moderate Risk';
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: riskColor, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        color: riskPercentage <= 5 ? PdfColors.green50 : PdfColors.orange50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Risk Level: $riskLevel',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: riskColor,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: riskColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                child: pw.Text(
                  '$riskPercentage%',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
          if (recommendation != null) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Recommendation:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              recommendation,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildDiagnosisTable(List<DiagnosisRecord> records) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Diagnosis', isHeader: true),
            _buildTableCell('Heart Rate', isHeader: true),
          ],
        ),
        // Records
        ...records.reversed.take(10).map((record) => pw.TableRow(
              children: [
                _buildTableCell(
                  DateFormat('MMM dd, yyyy\nHH:mm').format(record.timestamp),
                ),
                _buildTableCell(record.diagnosis),
                _buildTableCell('${record.heartRate.toStringAsFixed(1)} BPM'),
              ],
            )),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildStatistics(UserProfile profile) {
    final records = profile.diagnosisHistory;
    if (records.isEmpty) return pw.SizedBox();

    final avgHeartRate = records
            .map((r) => r.heartRate)
            .reduce((a, b) => a + b) /
        records.length;

    final diagnosisCounts = <String, int>{};
    for (final record in records) {
      diagnosisCounts[record.diagnosis] =
          (diagnosisCounts[record.diagnosis] ?? 0) + 1;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Total Diagnoses:', '${records.length}'),
        _buildInfoRow('Average Heart Rate:', '${avgHeartRate.toStringAsFixed(1)} BPM'),
        pw.SizedBox(height: 10),
        pw.Text('Diagnosis Breakdown:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        ...diagnosisCounts.entries.map((entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20, bottom: 3),
              child: pw.Text(
                '${entry.key}: ${entry.value} ${entry.value == 1 ? 'time' : 'times'}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            )),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'This report is generated by AI Stethoscope for informational purposes only.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'Please consult with a healthcare professional for medical advice.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // Save PDF to Downloads folder
  static Future<String?> savePdfToDownloads(File pdfFile) async {
    try {
      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          // For Android 13+, use manageExternalStorage or photos permission
          status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            return null;
          }
        }
      }

      // Get Downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        // For Android, use the public Downloads folder
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null) return null;

      // Create unique filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'StethApp_Report_$timestamp.pdf';
      final filePath = '${downloadsDir.path}/$fileName';

      // Copy file to Downloads
      final savedFile = await pdfFile.copy(filePath);
      
      return savedFile.path;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }

  // Share or preview PDF
  static Future<void> sharePdf(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: 'medical_report.pdf',
    );
  }

  // Print PDF
  static Future<void> printPdf(UserProfile profile) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final file = await generateMedicalReport(profile);
        return file.readAsBytes();
      },
    );
  }
}
