import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/user_model.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/services/storage_service.dart';
import 'package:ottobit/services/auth_service.dart';
import 'package:ottobit/layout/app_scaffold.dart';
import 'package:ottobit/widgets/common/section_card.dart';
import 'package:ottobit/widgets/common/language_dropdown.dart';
import 'package:ottobit/services/student_service.dart';
import 'package:ottobit/utils/constants.dart';
import 'package:ottobit/models/student_model.dart';
import 'package:ottobit/widgets/enrolls/my_enrollments_grid.dart';
import 'package:ottobit/screens/support/tickets_screen.dart';
import 'package:ottobit/screens/submissions/my_submissions_screen.dart';
import 'package:ottobit/widgets/courseDetail/activation_code_dialog.dart';
import 'package:ottobit/screens/profile/my_robots_screen.dart';
import 'package:ottobit/screens/profile/my_notes_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
// removed ui/rendering imports used by old editor
import 'package:ottobit/services/location_service.dart';
import 'package:ottobit/models/location_model.dart';
import 'package:ottobit/utils/api_error_handler.dart';
import 'package:ottobit/widgets/common/student_required_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _creatingStudent = false;
  Student? _student;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Removed old direct upload method; using editor + bytes upload instead

  // Upload raw image bytes to Cloudinary
  Future<String?> _uploadBytesToCloudinary(Uint8List bytes) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/${AppConstants.cloudinaryCloudName}/image/upload');
      final req = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = AppConstants.cloudinaryUploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'avatar.png'));
      final resp = await req.send();
      final body = await resp.stream.bytesToString();
      if (resp.statusCode == 200) {
        final jsonMap = jsonDecode(body) as Map<String, dynamic>;
        return (jsonMap['secure_url'] ?? jsonMap['url'])?.toString();
      } else {
        if (mounted) {
          final msg = 'profile.uploadFailed'.tr(namedArgs: {
            'status': resp.statusCode.toString(),
            'reason': resp.reasonPhrase ?? '',
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        final msg = 'profile.uploadError'.tr(namedArgs: {'err': ApiErrorMapper.fromException(e)});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      return null;
    }
  }

  // removed avatar editor flow

  Future<void> _openEditProfile() async {
    final avatarController = TextEditingController(text: _user?.avatar ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final mq = MediaQuery.of(context);
        final isWide = mq.size.width > 600;
        return AlertDialog(
          scrollable: true,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isWide ? mq.size.width * 0.25 : 16,
            vertical: 24,
          ),
          title: Text('profile.updateProfile'.tr()),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              StatefulBuilder(
                builder: (context, setDialogState) {
                  final url = avatarController.text.trim();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF1F5F9)),
                        clipBehavior: Clip.antiAlias,
                        child: url.isNotEmpty
                            ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                            : const Icon(Icons.person, size: 64, color: Colors.black26),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
                                if (picked == null) return;
                                final bytes = await picked.readAsBytes();
                                final link = await _uploadBytesToCloudinary(bytes);
                                if (link != null) {
                                  avatarController.text = link;
                                  setDialogState(() {});
                                }
                              },
                              icon: const Icon(Icons.cloud_upload),
                              label: Text('profile.upload'.tr()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (url.isNotEmpty)
                            OutlinedButton(
                              onPressed: () {
                                avatarController.clear();
                                setDialogState(() {});
                              },
                              child: Text('profile.removeImage'.tr()),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('common.cancel'.tr())),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('profile.save'.tr())),
          ],
        );
      },
    );
    if (result == true) {
      final res = await AuthService.updateProfile(
        avatarUrl: avatarController.text.trim().isEmpty ? null : avatarController.text.trim(),
      );
      if (!mounted) return;
      if (res.isSuccess) {
        setState(() { _user = res.user; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'profile.updateSuccess'.tr())),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'profile.updateFailed'.tr()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadUser() async {
    final user = await StorageService.getUser();
    setState(() { _user = user; });
    // Fetch latest profile from server
    final res = await AuthService.getProfile();
    if (res.isSuccess && res.user != null) {
      setState(() { _user = res.user; });
    }
    await _loadStudent();
  }

  Future<void> _loadStudent() async {
    try {
      final resp = await StudentService().getStudentByUser();
      setState(() {
        _student = resp.data;
      });
    } catch (_) {}
  }

  void _openRobotActivationDialog() {
    showDialog(
      context: context,
      builder: (context) => const ActivationCodeDialog(),
    );
  }

  Future<void> _handleLogout() async {
    await StorageService.clearToken();
    await StorageService.clearRefreshToken();
    await StorageService.clearTokenExpiry();
    await StorageService.clearUser();
    await StorageService.removeValue(AppConstants.onboardingSeenKey);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.onboarding, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      foregroundColor: const Color.fromARGB(255, 0, 0, 0),
      title: 'profile.title'.tr(),
      gradientColors: const [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
              title: 'profile.userInfo'.tr(),
            child: _user == null
                ? Text('profile.noUser'.tr())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: const Color(0xFFE2E8F0),
                            backgroundImage: (_user!.avatar != null && _user!.avatar!.isNotEmpty)
                                ? NetworkImage(_user!.avatar!)
                                : null,
                            child: (_user!.avatar == null || _user!.avatar!.isEmpty)
                                ? const Icon(Icons.person, color: Color(0xFF2D3748), size: 36)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _user!.email,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                // const SizedBox(height: 4),
                                if (_user!.phone.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF16A34A)),
                                        const SizedBox(width: 6),
                                        Text(
                                          _user!.phone,
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _openEditProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00ba4a),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.edit_outlined),
                              label: Text('profile.editProfile'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async { await _loadUser(); },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            child: const Icon(Icons.refresh, color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          // Language switcher
          SectionCard(
            title: 'profile.language'.tr(),
            child: const LanguageDropdown(),
          ),
          const SizedBox(height: 16),
          // Quick actions
          SectionCard(
            title: 'profile.quickActions'.tr(),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    if (_student == null) {
                      StudentRequiredDialog.show(context);
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: Text('profile.myCourses'.tr())),
                          body: const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: MyEnrollmentsGrid(),
                          ),
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00ba4a), width: 2),
                    foregroundColor: const Color(0xFF00ba4a),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.library_books),
                  label: Text('profile.myCourses'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    if (_student == null) {
                      StudentRequiredDialog.show(context);
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MySubmissionsScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2563EB), width: 2),
                    foregroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.code),
                  label: Text('profile.mySubmissions'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    if (_student == null) {
                      StudentRequiredDialog.show(context);
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyRobotsScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF10B981), width: 2),
                    foregroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.smart_toy),
                  label: Text('profile.myRobots'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    if (_student == null) {
                      StudentRequiredDialog.show(context);
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyNotesScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF9333EA), width: 2),
                    foregroundColor: const Color(0xFF9333EA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.note_outlined),
                  label: Text('profile.myNotes'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    if (_student == null) {
                      StudentRequiredDialog.show(context);
                      return;
                    }
                    Navigator.pushNamed(context, AppRoutes.cart);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFED8936), width: 2),
                    foregroundColor: const Color(0xFFED8936),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.shopping_cart),
                  label: Text('cart.title'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    if (_student == null) {
                      StudentRequiredDialog.show(context);
                      return;
                    }
                    Navigator.pushNamed(context, AppRoutes.orders);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF3182CE), width: 2),
                    foregroundColor: const Color(0xFF3182CE),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.receipt_long),
                  label: Text('profile.myOrders'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    if (_student == null) {
                      StudentRequiredDialog.show(context);
                      return;
                    }
                    Navigator.pushNamed(context, AppRoutes.certificates);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                    foregroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.workspace_premium),
                  label: Text('profile.myCertificates'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    if (_student == null) {
                      StudentRequiredDialog.show(context);
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TicketsScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF9333EA), width: 2),
                    foregroundColor: const Color(0xFF9333EA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.support_agent),
                  label: Text('ticket.myTickets'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                OutlinedButton.icon(
                  onPressed: _openRobotActivationDialog,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
                    foregroundColor: const Color(0xFF0EA5E9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.smart_toy),
                  label: Text('profile.activateRobot'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'profile.security'.tr(),
            child: Column(
              children: [
                // Đăng ký làm Student
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _creatingStudent || _student != null ? null : _handleCreateStudent,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF4299E1), width: 2),
                      foregroundColor: const Color(0xFF4299E1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _creatingStudent
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.school),
                    label: Text(
                        _student != null
                            ? 'profile.student.alreadyStudent'.tr()
                            : _creatingStudent
                                ? 'profile.student.registering'.tr()
                                : 'profile.student.registerButton'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                if (_student != null) ...[
                  const SizedBox(height: 12),
                  _buildStudentProfileCard(),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _creatingStudent ? null : _handleUpdateStudent,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF10B981), width: 2),
                        foregroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _creatingStudent
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.edit),
                      label: Text(
                          _creatingStudent
                              ? 'profile.student.registering'.tr()
                              : 'profile.editStudentProfile'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.changePassword),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00ba4a),
                      foregroundColor: const Color(0xFF2D3748),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.password),
                    label: Text('profile.changePassword'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _handleLogout,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE53E3E), width: 2),
                      foregroundColor: const Color(0xFFE53E3E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.logout),
                    label: Text('profile.logout'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreateStudent() async {
    if (_user == null) return;
    
    // Show dialog for student registration
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _StudentRegistrationDialog(
        initialFullname: '',
        initialPhone: _user!.phone,
      ),
    );
    
    if (result == null) return; // User cancelled
    
    setState(() => _creatingStudent = true);
    try {
      final service = StudentService();
      final resp = await service.createStudent(
        fullname: result['fullname'] as String,
        phoneNumber: result['phoneNumber'] as String,
        address: result['address'] as String,
        state: result['state'] as String,
        city: result['city'] as String,
        dateOfBirth: result['dateOfBirth'] as DateTime,
      );
      if (!mounted) return;
      final created = resp.data;
      if (created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile.student.success'.tr()), backgroundColor: Colors.green),
        );
        await _loadStudent();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message.isNotEmpty ? resp.message : 'profile.student.failed'.tr()), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profile.student.error'.tr(namedArgs: {'err': '$e'})), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _creatingStudent = false);
    }
  }

  Future<void> _handleUpdateStudent() async {
    if (_student == null) return;
    
    // Show dialog for student update
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _StudentRegistrationDialog(
        initialFullname: _student!.fullname,
        initialPhone: _student!.phoneNumber,
        initialAddress: _student!.address,
        initialState: _student!.state,
        initialCity: _student!.city,
        initialDateOfBirth: _student!.dateOfBirth,
        isUpdate: true,
      ),
    );
    
    if (result == null) return; // User cancelled
    
    setState(() => _creatingStudent = true);
    try {
      final service = StudentService();
      final resp = await service.updateStudent(
        studentId: _student!.id,
        fullname: result['fullname'] as String,
        phoneNumber: result['phoneNumber'] as String,
        address: result['address'] as String,
        state: result['state'] as String,
        city: result['city'] as String,
        dateOfBirth: result['dateOfBirth'] as DateTime,
      );
      if (!mounted) return;
      final updated = resp.data;
      if (updated != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile.student.updateSuccess'.tr()), backgroundColor: Colors.green),
        );
        await _loadStudent();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message.isNotEmpty ? resp.message : 'profile.student.updateFailed'.tr()), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = 'profile.student.updateError'.tr(namedArgs: {'err': ApiErrorMapper.fromException(e)});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _creatingStudent = false);
    }
  }
}

Widget _infoRow(String label, String value) {
  return Row(
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(width: 8),
      Expanded(child: Text(value, textAlign: TextAlign.right)),
    ],
  );
}

extension _StudentCard on _ProfileScreenState {
  Widget _buildStudentProfileCard() {
    final s = _student!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('profile.student.title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _infoRow('${'profile.student.fullname'.tr()}:', s.fullname),
          const SizedBox(height: 6),
          _infoRow('${'profile.phone'.tr()}:', s.phoneNumber),
          const SizedBox(height: 6),
          _infoRow('${'profile.address'.tr()}:', s.address),
          const SizedBox(height: 6),
          _infoRow('${'profile.state'.tr()}:', s.state),
          const SizedBox(height: 6),
          _infoRow('${'profile.city'.tr()}:', s.city),
          const SizedBox(height: 6),
          _infoRow('${'profile.student.dob'.tr()}:', '${s.dateOfBirth.day.toString().padLeft(2, '0')}/${s.dateOfBirth.month.toString().padLeft(2, '0')}/${s.dateOfBirth.year}'),
          const SizedBox(height: 6),
          _infoRow('profile.student.enrollments'.tr(), s.enrollmentsCount.toString()),
          const SizedBox(height: 6),
          _infoRow('profile.student.submissions'.tr(), s.submissionsCount.toString()),
        ],
      ),
    );
  }
}

class _StudentRegistrationDialog extends StatefulWidget {
  final String initialFullname;
  final String initialPhone;
  final String? initialAddress;
  final String? initialState;
  final String? initialCity;
  final DateTime? initialDateOfBirth;
  final bool isUpdate;

  const _StudentRegistrationDialog({
    required this.initialFullname,
    required this.initialPhone,
    this.initialAddress,
    this.initialState,
    this.initialCity,
    this.initialDateOfBirth,
    this.isUpdate = false,
  });

  @override
  State<_StudentRegistrationDialog> createState() => _StudentRegistrationDialogState();
}

class _StudentRegistrationDialogState extends State<_StudentRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _locationsLoading = true;
  List<Province> _provinces = [];
  Province? _selectedProvince;
  Ward? _selectedWard;

  @override
  void initState() {
    super.initState();
    _fullnameController.text = widget.initialFullname;
    _phoneController.text = widget.initialPhone;
    _addressController.text = widget.initialAddress ?? '';
    _selectedDate = widget.initialDateOfBirth;
    _loadLocations();
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final provinces = await LocationService.instance.getProvinces();
      Province? matchedProvince;
      Ward? matchedWard;
      if ((widget.initialState ?? '').isNotEmpty) {
        try {
          matchedProvince = provinces.firstWhere((p) => p.name == widget.initialState);
        } catch (_) {}
        if (matchedProvince != null && (widget.initialCity ?? '').isNotEmpty) {
          try {
            matchedWard = matchedProvince.wards.firstWhere((w) => w.name == widget.initialCity);
          } catch (_) {}
        }
      }
      if (!mounted) return;
      setState(() {
        _provinces = provinces;
        _selectedProvince = matchedProvince;
        _selectedWard = matchedWard;
        _locationsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationsLoading = false;
      });
      final msg = 'profile.loadProvincesError'.tr(namedArgs: {'err': ApiErrorMapper.fromException(e)});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _selectDate() async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)), // Default to 18 years ago
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
        });
      }
    } catch (e) {
      // Handle any date picker errors gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.student.dobError'.tr(namedArgs: {'err': '$e'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedDate != null && !_locationsLoading) {
      Navigator.of(context).pop({
        'fullname': _fullnameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'state': _selectedProvince?.name ?? '',
        'city': _selectedWard?.name ?? '',
        'dateOfBirth': _selectedDate!,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isUpdate ? 'profile.editStudentProfile'.tr() : 'profile.student.dialogTitle'.tr(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _fullnameController,
                decoration: InputDecoration(
                  labelText: '${'profile.student.fullname'.tr()} *',
                  hintText: 'profile.student.fullnameHint'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'profile.student.fullnameRequired'.tr();
                  }
                  if (value.trim().length < 2) {
                    return 'profile.student.fullnameMin'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: '${'profile.phoneNumber'.tr()} *',
                  hintText: 'profile.phoneNumberHint'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'profile.phoneNumberRequired'.tr();
                  }
                  // Validate Vietnamese phone number format
                  final phone = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
                  // Vietnamese phone numbers: 10 digits starting with 0[3|5|7|8|9], or 11 digits starting with 84[3|5|7|8|9]
                  final phoneRegex = RegExp(r'^(0[35789][0-9]{8})$|^(84[35789][0-9]{8})$');
                  if (!phoneRegex.hasMatch(phone)) {
                    return 'profile.phoneNumberInvalid'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: '${'profile.address'.tr()} *',
                  hintText: 'profile.addressHint'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'profile.addressRequired'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_locationsLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                DropdownButtonFormField<Province>(
                  value: _selectedProvince,
                  decoration: InputDecoration(
                    labelText: '${'profile.provinceCity'.tr()} *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                  items: _provinces
                      .map(
                        (province) => DropdownMenuItem<Province>(
                          value: province,
                          child: Text(province.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvince = value;
                      _selectedWard = null;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'profile.stateProvinceRequired'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Ward>(
                  value: _selectedWard,
                  decoration: InputDecoration(
                    labelText: '${'profile.districtWard'.tr()} *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                  items: (_selectedProvince?.wards ?? const [])
                      .map(
                        (ward) => DropdownMenuItem<Ward>(
                          value: ward,
                          child: Text(ward.name),
                        ),
                      )
                      .toList(),
                  onChanged: _selectedProvince == null
                      ? null
                      : (value) {
                          setState(() {
                            _selectedWard = value;
                          });
                        },
                  validator: (value) {
                    if (_selectedProvince == null) {
                      return 'profile.selectProvinceFirst'.tr();
                    }
                    if (value == null) {
                      return 'profile.cityWardRequired'.tr();
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '${'profile.student.dob'.tr()} *',
                    hintText: 'profile.student.dobPick'.tr(),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                        : 'profile.student.dobPick'.tr(),
                    style: TextStyle(
                      color: _selectedDate != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              if (_selectedDate == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'profile.student.dobRequired'.tr(),
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('common.cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: (_isLoading || _locationsLoading) ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4299E1),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(widget.isUpdate ? 'profile.update'.tr() : 'common.register'.tr()),
        ),
      ],
    );
  }
}

// Removed avatar editor per request; direct upload flow is used
