import 'package:flutter/material.dart';

class PromotionModal extends StatelessWidget {
  const PromotionModal({super.key, required this.onButtonPress});

  final VoidCallback onButtonPress;

  static void showPromoModal(
    BuildContext context, {
    required VoidCallback onButtonPress,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => PromotionModal(onButtonPress: onButtonPress),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars, color: Colors.orange, size: 50),
          const SizedBox(height: 15),
          Text(
            "გსურთ თქვენი ბიზნესი რუკაზე? 🚀",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "დაამატეთ თქვენი ობიექტი ივერთუბნის რუკაზე და გახადეთ ის ყველასთვის ხელმისაწვდომი.",
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onButtonPress,
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text(
              "შეავსეთ განაცხადი",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
