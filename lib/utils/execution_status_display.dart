import 'package:flutter/material.dart';

import '../models/models.dart';

String executionStatusLabel(ExecutionStatus status) {
  return switch (status) {
    ExecutionStatus.requested => '요청 접수',
    ExecutionStatus.unable => '실행 불가',
    ExecutionStatus.followUpNeeded => '후속 확인 필요',
  };
}

String executionStatusMessage({required ExecutionStatus status, String? note}) {
  return switch (status) {
    ExecutionStatus.requested => '요청 접수 상태입니다. Client Advisor가 후속 확인을 진행 중입니다.',
    ExecutionStatus.unable =>
      '실행이 어렵습니다. ${note ?? 'Client Advisor가 사유를 확인 중입니다.'}',
    ExecutionStatus.followUpNeeded =>
      '후속 확인이 필요합니다. ${note ?? 'Client Advisor가 추가 안내를 준비 중입니다.'}',
  };
}

IconData executionStatusIcon(ExecutionStatus status) {
  return switch (status) {
    ExecutionStatus.requested => Icons.schedule_outlined,
    ExecutionStatus.unable => Icons.error_outline,
    ExecutionStatus.followUpNeeded => Icons.info_outline,
  };
}

bool executionStatusRequiresNote(ExecutionStatus status) {
  return status == ExecutionStatus.unable ||
      status == ExecutionStatus.followUpNeeded;
}
