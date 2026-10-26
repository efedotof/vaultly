import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/features/global_widget/custom_text_field/custom_text_field.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

class UpdateProfileWidget extends StatefulWidget {
  const UpdateProfileWidget({super.key, required this.onSave, this.onCancel});

  final void Function({
    required String firstName,
    required String lastName,
    required String username,
  })
  onSave;

  final VoidCallback? onCancel;

  @override
  State<UpdateProfileWidget> createState() => _UpdateProfileWidgetState();
}

class _UpdateProfileWidgetState extends State<UpdateProfileWidget> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    final user = Get.find<AuthLocalStorage>().cachedUserInfo;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    widget.onSave(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: _usernameController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Get.find<AuthLocalStorage>().cachedUserInfo;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF43416d),
        title: const Text('Редактирование профиля'),
        actions: [
          if (widget.onCancel != null)
            TextButton(onPressed: widget.onCancel, child: const Text('Отмена')),
        ],
      ),
      backgroundColor: const Color(0xFF1d3687),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              controller: _firstNameController,
              hintText: 'Имя',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),
            CustomTextField(
              controller: _lastNameController,
              hintText: 'Фамилия',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),
            CustomTextField(
              controller: _usernameController,
              hintText: 'Username',
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF525252),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Email: ${user?.email ?? "—"} (не изменяется)',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _submit, child: const Text('Сохранить')),
          ],
        ),
      ),
    );
  }
}
