import 'package:flutter/material.dart';

class TmdbPosterImage extends StatelessWidget {
  const TmdbPosterImage({
    super.key,
    required this.posterPath,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  final String? posterPath;
  final double width;
  final double height;
  final BoxFit fit;

  static const String _baseUrl =
      'https://image.tmdb.org/t/p/w500';

  String? get _imageUrl {
    if (posterPath == null || posterPath!.isEmpty) {
      return null;
    }

    return '$_baseUrl$posterPath';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl;

    if (imageUrl == null) {
      return _placeholder();
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return _placeholder();
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 40,
        color: Colors.grey,
      ),
    );
  }
}
