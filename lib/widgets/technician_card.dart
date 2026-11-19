import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/technician_model.dart';
import '../theme/app_theme.dart';

class TechnicianCard extends StatelessWidget {
  final TechnicianModel technician;
  final VoidCallback onTap;

  const TechnicianCard({
    super.key,
    required this.technician,
    required this.onTap,
  });

  Future<void> _makeCall(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo llamar a $phone')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar, Name & Phone Action
                Row(
                  children: [
                    // Avatar Circle
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        technician.initials,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name & Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            technician.name,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (technician.telefono != null && technician.telefono!.isNotEmpty) ...[
                                const Icon(Icons.phone_outlined, size: 13, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  technician.telefono!,
                                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (technician.cedula != null) ...[
                                Text(
                                  'CC: ${technician.cedula}',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Call Button
                    if (technician.telefono != null && technician.telefono!.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF10B981)),
                        tooltip: 'Llamar al técnico',
                        onPressed: () => _makeCall(context, technician.telefono!),
                      ),
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                // Bottom Row: Order Status Counters
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCounterBadge(
                      label: 'Activas',
                      count: technician.counts.total,
                      color: AppTheme.primary,
                    ),
                    _buildCounterBadge(
                      label: 'Asignadas',
                      count: technician.counts.assigned,
                      color: AppTheme.statusAssigned,
                    ),
                    _buildCounterBadge(
                      label: 'En Proceso',
                      count: technician.counts.inProgress,
                      color: AppTheme.statusInProgress,
                    ),
                    _buildCounterBadge(
                      label: 'Especiales',
                      count: technician.counts.special,
                      color: AppTheme.statusSpecial,
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

  Widget _buildCounterBadge({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60), width: 0.8),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }
}
