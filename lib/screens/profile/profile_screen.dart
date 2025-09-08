import 'package:flutter/material.dart';
import 'package:otto_mobile/models/user_model.dart';
import 'package:otto_mobile/routes/app_routes.dart';
import 'package:otto_mobile/services/storage_service.dart';
import 'package:otto_mobile/layout/app_scaffold.dart';
import 'package:otto_mobile/widgets/common/section_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;

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
}
