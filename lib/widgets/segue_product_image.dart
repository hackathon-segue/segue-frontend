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
  const SegueProductImage({this.imageUrl, this.width = 237, this.height = 256, super.key});

  final String? imageUrl;
  final double width;
  final double height;

  /// API.md documents `imageUrl` as an absolute `https://...` URL, but the
  /// real backend has been observed returning a path-only value (e.g.
  /// `/images/products/bag1.png`) — resolving that against the frontend's
  /// own origin (Image.network's default for a relative URL) would always
  /// 404 since the API and the web app run on different origins. Resolving
  /// against [AppConfig.apiBaseUrl] instead makes both shapes work; already-
  /// absolute URLs (including mock data's `https://example.com/...`) pass
  /// through [Uri.resolve] unchanged.
  static String _resolve(String url) {
    final Uri parsed = Uri.parse(url);
    if (parsed.hasScheme) {
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
      _resolve(imageUrl!),
      width: width,
      height: height,
      fit: BoxFit.cover,
      headers: AppConfig.ngrokSkipWarningHeader,
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => _placeholder(),
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
