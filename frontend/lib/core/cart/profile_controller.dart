import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class ProfileController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel _user = UserModel.dummy();
  bool _isLoading = false;

  UserModel get user => _user;
  bool get isLoading => _isLoading;

  String get name => _user.name;
  String get email => _user.email;
  String get phone => _user.phone;
  String get gender => _user.gender;
  String get dob => _user.dob;
  String get age => _user.age;
  String get bloodGroup => _user.bloodGroup;
  String get height => _user.height;
  String get weight => _user.weight;
  String? get profileImageUrl => _user.profileImageUrl;

  // ── Load user data from Firestore ─────────────────────
  Future<void> loadUserData() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        _user = _user.copyWith(
          name: data['name'] ?? _user.name,
          email: data['email'] ?? _user.email,
          phone: data['phone'] ?? _user.phone,
          gender: data['gender'] ?? _user.gender,
          dob: data['dob'] ?? _user.dob,
          age: data['age'] ?? _user.age,
          bloodGroup: data['bloodGroup'] ?? _user.bloodGroup,
          height: data['height'] ?? _user.height,
          weight: data['weight'] ?? _user.weight,
        );
      }
    } catch (e) {
      debugPrint("Error loading user: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Update profile in Firestore ───────────────────────
  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String gender,
    required String dob,
    required String age,
    required String bloodGroup,
    required String height,
    required String weight,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) return;

      // Save to Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
        'dob': dob,
        'age': age,
        'bloodGroup': bloodGroup,
        'height': height,
        'weight': weight,
      });

      // Update local state
      _user = _user.copyWith(
        name: name,
        email: email,
        phone: phone,
        gender: gender,
        dob: dob,
        age: age,
        bloodGroup: bloodGroup,
        height: height,
        weight: weight,
      );
    } catch (e) {
      debugPrint("Error updating profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Logout ────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    _user = UserModel.dummy();
    notifyListeners();
  }
}
