import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/priority_badge.dart';
import '../widgets/service_type_badge.dart';
import 'photo_viewer_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderNumber;

  const OrderDetailScreen({super.key, required this.orderNumber});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService _apiService = ApiService();
  OrderModel? _order;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final order = await _apiService.getOrderDetail(widget.orderNumber);
      setState(() {
        _order = order;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchCaller(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo iniciar la llamada a $phoneNumber')),
        );
      }
    }
  }

  Future<void> _openGoogleMaps(String coordinates) async {
    final trimmed = coordinates.trim();
    if (trimmed.isEmpty) return;
    Uri url;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      url = Uri.parse(trimmed);
    } else {
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(trimmed)}');
    }
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir Google Maps: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = AuthService().token;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Orden N° ${widget.orderNumber}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: _loadOrderDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadOrderDetail,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _order == null
                  ? const Center(child: Text('Orden no encontrada'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Read-only indicator banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF1E3A8A).withAlpha(40)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF1E3A8A)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Modo Solo Lectura - Vista de Operador',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF1E3A8A),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Header Status & Priority Card
                          _buildSectionCard(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Estado Actual',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    StatusBadge(status: _order!.estadoOrden),
                                  ],
                                ),
                                if (_order!.prioridad > 0) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Nivel de Prioridad',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      PriorityBadge(priority: _order!.prioridad),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Client Information Card
                          _buildSectionCard(
                            title: 'Información del Cliente',
                            icon: Icons.person_outline_rounded,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Cliente', _order!.nombreCliente, isHighlight: true),
                                if (_order!.codigoContrato != null)
                                  _buildInfoRow('Código de Contrato', _order!.codigoContrato!, isHighlight: true),
                                if (_order!.planInternet != null) _buildInfoRow('Plan', _order!.planInternet!),
                                if (_order!.cedula != null) _buildInfoRow('Cédula / NIT', _order!.cedula!),
                                if (_order!.telefono != null && _order!.telefono!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Teléfono', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                                          Text(
                                            _order!.telefono!,
                                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.phone_rounded, size: 16),
                                        label: const Text('Llamar'),
                                        onPressed: () => _launchCaller(_order!.telefono!),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (_order!.direccion != null) _buildInfoRow('Dirección', _order!.direccion!),
                                if (_order!.barrio != null) _buildInfoRow('Barrio', _order!.barrio!),
                                if (_order!.coordenadas != null && _order!.coordenadas!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B82F6),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                    icon: const Icon(Icons.map_rounded, size: 18),
                                    label: const Text('Abrir Ubicación en Google Maps'),
                                    onPressed: () => _openGoogleMaps(_order!.coordenadas!),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Service Details Card
                          _buildSectionCard(
                            title: 'Detalles del Servicio',
                            icon: Icons.assignment_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Tipo de Orden', _order!.tipoOrdenLabel, isHighlight: true),
                                if (_order!.esOrdenManual) _buildInfoRow('Origen', 'Orden manual (creada en el panel)'),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Tipo de Servicio',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          ServiceTypeBadge(order: _order!),
                                          if (_order!.esOrdenManual) const ManualOrderTag(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_order!.solicitudSuscriptor != null)
                                  _buildInfoRow('Solicitud Suscriptor', _order!.solicitudSuscriptor!, isHighlight: true),
                                if (_order!.observacion != null && _order!.observacion!.isNotEmpty)
                                  _buildInfoRow('Observaciones', _order!.observacion!),
                                if (_order!.solucionTecnico != null)
                                  _buildInfoRow('Solución del Técnico', _order!.solucionTecnico.toString()),
                                if (_order!.materialesUtilizados != null && _order!.materialesUtilizados!.isNotEmpty)
                                  _buildInfoRow('Materiales Utilizados', _order!.materialesUtilizados!),
                                if (_order!.precintoInstalado != null) _buildInfoRow('Precinto Instalado', _order!.precintoInstalado!),
                                if (_order!.precintoRetirado != null) _buildInfoRow('Precinto Retirado', _order!.precintoRetirado!),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Technical Team & Timeline
                          _buildSectionCard(
                            title: 'Equipo Técnico & Tiempos',
                            icon: Icons.timelapse_rounded,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_order!.technicianName != null)
                                  _buildInfoRow('Técnico Asignado', _order!.technicianName!, isHighlight: true),
                                if (_order!.tecnicoAuxiliarName != null)
                                  _buildInfoRow('Técnico Auxiliar', _order!.tecnicoAuxiliarName!),
                                const SizedBox(height: 10),
                                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                const SizedBox(height: 10),
                                if (_order!.fechaAsignacion != null) _buildInfoRow('Fecha Asignación', _order!.fechaAsignacion!),
                                if (_order!.fechaLlegada != null) _buildInfoRow('Llegada a Sitio', _order!.fechaLlegada!),
                                if (_order!.fechaInicioAtencion != null) _buildInfoRow('Inicio Atención', _order!.fechaInicioAtencion!),
                                if (_order!.fechaFinAtencion != null) _buildInfoRow('Fin Atención', _order!.fechaFinAtencion!),
                                if (_order!.fechaCierre != null) _buildInfoRow('Fecha de Cierre', _order!.fechaCierre!),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Photos & Evidence Gallery
                          _buildSectionCard(
                            title: 'Evidencias Fotográficas (${_order!.fotos.length})',
                            icon: Icons.photo_camera_back_outlined,
                            child: _order!.fotos.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: Text(
                                        'No hay fotos registradas aún',
                                        style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
                                      ),
                                    ),
                                  )
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 1,
                                    ),
                                    itemCount: _order!.fotos.length,
                                    itemBuilder: (context, index) {
                                      final photo = _order!.fotos[index];
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => PhotoViewerScreen(
                                                imageUrl: photo.url,
                                                title: photo.tipoFoto ?? 'Evidencia',
                                                subtitle: photo.createdAt,
                                                authToken: token,
                                              ),
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              CachedNetworkImage(
                                                imageUrl: photo.url,
                                                httpHeaders: token != null ? {'Authorization': 'Bearer $token'} : null,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  color: Colors.grey.shade200,
                                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                ),
                                                errorWidget: (context, url, error) => Container(
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                                                ),
                                              ),
                                              if (photo.tipoFoto != null)
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  right: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                    color: Colors.black.withAlpha(160),
                                                    child: Text(
                                                      photo.tipoFoto!,
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 14),

                          // Signature Preview
                          if (_order!.signatureUrl != null && _order!.signatureUrl!.isNotEmpty)
                            _buildSectionCard(
                              title: 'Firma Registrada',
                              icon: Icons.draw_outlined,
                              child: Container(
                                height: 140,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: _order!.signatureUrl!,
                                    httpHeaders: token != null ? {'Authorization': 'Bearer $token'} : null,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    errorWidget: (context, url, error) => const Center(
                                      child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSectionCard({
    String? title,
    IconData? icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
