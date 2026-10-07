import 'package:flutter/material.dart';
import '../../data/models/category_model.dart';
import '../constants/app_colors.dart';

class CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circle avatar card matching item_category_home.xml
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primaryLight.withOpacity(0.4) : Colors.white,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade200,
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: category.iconUrl != null && category.iconUrl!.isNotEmpty
                    ? Image.network(
                        category.iconUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                      )
                    : _buildFallbackIcon(),
              ),
            ),
            const SizedBox(height: 6),
            // Category Name (matching 12sp, max 2 lines, centered)
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF424242),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    IconData iconData = Icons.restaurant;
    final nameLower = category.name.toLowerCase();
    if (nameLower.contains('tất cả')) {
      iconData = Icons.grid_view_rounded;
    } else if (nameLower.contains('cơm')) {
      iconData = Icons.rice_bowl;
    } else if (nameLower.contains('bún') || nameLower.contains('phở') || nameLower.contains('mì')) {
      iconData = Icons.ramen_dining;
    } else if (nameLower.contains('trà sữa') || nameLower.contains('uống')) {
      iconData = Icons.local_cafe;
    } else if (nameLower.contains('bánh')) {
      iconData = Icons.lunch_dining;
    } else if (nameLower.contains('vặt')) {
      iconData = Icons.fastfood;
    }

    return Center(
      child: Icon(
        iconData,
        color: isSelected ? AppColors.primary : Colors.grey.shade700,
        size: 26,
      ),
    );
  }
}
