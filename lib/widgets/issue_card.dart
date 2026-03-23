import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';

class IssueCard extends StatelessWidget {
  final Map<String, dynamic> issue;
  final VoidCallback onTap;
  final Widget? trailing;

  const IssueCard({
    super.key,
    required this.issue,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final status = issue['status'] ?? 'Pending';
    final category = issue['category'] ?? 'General';
    final isAssigned = issue['assigned_to'] != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCategoryBadge(category),
                  _buildStatusChip(status, isAssigned),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                issue['title'] ?? 'No Title',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                issue['description'] ?? 'No description provided.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary.withOpacity(0.6)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      issue['location'] ?? 'Unknown location',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withOpacity(0.8),
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF5E92C1),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isAssigned) {
    Color color;
    switch (status.toLowerCase()) {
      case 'resolved':
        color = AppColors.success;
        break;
      case 'completed':
        color = const Color(0xFF81D4FA);
        break;
      case 'in progress':
      case 'assigned':
        color = AppColors.primary;
        break;
      case 'rejected':
        color = AppColors.error;
        break;
      case 'pending':
      default:
        color = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color.withOpacity(0.9),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
