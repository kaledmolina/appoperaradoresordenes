import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/technician_model.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/technician_card.dart';
import 'technician_orders_screen.dart';
import 'login_screen.dart';

class TechniciansScreen extends StatefulWidget {
  const TechniciansScreen({super.key});

  @override
  State<TechniciansScreen> createState() => _TechniciansScreenState();
}

class _TechniciansScreenState extends State<TechniciansScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<TechnicianModel> _technicians = [];
  List<TechnicianModel> _filteredTechnicians = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _errorMessage;

  /// Código del tipo de orden por el que se filtran los contadores y las
  /// órdenes al entrar al técnico (null = todos los tipos).
  String? _tipoOrdenFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterTechnicians);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTechnicians() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredTechnicians = _technicians;
      } else {
        _filteredTechnicians = _technicians.where((tech) {
          final nameMatch = tech.name.toLowerCase().contains(query);
          final emailMatch = (tech.email ?? '').toLowerCase().contains(query);
          final cedulaMatch = (tech.cedula ?? '').toLowerCase().contains(query);
          final phoneMatch = (tech.telefono ?? '').toLowerCase().contains(query);
          return nameMatch || emailMatch || cedulaMatch || phoneMatch;
        }).toList();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getTechnicians(tipoOrden: _tipoOrdenFilter);
      setState(() {
        _technicians = result['technicians'] as List<TechnicianModel>;
        _filteredTechnicians = _technicians;
        _stats = result['stats'] as Map<String, dynamic>;
        _filterTechnicians();
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

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cerrar Sesión', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que deseas salir del panel?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Cerrar Sesión', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Técnicos de Campo',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            if (currentUser != null)
              Text(
                'Operador: ${currentUser.name}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            tooltip: 'Actualizar lista',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Cerrar sesión',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
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
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      // Global KPIs & Stats
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // KPI Cards Grid
                              Row(
                                children: [
                                  Expanded(
                                    child: StatCard(
                                      title: 'Técnicos',
                                      value: '${_stats['total_technicians'] ?? _technicians.length}',
                                      icon: Icons.engineering_rounded,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: StatCard(
                                      title: 'Asignadas',
                                      value: '${_stats['total_assigned_orders'] ?? 0}',
                                      icon: Icons.assignment_outlined,
                                      color: AppTheme.statusAssigned,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: StatCard(
                                      title: 'En Proceso',
                                      value: '${_stats['total_in_progress_orders'] ?? 0}',
                                      icon: Icons.run_circle_outlined,
                                      color: AppTheme.statusInProgress,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: StatCard(
                                      title: 'Especiales',
                                      value: '${_stats['total_special_orders'] ?? 0}',
                                      icon: Icons.warning_amber_rounded,
                                      color: AppTheme.statusSpecial,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Search Bar
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Buscar técnico por nombre, cédula o teléfono...',
                                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                          },
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Filtro por tipo de orden (antes de elegir técnico)
                              DropdownButtonFormField<String>(
                                initialValue: _tipoOrdenFilter ?? '',
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de orden',
                                  prefixIcon: Icon(Icons.assignment_outlined, size: 20, color: AppTheme.textSecondary),
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: '',
                                    child: Text(
                                      'Todos los tipos de orden',
                                      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  ...OrderModel.tipoOrdenOptions.entries.map(
                                    (e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(
                                        e.value,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _tipoOrdenFilter = (value == null || value.isEmpty) ? null : value;
                                  });
                                  _loadData();
                                },
                              ),
                              const SizedBox(height: 16),

                              // Section Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Selecciona un Técnico (${_filteredTechnicians.length})',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),

                      // Technicians List
                      if (_filteredTechnicians.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.person_search_rounded, size: 54, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No se encontraron técnicos',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Intenta con otro término de búsqueda',
                                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final tech = _filteredTechnicians[index];
                                return TechnicianCard(
                                  technician: tech,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TechnicianOrdersScreen(
                                          technician: tech,
                                          initialTipoOrden: _tipoOrdenFilter,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              childCount: _filteredTechnicians.length,
                            ),
                          ),
                        ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 32),
                      ),
                    ],
                  ),
      ),
    );
  }
}
