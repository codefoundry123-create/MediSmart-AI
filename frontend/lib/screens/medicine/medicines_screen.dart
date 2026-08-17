import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_colors.dart';
import 'medicine_details_screen.dart';

class MedicinesScreen extends StatefulWidget {
  final String? category;

  const MedicinesScreen({super.key, this.category});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('medicines');

    if (widget.category != null &&
        widget.category!.isNotEmpty &&
        widget.category != "All Medicines") {
      query = query.where('category', isEqualTo: widget.category);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(widget.category ?? "All Medicines"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search medicine...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Something went wrong"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No medicines found"));
                }

                final allMedicines = snapshot.data!.docs;

                final medicines = allMedicines.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final name = (data["name"] ?? "").toString().toLowerCase();

                  return name.contains(searchText);
                }).toList();

                if (medicines.isEmpty) {
                  return const Center(
                    child: Text(
                      "Medicine not found",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final data =
                        medicines[index].data() as Map<String, dynamic>;

                    final imageName = data["image"]?.toString() ?? "";

                    final imagePath = "assets/images/$imageName";

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MedicineDetailsScreen(
                              medicine: {
                                "name": data["name"] ?? "",
                                "salt": data["salt"] ?? "",
                                "price": data["price"].toString(),
                                "image": imagePath,
                                "category": data["category"] ?? "",
                                "inStock": data["inStock"] ?? false,
                              },
                            ),
                          ),
                        );
                      },

                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                        ),

                        child: Row(
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Image.asset(
                                  imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image, size: 40),
                                ),
                              ),
                            ),

                            const SizedBox(width: 15),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data["name"] ?? "",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    data["salt"] ?? "",
                                    style: TextStyle(color: subtitleColor),
                                  ),

                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      Text(
                                        "Rs. ${data["price"]}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: data["inStock"] == true
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              data["inStock"] == true
                                                  ? "In Stock"
                                                  : "Out of Stock",
                                              style: TextStyle(
                                                color: data["inStock"] == true
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(
                              width: 90,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MedicineDetailsScreen(
                                            medicine: {
                                              "name": data["name"] ?? "",
                                              "salt": data["salt"] ?? "",
                                              "price": data["price"].toString(),
                                              "image": imagePath,
                                              "category":
                                                  data["category"] ?? "",
                                              "inStock":
                                                  data["inStock"] ?? false,
                                            },
                                          ),
                                    ),
                                  );
                                },
                                child: const Text("Add"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
