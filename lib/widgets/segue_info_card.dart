import 'package:flutter/material.dart';

import '../utils/segue_card_tokens.dart';

/// Matches every "Details Container" instance in Figma nodes 164:3213 /
/// 159:2295 / 159:2173 / 159:3053 / 169:3683 / 169:3891 — white fill,
/// 2px #DBDCE0 border, sharp (non-rounded) corners, 20/15px inner padding.
class SegueInfoCard extends StatelessWidget {
  const SegueInfoCard({
    required this.title,
    required this.child,
    this.backgroundColor,
    this.height,
    super.key,
  });

  final String title;
  final Widget child;
  final Color? backgroundColor;

  /// Fixed card height (e.g. 177 for the 3-card rows in 159:2295/159:2173/
  /// 159:3053 — Figma gives every card in that row the same height
  /// regardless of content length, rather than letting each card's height
  /// follow its own content). Null keeps the card's natural content height
  /// (used where Figma doesn't fix a height, e.g. the product info box).
  final double? height;

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: height != null ? MainAxisSize.min : MainAxisSize.max,
      children: <Widget>[
        Text(title, style: SegueCardText.sectionTitle20),
        // Figma (159:2295 card): title top 15 (h29) → content top 59 = 15px.
        const SizedBox(height: 15),
        child,
      ],
    );
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        border: Border.all(color: SegueCardColors.border, width: 2),
      ),
      child: height != null ? SingleChildScrollView(child: content) : content,
    );
  }
}

/// Product photo placeholder matching Figma's "image 14/16/17" instances —
/// no image bytes are bundled/fetched (mock `imageUrl` values are fake
/// `https://example.com/...` placeholders, same as every other screen in
/// this app), so this renders a labeled box at the same size instead.
class SegueProductImage extends StatelessWidget {
  const SegueProductImage({this.width = 237, this.height = 256, super.key});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
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

/// A "label  value" row inside a [SegueInfoCard], matching the repeated
/// `<b>label</b>  value` pattern (e.g. "현재 매장  미보유"). Two separate
/// [Text] widgets (not one `RichText`/`TextSpan`) so `find.text(value)`
/// keeps working in widget tests, consistent with every other label/value
/// row in this app.
class SegueLabelValueRow extends StatelessWidget {
  const SegueLabelValueRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        children: <Widget>[
          Text(label, style: SegueCardText.bodyLabel18Bold),
          const SizedBox(width: 8),
          Text(value, style: SegueCardText.body18),
        ],
      ),
    );
  }
}
