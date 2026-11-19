class PhotoModel {
  final int id;
  final int ordenId;
  final String path;
  final String url;
  final String? tipoFoto;
  final String? createdAt;

  PhotoModel({
    required this.id,
    required this.ordenId,
    required this.path,
    required this.url,
    this.tipoFoto,
    this.createdAt,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'] ?? 0,
      ordenId: json['orden_id'] ?? 0,
      path: json['path'] ?? '',
      url: json['url'] ?? json['foto_url'] ?? '',
      tipoFoto: json['tipo_foto'] ?? json['tipo'],
      createdAt: json['created_at'],
    );
  }
}
