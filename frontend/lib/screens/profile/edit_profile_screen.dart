// ════════════════════════════════════════════════════════════
// FILE LOCATION: lib/screens/profile/edit_profile_screen.dart
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/cart/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers — pre-filled with current profile data
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _bloodGroupCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late String _selectedGender;

  @override
  void initState() {
    super.initState();
    // Read current values from ProfileController
    final c = context.read<ProfileController>();
    _nameCtrl       = TextEditingController(text: c.name);
    _phoneCtrl      = TextEditingController(text: c.phone);
    _emailCtrl      = TextEditingController(text: c.email);
    _dobCtrl        = TextEditingController(text: c.dob);
    _ageCtrl        = TextEditingController(text: c.age);
    _bloodGroupCtrl = TextEditingController(text: c.bloodGroup);
    _heightCtrl     = TextEditingController(text: c.height);
    _weightCtrl     = TextEditingController(text: c.weight);
    _selectedGender = c.gender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _ageCtrl.dispose();
    _bloodGroupCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // ── Save button pressed ───────────────────────────────────
  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<ProfileController>().updateProfile(
      name:        _nameCtrl.text.trim(),
      email:       _emailCtrl.text.trim(),
      phone:       _phoneCtrl.text.trim(),
      gender:      _selectedGender,
      dob:         _dobCtrl.text.trim(),
      age:         _ageCtrl.text.trim(),
      bloodGroup:  _bloodGroupCtrl.text.trim(),
      height:      _heightCtrl.text.trim(),
      weight:      _weightCtrl.text.trim(),
    );

    if (!mounted) return;

    // Show success message and go back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Profile updated successfully!'),
        backgroundColor: Color(0xFF00897B),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
    Navigator.pop(context);
  }

  // ── Date Picker ───────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1998, 7, 12),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF00897B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dobCtrl.text =
          '${_monthName(picked.month)} ${picked.day}, ${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdating = context.watch<ProfileController>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom App Bar ────────────────────────────────
            _buildAppBar(),

            // ── Scrollable Form ───────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Avatar ──────────────────────────────
                      _buildAvatar(),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Registered since Feb 16, 2018',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Personal Information ─────────────────
                      _sectionLabel('PERSONAL INFORMATION'),
                      const SizedBox(height: 14),

                      // Full Name
                      _buildField(
                        controller: _nameCtrl,
                        hint: 'Full Name',
                        suffixIcon: Icons.person_outline,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Please enter your name'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Gender Dropdown
                      _buildGenderDropdown(),
                      const SizedBox(height: 12),

                      // Date of Birth
                      _buildField(
                        controller: _dobCtrl,
                        hint: 'Date of Birth',
                        suffixIcon: Icons.calendar_today_outlined,
                        readOnly: true,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 12),

                      // Phone
                      _buildField(
                        controller: _phoneCtrl,
                        hint: 'Phone Number',
                        suffixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        prefix: '+1  ',
                        validator: (v) => v == null || v.isEmpty
                            ? 'Please enter your phone'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Email
                      _buildField(
                        controller: _emailCtrl,
                        hint: 'Email Address',
                        suffixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!v.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── Health Information ───────────────────
                      _sectionLabel('HEALTH INFORMATION'),
                      const SizedBox(height: 14),

                      // Age + Blood Group
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _ageCtrl,
                              hint: 'e.g. 25 years',
                              label: 'Age',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _bloodGroupCtrl,
                              hint: 'e.g. AB+',
                              label: 'Blood Group',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Height + Weight
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _heightCtrl,
                              hint: 'e.g. 170 cm',
                              label: 'Height',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _weightCtrl,
                              hint: 'e.g. 65 KG',
                              label: 'Weight',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // ── Update Profile Button ────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isUpdating ? null : _onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00897B),
                            disabledBackgroundColor:
                                const Color(0xFF00897B).withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: isUpdating
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Update Profile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // App Bar
  // ─────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final controller = context.watch<ProfileController>();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 20, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Edit Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          // Avatar thumbnail in top right
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 20,
              backgroundColor:
                  const Color(0xFF00897B).withOpacity(0.15),
              backgroundImage: controller.profileImageUrl != null
                  ? NetworkImage(controller.profileImageUrl!)
                  : null,
              child: controller.profileImageUrl == null
                  ? const Icon(Icons.person,
                      color: Color(0xFF00897B), size: 24)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Avatar with Camera Icon
  // ─────────────────────────────────────────────────────────
  Widget _buildAvatar() {
    final controller = context.watch<ProfileController>();
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor:
                const Color(0xFF00897B).withOpacity(0.15),
            backgroundImage: controller.profileImageUrl != null
                ? NetworkImage(controller.profileImageUrl!)
                : null,
            child: controller.profileImageUrl == null
                ? const Icon(Icons.person,
                    size: 58, color: Color(0xFF00897B))
                : null,
          ),
          // Camera button
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                // TODO: Add image_picker package then:
                // final picker = ImagePicker();
                // final file = await picker.pickImage(source: ImageSource.gallery);
                // if (file != null) controller.uploadProfileImage(file.path);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Section Label
  // ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Reusable Text Field
  // ─────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    String? label,
    IconData? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    String? prefix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: Colors.grey[400], size: 20)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF00897B), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Gender Dropdown
  // ─────────────────────────────────────────────────────────
  Widget _buildGenderDropdown() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Colors.grey),
          items: ['Male', 'Female', 'Other']
              .map((g) =>
                  DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedGender = val);
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Month Name Helper
  // ─────────────────────────────────────────────────────────
  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}