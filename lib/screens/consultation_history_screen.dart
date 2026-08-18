import 'package:flutter/material.dart';

import '../utils/segue_card_tokens.dart';
import '../widgets/segue_card_shell.dart';

/// Static "상담 내역" screen (Figma 169:4208) — reached from the sidebar's
/// CONSULTATION HISTORY item. MVP scope: no repository/API/DB wiring, no
/// state management — reproduces Figma's own example content and layout
/// as a fixed page (search/date filter, results table, pagination footer
/// are all decorative, matching "정적인 페이지" in the request).
class ConsultationHistoryScreen extends StatelessWidget {
  const ConsultationHistoryScreen({super.key});

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

  static const TextStyle _pageNumber14 = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: SegueCardColors.ink,
  );

  // Figma's own literal example rows (169:4208) — reproduced as-is since
  // this is an explicitly static, non-API-backed mock page.
  static const List<List<String>> _rows = <List<String>>[
    <String>[
      '2026.08.18  11:13',
      '이현승 / TEST-MCM-01',
      'M Diamond 비세토르 레더 믹스',
      '정확한 제품 확인',
      '김셀러 Client Advisor',
    ],
    <String>[
      '2026.08.18  14:13',
      '유비니 / TEST-MCM-02',
      'M Diamond 비세토르 레더 믹스',
      '매장 보유 확인됨',
      '김셀러 Client Advisor',
    ],
    <String>[
      '2026.08.18  14:13',
      '유비니 / TEST-MCM-02',
      'M Diamond 비세토르 레더 믹스',
      '매장 보유 확인됨',
      '김셀러 Client Advisor',
    ],
    <String>[
      '2026.08.18  14:13',
      '유비니 / TEST-MCM-02',
      'M Diamond 비세토르 레더 믹스',
      '매장 보유 확인됨',
      '김셀러 Client Advisor',
    ],
    <String>[
      '2026.08.18  14:13',
      '유비니 / TEST-MCM-02',
      'M Diamond 비세토르 레더 믹스',
      '매장 보유 확인됨',
      '김셀러 Client Advisor',
    ],
    <String>[
      '2026.08.18  14:13',
      '유비니 / TEST-MCM-02',
      'M Diamond 비세토르 레더 믹스',
      '매장 보유 확인됨',
      '김셀러 Client Advisor',
    ],
    <String>[
      '2026.08.18  14:13',
      '유비니 / TEST-MCM-02',
      'M Diamond 비세토르 레더 믹스',
      '매장 보유 확인됨',
      '김셀러 Client Advisor',
    ],
  ];

  static const List<String> _columnHeaders = <String>[
    '상담 일시',
    '고객명 / 회원번호',
    '상담 제품',
    '상담 결과',
    '상담 진행자',
  ];

  // Figma column x-offsets (316/490/696/1089/1241, table left=294) converted
  // to column widths so the 5 cells line up exactly under their headers.
  static const List<double> _columnWidths = <double>[174, 206, 389, 152, 166];
  static const double _contentWidth = 1113;
  static const double _contentHeight = 650;

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
      pageTitle: 'CONSULTATION HISTORY',
      activeMenuItem: TabletMenuItem.consultationHistory,
      subtitle: '고객과의 상담 내역을 확인하고 이전 상담 내용을 조회할 수 있습니다.',
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
            const Text('상담 기간', style: SegueCardText.detailLabel16),
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
          TextSpan(text: '12', style: _resultsCountBold14),
          TextSpan(text: '건', style: _resultsCountBold14),
          TextSpan(text: '의 상담 기록'),
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
        const SizedBox(width: 16),
        const Text('2', style: _pageNumber14),
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
