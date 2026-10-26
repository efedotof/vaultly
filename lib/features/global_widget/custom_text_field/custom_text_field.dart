import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onChanged,
    this.isPassword = false,
    this.hintText,
    this.textInputAction = TextInputAction.done,
    this.focusNode,
    this.nextFocusNode,
    this.autofocus = false,
    this.keyboardType,
    this.allowWhitespace = false,
    this.textAlign = TextAlign.justify,
    this.hasError = false,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool isPassword;
  final String? hintText;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final bool autofocus;
  final TextInputType? keyboardType;
  final bool allowWhitespace;
  final TextAlign textAlign;
  final bool hasError;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF525252),
        borderRadius: BorderRadius.circular(10),
        border: widget.hasError
            ? Border.all(color: const Color(0xFFB00020), width: 1.5)
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        textAlign: widget.textAlign,
        textAlignVertical: TextAlignVertical.center,
        obscureText: widget.isPassword && _obscureText,
        keyboardType:
            widget.keyboardType ??
            (widget.isPassword
                ? TextInputType.visiblePassword
                : TextInputType.text),
        textInputAction: widget.textInputAction,
        inputFormatters: widget.allowWhitespace
            ? null
            : [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
        onChanged: widget.onChanged,
        onSubmitted: (value) {
          widget.onSubmitted?.call(value);
          if (widget.nextFocusNode != null) {
            widget.nextFocusNode!.requestFocus();
          } else {
            FocusScope.of(context).unfocus();
          }
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: widget.hintText,
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _obscureText = !_obscureText);
                  },
                )
              : null,
        ),
      ),
    );
  }
}
