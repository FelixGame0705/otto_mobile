import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:ottobit/models/assistance_ticket_model.dart';
import 'package:ottobit/services/assistance_ticket_service.dart';
import 'package:ottobit/services/student_service.dart';
import 'package:ottobit/screens/support/ticket_detail_screen.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final AssistanceTicketService _service = AssistanceTicketService();
  final StudentService _studentService = StudentService();
  List<AssistanceTicket> _tickets = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _loadStudentAndTickets();
  }

  Future<void> _loadStudentAndTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // First get the student info
      try {
        final studentResponse = await _studentService.getStudentByUser();
        if (mounted && studentResponse.data != null) {
          setState(() {
            _studentId = studentResponse.data!.id;
          });
        }
      } catch (e) {
        print('Could not get student info: $e');
        // Continue without studentId
      }

      // Then load tickets (studentId is optional in API)
      print('Loading tickets with studentId: $_studentId');
      final response = await _service.getMyTickets(
        page: 1,
        size: 100, // Get all tickets
        studentId: _studentId,
      );

      print('Tickets response: ${response.data?.items.length ?? 0} tickets');
      if (mounted) {
        final tickets = response.data?.items ?? [];
        print('Setting tickets: ${tickets.length} items');
        // Show all tickets for now (API should filter by studentId automatically via JWT)
        setState(() {
          _tickets = tickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading tickets: $e');
      print('Error stack: ${StackTrace.current}');
      if (mounted) {
        final isEnglish = context.locale.languageCode == 'en';
        final errorMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTickets() async {
    await _loadStudentAndTickets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('ticket.myTickets'.tr()),
        backgroundColor: const Color(0xFF17a64b),
        foregroundColor: Colors.white,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF17a64b)),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'common.error'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTickets,
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (_tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.support_agent,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'ticket.noTickets'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ticket.noTicketsMessage'.tr(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: ListView.separated(
        itemCount: _tickets.length,
        padding: const EdgeInsets.all(16),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          return Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketDetailScreen(ticket: ticket),
                  ),
                ).then((_) {
                  // Khi quay lại từ màn hình chi tiết, luôn reload lại danh sách ticket
                  _loadTickets();
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: _getStatusColor(ticket.status),
                      radius: 24,
                      child: const Icon(Icons.support_agent, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatusChip(ticket.status),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ticket.courseName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${'common.createdAt'.tr()} ${_formatDate(ticket.createdAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(int status) {
    String label;
    Color color;
    
    switch (status) {
      case 1:
        label = 'ticket.status.open'.tr();
        color = Colors.orange;
        break;
      case 2:
        label = 'ticket.status.inProgress'.tr();
        color = Colors.blue;
        break;
      case 3:
        label = 'ticket.status.resolved'.tr();
        color = Colors.green;
        break;
      case 4:
        label = 'ticket.status.closed'.tr();
        color = Colors.red;
        break;
      default:
        label = 'ticket.status.open'.tr();
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

