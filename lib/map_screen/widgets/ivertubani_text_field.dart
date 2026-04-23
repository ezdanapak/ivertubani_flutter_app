import 'package:flutter/material.dart';

class IvertubaniTextField extends StatelessWidget {
  const IvertubaniTextField({
    super.key,
    required this.onTextFieldChange,
    required this.controller,
  });

  final TextEditingController controller;
  final ValueChanged<String> onTextFieldChange;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 10,
      left: 15,
      right: 80,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "ძებნა...",
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.indigo),
          ),
          onChanged: onTextFieldChange,
        ),
      ),
    );
  }
}
