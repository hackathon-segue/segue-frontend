import 'package:flutter/material.dart';

import '../utils/app_design_tokens.dart';

enum AppStateTone { neutral, success, warning, danger }

class AppStateView extends StatelessWidget {
  const AppStateView({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.tone = AppStateTone.neutral,
    this.isLoading = false,
    super.key,
  });

  const AppStateView.loading({
    this.title = '불러오는 중입니다',
    this.message,
    super.key,
  }) : icon = Icons.hourglass_empty,
       actionLabel = null,
       onAction = null,
       secondaryActionLabel = null,
       onSecondaryAction = null,
       tone = AppStateTone.neutral,
       isLoading = true;

  const AppStateView.empty({
    this.title = '표시할 내용이 없습니다',
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : icon = Icons.inbox_outlined,
       tone = AppStateTone.neutral,
       isLoading = false,
       secondaryActionLabel = null,
       onSecondaryAction = null;

  const AppStateView.error({
    this.title = '다시 확인이 필요합니다',
    this.message,
    this.actionLabel = '다시 시도',
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    super.key,
  }) : icon = Icons.error_outline,
       tone = AppStateTone.danger,
       isLoading = false;

  const AppStateView.success({
    this.title = '완료되었습니다',
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : icon = Icons.check_circle_outline,
       tone = AppStateTone.success,
       isLoading = false,
       secondaryActionLabel = null,
       onSecondaryAction = null;

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Optional second button next to [actionLabel] (e.g. "뒤로 돌아가기") — lets
  /// an error state offer an escape hatch besides retrying, only rendered
  /// when both this and [onSecondaryAction] are set.
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final AppStateTone tone;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = _toneColor();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (isLoading)
              const SizedBox.square(
                dimension: AppSizes.loadingIndicator,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.loadingStroke,
                ),
              )
            else
              Icon(icon, color: color, size: AppSizes.iconLarge),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                  if (secondaryActionLabel != null &&
                      onSecondaryAction != null)
                    TextButton(
                      onPressed: onSecondaryAction,
                      child: Text(secondaryActionLabel!),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _toneColor() {
    return switch (tone) {
      AppStateTone.neutral => AppColors.ink,
      AppStateTone.success => AppColors.success,
      AppStateTone.warning => AppColors.warning,
      AppStateTone.danger => AppColors.danger,
    };
  }
}
