import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:http/http.dart' as http;

import '../../../core/theme/app_colors.dart';
import 'ai_alternative_detail_screen.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  File? _image;
  bool _isAnalyzing = false;
  bool _showResult = false;

  final TextEditingController _manualTextController = TextEditingController();

  List<Map<String, dynamic>> results = [];
  List<String> correctedMedicineNames = [];

  String extractedText = "";
  String medicineOnlyText = "";
  String _analysisStatus = "";

  DateTime selectedPrescriptionDateTime = DateTime.now();

  // Replace YOUR_EC2_PUBLIC_IP with your actual EC2 IP after setup
  final String aiApiUrl = 'http://52.70.181.114:5000/predict';
  final String uploadUrl = 'http://52.70.181.114:5000/upload';
  final String historyUrl = 'http://52.70.181.114:5000/history';

  List<Map<String, dynamic>> _searchHistory = [];

  Future<void> _loadHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'anonymous';
      final response = await http.get(Uri.parse('$historyUrl/$uid'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _searchHistory = List<Map<String, dynamic>>.from(data['history'] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint("History load error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<Map<String, dynamic>?> getAIAlternatives(String medicineName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final response = await http.post(
        Uri.parse(aiApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "medicine": medicineName,
          "user_id": user?.uid ?? "anonymous",
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("AI API Error: $e");
      return null;
    }
  }

  // NEW: Upload prescription image to Amazon S3 via EC2
  Future<String?> uploadImageToS3(File image) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['user_id'] = user?.uid ?? 'anonymous';
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final data = jsonDecode(body);
        return data['image_url'];
      }
      return null;
    } catch (e) {
      debugPrint("S3 Upload Error: $e");
      return null;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _showResult = false;
        results.clear();
        correctedMedicineNames.clear();
        extractedText = "";
        medicineOnlyText = "";
        _analysisStatus = "";
      });
    }
  }

  Future<void> _pickPrescriptionDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedPrescriptionDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedPrescriptionDateTime),
    );

    if (time == null) return;

    setState(() {
      selectedPrescriptionDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour == 0
        ? 12
        : dateTime.hour;

    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? "PM" : "AM";

    return "${dateTime.day}/${dateTime.month}/${dateTime.year}  $hour:$minute $amPm";
  }

  Future<String> _extractText(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = TextRecognizer();
    final recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    return recognizedText.text;
  }

  String _cleanText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _removeSpaces(String text) {
    return _cleanText(text).replaceAll(' ', '');
  }

  String _extractPossibleMedicineLines(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final ignoredWords = [
      'dr',
      'doctor',
      'patient',
      'name',
      'age',
      'date',
      'hospital',
      'clinic',
      'infinix',
      'note',
      'camera',
      'years',
      'muhammad',
      'ahmad',
      'ali',
    ];

    final possibleLines = <String>[];

    for (final line in lines) {
      final cleanLine = _cleanText(line);
      if (cleanLine.length < 3) continue;

      final hasIgnored = ignoredWords.any((w) => cleanLine.contains(w));
      if (hasIgnored) continue;

      final words = cleanLine.split(' ');
      if (words.length > 4) continue;

      final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(line);
      if (!hasLetters) continue;

      possibleLines.add(line);
    }

    return possibleLines.join('\n');
  }

  double _medicineScore(String ocrText, String medicineName) {
    final cleanOcr = _cleanText(ocrText);
    final cleanMed = _cleanText(medicineName);

    if (cleanOcr.isEmpty || cleanMed.isEmpty) return 0;

    final ocrNoSpace = _removeSpaces(ocrText);
    final medNoSpace = _removeSpaces(medicineName);

    double bestScore = 0;

    if (cleanOcr.contains(cleanMed)) bestScore = 1.0;

    final fullScore = cleanOcr.similarityTo(cleanMed);
    if (fullScore > bestScore) bestScore = fullScore;

    final noSpaceScore = ocrNoSpace.similarityTo(medNoSpace);
    if (noSpaceScore > bestScore) bestScore = noSpaceScore;

    final ocrWords = cleanOcr.split(' ');
    final medWords = cleanMed.split(' ');

    for (final medWord in medWords) {
      if (medWord.length < 4) continue;

      for (final ocrWord in ocrWords) {
        if (ocrWord.length < 4) continue;

        final score = ocrWord.similarityTo(medWord);
        if (score > bestScore) bestScore = score;
      }

      final joinedScore = ocrNoSpace.similarityTo(medWord);
      if (joinedScore > bestScore) bestScore = joinedScore;
    }

    return bestScore;
  }

  List<Map<String, dynamic>> _findMedicineMatches(
    String textForMatching,
    List<Map<String, dynamic>> medicines,
  ) {
    final matches = <Map<String, dynamic>>[];
    final addedMedicines = <String>{};

    for (var med in medicines) {
      final medName = med['name']?.toString().trim() ?? "";
      final medType = med['type']?.toString().toLowerCase().trim() ?? "";

      if (medName.isEmpty || medType != "medicine") continue;

      final score = _medicineScore(textForMatching, medName);

      if (score >= 0.55) {
        final key = medName.toLowerCase();

        if (!addedMedicines.contains(key)) {
          addedMedicines.add(key);
          matches.add({"medicine": med, "confidence": (score * 100).toInt()});
        }
      }
    }

    matches.sort(
      (a, b) => (b["confidence"] as int).compareTo(a["confidence"] as int),
    );

    return matches;
  }

  List<String> _getCorrectedMedicineNames(
    List<Map<String, dynamic>> matchedMedicines,
  ) {
    return matchedMedicines.map((match) {
      final med = match["medicine"];
      final confidence = match["confidence"];
      return "${med['name']} ($confidence%)";
    }).toList();
  }

  void _updateStatus(String status) {
    if (!mounted) return;
    setState(() {
      _analysisStatus = status;
    });
  }

  // CHANGED: Now uploads image to S3 first, then saves S3 URL to Firestore
  Future<void> _savePrescriptionHistory(
    List<Map<String, dynamic>> finalResults,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    // Upload image to S3 if exists
    String? s3ImageUrl;
    if (_image != null) {
      _updateStatus("Uploading image to Amazon S3...");
      s3ImageUrl = await uploadImageToS3(_image!);
    }

    await FirebaseFirestore.instance.collection('prescriptions').add({
      "userId": user?.uid,
      "userEmail": user?.email,
      "prescriptionText": extractedText,
      "detectedMedicines": correctedMedicineNames,
      "hasImage": _image != null,
      "s3ImageUrl": s3ImageUrl,  // NEW: S3 image URL stored here
      "status": "Submitted",
      "prescriptionDateTime": Timestamp.fromDate(selectedPrescriptionDateTime),
      "createdAt": FieldValue.serverTimestamp(),
      "results": finalResults.map((item) {
        return {
          "original": item["original"]?["name"],
          "alternative": item["alternative"]?["name"],
          "predictedSalt": item["predictedSalt"],
          "confidence": item["confidence"],
          "aiMethod": item["aiMethod"],
          "matchedName": item["matchedName"],
          "bedrockUsed": item["bedrockUsed"] ?? false,  // NEW: track if Bedrock was used
        };
      }).toList(),
    });
  }

  Future<void> _analyzePrescription() async {
    final manualText = _manualTextController.text.trim();

    if (_image == null && manualText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload prescription image or type medicines."),
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _showResult = false;
      results.clear();
      correctedMedicineNames.clear();
      extractedText = "";
      medicineOnlyText = "";
      _analysisStatus = "Starting AI prescription analysis...";
    });

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      if (manualText.isNotEmpty) {
        _updateStatus("Reading typed prescription text...");
        extractedText = manualText;
      } else {
        _updateStatus("Reading prescription image using OCR...");
        extractedText = await _extractText(_image!);
      }

      await Future.delayed(const Duration(milliseconds: 300));
      _updateStatus("Extracting medicine-like text...");

      medicineOnlyText = _extractPossibleMedicineLines(extractedText);
      final textForMatching = "$medicineOnlyText\n$extractedText";

      await Future.delayed(const Duration(milliseconds: 300));
      _updateStatus("Loading pharmacy medicine database...");

      final snapshot = await FirebaseFirestore.instance
          .collection('medicines')
          .get();

      final List<Map<String, dynamic>> medicines = snapshot.docs
          .map((doc) => doc.data())
          .toList();

      await Future.delayed(const Duration(milliseconds: 300));
      _updateStatus("Correcting medicine names...");

      final matchedMedicines = _findMedicineMatches(textForMatching, medicines);
      correctedMedicineNames = _getCorrectedMedicineNames(matchedMedicines);

      await Future.delayed(const Duration(milliseconds: 300));
      _updateStatus("Calling AI model for salt prediction...");

      final finalResults = <Map<String, dynamic>>[];

      for (var match in matchedMedicines) {
        final Map<String, dynamic> originalMed = match["medicine"];
        final int confidence = match["confidence"];

        final aiResponse = await getAIAlternatives(
          originalMed['name'].toString(),
        );

        final String predictedSalt = aiResponse != null
            ? aiResponse['predicted_salt'].toString().toLowerCase().trim()
            : originalMed['salt']?.toString().toLowerCase().trim() ?? "";

        final String method = aiResponse != null
            ? aiResponse['method'].toString()
            : "firestore_fallback";

        final String matchedName = aiResponse != null
            ? aiResponse['matched_name'].toString()
            : originalMed['name'].toString();

        Map<String, dynamic>? availableAlt;

        final originalName =
            originalMed['name']?.toString().toLowerCase().trim() ?? "";

        final List<String> firestoreAlternatives =
            (originalMed['alternatives'] as List<dynamic>? ?? [])
                .map((e) => e.toString().toLowerCase().trim())
                .toList();

        final List<Map<String, dynamic>> possibleAlternatives = [];

        for (var otherMed in medicines) {
          final otherSalt =
              otherMed['salt']?.toString().toLowerCase().trim() ?? "";

          final otherName =
              otherMed['name']?.toString().toLowerCase().trim() ?? "";

          final otherType =
              otherMed['type']?.toString().toLowerCase().trim() ?? "";

          final sameSalt =
              predictedSalt.isNotEmpty && predictedSalt == otherSalt;

          final listedAlternative = firestoreAlternatives.contains(otherName);

          final differentMedicine = originalName != otherName;
          final inStock = otherMed['inStock'] == true;
          final isMedicine = otherType == "medicine";

          if ((sameSalt || listedAlternative) &&
              differentMedicine &&
              inStock &&
              isMedicine) {
            possibleAlternatives.add(otherMed);
          }
        }

        possibleAlternatives.sort((a, b) {
          final priceA = int.tryParse(a['price'].toString()) ?? 999999;
          final priceB = int.tryParse(b['price'].toString()) ?? 999999;
          return priceA.compareTo(priceB);
        });

        if (possibleAlternatives.isNotEmpty) {
          availableAlt = possibleAlternatives.first;
        }

        finalResults.add({
          "original": originalMed,
          "alternative": availableAlt,
          "confidence": confidence,
          "predictedSalt": predictedSalt,
          "aiMethod": method, 
          "matchedName": matchedName,
          "bedrockUsed": aiResponse?["bedrock_used"] ?? false,
          "fromMemory": aiResponse?["from_memory"] ?? false,
        });
      }

      await _savePrescriptionHistory(finalResults);
      await _loadHistory();

      setState(() {
        results = finalResults;
        _isAnalyzing = false;
        _showResult = true;
        _analysisStatus = "Analysis completed.";
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _showResult = true;
        _analysisStatus = "Analysis failed. Please try again.";
      });

      debugPrint("AI Analysis Error: $e");
    }
  }

  Widget _analysisLoadingBox() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const SizedBox(
            height: 26,
            width: 26,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _analysisStatus,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey;

    return GestureDetector(
      onTap: _isAnalyzing ? null : _pickImage,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.35)
                  : Colors.black.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: _image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: const Icon(
                      Icons.upload_file,
                      size: 34,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Upload Prescription Image",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "AI will detect medicines automatically",
                    style: TextStyle(color: subtitleColor),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.file(
                  _image!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
      ),
    );
  }

  Widget _manualTextBox() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey.shade500;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _manualTextController,
        maxLines: 5,
        enabled: !_isAnalyzing,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(bottom: 74),
            child: Icon(Icons.edit_note, color: AppColors.primary),
          ),
          hintText:
              "Or type medicines here...\nExample:\nPanadol Extra\nGlucophage\nBrufen",
          border: InputBorder.none,
          hintStyle: TextStyle(color: subtitleColor),
        ),
      ),
    );
  }

  Widget _dateTimeBox() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final iconColor = isDark ? Colors.white70 : Colors.grey;

    return GestureDetector(
      onTap: _isAnalyzing ? null : _pickPrescriptionDateTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.35)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Prescription Date: ${_formatDateTime(selectedPrescriptionDateTime)}",
                style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
            Icon(Icons.edit, size: 18, color: iconColor),
          ],
        ),
      ),
    );
  }

  Widget _historyPanel() {
    if (_searchHistory.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text(
                "Your Search History (CockroachDB Memory)",
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._searchHistory.take(5).map((h) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.medication_outlined, size: 14, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "${h['medicine']} → ${h['salt']}",
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                ),
                if (h['bedrock_used'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("Bedrock", style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _smallResultCard(Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    final original = item['original'];
    final alt = item['alternative'];
    final fromMemory = item['fromMemory'] ?? false;
    final predictedSalt = item['predictedSalt'] ?? "";
    final aiMethod = item['aiMethod'] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: const Icon(Icons.medication, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  original['name']?.toString() ?? "Unknown",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alt != null
                      ? "1 alternative found"
                      : "No in-stock alternative found",
                  style: TextStyle(
                    color: alt != null ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (fromMemory)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("Memory", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
              if (item['bedrockUsed'] == true)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("Bedrock", style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AiAlternativeDetailScreen(
                        original: original,
                        alternative: alt,
                        confidence: item['confidence'] ?? 0,
                        predictedSalt: predictedSalt,
                        aiMethod: aiMethod,
                      ),
                    ),
                  );
                },
                child: const Text("View"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final dividerColor = isDark ? Colors.white24 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("AI Prescription"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Upload or Type Prescription",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Get AI-based same-salt alternatives from pharmacy stock.",
              style: TextStyle(color: subtitleColor),
            ),
            const SizedBox(height: 18),
            _historyPanel(),
            _uploadCard(),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(child: Divider(color: dividerColor)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "OR",
                    style: TextStyle(
                      color: subtitleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: dividerColor)),
              ],
            ),

            const SizedBox(height: 18),
            _manualTextBox(),
            const SizedBox(height: 18),
            _dateTimeBox(),
            const SizedBox(height: 22),

            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 4,
                ),
                onPressed: _isAnalyzing ? null : _analyzePrescription,
                icon: const Icon(Icons.auto_awesome),
                label: const Text(
                  "Analyze Prescription",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),
            if (_isAnalyzing) _analysisLoadingBox(),

            const SizedBox(height: 24),

            if (_showResult) ...[
              Text(
                "AI Suggested Alternatives",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),

              if (correctedMedicineNames.isNotEmpty) ...[
                Text(
                  "Detected Medicines:\n${correctedMedicineNames.join('\n')}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (results.isEmpty)
                const Text(
                  "No medicine matched from your database.",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ...results.map((item) => _smallResultCard(item)),
            ],
          ],
        ),
      ),
    );
  }
}
