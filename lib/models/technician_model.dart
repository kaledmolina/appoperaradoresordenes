class TechnicianCounts {
  final int total;
  final int assigned;
  final int inProgress;
  final int completed;
  final int special;

  TechnicianCounts({
    this.total = 0,
    this.assigned = 0,
    this.inProgress = 0,
    this.completed = 0,
    this.special = 0,
  });

  factory TechnicianCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return TechnicianCounts();
    return TechnicianCounts(
      total: json['total'] ?? 0,
      assigned: json['assigned'] ?? 0,
      inProgress: json['in_progress'] ?? 0,
      completed: json['completed'] ?? 0,
      special: json['special'] ?? 0,
    );
  }
}

class TechnicianModel {
  final int id;
  final String name;
  final String? email;
  final String? cedula;
  final String? telefono;
  final double? latitude;
  final double? longitude;
  final String? locationUpdatedAt;
  final bool isActive;
  final TechnicianCounts counts;

  TechnicianModel({
    required this.id,
    required this.name,
    this.email,
    this.cedula,
    this.telefono,
    this.latitude,
    this.longitude,
    this.locationUpdatedAt,
    this.isActive = true,
    required this.counts,
  });

  factory TechnicianModel.fromJson(Map<String, dynamic> json) {
    double? parseCoord(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return TechnicianModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Técnico sin nombre',
      email: json['email'],
      cedula: json['cedula']?.toString(),
      telefono: json['telefono']?.toString(),
      latitude: parseCoord(json['latitude']),
      longitude: parseCoord(json['longitude']),
      locationUpdatedAt: json['location_updated_at'],
      isActive: json['is_active'] ?? true,
      counts: TechnicianCounts.fromJson(json['counts'] as Map<String, dynamic>?),
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'T';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
