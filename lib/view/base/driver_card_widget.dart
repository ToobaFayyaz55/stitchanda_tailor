import 'package:flutter/material.dart';
import 'package:stichanda_tailor/data/models/driver_model.dart';
import 'package:stichanda_tailor/theme/theme.dart';

/// Driver Card Widget - displays driver info with selection capability
class DriverCard extends StatelessWidget {
  final Driver driver;
  final VoidCallback onSelect;
  final bool isSelected;
  final bool isLoading;

  const DriverCard({
    Key? key,
    required this.driver,
    required this.onSelect,
    this.isSelected = false,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppColors.caramel : AppColors.outline,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? AppColors.caramel.withValues(alpha: 0.05) : AppColors.surface,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onSelect,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver Header Row
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.beige.withValues(alpha: 0.3),
                        border: Border.all(
                          color: AppColors.caramel,
                          width: 1,
                        ),
                      ),
                      child: driver.profileImagePath.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Image.network(
                                driver.profileImagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.person,
                                      color: AppColors.deepBrown,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.person,
                                color: AppColors.deepBrown,
                                size: 24,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Driver Name and Rating
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textBlack,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amber[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${driver.rating.toStringAsFixed(1)} (${driver.vehicleType})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Selection Indicator
                    if (isSelected)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.caramel,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      )
                    else
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.outline,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Contact Info Row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: AppColors.deepBrown,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              driver.phone,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 16,
                            color: AppColors.deepBrown,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              driver.email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Driver Card List Item - simplified version for list views
class DriverListTile extends StatelessWidget {
  final Driver driver;
  final VoidCallback onTap;

  const DriverListTile({
    Key? key,
    required this.driver,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.beige.withValues(alpha: 0.3),
          ),
          child: driver.profileImagePath.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(22.5),
                  child: Image.network(
                    driver.profileImagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person);
                    },
                  ),
                )
              : const Icon(Icons.person),
        ),
        title: Text(
          driver.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star_rounded, size: 12, color: Colors.amber[600]),
                const SizedBox(width: 4),
                Text('${driver.rating.toStringAsFixed(1)} • ${driver.vehicleType}'),
              ],
            ),
            const SizedBox(height: 4),
            Text(driver.phone, style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}

