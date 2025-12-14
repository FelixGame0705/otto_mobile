import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:ottobit/models/product_model.dart';

class TechnicalSpecsSection extends StatelessWidget {
  final Product product;

  const TechnicalSpecsSection({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final hasSpecs = product.technicalSpecs.trim().isNotEmpty;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final hasCreated = product.createdAt.millisecondsSinceEpoch > 0;
    final hasUpdated = product.updatedAt.millisecondsSinceEpoch > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'product.technicalSpecs'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        if (hasSpecs)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              product.technicalSpecs,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.5,
              ),
            ),
          ),
        if (hasSpecs) const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasCreated)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 18, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Text(
                      '${'product.createdAt'.tr()}: ${dateFormat.format(product.createdAt)}',
                      style: const TextStyle(color: Color(0xFF374151), fontSize: 14),
                    ),
                  ],
                ),
              ),
            if (hasUpdated)
              Row(
                children: [
                  const Icon(Icons.update, size: 18, color: Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  Text(
                    '${'product.updatedAt'.tr()}: ${dateFormat.format(product.updatedAt)}',
                    style: const TextStyle(color: Color(0xFF374151), fontSize: 14),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
