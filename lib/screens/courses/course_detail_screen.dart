import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/layout/app_scaffold.dart';
import 'package:ottobit/models/course_detail_model.dart';
import 'package:ottobit/services/course_detail_service.dart';
import 'package:ottobit/widgets/courseDetail/course_detail_header.dart';
import 'package:ottobit/widgets/courseDetail/course_info_section.dart';
import 'package:ottobit/widgets/courseDetail/course_action_buttons.dart';
import 'package:ottobit/widgets/courseDetail/course_rating_widget.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/services/enrollment_service.dart';
import 'package:ottobit/services/cart_service.dart';
import 'package:ottobit/models/cart_model.dart';
import 'package:ottobit/screens/home/home_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ottobit/services/course_robot_service.dart';
import 'package:ottobit/models/course_robot_model.dart';
import 'package:ottobit/services/auth_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';
import 'package:ottobit/widgets/common/create_ticket_dialog.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final bool hideEnroll;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    this.hideEnroll = false,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final CourseDetailService _courseDetailService = CourseDetailService();
  final CartService _cartService = CartService();
  final CourseRobotService _courseRobotService = CourseRobotService();
  final EnrollmentService _enrollmentService = EnrollmentService();

  CourseDetail? _course;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isEnrolled = false;
  bool _isEnrolling = false;
  bool _isInCart = false;
  bool _isAddingToCart = false;
  CourseRobot? _requiredRobot;
  bool _isLoadingRobot = false;
  String? _currentStudentId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadCourseDetail();
    _checkCartStatus();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentStudentId = user?.id; // Use user id as studentId
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _checkEnrollmentStatus() async {
    try {
      final enrolled = await _enrollmentService.isEnrolledInCourse(
        courseId: widget.courseId,
      );
      if (!mounted) return;
      setState(() {
        _isEnrolled = enrolled;
        if (enrolled) {
          // If already enrolled, we don't care about cart status anymore
          _isInCart = false;
        }
      });
    } catch (e) {
      print('Error checking enrollment status: $e');
    }
  }


  Future<void> _loadCourseDetail() async {
    print('=== Loading Course Detail ===');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Course ID: ${widget.courseId}');
      final response = await _courseDetailService.getCourseDetail(widget.courseId);

      print('Response received: ${response.data?.title ?? 'No data'}');
      print('Response data: ${response.data}');

      if (mounted) {
        setState(() {
          _course = response.data;
          _isLoading = false;
        });
        print('State updated with course: ${_course?.title}');
        // Check if user is already enrolled in this course
        await _checkEnrollmentStatus();
        
        // Check cart status for paid courses
        if (_course != null && _course!.isPaid) {
          _checkCartStatus();
        }
        
        // Load required robot for all courses
        if (_course != null) {
          _loadRequiredRobot();
        }
      }
    } catch (e) {
      print('Error loading course detail: $e');
      if (mounted) {
        final isEnglish = context.locale.languageCode == 'en';
        setState(() {
          _errorMessage = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleEnroll() async {
    if (_course == null) return;

    setState(() {
      _isEnrolling = true;
    });

    try {
      final resp = await EnrollmentService().enroll(courseId: widget.courseId);
      if (!mounted) return;
      setState(() {
        _isEnrolled = true;
        _isEnrolling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp.message.isNotEmpty ? resp.message : 'course.enrollSuccess'.tr()),
          backgroundColor: const Color(0xFF48BB78),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isEnrolling = false;
      });
      final isEnglish = context.locale.languageCode == 'en';
      final msg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkCartStatus() async {
    if (_course == null || !_course!.isPaid) return;
    
    try {
      final response = await _cartService.checkItemExists(_course!.id);
      if (mounted) {
        setState(() {
          _isInCart = response.data ?? false;
        });
      }
    } catch (e) {
      print('Error checking cart status: $e');
    }
  }

  Future<void> _loadRequiredRobot() async {
    if (_course == null) return;
    
    setState(() {
      _isLoadingRobot = true;
    });
    
    try {
      final robot = await _courseRobotService.getCourseRobotByCourseId(_course!.id);
      if (mounted) {
        setState(() {
          _requiredRobot = robot;
          _isLoadingRobot = false;
        });
      }
    } catch (e) {
      print('Error loading required robot: $e');
      if (mounted) {
        setState(() {
          _isLoadingRobot = false;
        });
      }
    }
  }

  Future<void> _handleAddToCart() async {
    if (_course == null || !_course!.isPaid) return;

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final request = AddToCartRequest(
        courseId: _course!.id,
        unitPrice: _course!.price,
      );
      
      await _cartService.addToCart(request);
      
      if (mounted) {
        setState(() {
          _isInCart = true;
          _isAddingToCart = false;
        });
        
        // Refresh cart count in home screen
        HomeScreen.refreshCartCount(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cart.addedSuccessfully'.tr()),
            backgroundColor: const Color(0xFF48BB78),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
        
        final isEnglish = context.locale.languageCode == 'en';
        final msg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleShare() {
    if (_course == null) return;
    final url = 'https://ottobit-fe.vercel.app/user/courses/${_course!.id}';
    final message = '${_course!.title}\n\n${_course!.description}\n\n$url';
    Share.share(message, subject: _course!.title);
  }

  Future<void> _showCreateTicketDialog() async {
    if (_course == null) return;

    await showDialog<bool>(
      context: context,
      builder: (context) => CreateTicketDialog(
        courseId: _course!.id,
        courseName: _course!.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'course.detailTitle'.tr(),
      showAppBar: false, // We'll use custom header
      gradientColors: const [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4299E1)),
            ),
            const SizedBox(height: 16),
            Text(
              'course.loading'.tr(),
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF718096),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'common.error'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCourseDetail,
              icon: const Icon(Icons.refresh),
              label: Text('common.retry'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4299E1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_course == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'course.notFound'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Course Header
          CourseDetailHeader(course: _course!),
          
          // Course Info
          CourseInfoSection(course: _course!),
          
          // Action Buttons
          if (!widget.hideEnroll)
            CourseActionButtons(
              onEnroll: _course!.isFree && !_isEnrolled ? _handleEnroll : null,
              // Only allow adding to cart if course is paid, not enrolled yet, and not already in cart
              onAddToCart: _course!.isPaid && !_isEnrolled && !_isInCart
                  ? _handleAddToCart
                  : null,
              onShare: _handleShare,
              isEnrolled: _isEnrolled,
              isLoading: _isEnrolling || _isAddingToCart,
              isPaid: _course!.isPaid,
              isInCart: _isInCart,
              price: _course!.isPaid ? _course!.formattedPrice : null,
              requiredRobot: _requiredRobot,
              isLoadingRobot: _isLoadingRobot,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _handleShare,
                  icon: const Icon(Icons.share),
                label: Text('common.share'.tr()),
                ),
              ),
            ),
          
          // Lessons Button (hidden in read-only mode)
          if (!widget.hideEnroll)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.lessons,
                          arguments: {
                            'courseId': widget.courseId,
                            'courseTitle': _course?.title,
                          },
                        );
                      },
                      icon: const Icon(Icons.menu_book),
                      label: Text('course.viewLessons'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF48BB78),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showCreateTicketDialog,
                      icon: const Icon(Icons.support_agent),
                      label: Text('ticket.getSupport'.tr()),
                      style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF17a64b),
                      side: const BorderSide(color: Color(0xFF17a64b)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Course Rating (at the end)
          CourseRatingWidget(
            courseId: widget.courseId,
            currentStudentId: _currentStudentId,
          ),
        ],
      ),
    );
  }
}
