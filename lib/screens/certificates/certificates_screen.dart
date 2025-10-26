import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ottobit/models/certificate_model.dart';
import 'package:ottobit/services/certificate_service.dart';
import 'package:ottobit/widgets/common/section_card.dart';
import 'package:ottobit/routes/app_routes.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  final CertificateService _certificateService = CertificateService();
  final ScrollController _scrollController = ScrollController();
  
  List<Certificate> _certificates = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 10;
  String _searchTerm = '';
  String _orderBy = 'updatedAt';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCertificates();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      setState(() {}); // Rebuild to update clear button visibility
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreCertificates();
      }
    }
  }

  Future<void> _loadCertificates({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _certificates.clear();
        _hasMore = true;
      }
    });

    try {
      final response = await _certificateService.getMyCertificates(
        page: _currentPage,
        size: _pageSize,
        searchTerm: _searchTerm.isNotEmpty ? _searchTerm : null,
        orderBy: _orderBy,
      );

      if (response.isSuccess && response.data != null) {
        setState(() {
          if (refresh) {
            _certificates = response.data!.items;
          } else {
            _certificates.addAll(response.data!.items);
          }
          _hasMore = _certificates.length < response.data!.total;
          _currentPage++;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Failed to load certificates'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading certificates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreCertificates() async {
    await _loadCertificates();
  }

  Future<void> _refreshCertificates() async {
    await _loadCertificates(refresh: true);
  }

  void _searchCertificates() {
    setState(() {
      _searchTerm = _searchController.text.trim();
    });
    _loadCertificates(refresh: true);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchTerm = '';
    });
    _loadCertificates(refresh: true);
  }

  void _shareCertificate(Certificate certificate) async {
    try {
      final shareText = '''
🎓 Certificate of Completion

Student: ${certificate.studentFullname}
Course: ${certificate.courseTitle}
Certificate No: ${certificate.certificateNo}
Verification Code: ${certificate.verificationCode}
Issued: ${DateFormat('MMMM dd, yyyy').format(certificate.issuedAt)}
${certificate.expiresAt != null ? 'Expires: ${DateFormat('MMMM dd, yyyy').format(certificate.expiresAt!)}' : ''}
Status: ${certificate.statusText}

This certificate was issued by Ottobit Academy.
Verify at: https://ottobit.academy/verify
      ''';
      
      await Share.share(
        shareText,
        subject: 'Certificate: ${certificate.courseTitle}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _sortCertificates(String orderBy) {
    setState(() {
      _orderBy = orderBy;
    });
    _loadCertificates(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
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
          child: Column(
            children: [
                  // Search and Filter Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SectionCard(
                      title: 'Search & Filter',
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search certificates...',
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_searchController.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: _clearSearch,
                                    )else
                                  IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: _searchCertificates,
                                  ),
                                ],
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            onSubmitted: (value) => _searchCertificates(),
                            textInputAction: TextInputAction.search,
                          ),
                          const SizedBox(height: 12),
                          // Responsive layout for filter controls
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 600) {
                                // Desktop/Tablet layout - horizontal
                                return Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          labelText: 'Sort by',
                                          border: OutlineInputBorder(),
                                        ),
                                        value: _orderBy,
                                        items: const [
                                          DropdownMenuItem(value: 'updatedAt', child: Text('Recently Updated')),
                                          DropdownMenuItem(value: 'issuedAt', child: Text('Issue Date')),
                                          DropdownMenuItem(value: 'courseTitle', child: Text('Course Name')),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) _sortCertificates(value);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _refreshCertificates,
                                        icon: const Icon(Icons.refresh, color: Color(0xFF00ba4a),),
                                        label: const Text('Refresh', style: TextStyle(color: Color(0xFF00ba4a)),),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                // Mobile layout - vertical
                                return Column(
                                  children: [
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Sort by',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: _orderBy,
                                      items: const [
                                        DropdownMenuItem(value: 'updatedAt', child: Text('Recently Updated')),
                                        DropdownMenuItem(value: 'issuedAt', child: Text('Issue Date')),
                                        DropdownMenuItem(value: 'courseTitle', child: Text('Course Name')),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) _sortCertificates(value);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _refreshCertificates,
                                        icon: const Icon(Icons.refresh, color: Color(0xFF00ba4a),),
                                        label: const Text('Refresh', style: TextStyle(color: Color(0xFF00ba4a)),),
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              // Certificates List
              Expanded(
                child: _certificates.isEmpty && !_isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.workspace_premium_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No certificates found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete courses to earn certificates',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                        : RefreshIndicator(
                            onRefresh: _refreshCertificates,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth > 800) {
                                  // Desktop/Tablet layout - Grid view
                                  return GridView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: constraints.maxWidth > 1200 ? 3 : 2,
                                      childAspectRatio: 1.2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                    itemCount: _certificates.length + (_isLoading ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _certificates.length) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      final certificate = _certificates[index];
                                      return _CertificateCard(
                                        certificate: certificate,
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.certificateDetail,
                                            arguments: {
                                              'certificateId': certificate.id,
                                              'certificate': certificate,
                                            },
                                          );
                                        },
                                        onShare: () => _shareCertificate(certificate),
                                      );
                                    },
                                  );
                                } else {
                                  // Mobile layout - List view
                                  return ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    itemCount: _certificates.length + (_isLoading ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _certificates.length) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }

                                      final certificate = _certificates[index];
                                      return _CertificateCard(
                                        certificate: certificate,
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.certificateDetail,
                                            arguments: {
                                              'certificateId': certificate.id,
                                              'certificate': certificate,
                                            },
                                          );
                                        },
                                        onShare: () => _shareCertificate(certificate),
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final Certificate certificate;
  final VoidCallback onTap;
  final VoidCallback onShare;

  const _CertificateCard({
    required this.certificate,
    required this.onTap,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 300;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: certificate.isActive ? Colors.green[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.workspace_premium,
                      color: certificate.isActive ? Colors.green[700] : Colors.grey[600],
                      size: isWide ? 24 : 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          certificate.courseTitle,
                          style: TextStyle(
                            fontSize: isWide ? 16 : 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                          maxLines: isWide ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          certificate.studentFullname,
                          style: TextStyle(
                            fontSize: isWide ? 14 : 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: certificate.isActive ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      certificate.statusText,
                      style: TextStyle(
                        fontSize: isWide ? 12 : 10,
                        fontWeight: FontWeight.w500,
                        color: certificate.isActive ? Colors.green[700] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Responsive layout for certificate info
              if (isWide) ...[
                // Wide layout - horizontal
                Row(
                  children: [
                    Icon(Icons.confirmation_number, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Certificate #${certificate.certificateNo}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(certificate.issuedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Narrow layout - vertical
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.confirmation_number, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Certificate #${certificate.certificateNo}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(certificate.issuedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              if (certificate.expiresAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: isWide ? 16 : 14,
                      color: certificate.isExpired ? Colors.red[600] : Colors.orange[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Expires: ${DateFormat('MMM dd, yyyy').format(certificate.expiresAt!)}',
                        style: TextStyle(
                          fontSize: isWide ? 12 : 11,
                          color: certificate.isExpired ? Colors.red[600] : Colors.orange[600],
                          fontWeight: certificate.isExpired ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Responsive button layout
              if (isWide) ...[
                // Wide layout - horizontal buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00ba4a),
                          side: const BorderSide(color: Color(0xFF00ba4a)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3182CE),
                        side: const BorderSide(color: Color(0xFF3182CE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Narrow layout - vertical buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.visibility, size: 14),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00ba4a),
                          side: const BorderSide(color: Color(0xFF00ba4a)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.share, size: 14),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3182CE),
                          side: const BorderSide(color: Color(0xFF3182CE)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
