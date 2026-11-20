import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../widgets/movielog_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _nickname = TextEditingController(
    text: context.read<AuthViewModel>().member?.nickname ?? '',
  );
  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final vm = context.read<EditProfileViewModel>();
    final auth = context.read<AuthViewModel>();
    final version = auth.sessionVersion;
    final success = await vm.save(_nickname.text);
    if (!mounted || !auth.isSignedInVersion(version)) return;
    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/my');
      }
    } else if (vm.message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(vm.message!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditProfileViewModel>();
    final saving = vm.status == EditProfileStatus.saving;
    final email = context.select<AuthViewModel, String?>(
      (a) => a.member?.email,
    );
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('프로필 수정'),
          centerTitle: true,
          leading: BackButton(
            onPressed: saving
                ? null
                : () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/my');
                    }
                  },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  initialValue: email,
                  enabled: false,
                  decoration: const InputDecoration(labelText: '이메일'),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nickname,
                  enabled: !saving,
                  maxLength: 12,
                  onChanged: (_) => vm.clearError(),
                  decoration: InputDecoration(
                    labelText: '닉네임',
                    errorText: vm.nicknameError,
                  ),
                ),
                const SizedBox(height: 40),
                MovieLogButton(
                  label: '저장',
                  isLoading: saving,
                  onPressed: saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
