import 'package:flutter/material.dart';

import '../utils/segue_card_tokens.dart';
import '../widgets/segue_card_shell.dart';

/// Static "REQUESTS" screen (Figma 183:4525) — reached from the sidebar's
/// REQUESTS item. MVP scope: no repository/API/DB wiring, no state
/// management — reproduces Figma's own example content and layout as a
/// fixed page (search/date filter, results table are all decorative,
/// matching "정적인 화면" in the request).
class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  static const Color _tableBorder = Color(0xFFEDEDED);

  static const TextStyle _rowValue16 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.detailText,
    height: 24 / 16,
  );

  static const TextStyle _resultsCount14 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: SegueCardColors.detailText,
  );

  static const TextStyle _resultsCountBold14 = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: SegueCardColors.detailText,
  );

  // Figma's own literal example rows (183:4525) — reproduced as-is since
  // this is an explicitly static, non-API-backed mock page.
  static const List<List<String>> _rows = <List<String>>[
    <String>[
      '2026.08.18  11:13',
      '이현승 / TEST-MCM-01',
      'M Diamond 비세토르 레더 믹스',
      '타 매장 재고 확인',
      '확인 중',
    ],
    <String>[
      '2026.08.18  11:13',
      '이현승 / TEST-MCM-01',
      'M Diamond 비세토르 레더 믹스',
      '타 매장 재고 확인',
      '확인 중',
    ],
  ];

  static const List<String> _columnHeaders = <String>[
    '요청 일시',
    '고객명 / 회원번호',
    '요청 제품',
    '요청 유형',
    '상태',
  ];

  // Same column geometry as ConsultationHistoryScreen (169:4208) — both
  // tables share the identical 5-column template (left=294 inset,
  // x-offsets 316/490/696/1089/1241 on a 1440-wide frame), just with
  // Requests-specific header/value copy.
  static const List<double> _columnWidths = <double>[174, 206, 389, 152, 166];
  static const double _contentWidth = 1113;
  static const double _contentHeight = 400;

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildFilterBar(),
        const SizedBox(height: 68),
        _buildResultsCount(),
        const SizedBox(height: 12),
        _buildTable(),
        const SizedBox(height: 24),
        _buildPagination(),
      ],
    );

    return SegueCardShell(
      pageTitle: 'REQUESTS',
      activeMenuItem: TabletMenuItem.requests,
      subtitle: '고객에게 제안한 다음 행동 중 추가 확인이 필요한 요청을 관리합니다.',
      bodyTopGap: 46,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth >= _contentWidth) {
            return content;
          }
          final double scale = constraints.maxWidth / _contentWidth;
          return SizedBox(
            width: constraints.maxWidth,
            height: _contentHeight * scale,
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: _contentWidth,
                height: _contentHeight,
                child: content,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('고객명 / 회원번호', style: SegueCardText.detailLabel16),
            const SizedBox(height: 7),
            Container(
              width: 325,
              height: 49,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border.fromBorderSide(
                  BorderSide(color: _tableBorder, width: 2),
                ),
              ),
              child: const Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '이름 또는 회원번호 입력',
                      style: SegueCardText.inputPlaceholder14,
                    ),
                  ),
                  Icon(
                    Icons.search,
                    size: 16,
                    color: SegueCardColors.placeholderMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('요청 일시', style: SegueCardText.detailLabel16),
            const SizedBox(height: 7),
            Container(
              width: 304,
              height: 49,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border.fromBorderSide(
                  BorderSide(color: _tableBorder, width: 2),
                ),
              ),
              child: const Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '2026.08.01',
                      style: SegueCardText.detailLabel16,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: 12),
                  SizedBox(
                    width: 11,
                    child: Divider(color: SegueCardColors.muted, height: 1),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '2026.08.01',
                      style: SegueCardText.detailLabel16,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: SegueCardColors.placeholderMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        const _OutlineFilterButton(label: '초기화'),
        const SizedBox(width: 8),
        SegueCtaButton(label: '검색', onPressed: () {}, showArrow: false),
      ],
    );
  }

  Widget _buildResultsCount() {
    return const Text.rich(
      TextSpan(
        style: _resultsCount14,
        children: <InlineSpan>[
          TextSpan(text: '총 '),
          TextSpan(text: '2', style: _resultsCountBold14),
          TextSpan(text: '건', style: _resultsCountBold14),
          TextSpan(text: '의 요청 기록'),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border.fromBorderSide(
          BorderSide(color: _tableBorder, width: 2),
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 51,
            color: SegueCardColors.panelBg,
            child: _tableRow(
              _columnHeaders,
              style: SegueCardText.detailLabel16,
            ),
          ),
          for (int i = 0; i < _rows.length; i++) ...<Widget>[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: _tableBorder),
            SizedBox(
              height: 51,
              child: _tableRow(_rows[i], style: _rowValue16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tableRow(List<String> cells, {required TextStyle style}) {
    return Padding(
      padding: const EdgeInsets.only(left: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < cells.length; i++)
            SizedBox(
              width: _columnWidths[i],
              child: Text(
                cells[i],
                style: style,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: SegueCardColors.ink,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '1',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlineFilterButton extends StatelessWidget {
  const _OutlineFilterButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 43,
      decoration: const BoxDecoration(
        border: Border.fromBorderSide(BorderSide(color: Colors.black)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SegueCardColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
