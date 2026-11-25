import 'photo_model.dart';

class OrderModel {
  final int id;
  final String numeroOrden;
  final int? clienteId;
  final String nombreCliente;
  final String? cedula;
  final String? codigoContrato;
  final String? planInternet;
  final String? direccion;
  final String? barrio;
  final String? telefono;
  final String? coordenadas;
  final String? precinto;

  final String? tipoOrden;
  final String? tipoFuncion;
  final String? tipoServicio;

  /// Columna 'tipo' de la orden: 'TV' o 'CAMARA' cuando se creó manualmente
  /// desde los recursos de Órdenes de TV / Órdenes de Cámara del panel.
  final String? tipo;

  /// false = orden creada manualmente en el panel (no proviene de Enlace).
  final bool esEnlace;
  final String? solicitudSuscriptor;
  final String? observacion;
  final String? reportesNoc;
  final String estadoOrden;
  final int prioridad;

  final dynamic solucionTecnico;
  final String? materialesUtilizados;
  final String? precintoInstalado;
  final String? precintoRetirado;

  final int? technicianId;
  final String? technicianName;
  final String? tecnicoAuxiliarName;

  final String? fechaAsignacion;
  final String? fechaInicioAtencion;
  final String? fechaLlegada;
  final String? fechaFinAtencion;
  final String? fechaCierre;
  final String? fechaTrn;
  final String? createdAt;
  final String? deadlineAt;

  final List<PhotoModel> fotos;
  final String? signatureUrl;

  static const Map<String, String> tipoOrdenOptions = {
    '025': '025 REVISIÓN TÉCNICA',
    '033': '033 RECONEXIÓN',
    '037': '037 CAMBIO CONTRASEÑA',
    '038': '038 TRASLADO INTERNO',
    '004': '004 SUSPENSIÓN',
    '005': '005 RECONEXIÓN',
    '010': '010 TRASLADO',
    '018': '018 CAMBIO DE EQUIPO',
    '001': '001 INSTALACIÓN',
    '002': '002 RETIRO',
  };

  /// El servicio que realmente se instala/atiende en esta orden.
  /// El cálculo del plan lo hace la API (`tipo_servicio`); aquí solo se resuelven
  /// las órdenes manuales de TV/Cámara, que no dependen del plan del cliente.
  String get tipoServicioNormalizado {
    final tipoRegistro = (tipo ?? '').trim().toUpperCase();
    if (tipoRegistro == 'TV') return 'TV';
    if (tipoRegistro == 'CAMARA' || tipoRegistro == 'CÁMARA') return 'CAMARA';

    switch ((tipoServicio ?? '').trim().toUpperCase()) {
      case 'COMBO_AUTOMONITOREO':
      case 'INTERNET_TV_AUTOMONITOREO':
        return 'COMBO_AUTOMONITOREO';
      case 'INTERNET_AUTOMONITOREO':
      case 'CAMARA':
      case 'CÁMARA':
        return 'INTERNET_AUTOMONITOREO';
      case 'COMBO':
        return 'COMBO';
      case 'TV':
        return 'TV';
      case 'INTERNET':
      default:
        return 'INTERNET';
    }
  }

  String get tipoServicioDisplay {
    switch (tipoServicioNormalizado) {
      case 'COMBO_AUTOMONITOREO':
        return 'TV + Internet + Automonitoreo';
      case 'INTERNET_AUTOMONITOREO':
        return 'Internet + Automonitoreo';
      case 'COMBO':
        return 'TV + Internet';
      case 'TV':
        return 'Solo Televisión';
      case 'CAMARA':
        return 'Solo Cámara';
      case 'INTERNET':
      default:
        return 'Solo Internet';
    }
  }

  /// Orden creada manualmente en el panel (no sincronizada desde Enlace).
  bool get esOrdenManual => !esEnlace;

  String get tipoOrdenLabel {
    if (tipoOrden == null || tipoOrden!.trim().isEmpty) return 'Sin tipo especificado';
    final trimmed = tipoOrden!.trim();
    return tipoOrdenOptions[trimmed] ?? tipoOrdenOptions[trimmed.padLeft(3, '0')] ?? tipoOrden!;
  }

  OrderModel({
    required this.id,
    required this.numeroOrden,
    this.clienteId,
    required this.nombreCliente,
    this.cedula,
    this.codigoContrato,
    this.planInternet,
    this.direccion,
    this.barrio,
    this.telefono,
    this.coordenadas,
    this.precinto,
    this.tipoOrden,
    this.tipoFuncion,
    this.tipoServicio,
    this.tipo,
    this.esEnlace = true,
    this.solicitudSuscriptor,
    this.observacion,
    this.reportesNoc,
    required this.estadoOrden,
    this.prioridad = 0,
    this.solucionTecnico,
    this.materialesUtilizados,
    this.precintoInstalado,
    this.precintoRetirado,
    this.technicianId,
    this.technicianName,
    this.tecnicoAuxiliarName,
    this.fechaAsignacion,
    this.fechaInicioAtencion,
    this.fechaLlegada,
    this.fechaFinAtencion,
    this.fechaCierre,
    this.fechaTrn,
    this.createdAt,
    this.deadlineAt,
    this.fotos = const [],
    this.signatureUrl,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json, {List<dynamic>? fotosJson, String? signatureUrl}) {
    // Cliente nested or direct
    final cliente = json['cliente'] as Map<String, dynamic>?;
    final tech = json['technician'] as Map<String, dynamic>?;
    final auxTech = json['tecnico_auxiliar'] as Map<String, dynamic>?;

    String? cleanText(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    String? parseBarrio = json['barrio']?.toString();
    if (parseBarrio == null && cliente != null) {
      parseBarrio = cliente['barrio']?.toString();
    }

    String? parseTelefono = json['telefono']?.toString();
    if ((parseTelefono == null || parseTelefono.isEmpty) && cliente != null) {
      parseTelefono = cliente['telefono']?.toString() ?? cliente['telefono_facturacion']?.toString();
    }

    String? parseDireccion = json['direccion']?.toString();
    if ((parseDireccion == null || parseDireccion.isEmpty) && cliente != null) {
      parseDireccion = cliente['direccion']?.toString();
    }

    String? parseCedula = json['cedula']?.toString();
    if ((parseCedula == null || parseCedula.isEmpty) && cliente != null) {
      parseCedula = cliente['cedula']?.toString();
    }

    List<PhotoModel> parsedPhotos = [];
    if (fotosJson != null) {
      parsedPhotos = fotosJson.map((f) => PhotoModel.fromJson(f as Map<String, dynamic>)).toList();
    } else if (json['fotos'] != null && json['fotos'] is List) {
      parsedPhotos = (json['fotos'] as List).map((f) => PhotoModel.fromJson(f as Map<String, dynamic>)).toList();
    }

    return OrderModel(
      id: json['id'] ?? 0,
      numeroOrden: json['numero_orden']?.toString() ?? '',
      clienteId: json['cliente_id'],
      nombreCliente: json['nombre_cliente'] ?? cliente?['name'] ?? 'Sin Nombre',
      cedula: parseCedula,
      codigoContrato: cleanText(json['codigo_contrato'] ?? cliente?['codigo_contrato']),
      planInternet: cleanText(json['plan_internet'] ?? cliente?['plan_internet']),
      direccion: parseDireccion,
      barrio: parseBarrio,
      telefono: parseTelefono,
      coordenadas: json['coordenadas']?.toString(),
      precinto: json['precinto']?.toString(),
      tipoOrden: json['tipo_orden']?.toString(),
      tipoFuncion: json['tipo_funcion']?.toString(),
      tipoServicio: json['tipo_servicio']?.toString(),
      tipo: json['tipo']?.toString(),
      esEnlace: json['es_enlace'] == true || json['es_enlace'] == 1 || json['es_enlace'] == '1',
      solicitudSuscriptor: json['solicitud_suscriptor']?.toString(),
      observacion: json['observacion']?.toString(),
      reportesNoc: json['reportes_noc']?.toString(),
      estadoOrden: json['estado_orden']?.toString() ?? 'pendiente',
      prioridad: json['prioridad'] is int ? json['prioridad'] : int.tryParse(json['prioridad']?.toString() ?? '0') ?? 0,
      solucionTecnico: json['solucion_tecnico'],
      materialesUtilizados: json['materiales_utilizados']?.toString(),
      precintoInstalado: json['precinto_instalado']?.toString(),
      precintoRetirado: json['precinto_retirado']?.toString(),
      technicianId: json['technician_id'],
      technicianName: tech?['name'] ?? json['technician_name']?.toString(),
      tecnicoAuxiliarName: auxTech?['name'],
      fechaAsignacion: json['fecha_asignacion']?.toString(),
      fechaInicioAtencion: json['fecha_inicio_atencion']?.toString(),
      fechaLlegada: json['fecha_llegada']?.toString(),
      fechaFinAtencion: json['fecha_fin_atencion']?.toString(),
      fechaCierre: json['fecha_cierre']?.toString(),
      fechaTrn: json['fecha_trn']?.toString(),
      createdAt: json['created_at']?.toString(),
      deadlineAt: json['deadline_at']?.toString(),
      fotos: parsedPhotos,
      signatureUrl: signatureUrl ?? json['signature_url']?.toString(),
    );
  }
}
