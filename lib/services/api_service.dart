import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/user_model.dart';
import '../models/technician_model.dart';
import '../models/order_model.dart';

class ApiService {
  static const String _defaultDomain = 'https://ordenes.intalnet.com';
  static const String baseUrl = '$_defaultDomain/api';

  final AuthService _authService = AuthService();

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authService.token != null) {
      headers['Authorization'] = 'Bearer ${_authService.token}';
    }
    return headers;
  }

  /// Inicia sesión y valida que el usuario sea operador o administrador.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/v1/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token = data['access_token'] as String;
        final userJson = data['user'] as Map<String, dynamic>;
        final rolesJson = data['roles'] as List<dynamic>?;

        final user = UserModel.fromJson(userJson, rolesJson: rolesJson);

        // Validar que tenga rol de operador o administrador
        if (!user.isOperator && !user.isAdmin) {
          throw Exception('Acceso restringido: Esta aplicación es exclusiva para Operadores y Administradores.');
        }

        await _authService.saveSession(token: token, user: user);

        return {'success': true, 'user': user, 'token': token};
      } else {
        final message = data['message'] ?? 'Error al iniciar sesión';
        throw Exception(message);
      }
    } catch (e) {
      debugPrint("Login error: $e");
      rethrow;
    }
  }

  /// Cierra sesión en el servidor y en la app
  Future<void> logout() async {
    try {
      if (_authService.token != null) {
        await http.post(
          Uri.parse('$baseUrl/v1/logout'),
          headers: _getHeaders(),
        );
      }
    } catch (e) {
      debugPrint("Logout server error: $e");
    } finally {
      await _authService.logout();
    }
  }

  /// Obtiene la lista de técnicos y estadísticas globales para el operador
  Future<Map<String, dynamic>> getTechnicians({String? search, String? tipoOrden}) async {
    final queryParams = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (tipoOrden != null && tipoOrden.trim().isNotEmpty) {
      queryParams['tipo_orden'] = tipoOrden.trim();
    }

    final endpoint = Uri.parse('$baseUrl/v1/operators/technicians')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams)
        .toString();

    final response = await http.get(
      Uri.parse(endpoint),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawList = data['technicians'] as List<dynamic>? ?? [];
      final technicians = rawList.map((t) => TechnicianModel.fromJson(t as Map<String, dynamic>)).toList();
      final stats = data['stats'] as Map<String, dynamic>? ?? {};

      return {
        'technicians': technicians,
        'stats': stats,
      };
    } else if (response.statusCode == 401) {
      await _authService.logout();
      throw Exception('Sesión expirada. Por favor ingresa nuevamente.');
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Error al cargar los técnicos');
    }
  }

  /// Obtiene las órdenes asignadas a un técnico con filtros y paginación
  Future<Map<String, dynamic>> getTechnicianOrders(
    int technicianId, {
    String status = 'todas',
    String? search,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'status': status,
      'page': page.toString(),
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl/v1/operators/technicians/$technicianId/orders')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawOrdersPagination = data['orders'] as Map<String, dynamic>? ?? {};
      final rawList = rawOrdersPagination['data'] as List<dynamic>? ?? [];
      final orders = rawList.map((o) => OrderModel.fromJson(o as Map<String, dynamic>)).toList();
      final lastPage = rawOrdersPagination['last_page'] ?? 1;
      final total = rawOrdersPagination['total'] ?? orders.length;

      return {
        'technician': data['technician'],
        'orders': orders,
        'currentPage': page,
        'lastPage': lastPage,
        'total': total,
      };
    } else if (response.statusCode == 401) {
      await _authService.logout();
      throw Exception('Sesión expirada.');
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Error al cargar las órdenes del técnico');
    }
  }

  /// Obtiene TODAS las órdenes del técnico recorriendo todas las páginas, para
  /// que los filtros rápidos se apliquen sobre el total y no solo sobre la
  /// primera página.
  Future<Map<String, dynamic>> getAllTechnicianOrders(
    int technicianId, {
    String status = 'todas',
    String? search,
    int maxPages = 25,
  }) async {
    final all = <OrderModel>[];
    var page = 1;
    var lastPage = 1;
    var total = 0;

    do {
      final result = await getTechnicianOrders(
        technicianId,
        status: status,
        search: search,
        page: page,
      );

      final pageOrders = result['orders'] as List<OrderModel>;
      all.addAll(pageOrders);
      lastPage = result['lastPage'] as int;
      total = result['total'] as int;

      if (pageOrders.isEmpty) break;
      page++;
    } while (page <= lastPage && page <= maxPages);

    return {
      'orders': all,
      'currentPage': 1,
      'lastPage': 1,
      'total': total == 0 ? all.length : total,
    };
  }

  /// Obtiene el detalle completo de solo lectura de una orden
  Future<OrderModel> getOrderDetail(String numeroOrden) async {
    final uri = Uri.parse('$baseUrl/v1/operators/orders/$numeroOrden');
    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final orderJson = data['order'] as Map<String, dynamic>;
      final fotosJson = data['fotos'] as List<dynamic>?;
      final signatureUrl = data['signature_url'] as String?;

      return OrderModel.fromJson(
        orderJson,
        fotosJson: fotosJson,
        signatureUrl: signatureUrl,
      );
    } else if (response.statusCode == 401) {
      await _authService.logout();
      throw Exception('Sesión expirada.');
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Error al cargar el detalle de la orden');
    }
  }
}
