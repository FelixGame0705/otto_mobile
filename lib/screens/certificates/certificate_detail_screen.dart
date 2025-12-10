import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ottobit/models/certificate_model.dart';
import 'package:ottobit/services/certificate_service.dart';
import 'package:ottobit/widgets/common/section_card.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class CertificateDetailScreen extends StatefulWidget {
  final String certificateId;
  final Certificate? certificate;

  const CertificateDetailScreen({
    super.key,
    required this.certificateId,
    this.certificate,
  });

  @override
  State<CertificateDetailScreen> createState() => _CertificateDetailScreenState();
}

class _CertificateDetailScreenState extends State<CertificateDetailScreen> {
  final CertificateService _certificateService = CertificateService();
  
  Certificate? _certificate;
  CertificateTemplate? _template;
  bool _isLoading = true;
  String? _error;
  String? _renderedHtml;
  bool _webViewError = false;

  @override
  void initState() {
    super.initState();
    _loadCertificateDetails();
  }

  Future<void> _loadCertificateDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use provided certificate or try to load from API
      Certificate? certificate = widget.certificate;
      
      if (certificate == null) {
        // Try to load certificate from API as fallback
        final certificateResponse = await _certificateService.getCertificate(widget.certificateId);
        
        if (!certificateResponse.isSuccess || certificateResponse.data == null) {
          setState(() {
            _error = certificateResponse.message ?? 'certificate.loadErrorDetail'.tr(namedArgs: {'err': ''});
            _isLoading = false;
          });
          return;
        }
        certificate = certificateResponse.data!;
      }
      
      // Load certificate template
      final templateResponse = await _certificateService.getCertificateTemplate(certificate.templateId);
      
      if (!templateResponse.isSuccess || templateResponse.data == null) {
        setState(() {
          _error = templateResponse.message ?? 'certificate.loadTemplateError'.tr();
          _isLoading = false;
        });
        return;
      }

      final template = templateResponse.data!;
      
      // Render the certificate HTML with responsive CSS
      final renderedHtml = _wrapHtmlWithResponsiveCSS(template.renderTemplate(
        studentName: certificate.studentFullname,
        courseTitle: certificate.courseTitle,
        issueDate: DateFormat('MMMM dd, yyyy').format(certificate.issuedAt),
        certificateId: certificate.certificateNo,
      ));

      setState(() {
        _certificate = certificate;
        _template = template;
        _renderedHtml = renderedHtml;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'certificate.loadErrorDetail'.tr(namedArgs: {'err': ApiErrorMapper.fromException(e)});
        _isLoading = false;
      });
    }
  }

  void _shareCertificate() async {
    if (_certificate == null || _renderedHtml == null) return;
    
    try {
      // Create a simple text share with certificate info
      final shareText = '''
🎓 ${'certificate.shareTitle'.tr()}

${'certificate.shareStudent'.tr()}: ${_certificate!.studentFullname}
${'certificate.shareCourse'.tr()}: ${_certificate!.courseTitle}
${'certificate.shareCertificateNo'.tr()}: ${_certificate!.certificateNo}
${'certificate.shareVerificationCode'.tr()}: ${_certificate!.verificationCode}
${'certificate.shareIssued'.tr()}: ${DateFormat('MMMM dd, yyyy').format(_certificate!.issuedAt)}

${'certificate.shareFooter'.tr()}
      ''';
      
      await Share.share(
        shareText,
        subject: 'certificate.shareSubject'.tr(namedArgs: {'courseTitle': _certificate!.courseTitle}),
      );
    } catch (e) {
      if (mounted) {
        final msg = 'certificate.shareError'.tr(namedArgs: {'err': ApiErrorMapper.fromException(e)});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadCertificate() async {
    if (_certificate == null || _template == null) return;
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Generate PDF
      final pdf = await _generateCertificatePDF();
      final pdfBytes = await pdf.save();
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Try different PDF sharing methods
      try {
        // Method 1: Use Printing.layoutPdf
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: 'Certificate_${_certificate!.certificateNo}.pdf',
        );
      } catch (printingError) {
        // Method 2: Use Printing.sharePdf as fallback
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'Certificate_${_certificate!.certificateNo}.pdf',
        );
      }
      
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        final msg = 'certificate.downloadError'.tr(namedArgs: {'err': ApiErrorMapper.fromException(e)});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyVerificationCode() {
    if (_certificate == null) return;
    
    Clipboard.setData(ClipboardData(text: _certificate!.verificationCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('certificate.verificationCodeCopied'.tr())),
    );
  }

  void _openFullScreenCertificate() {
    if (_renderedHtml == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenCertificateView(
          htmlContent: _renderedHtml!,
          certificateTitle: _certificate?.courseTitle ?? 'Certificate',
        ),
      ),
    );
  }

  Future<pw.Document> _generateCertificatePDF() async {
    if (_certificate == null || _template == null) {
      throw Exception('Certificate or template data is missing');
    }

    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.green, width: 3),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header
                pw.Text(
                  'CERTIFICATE OF COMPLETION',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green,
                    letterSpacing: 3,
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Subtitle
                pw.Text(
                  'This certifies that',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 20),
                
                // Student Name
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.green, width: 2),
                    ),
                  ),
                  child: pw.Text(
                    _certificate!.studentFullname,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Course completion text
                pw.Text(
                  'has successfully completed the course',
                  style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 10),
                
                // Course Title
                pw.Text(
                  _certificate!.courseTitle,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green,
                  ),
                ),
                pw.SizedBox(height: 30),
                
                // Certificate details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          'Issued on:',
                          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                        ),
                        pw.Text(
                          DateFormat('MMM dd, yyyy').format(_certificate!.issuedAt),
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.Text('|', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey400)),
                    pw.Column(
                      children: [
                        pw.Text(
                          'Certificate ID:',
                          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                        ),
                        pw.Text(
                          _certificate!.certificateNo,
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                
                // Divider line
                pw.Container(
                  height: 1,
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [PdfColors.green, PdfColors.green700],
                    ),
                  ),
                ),
                pw.SizedBox(height: 30),
                
                // Issuer information
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          _template!.issuerName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green,
                          ),
                        ),
                        pw.Text(
                          _template!.issuerTitle,
                          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                
                // Footer
                pw.Text(
                  'Ottobit Academy · Robotics & STEM Education',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                ),
              ],
            ),
          );
        },
      ),
    );
    
    return pdf;
  }

  String _wrapHtmlWithResponsiveCSS(String htmlContent) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <style>
        body {
          margin: 0;
          padding: 8px;
          overflow-x: auto;
          overflow-y: auto;
          background: #ffffff;
          font-family: Arial, sans-serif;
          width: 500px;
          min-width: 500px;
          zoom: 0.8; /* Scale down to fit more content */
          -webkit-text-size-adjust: 100%;
          -webkit-font-smoothing: antialiased;
        }
        .certificate-container {
          max-width: 800px;
          width: 800px;
          min-width: 800px;
          box-sizing: border-box;
          overflow: visible;
          transform-origin: top left;
          min-height: auto;
          height: auto;
        }
        .certificate-container * {
          max-width: 800px !important;
          box-sizing: border-box !important;
        }
        .certificate-container > div {
          width: 800px !important;
          min-width: 800px !important;
          min-height: auto !important;
          height: auto !important;
        }
        img {
          max-width: 100% !important;
          height: auto !important;
        }
        /* Ensure certificate displays at desktop-like size */
        .certificate-container > div:first-child {
          width: 800px !important;
          min-width: 800px !important;
          max-width: 800px !important;
          min-height: auto !important;
          height: auto !important;
        }
        /* Allow horizontal scrolling for wide content */
        .certificate-container {
          overflow-x: auto;
          overflow-y: auto;
        }
        /* Ensure all elements can wrap content */
        .certificate-container * {
          min-height: auto !important;
          height: auto !important;
        }
      </style>
    </head>
    <body>
      <div class="certificate-container">
        $htmlContent
      </div>
    </body>
    </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('certificate.details'.tr()),
        backgroundColor: const Color(0xFF00ba4a),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadCertificateDetails,
                            child: Text('common.retry'.tr()),
                          ),
                        ],
                      ),
                    )
                  : _certificate == null || _template == null
                      ? Center(child: Text('certificate.notFound'.tr()))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                          // Certificate Actions
                          SectionCard(
                            title: 'certificate.actions'.tr(),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _shareCertificate,
                                    icon: const Icon(Icons.share),
                                    label: Text('certificate.share'.tr()),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3182CE),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _downloadCertificate,
                                    icon: const Icon(Icons.download),
                                    label: Text('certificate.download'.tr()),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF00ba4a),
                                      side: const BorderSide(color: Color(0xFF00ba4a)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Certificate Information
                          SectionCard(
                            title: 'certificate.information'.tr(),
                            child: Column(
                              children: [
                                _InfoRow(
                                  label: 'certificate.certificateNumber'.tr(),
                                  value: _certificate!.certificateNo,
                                  onTap: _copyVerificationCode,
                                ),
                                _InfoRow(
                                  label: 'certificate.verificationCode'.tr(),
                                  value: _certificate!.verificationCode,
                                  onTap: _copyVerificationCode,
                                  copyable: true,
                                ),
                                _InfoRow(
                                  label: 'certificate.studentName'.tr(),
                                  value: _certificate!.studentFullname,
                                ),
                                _InfoRow(
                                  label: 'certificate.courseTitle'.tr(),
                                  value: _certificate!.courseTitle,
                                ),
                                _InfoRow(
                                  label: 'certificate.issueDateLabel'.tr(),
                                  value: DateFormat('MMMM dd, yyyy').format(_certificate!.issuedAt),
                                ),
                                if (_certificate!.expiresAt != null)
                                  _InfoRow(
                                    label: 'certificate.expiryDate'.tr(),
                                    value: DateFormat('MMMM dd, yyyy').format(_certificate!.expiresAt!),
                                    valueColor: _certificate!.isExpired ? Colors.red : Colors.orange,
                                  ),
                                _InfoRow(
                                  label: 'certificate.status'.tr(),
                                  value: _certificate!.statusText,
                                  valueColor: _certificate!.isActive ? Colors.green : Colors.grey,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Certificate Preview
                          SectionCard(
                            title: 'certificate.preview'.tr(),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(
                                    minWidth: double.infinity,
                                    maxWidth: double.infinity,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _renderedHtml != null
                                        ? SizedBox(
                                            height: 600, // Reduced height
                                            child: WebViewWidget(
                                              controller: WebViewController()
                                                ..setJavaScriptMode(JavaScriptMode.disabled)
                                                ..setNavigationDelegate(
                                                  NavigationDelegate(
                                                    onNavigationRequest: (NavigationRequest request) {
                                                      return NavigationDecision.prevent;
                                                    },
                                                    onWebResourceError: (WebResourceError error) {
                                                      // Handle WebView error
                                                      setState(() {
                                                        _webViewError = true;
                                                      });
                                                    },
                                                    onPageFinished: (String url) {
                                                      // WebView page loaded successfully
                                                    },
                                                  ),
                                                )
                                                ..loadHtmlString(_renderedHtml!),
                                            ),
                                          )
                                        : _webViewError
                                            ? Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.error_outline,
                                                      size: 48,
                                                      color: Colors.red[400],
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'certificate.previewUnavailable'.tr(),
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.red[600],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'certificate.previewUnavailableMessage'.tr(),
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(32.0),
                                                  child: Text('certificate.previewNotAvailable'.tr()),
                                                ),
                                              ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _openFullScreenCertificate,
                                    icon: const Icon(Icons.fullscreen),
                                    label: Text('certificate.viewFullScreen'.tr()),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF00ba4a),
                                      side: const BorderSide(color: Color(0xFF00ba4a)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Verification Information
                          SectionCard(
                            title: 'certificate.verification'.tr(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'certificate.verificationDescription'.tr(),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'certificate.verificationInstructions'.tr(),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;
  final bool copyable;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: valueColor ?? const Color(0xFF1F2937),
                        fontWeight: copyable ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (copyable) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.copy,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenCertificateView extends StatelessWidget {
  final String htmlContent;
  final String certificateTitle;

  const _FullScreenCertificateView({
    required this.htmlContent,
    required this.certificateTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(certificateTitle),
        backgroundColor: const Color(0xFF00ba4a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              try {
                final shareText = '''
🎓 ${'certificate.shareTitle'.tr()}

${'certificate.shareStudent'.tr()}: $certificateTitle
${'certificate.shareCourse'.tr()}: $certificateTitle

${'certificate.shareFooter'.tr()}
                ''';
                
                await Share.share(
                  shareText,
                  subject: 'certificate.shareSubject'.tr(namedArgs: {'courseTitle': certificateTitle}),
                );
              } catch (e) {
                if (context.mounted) {
                  final msg = 'certificate.shareError'.tr(namedArgs: {'err': ApiErrorMapper.fromException(e)});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
          ),
        ),
        child: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(8.0), // Add padding to prevent edge overflow
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: WebViewWidget(
                controller: WebViewController()
                  ..setJavaScriptMode(JavaScriptMode.disabled)
                  ..setNavigationDelegate(
                    NavigationDelegate(
                      onNavigationRequest: (NavigationRequest request) {
                        return NavigationDecision.prevent;
                      },
                      onWebResourceError: (WebResourceError error) {
                        // Handle WebView error
                      },
                    ),
                  )
                  ..loadHtmlString(htmlContent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}