import 'package:flutter/material.dart';

import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';
import '../widgets/staff_text_field.dart';

/// Figma node 14:720 "직원용 웹 로그인".
///
/// API.md has no authentication endpoint, so this is a mock, client-side-only
/// gate matching the MVP test-account approach used elsewhere in the app:
/// any non-empty email/password proceeds to the staff home screen.
class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    Navigator.of(context).pushNamed(AppRoutes.staffHome);
  }

  @override
  Widget build(BuildContext context) {
    return StaffAppShell(
      currentRoute: AppRoutes.staffWeb,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 48,
        children: <Widget>[
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: <Widget>[
              Text('MCM 상담 지원', style: StaffText.title20Bold),
              Text('직원 로그인', style: StaffText.header16SemiBold),
            ],
          ),
          Center(
            child: SizedBox(
              width: 360,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 24,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16,
                      children: <Widget>[
                        StaffTextField(
                          label: '이메일',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (String? value) =>
                              (value == null || value.trim().isEmpty)
                              ? '이메일을 입력해 주세요.'
                              : null,
                        ),
                        StaffTextField(
                          label: '비밀번호',
                          controller: _passwordController,
                          obscureText: true,
                          validator: (String? value) =>
                              (value == null || value.isEmpty) ? '비밀번호를 입력해 주세요.' : null,
                        ),
                        StaffButton(
                          label: '로그인',
                          variant: StaffButtonVariant.primary,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                    const Text('로그인에 문제가 있으신가요?', style: StaffText.body12),
                    const StaffButton(label: '고객 지원', variant: StaffButtonVariant.link),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
