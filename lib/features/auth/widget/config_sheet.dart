import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/config.dart';
import '../../global_widget/custom_text_field/custom_text_field.dart';

void showConfigSheet() {
  Get.bottomSheet(
    Padding(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 10,
        bottom: MediaQuery.viewInsetsOf(Get.context!).bottom + 10,
      ),
      child: const _ConfigSheet(),
    ),
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

  final _baseUrlFocus = FocusNode();
  final _githubOwnerFocus = FocusNode();
  final _githubTokenFocus = FocusNode();

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
    _baseUrlFocus.dispose();
    _githubOwnerFocus.dispose();
    _githubTokenFocus.dispose();
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
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: _baseUrl,
            focusNode: _baseUrlFocus,
            nextFocusNode: _githubOwnerFocus,
            onSubmitted: (_) {},
            hintText: 'Base URL',
            textInputAction: TextInputAction.next,
            autofocus: true,
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: _githubOwner,
            focusNode: _githubOwnerFocus,
            nextFocusNode: _githubTokenFocus,
            onSubmitted: (_) {},
            hintText: 'GitHub owner',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: _githubToken,
            focusNode: _githubTokenFocus,
            onSubmitted: (_) => _save(),
            isPassword: true,
            hintText: 'GitHub token',
            textInputAction: TextInputAction.done,
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
    );
  }
}