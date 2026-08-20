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
    this.fallback,
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
  final Widget? fallback;

  static const Set<String> _localImageHosts = <String>{
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
    '10.0.2.2',
  };

  static bool hasUsableImageUrl(String? url) {
    final String trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == '/') {
      return false;
    }
    final Uri? uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return false;
    }
    if (uri.hasScheme &&
        (uri.path.isEmpty || uri.path == '/') &&
        !uri.hasQuery) {
      return false;
    }
    return true;
  }

  static String? resolveImageUrl(String? url) {
    if (!hasUsableImageUrl(url)) {
      return null;
    }

    final Uri uri = Uri.parse(url!.trim());
    if (!uri.hasScheme) {
      return Uri.parse(AppConfig.apiBaseUrl).resolveUri(uri).toString();
    }
    if (!_localImageHosts.contains(uri.host.toLowerCase())) {
      return url;
    }

    final Uri baseUri = Uri.parse(AppConfig.apiBaseUrl);
    return baseUri
        .replace(
          path: uri.path,
          query: uri.hasQuery ? uri.query : null,
          fragment: uri.hasFragment ? uri.fragment : null,
        )
        .toString();
  }

  static Map<String, String>? headersFor(String resolvedUrl) {
    final Uri? uri = Uri.tryParse(resolvedUrl);
    final String host = uri?.host.toLowerCase() ?? '';
    if (host.contains('ngrok')) {
      return AppConfig.ngrokSkipWarningHeader;
    }
    return null;
  }

  static ImageProvider<Object>? imageProviderFor(String? url) {
    final String? resolvedImageUrl = resolveImageUrl(url);
    if (resolvedImageUrl == null) {
      return null;
    }
    return NetworkImage(
      resolvedImageUrl,
      headers: headersFor(resolvedImageUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider<Object>? imageProvider = imageProviderFor(imageUrl);
    if (imageProvider == null) {
      return _placeholder();
    }
    return Image(
      image: imageProvider,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      loadingBuilder:
          (
            BuildContext context,
            Widget child,
            ImageChunkEvent? loadingProgress,
          ) {
            if (loadingProgress == null) {
              return child;
            }
            return _placeholder();
          },
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
          _placeholder(),
    );
  }

  Widget _placeholder() {
    if (fallback != null) {
      return SizedBox(width: width, height: height, child: fallback);
    }
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
