import 'package:flutter/material.dart';
import 'package:ottobit/routes/app_routes.dart';

class HomeHeroHeader extends StatefulWidget {
  final String greetingName;
  const HomeHeroHeader({super.key, required this.greetingName});

  @override
  State<HomeHeroHeader> createState() => _HomeHeroHeaderState();
}

class _HomeHeroHeaderState extends State<HomeHeroHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _dx;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _dx = Tween<double>(begin: -60, end: 60).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00ba4a), Color(0xFF15a349)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          // Centered moving robot background
          IgnorePointer(
            ignoring: true,
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _dx,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_dx.value, 0),
                    child: Align(
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: 0.5,
                        child: Image.asset(
                          'assets/images/robot-4.png',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Foreground content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OttoBit', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Chào, ${widget.greetingName}', style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox.shrink(),
            ],
              ),
              const SizedBox(height: 12),
              Center(
                child: InkWell(
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
                  borderRadius: BorderRadius.circular(56),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.white, size: 36),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SearchField(),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _ChipTag(label: 'Toán vui nhộn'),
                  _ChipTag(label: 'Tiếng Anh dễ thương'),
                  _ChipTag(label: 'Lập trình cho trẻ em'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Nhập khóa học bạn muốn tìm',
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _ChipTag extends StatelessWidget {
  final String label;
  const _ChipTag({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF374151), fontSize: 12)),
    );
  }
}


