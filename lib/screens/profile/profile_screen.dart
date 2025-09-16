import 'package:flutter/material.dart';
import 'package:otto_mobile/models/user_model.dart';
import 'package:otto_mobile/routes/app_routes.dart';
import 'package:otto_mobile/services/storage_service.dart';
import 'package:otto_mobile/layout/app_scaffold.dart';
import 'package:otto_mobile/widgets/common/section_card.dart';
import 'package:otto_mobile/services/student_service.dart';
import 'package:otto_mobile/models/student_model.dart';

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

  Future<void> _loadUser() async {
    final user = await StorageService.getUser();
    setState(() {
      _user = user;
    });
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Thông tin cá nhân',
      gradientColors: const [Color(0xFFEDFCF2), Color(0xFFEDFCF2)],
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Thông tin người dùng',
            child: _user == null
                ? const Text('Chưa có dữ liệu người dùng')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color.fromARGB(255, 193, 193, 193),
                            child: const Icon(Icons.person, color: Color(0xFF2D3748)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_user!.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text(_user!.email, style: const TextStyle(color: Color(0xFF718096))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_user!.phone.isNotEmpty) Text('SĐT: ${_user!.phone}'),
                      Text('ID: ${_user!.id}', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Bảo mật',
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
                            ? 'Đã là Student'
                            : _creatingStudent
                                ? 'Đang đăng ký...'
                                : 'Đăng ký làm Student',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                if (_student != null) ...[
                  const SizedBox(height: 12),
                  _buildStudentProfileCard(),
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
                    label: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.w600)),
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
    setState(() => _creatingStudent = true);
    try {
      final service = StudentService();
      final resp = await service.createStudent(
        fullname: _user!.fullName,
        dateOfBirth: DateTime.now(), // TODO: cho phép người dùng chọn ngày sinh
      );
      if (!mounted) return;
      final created = resp.data;
      if (created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký Student thành công'), backgroundColor: Colors.green),
        );
        await _loadStudent();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message.isNotEmpty ? resp.message : 'Đăng ký không thành công'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
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
          const Text('Hồ sơ Student', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _infoRow('Họ tên:', s.fullname),
          const SizedBox(height: 6),
          _infoRow('Ngày sinh:', s.dateOfBirth.toLocal().toString()),
          const SizedBox(height: 6),
          _infoRow('Enrollments:', s.enrollmentsCount.toString()),
          const SizedBox(height: 6),
          _infoRow('Submissions:', s.submissionsCount.toString()),
        ],
      ),
    );
  }
}
