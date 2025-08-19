import 'package:flutter/material.dart';
import 'package:kfc/theme/mau_sac.dart';

class BannerPlaceholder extends StatelessWidget {
  final String title;
  final String description;
  final String? badge;
  final Color? badgeColor;

  const BannerPlaceholder({
    Key? key,
    required this.title,
    required this.description,
    this.badge,
    this.badgeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MauSac.kfcRed.withOpacity(0.8),
            MauSac.kfcRed.withOpacity(0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Pattern background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: NetworkImage('https://via.placeholder.com/400x200/FF0000/FFFFFF?text=KFC'),
                  fit: BoxFit.cover,
                  opacity: 0.1,
                ),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor ?? MauSac.vang,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: MauSac.denNen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                Text(
                  title,
                  style: const TextStyle(
                    color: MauSac.trang,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  description,
                  style: const TextStyle(
                    color: MauSac.trang,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
              
              ],
            ),
          ),
        ],
      ),
    );
  }
}