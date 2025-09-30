import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerBar extends StatelessWidget {
  const ShimmerBar({super.key, this.width = double.infinity, this.height = 12});
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, this.height = 140});
  final double height;
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class SectionShimmer extends StatelessWidget {
  const SectionShimmer({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerBar(width: 120, height: 16),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, __) => const SizedBox(width: 260, child: ShimmerCard(height: 170)),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: 3,
          ),
        ),
      ],
    );
  }
}


