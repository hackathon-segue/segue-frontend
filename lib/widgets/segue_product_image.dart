import 'package:flutter/material.dart';

import '../utils/app_config.dart';
import '../utils/segue_card_tokens.dart';

/// Product photo widget matching Figma's "image 14/16/17" instances (same
/// fixed width/height/position as those Figma nodes — never Figma's own
/// example photo). Renders the real backend-provided `imageUrl` when it's
/// present and loads successfully; falls back to a neutral placeholder box
/// at the exact same size when `imageUrl` is null, empty, or fails to load.
///
/// Callers that don't pass `imageUrl` (unchanged call sites outside the
/// Last Intent result-detail flow) keep the old placeholder-only behavior.
class SegueProductImage extends StatelessWidget {
  const SegueProductImage({
    this.imageUrl,
    this.width = 237,
    this.height = 256,
    super.key,
  });

  final String? imageUrl;
  final double width;
  final double height;

  static String _resolveImageUrl(String url) {
    final Uri uri = Uri.parse(url);
    if (uri.hasScheme) {
      return url;
    }
    return Uri.parse(AppConfig.apiBaseUrl).resolve(url).toString();
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _placeholder();
    }
    return Image.network(
      _resolveImageUrl(imageUrl!),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) =>
              _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SegueCardColors.sidebarBg,
        border: Border.all(color: SegueCardColors.border),
      ),
      child: const Text('Image', style: SegueCardText.placeholder14),
    );
  }
}
