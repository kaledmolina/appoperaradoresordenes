import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';

/// Muestra el servicio real de la orden tal como lo verá el técnico:
/// Solo Internet, TV + Internet, Solo Cámara, Solo Televisión o los combos
/// con automonitoreo.
class ServiceTypeBadge extends StatelessWidget {
  final OrderModel order;
  final bool compact;

  const ServiceTypeBadge({
    super.key,
    required this.order,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tipo = order.tipoServicioNormalizado;

    Color bgColor;
    Color borderColor;
    Color textColor;
    List<Widget> contentChildren;

    switch (tipo) {
      case 'COMBO_AUTOMONITOREO':
        bgColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFF10B981);
        textColor = const Color(0xFF065F46);
        contentChildren = [
          Icon(Icons.tv, size: compact ? 12 : 14, color: textColor),
          _plus(textColor),
          Icon(Icons.wifi, size: compact ? 12 : 14, color: textColor),
          _plus(textColor),
          Icon(Icons.shield_outlined, size: compact ? 12 : 14, color: textColor),
          const SizedBox(width: 4),
          _label(compact ? 'TV + INT + AUTO' : 'TV + INTERNET + AUTOMONITOREO', textColor),
        ];
        break;
      case 'INTERNET_AUTOMONITOREO':
        bgColor = const Color(0xFFF0FDFA);
        borderColor = const Color(0xFF14B8A6);
        textColor = const Color(0xFF115E59);
        contentChildren = [
          Icon(Icons.wifi, size: compact ? 12 : 14, color: textColor),
          _plus(textColor),
          Icon(Icons.shield_outlined, size: compact ? 12 : 14, color: textColor),
          const SizedBox(width: 4),
          _label(compact ? 'INT + AUTO' : 'INTERNET + AUTOMONITOREO', textColor),
        ];
        break;
      case 'COMBO':
        bgColor = const Color(0xFFF3E8FF);
        borderColor = const Color(0xFFA855F7);
        textColor = const Color(0xFF6B21A8);
        contentChildren = [
          Icon(Icons.tv, size: compact ? 12 : 14, color: textColor),
          _plus(textColor),
          Icon(Icons.wifi, size: compact ? 12 : 14, color: textColor),
          const SizedBox(width: 4),
          _label('TV + INTERNET', textColor),
        ];
        break;
      case 'TV':
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFF59E0B);
        textColor = const Color(0xFF92400E);
        contentChildren = [
          Icon(Icons.tv, size: compact ? 12 : 15, color: textColor),
          const SizedBox(width: 4),
          _label('SOLO TELEVISIÓN', textColor),
        ];
        break;
      case 'CAMARA':
        bgColor = const Color(0xFFEEF2FF);
        borderColor = const Color(0xFF6366F1);
        textColor = const Color(0xFF3730A3);
        contentChildren = [
          Icon(Icons.videocam, size: compact ? 12 : 15, color: textColor),
          const SizedBox(width: 4),
          _label('SOLO CÁMARA', textColor),
        ];
        break;
      case 'INTERNET':
      default:
        bgColor = const Color(0xFFE0F2FE);
        borderColor = const Color(0xFF0284C7);
        textColor = const Color(0xFF075985);
        contentChildren = [
          Icon(Icons.wifi, size: compact ? 12 : 15, color: textColor),
          const SizedBox(width: 4),
          _label('SOLO INTERNET', textColor),
        ];
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 9,
        vertical: compact ? 2 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: contentChildren,
      ),
    );
  }

  Widget _plus(Color color) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          '+',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: compact ? 9 : 11,
          ),
        ),
      );

  Widget _label(String text, Color color) => Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      );
}

/// Etiqueta pequeña para las órdenes creadas manualmente en el panel.
class ManualOrderTag extends StatelessWidget {
  final bool compact;

  const ManualOrderTag({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(color: const Color(0xFFF97316), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.build_circle_outlined, size: compact ? 11 : 13, color: const Color(0xFFC2410C)),
          const SizedBox(width: 3),
          Text(
            'MANUAL',
            style: GoogleFonts.inter(
              color: const Color(0xFFC2410C),
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
