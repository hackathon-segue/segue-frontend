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
    this.fit = BoxFit.cover,
    super.key,
  });

  final String? imageUrl;
  final double width;
  final double height;

  /// Every existing call site relies on the original `cover` (crops to
  /// fill the fixed box) — this default is unchanged. Callers whose box
  /// doesn't match the real photo's aspect ratio (e.g. Home's wide
  /// "진행 중인 상담" card) can pass `BoxFit.contain` instead so the product
  /// is never cropped out of frame.
  final BoxFit fit;

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
      fit: fit,
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
