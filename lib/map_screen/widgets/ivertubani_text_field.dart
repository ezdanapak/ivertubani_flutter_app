import 'package:flutter/material.dart';

class IvertubaniTextField extends StatefulWidget {
  const IvertubaniTextField({
    super.key,
    required this.onTextFieldChange,
    required this.controller,
  });

  final TextEditingController controller;
  final ValueChanged<String> onTextFieldChange;

  @override
  State<IvertubaniTextField> createState() => _IvertubaniTextFieldState();
}

class _IvertubaniTextFieldState extends State<IvertubaniTextField> {
  // Rebuild only when text transitions between empty ↔ non-empty,
  // so the clear button appears/disappears correctly.
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    final nowHasText = widget.controller.text.isNotEmpty;
    if (nowHasText != _hasText) {
      setState(() => _hasText = nowHasText);
    }
  }

  void _clear() {
    widget.controller.clear();
    widget.onTextFieldChange('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final hintColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final iconColor = isDark ? Colors.indigo.shade200 : Colors.indigo;

    return Positioned(
      bottom: 10,
      left: 15,
      right: 80,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: iconColor, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'ძებნა...',
                  hintStyle: TextStyle(color: hintColor),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: widget.onTextFieldChange,
              ),
            ),
            // Clear button — visible only when field has text
            if (_hasText)
              GestureDetector(
                onTap: _clear,
                child: Icon(Icons.close, color: hintColor, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
