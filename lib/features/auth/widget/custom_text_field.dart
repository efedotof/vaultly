import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.editingAction,
    required this.controller,
    required this.isPassword,
    this.hintText,
  });

  final VoidCallback editingAction;
  final TextEditingController controller;
  final bool isPassword;
  final String? hintText;

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
      ),
      child: TextField(
        textAlign: TextAlign.justify,
        controller: widget.controller,
        obscureText: widget.isPassword && _obscureText,
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(r'\s')),
        ],
        textAlignVertical:TextAlignVertical.center,
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
        onEditingComplete: widget.editingAction,
      ),
    );
  }
}