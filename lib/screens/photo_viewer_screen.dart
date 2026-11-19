import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PhotoViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String? authToken;

  const PhotoViewerScreen({
    super.key,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.authToken,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withAlpha(200),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title ?? 'Evidencia Fotográfica',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            httpHeaders: authToken != null ? {'Authorization': 'Bearer $authToken'} : null,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image_rounded, size: 48, color: Colors.white54),
                const SizedBox(height: 12),
                Text(
                  'No se pudo cargar la imagen',
                  style: GoogleFonts.inter(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
