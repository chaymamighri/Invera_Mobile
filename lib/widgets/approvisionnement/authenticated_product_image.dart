import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';

class AuthenticatedProductImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget Function() fallbackBuilder;

  const AuthenticatedProductImage({
    super.key,
    required this.imageUrl,
    required this.fallbackBuilder,
    this.fit = BoxFit.cover,
  });

  @override
  State<AuthenticatedProductImage> createState() =>
      _AuthenticatedProductImageState();
}

class _AuthenticatedProductImageState extends State<AuthenticatedProductImage> {
  late Future<Uint8List>? _protectedImageFuture;

  @override
  void initState() {
    super.initState();
    _protectedImageFuture = _isBackendUpload(widget.imageUrl)
        ? _loadProtectedImage(widget.imageUrl)
        : null;
  }

  @override
  void didUpdateWidget(covariant AuthenticatedProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _protectedImageFuture = _isBackendUpload(widget.imageUrl)
          ? _loadProtectedImage(widget.imageUrl)
          : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final future = _protectedImageFuture;
    if (future == null) {
      return Image.network(
        widget.imageUrl,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => widget.fallbackBuilder(),
      );
    }

    return FutureBuilder<Uint8List>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: widget.fit,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => widget.fallbackBuilder(),
          );
        }

        if (snapshot.hasError) {
          return widget.fallbackBuilder();
        }

        return widget.fallbackBuilder();
      },
    );
  }

  static bool _isBackendUpload(String imageUrl) {
    final imageUri = Uri.tryParse(imageUrl);
    final baseUri = Uri.tryParse(ApiConfig.baseUrl);
    if (imageUri == null || baseUri == null) return false;

    return imageUri.scheme == baseUri.scheme &&
        imageUri.host == baseUri.host &&
        imageUri.port == baseUri.port &&
        imageUri.path.startsWith('/uploads/');
  }

  static Future<Uint8List> _loadProtectedImage(String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token')?.trim();
    final headers = <String, String>{};

    if (token != null && token.isNotEmpty) {
      headers[ApiConfig.authHeader] = '${ApiConfig.bearerPrefix}$token';
    }

    final response = await http.get(Uri.parse(imageUrl), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Image request failed with ${response.statusCode}');
    }

    return response.bodyBytes;
  }
}
