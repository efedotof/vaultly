import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/config.dart';
import 'custom_text_field.dart';

void showConfigSheet() {
  Get.bottomSheet(
    const _ConfigSheet(),
    isScrollControlled: true,
    backgroundColor: const Color(0xFF43416d),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  );
}

class _ConfigSheet extends StatefulWidget {
  const _ConfigSheet();

  @override
  State<_ConfigSheet> createState() => _ConfigSheetState();
}

class _ConfigSheetState extends State<_ConfigSheet> {
  final _config = Get.find<Config>();

  late final TextEditingController _baseUrl;
  late final TextEditingController _githubOwner;
  late final TextEditingController _githubToken;

  @override
  void initState() {
    super.initState();
    _baseUrl = TextEditingController(text: _config.baseUrl);
    _githubOwner = TextEditingController(text: _config.githubOwner);
    _githubToken = TextEditingController(text: _config.githubToken);
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _githubOwner.dispose();
    _githubToken.dispose();
    super.dispose();
  }

  void _save() {
    _config.baseUrl = _baseUrl.text.trim();
    _config.githubOwner = _githubOwner.text.trim();
    _config.githubToken = _githubToken.text.trim();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedPadding(
          padding: EdgeInsets.only(
            left: 10,
            right: 10,
            top: 10,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 10,
          ),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  editingAction: _save,
                  controller: _baseUrl,
                  isPassword: false,
                  hintText: 'Base URL',
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  editingAction: _save,
                  controller: _githubOwner,
                  isPassword: false,
                  hintText: 'GitHub owner',
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  editingAction: _save,
                  controller: _githubToken,
                  isPassword: true,
                  hintText: 'GitHub token',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
