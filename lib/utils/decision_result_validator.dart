import '../models/models.dart';

/// Issue #14: last-line client-side check before a [DecisionResult] is ever
/// rendered on the Last Intent Card. Real backend/AI text is out of the
/// frontend's control, so this exists as a safety net against language the
/// product explicitly forbids showing to a CA/customer — it does not mean
/// the current mock ever produces these (it doesn't; see
/// `mock_segue_repository.dart`).
abstract final class DecisionResultValidator {
  static const List<String> _bannedSubstrings = <String>['품절', '대체품', 'best match'];

  // Every text field checked here exists purely to explain ONE AI
  // recommendation, so any raw "NN%" in it reads as a match-score/적합도
  // expression — there's no legitimate reason for a percentage to appear
  // in these specific fields, so a blanket digit+% check is intentionally
  // broad rather than matching only the literal word "적합도".
  static final RegExp _percentPattern = RegExp(r'\d+\s*%');

  /// Fields actually rendered on [LastIntentCardScreen] — coreConditions,
  /// nextAction, reason, difference, pathDescription, actionButtonLabel.
  static bool hasForbiddenLanguage(DecisionResult result) {
    return <String>[
      result.coreConditions,
      result.nextAction,
      result.reason,
      result.difference,
      result.pathDescription,
      result.actionButtonLabel,
    ].any(_isForbidden);
  }

  static bool _isForbidden(String text) {
    final String lower = text.toLowerCase();
    return _bannedSubstrings.any(lower.contains) || _percentPattern.hasMatch(text);
  }
}
