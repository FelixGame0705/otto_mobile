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
        const ShimmerBar(width: 180, height: 20),
        const SizedBox(height: 16),
        const CourseSelectorShimmer(),
        const SizedBox(height: 16),
        const LearningPathShimmer(),
      ],
    );
  }
}

class CourseSelectorShimmer extends StatelessWidget {
  const CourseSelectorShimmer({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: 3,
      ),
    );
  }
}

class LearningPathShimmer extends StatelessWidget {
  const LearningPathShimmer({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (row) {
        final bool left = row % 2 == 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: left ? Alignment.centerRight : Alignment.centerLeft,
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Align(
                  alignment: left ? Alignment.centerLeft : Alignment.centerRight,
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: 160,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}


