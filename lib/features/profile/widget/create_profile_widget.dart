import 'package:flutter/material.dart';
import 'package:vaulth_app/features/global_widget/custom_text_field/custom_text_field.dart';

typedef ProfileSaveCallback =
    void Function({
      required String firstName,
      required String lastName,
      required String email,
      required bool totpEnabled,
    });

class CreateProfileWidget extends StatefulWidget {
  const CreateProfileWidget({super.key, required this.onSave});

  final ProfileSaveCallback onSave;

  @override
  State<CreateProfileWidget> createState() => _CreateProfileWidgetState();
}

class _CreateProfileWidgetState extends State<CreateProfileWidget> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();

  bool _totpEnabled = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      totpEnabled: _totpEnabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF43416d),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      backgroundColor: const Color(0xFF1d3687),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Stack(
                clipBehavior: Clip.none,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF525252),
                    child: Icon(Icons.person, size: 32, color: Colors.white54),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Material(
                      color: const Color(0xFF43416d),
                      shape: const CircleBorder(
                        side: BorderSide(color: Colors.white, width: 2),
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {},
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: const Color(0xFF43416d),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _firstNameController,
                      focusNode: _firstNameFocus,
                      nextFocusNode: _lastNameFocus,
                      onSubmitted: (_) {},
                      hintText: 'Имя',
                      textInputAction: TextInputAction.next,
                      autofocus: true,
                      allowWhitespace: true,
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _lastNameController,
                      focusNode: _lastNameFocus,
                      nextFocusNode: _emailFocus,
                      onSubmitted: (_) {},
                      hintText: 'Фамилия',
                      textInputAction: TextInputAction.next,
                      allowWhitespace: true,
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      onSubmitted: (_) => _save(),
                      hintText: 'Email',
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: const Color(0xFF43416d),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Двухфакторная аутентификация (TOTP)',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                    Switch(
                      value: _totpEnabled,
                      onChanged: (v) => setState(() => _totpEnabled = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
