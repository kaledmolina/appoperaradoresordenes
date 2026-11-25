import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/technician_model.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';

class TechnicianOrdersScreen extends StatefulWidget {
  final TechnicianModel technician;

  const TechnicianOrdersScreen({super.key, required this.technician});

  @override
  State<TechnicianOrdersScreen> createState() => _TechnicianOrdersScreenState();
}

class _TechnicianOrdersScreenState extends State<TechnicianOrdersScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  final List<String> _statusFilters = ['todas', 'asignadas', 'en_proceso', 'pendientes', 'especiales'];
  final List<String> _tabLabels = ['Todas Activas', 'Asignadas', 'En Proceso', 'Pendientes', 'Especiales'];

  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalOrders = 0;

  // Filtros rápidos (se aplican sobre las órdenes cargadas)
  String? _servicioFilter;
  bool _soloPrioridadAlta = false;
  bool _soloVencidas = false;

  bool get _hayFiltrosActivos =>
      _servicioFilter != null || _soloPrioridadAlta || _soloVencidas;

  List<OrderModel> get _filteredOrders {
    return _orders.where((o) {
      if (_servicioFilter != null) {
        final tipo = o.tipoServicioNormalizado;
        final coincide = switch (_servicioFilter) {
          'INTERNET' => tipo == 'INTERNET',
          'COMBO' => tipo == 'COMBO',
          'CAMARA' => tipo == 'CAMARA' ||
              tipo == 'INTERNET_AUTOMONITOREO' ||
              tipo == 'COMBO_AUTOMONITOREO',
          'MANUAL' => o.esOrdenManual,
          _ => true,
        };
        if (!coincide) return false;
      }
      if (_soloPrioridadAlta && o.prioridad < 3) return false;
      if (_soloVencidas && !_isOverdue(o)) return false;
      return true;
    }).toList();
  }

  bool _isOverdue(OrderModel order) {
    final raw = order.deadlineAt;
    if (raw == null || raw.trim().isEmpty) return false;
    final deadline = DateTime.tryParse(raw.trim().replaceFirst(' ', 'T'));
    if (deadline == null) return false;
    return deadline.isBefore(DateTime.now().toUtc());
  }

  void _limpiarFiltros() {
    setState(() {
      _servicioFilter = null;
      _soloPrioridadAlta = false;
      _soloVencidas = false;
    });
  }

  Widget _buildQuickFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(
              label: 'Todos',
              icon: Icons.apps_rounded,
              selected: !_hayFiltrosActivos,
              onSelected: _limpiarFiltros,
            ),
            _filterChip(
              label: 'Solo Internet',
              icon: Icons.wifi_rounded,
              selected: _servicioFilter == 'INTERNET',
              onSelected: () => setState(() {
                _servicioFilter = _servicioFilter == 'INTERNET' ? null : 'INTERNET';
              }),
            ),
            _filterChip(
              label: 'TV + Internet',
              icon: Icons.tv_rounded,
              selected: _servicioFilter == 'COMBO',
              onSelected: () => setState(() {
                _servicioFilter = _servicioFilter == 'COMBO' ? null : 'COMBO';
              }),
            ),
            _filterChip(
              label: 'Cámara',
              icon: Icons.videocam_rounded,
              selected: _servicioFilter == 'CAMARA',
              onSelected: () => setState(() {
                _servicioFilter = _servicioFilter == 'CAMARA' ? null : 'CAMARA';
              }),
            ),
            _filterChip(
              label: 'Manuales',
              icon: Icons.build_circle_outlined,
              selected: _servicioFilter == 'MANUAL',
              onSelected: () => setState(() {
                _servicioFilter = _servicioFilter == 'MANUAL' ? null : 'MANUAL';
              }),
            ),
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: const Color(0xFFE2E8F0),
            ),
            _filterChip(
              label: 'Prioridad alta',
              icon: Icons.local_fire_department_rounded,
              selected: _soloPrioridadAlta,
              onSelected: () => setState(() {
                _soloPrioridadAlta = !_soloPrioridadAlta;
              }),
            ),
            _filterChip(
              label: 'Vencidas',
              icon: Icons.schedule_rounded,
              selected: _soloVencidas,
              onSelected: () => setState(() {
                _soloVencidas = !_soloVencidas;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        onSelected: (_) => onSelected(),
        avatar: Icon(
          icon,
          size: 16,
          color: selected ? AppTheme.primary : AppTheme.textSecondary,
        ),
        label: Text(label),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? AppTheme.primary : AppTheme.textSecondary,
        ),
        showCheckmark: false,
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primary.withAlpha(20),
        side: BorderSide(
          color: selected ? AppTheme.primary : const Color(0xFFE2E8F0),
          width: selected ? 1.2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadOrders(resetPage: true);
      }
    });
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 1;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentStatus = _statusFilters[_tabController.index];
      // Se traen todas las páginas para que los filtros rápidos cubran el total
      // de órdenes del técnico y no solo la página visible.
      final result = await _apiService.getAllTechnicianOrders(
        widget.technician.id,
        status: currentStatus,
        search: _searchController.text,
      );

      setState(() {
        _orders = result['orders'] as List<OrderModel>;
        _currentPage = result['currentPage'] as int;
        _lastPage = result['lastPage'] as int;
        _totalOrders = result['total'] as int;
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

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Órdenes de Trabajo',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Technician Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.technician.initials,
                    style: GoogleFonts.outfit(
                      color: AppTheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.technician.name,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Órdenes activas en curso: ${widget.technician.counts.total}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.technician.telefono != null && widget.technician.telefono!.isNotEmpty)
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF10B981).withAlpha(25)),
                    icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF10B981), size: 20),
                    tooltip: 'Llamar al técnico',
                    onPressed: () => _makeCall(widget.technician.telefono!),
                  ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _loadOrders(resetPage: true),
              decoration: InputDecoration(
                hintText: 'Buscar por N° orden, cliente, dirección...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textSecondary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded, size: 18, color: AppTheme.primary),
                  onPressed: () => _loadOrders(resetPage: true),
                ),
              ),
            ),
          ),

          // Tab Bar Filters
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
            ),
          ),

          _buildQuickFilters(),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _hayFiltrosActivos
                        ? 'Mostrando ${_filteredOrders.length} de ${_orders.length} órdenes · filtros aplicados'
                        : (_lastPage > 1
                            ? 'Mostrando ${_orders.length} de $_totalOrders órdenes (Pág. $_currentPage de $_lastPage)'
                            : 'Mostrando ${_orders.length} de $_totalOrders órdenes'),
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
                if (_hayFiltrosActivos)
                  TextButton.icon(
                    onPressed: _limpiarFiltros,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 15),
                    label: Text('Limpiar', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadOrders(resetPage: true),
              color: AppTheme.primary,
              child: _isLoading
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
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => _loadOrders(resetPage: true),
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _filteredOrders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _hayFiltrosActivos ? Icons.filter_alt_off_rounded : Icons.inbox_outlined,
                                    size: 54,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _hayFiltrosActivos
                                        ? 'Ninguna orden coincide con los filtros'
                                        : 'No hay órdenes en este estado',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _hayFiltrosActivos
                                        ? 'Prueba con otro filtro o quítalos'
                                        : 'El técnico no tiene órdenes asignadas aquí',
                                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                  if (_hayFiltrosActivos) ...[
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: _limpiarFiltros,
                                      icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                                      label: Text('Limpiar filtros', style: GoogleFonts.inter(fontSize: 13)),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = _filteredOrders[index];
                                return OrderCard(
                                  order: order,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => OrderDetailScreen(orderNumber: order.numeroOrden),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
