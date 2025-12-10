import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/component_model.dart';

class ComponentCard extends StatelessWidget {
  final Component component;
  final VoidCallback? onTap;

  const ComponentCard({
    super.key,
    required this.component,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Component Image
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xFFF3F4F6),
                ),
                child: component.imageUrl != null && component.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          component.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.extension, color: Color(0xFF9CA3AF), size: 32),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.extension, color: Color(0xFF9CA3AF), size: 32),
                      ),
              ),
              const SizedBox(height: 8),
              // Component Name
              Text(
                component.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Component Type
              Text(
                'Type ${component.type}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ComponentDetailDialog extends StatelessWidget {
  final Component component;

  const ComponentDetailDialog({
    super.key,
    required this.component,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(component.name),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (component.imageUrl != null && component.imageUrl!.isNotEmpty)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xFFF3F4F6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    component.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.extension, color: Color(0xFF9CA3AF), size: 32),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              component.description,
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            Text(
              'Type: ${component.type}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            if (component.specifications.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${'product.specifications'.tr()}:',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                component.specifications,
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.close'.tr()),
        ),
      ],
    );
  }
}
