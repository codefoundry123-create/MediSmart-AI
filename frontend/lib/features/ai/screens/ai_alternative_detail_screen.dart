import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AiAlternativeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> original;
  final Map<String, dynamic>? alternative;
  final int confidence;
  final String predictedSalt;
  final String aiMethod;

  const AiAlternativeDetailScreen({
    super.key,
    required this.original,
    required this.alternative,
    required this.confidence,
    required this.predictedSalt,
    required this.aiMethod,
  });

  Widget _medicineImage(String? imageName) {
    if (imageName == null || imageName.isEmpty) {
      return const Icon(Icons.medication, size: 55, color: AppColors.primary);
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        "assets/images/$imageName",
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.medication,
            size: 55,
            color: AppColors.primary,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAlt = alternative != null;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade700;

    final int originalPrice = int.tryParse(original['price'].toString()) ?? 0;

    final int altPrice = hasAlt
        ? int.tryParse(alternative!['price'].toString()) ?? 0
        : 0;

    final int saving = hasAlt ? (originalPrice - altPrice) : 0;

    final double savingPercent = hasAlt && originalPrice > 0
        ? (saving / originalPrice) * 100
        : 0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("AI Alternative"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 40,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "AI Same Salt Match",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    predictedSalt.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "AI Confidence: $confidence%",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _medicineBox(
                    context: context,
                    title: "Your Medicine",
                    titleColor: Colors.black87,
                    medicine: original,
                    price: originalPrice,
                    stockText: original['inStock'] == true
                        ? "In Stock"
                        : "Out of Stock",
                    stockColor: original['inStock'] == true
                        ? Colors.green
                        : Colors.red,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: hasAlt
                      ? _medicineBox(
                          context: context,
                          title: "Recommended",
                          titleColor: Colors.green,
                          medicine: alternative!,
                          price: altPrice,
                          stockText: "Available",
                          stockColor: Colors.green,
                        )
                      : _emptyAlternativeBox(context),
                ),
              ],
            ),

            const SizedBox(height: 22),

            if (hasAlt)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.savings, color: Colors.green, size: 34),

                    const SizedBox(height: 8),

                    Text(
                      saving > 0
                          ? "Save Rs.$saving (${savingPercent.toStringAsFixed(0)}%)"
                          : "Recommended alternative available",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 18),

            Text(
              "AI Method: $aiMethod",
              style: TextStyle(
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 26),

            if (hasAlt)
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text(
                    "Add Alternative to Cart",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _medicineBox({
    required BuildContext context,
    required String title,
    required Color titleColor,
    required Map<String, dynamic> medicine,
    required int price,
    required String stockText,
    required Color stockColor,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: titleColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: titleColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _medicineImage(medicine['image']?.toString()),
          ),

          const SizedBox(height: 14),

          Text(
            medicine['name']?.toString() ?? "Unknown",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            medicine['salt']?.toString() ?? "",
            textAlign: TextAlign.center,
            style: TextStyle(color: subtitleColor),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: stockColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              stockText,
              style: TextStyle(color: stockColor, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            "Rs $price",
            style: TextStyle(
              color: titleColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyAlternativeBox(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.all(14),
      height: 390,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: const Center(
        child: Text(
          "No in-stock\nalternative found",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
