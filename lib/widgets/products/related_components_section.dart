import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/component_model.dart';

class RelatedComponentsSection extends StatelessWidget {
  final List<RobotComponent> robotComponents;
  final bool isLoadingComponents;
  final bool isLoadingMore;
  final bool hasMore;
  final ScrollController scrollController;
  final Function(RobotComponent) onComponentTap;

  const RelatedComponentsSection({
    super.key,
    required this.robotComponents,
    required this.isLoadingComponents,
    required this.isLoadingMore,
    required this.hasMore,
    required this.scrollController,
    required this.onComponentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'product.relatedComponents'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        if (isLoadingComponents)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (robotComponents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                const Icon(Icons.extension, color: Color(0xFF9CA3AF), size: 48),
                const SizedBox(height: 12),
                Text(
                  'product.noComponents'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: robotComponents.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= robotComponents.length) {
                  // Loading indicator at the end
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final robotComponent = robotComponents[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  child: RobotComponentCard(
                    robotComponent: robotComponent,
                    onTap: () => onComponentTap(robotComponent),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class RobotComponentCard extends StatelessWidget {
  final RobotComponent robotComponent;
  final VoidCallback? onTap;

  const RobotComponentCard({
    super.key,
    required this.robotComponent,
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
                child: robotComponent.componentImageUrl != null && 
                       robotComponent.componentImageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          robotComponent.componentImageUrl!,
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
                robotComponent.componentName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Quantity
              Text(
                '${'product.quantity'.tr()}: ${robotComponent.quantity}',
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

class RobotComponentDetailDialog extends StatelessWidget {
  final RobotComponent robotComponent;

  const RobotComponentDetailDialog({
    super.key,
    required this.robotComponent,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(robotComponent.componentName),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (robotComponent.componentImageUrl != null && 
                robotComponent.componentImageUrl!.isNotEmpty)
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
                    robotComponent.componentImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.extension, color: Color(0xFF9CA3AF), size: 32),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              '${'product.quantity'.tr()}: ${robotComponent.quantity}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            Text(
              '${'product.robotName'.tr()}: ${robotComponent.robotName}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
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
