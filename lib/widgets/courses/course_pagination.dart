import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class CoursePagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final Function(int)? onPageSelected;

  const CoursePagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    this.onPreviousPage,
    this.onNextPage,
    this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final startItem = (currentPage - 1) * pageSize + 1;
    final endItem = (currentPage * pageSize).clamp(0, totalItems);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Page Info
          Text(
            'pagination.showing'.tr(namedArgs: {
              'start': '$startItem',
              'end': '$endItem',
              'total': '$totalItems',
            }),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Pagination Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous Button
              IconButton(
                onPressed: currentPage > 1 ? onPreviousPage : null,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: currentPage > 1 
                      ? const Color(0xFF4299E1)
                      : Colors.grey[300],
                  foregroundColor: currentPage > 1 ? Colors.white : Colors.grey[600],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Page Numbers
              ..._buildPageNumbers(),
              
              const SizedBox(width: 8),
              
              // Next Button
              IconButton(
                onPressed: currentPage < totalPages ? onNextPage : null,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: currentPage < totalPages 
                      ? const Color(0xFF4299E1)
                      : Colors.grey[300],
                  foregroundColor: currentPage < totalPages ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final List<Widget> pageNumbers = [];
    final int maxVisiblePages = 5;
    
    int startPage = (currentPage - maxVisiblePages / 2).clamp(1, totalPages - maxVisiblePages + 1).toInt();
    int endPage = (startPage + maxVisiblePages - 1).clamp(1, totalPages);
    
    // Adjust start if we're near the end
    if (endPage - startPage + 1 < maxVisiblePages) {
      startPage = (endPage - maxVisiblePages + 1).clamp(1, totalPages);
    }

    // Add first page and ellipsis if needed
    if (startPage > 1) {
      pageNumbers.add(_buildPageButton(1));
      if (startPage > 2) {
        pageNumbers.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: Color(0xFF718096))),
        ));
      }
    }

    // Add visible page numbers
    for (int i = startPage; i <= endPage; i++) {
      pageNumbers.add(_buildPageButton(i));
    }

    // Add ellipsis and last page if needed
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        pageNumbers.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: Color(0xFF718096))),
        ));
      }
      pageNumbers.add(_buildPageButton(totalPages));
    }

    return pageNumbers;
  }

  Widget _buildPageButton(int pageNumber) {
    final isCurrentPage = pageNumber == currentPage;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => onPageSelected?.call(pageNumber),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentPage 
                ? const Color(0xFF4299E1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isCurrentPage 
                ? null
                : Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            '$pageNumber',
            style: TextStyle(
              color: isCurrentPage 
                  ? Colors.white
                  : const Color(0xFF2D3748),
              fontWeight: isCurrentPage 
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
