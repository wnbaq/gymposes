import 'package:flutter/material.dart';

class GoodBadSkipBar extends StatelessWidget {
  final void Function(String result) onResult;

  const GoodBadSkipBar({required this.onResult, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Nasıl gitti?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _ResultButton(
                label: 'GOOD',
                backgroundColor: const Color(0xFFE8F5E9),
                borderColor: const Color(0xFF4CAF50),
                textColor: const Color(0xFF2E7D32),
                onTap: () => onResult('GOOD'),
              ),
              const SizedBox(width: 8),
              _ResultButton(
                label: 'BAD',
                backgroundColor: const Color(0xFFFCE4EC),
                borderColor: const Color(0xFFE91E63),
                textColor: const Color(0xFFC2185B),
                onTap: () => onResult('BAD'),
              ),
              const SizedBox(width: 8),
              _ResultButton(
                label: 'SKIP',
                backgroundColor: const Color(0xFFEDE7F6),
                borderColor: const Color(0xFF9C27B0),
                textColor: const Color(0xFF6A1B9A),
                onTap: () => onResult('SKIP'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ResultButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ResultButton({
    required this.label, required this.backgroundColor,
    required this.borderColor, required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ),
      ),
    );
  }
}
