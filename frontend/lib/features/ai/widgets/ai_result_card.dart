import 'package:flutter/material.dart';
import '../screens/ai_alternative_detail_screen.dart';

class AiResultCard extends StatelessWidget {
  final String originalMedicine;
  final String alternativeMedicine;
  final int originalPrice;
  final int alternativePrice;
  final String description;
  final bool originalInStock;
  final bool alternativeInStock;
  final int confidence;

  final Map<String, dynamic> originalData;
  final Map<String, dynamic>? alternativeData;
  final String predictedSalt;
  final String aiMethod;

  const AiResultCard({
    super.key,
    required this.originalMedicine,
    required this.alternativeMedicine,
    required this.originalPrice,
    required this.alternativePrice,
    required this.description,
    required this.originalInStock,
    required this.alternativeInStock,
    required this.confidence,
    required this.originalData,
    required this.alternativeData,
    required this.predictedSalt,
    required this.aiMethod,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasAlternative = alternativeMedicine != "Not Available";
    final int priceDifference = (originalPrice - alternativePrice).abs();
    final bool cheaper = hasAlternative && alternativePrice <= originalPrice;

    final double savingPercent = hasAlternative && originalPrice > 0
        ? (priceDifference / originalPrice) * 100
        : 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              originalMedicine,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusChip(
                  originalInStock
                      ? "Original In Stock"
                      : "Original Out of Stock",
                  originalInStock ? Colors.green : Colors.red,
                ),
                _statusChip("Match $confidence%", Colors.blue),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              "Alternative: $alternativeMedicine",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            if (hasAlternative)
              _statusChip(
                alternativeInStock
                    ? "Alternative Available"
                    : "Alternative Not Available",
                alternativeInStock ? Colors.green : Colors.red,
              ),

            const SizedBox(height: 12),

            if (hasAlternative)
              Text(
                cheaper
                    ? "Price: Rs.$alternativePrice  |  Save Rs.$priceDifference (${savingPercent.toStringAsFixed(0)}%)"
                    : "Price: Rs.$alternativePrice",
                style: TextStyle(
                  color: cheaper ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

            const SizedBox(height: 10),

            Text(description, style: TextStyle(color: Colors.grey.shade700)),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AiAlternativeDetailScreen(
                        original: originalData,
                        alternative: alternativeData,
                        confidence: confidence,
                        predictedSalt: predictedSalt,
                        aiMethod: aiMethod,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.compare_arrows),
                label: const Text("View Details"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
