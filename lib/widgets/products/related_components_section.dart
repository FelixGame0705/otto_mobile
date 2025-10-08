import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/component_model.dart';
import 'package:ottobit/widgets/products/component_card.dart';

class RelatedComponentsSection extends StatelessWidget {
  final List<Component> components;
  final bool isLoadingComponents;
  final Function(Component) onComponentTap;

  const RelatedComponentsSection({
    super.key,
    required this.components,
    required this.isLoadingComponents,
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
        else if (components.isEmpty)
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
              scrollDirection: Axis.horizontal,
              itemCount: components.length,
              itemBuilder: (context, index) {
                final component = components[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  child: ComponentCard(
                    component: component,
                    onTap: () => onComponentTap(component),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
