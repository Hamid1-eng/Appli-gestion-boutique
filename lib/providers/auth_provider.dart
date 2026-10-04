import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/data_retention_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _user = _auth.currentUser;
    _sub = _auth.authStateChanges().listen(
      (User? nextUser) {
        _user = nextUser;
        if (nextUser == null) {
          _clearProfileCache();
        } else {
          unawaited(_syncProfileCache(nextUser.uid));
          unawaited(_runRetentionForAdmin(nextUser.uid));
        }
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('AuthProvider stream error: $error');
      },
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _sub;
  User? _user;
  String? _profileFirstName;
  String? _profileLastName;
  String? _profileDisplayName;
  String? _profileEmail;
  bool _profileLoaded = false;
  int _profileLoadVersion = 0;
  final Set<String> _retentionRunsInProgress = <String>{};

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get currentAdminId => _user?.uid;
  String? get currentAdminEmail => _user?.email;
  String get currentAdminDisplayName {
    final String? displayName = _profileDisplayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final String firstName = _profileFirstName?.trim() ?? '';
    final String lastName = _profileLastName?.trim() ?? '';
    final String combinedName = '$firstName $lastName'.trim();
    if (combinedName.isNotEmpty) {
      return combinedName;
    }

    final String? authDisplayName = _user?.displayName?.trim();
    if (authDisplayName != null && authDisplayName.isNotEmpty) {
      return authDisplayName;
    }

    final String? authEmail = _user?.email?.trim();
    if (authEmail != null && authEmail.isNotEmpty) {
      return authEmail.split('@').first;
    }

    return 'Admin';
  }

  String? get currentAdminFirstName {
    final String value = _profileFirstName?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  String? get currentAdminLastName {
    final String value = _profileLastName?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  String? get currentAdminProfileEmail {
    final String value = _profileEmail?.trim() ?? '';
    if (value.isNotEmpty) {
      return value;
    }
    return _user?.email;
  }

  DocumentReference<Map<String, dynamic>> _profileDoc(String adminId) {
    return _firestore.collection('admin_profiles').doc(adminId);
  }

  Map<String, String> _fallbackProfileData(User user) {
    final String displayName = user.displayName?.trim() ?? '';
    final String email = user.email?.trim() ?? '';
    final String source = displayName.isNotEmpty
        ? displayName
        : (email.isNotEmpty ? email.split('@').first : 'Admin');
    final List<String> parts = source.split(RegExp(r'\s+'));
    final String firstName = parts.isNotEmpty ? parts.first : 'Admin';
    final String lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return <String, String>{
      'firstName': firstName,
      'lastName': lastName,
      'displayName': source,
      'email': email,
    };
  }

  void _clearProfileCache() {
    _profileFirstName = null;
    _profileLastName = null;
    _profileDisplayName = null;
    _profileEmail = null;
    _profileLoaded = false;
  }

  void _applyProfileData(Map<String, dynamic>? data, {String? fallbackEmail}) {
    _profileFirstName = (data?['firstName'] ?? '').toString().trim();
    _profileLastName = (data?['lastName'] ?? '').toString().trim();
    _profileDisplayName = (data?['displayName'] ?? '').toString().trim();
    final String fallback = fallbackEmail?.trim() ?? '';
    _profileEmail = (data?['email'] ?? fallback).toString().trim();
    _profileLoaded = true;
  }

  Future<void> _syncProfileCache(String adminId) async {
    final int loadVersion = ++_profileLoadVersion;
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _profileDoc(
        adminId,
      ).get();
      if (loadVersion != _profileLoadVersion || _user?.uid != adminId) {
        return;
      }

      final User? currentUser = _user;
      if (snapshot.data() == null && currentUser != null) {
        final Map<String, String> fallback = _fallbackProfileData(currentUser);
        _applyProfileData(<String, dynamic>{
          'firstName': fallback['firstName'] ?? '',
          'lastName': fallback['lastName'] ?? '',
          'displayName': fallback['displayName'] ?? '',
          'email': fallback['email'] ?? '',
        }, fallbackEmail: currentUser.email);
        try {
          await _upsertAdminProfile(
            user: currentUser,
            firstName: fallback['firstName'] ?? 'Admin',
            lastName: fallback['lastName'] ?? '',
          );
        } catch (error) {
          debugPrint('AuthProvider profile seed error: $error');
        }
      } else {
        _applyProfileData(snapshot.data(), fallbackEmail: _user?.email);
      }
      notifyListeners();
    } catch (error) {
      debugPrint('AuthProvider profile load error: $error');
    }
  }

  Future<void> _runRetentionForAdmin(String adminId) async {
    final String normalizedId = adminId.trim();
    if (normalizedId.isEmpty ||
        _retentionRunsInProgress.contains(normalizedId)) {
      return;
    }

    _retentionRunsInProgress.add(normalizedId);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String key = 'retention_last_run_$normalizedId';
      final int? lastRunMillis = prefs.getInt(key);
      final DateTime now = DateTime.now();
      if (lastRunMillis != null) {
        final DateTime lastRun = DateTime.fromMillisecondsSinceEpoch(
          lastRunMillis,
        );
        if (now.difference(lastRun) < const Duration(hours: 24)) {
          return;
        }
      }

      final int deleted = await DataRetentionService.purgeForAdmin(
        firestore: _firestore,
        adminId: normalizedId,
      );
      debugPrint('Retention cleanup for $normalizedId deleted $deleted docs');
      await prefs.setInt(key, now.millisecondsSinceEpoch);
    } catch (error) {
      debugPrint('AuthProvider retention cleanup error: $error');
    } finally {
      _retentionRunsInProgress.remove(normalizedId);
    }
  }

  Future<Map<String, String>?> loadAdminProfile() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    if (_profileLoaded && _user?.uid == currentUser.uid) {
      return <String, String>{
        'firstName': _profileFirstName ?? '',
        'lastName': _profileLastName ?? '',
        'displayName': _profileDisplayName ?? currentAdminDisplayName,
        'email': _profileEmail ?? currentUser.email ?? '',
      };
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _profileDoc(
      currentUser.uid,
    ).get();
    final Map<String, dynamic>? data = snapshot.data();
    if (data == null) {
      final Map<String, String> fallback = _fallbackProfileData(currentUser);
      _applyProfileData(<String, dynamic>{
        'firstName': fallback['firstName'] ?? '',
        'lastName': fallback['lastName'] ?? '',
        'displayName': fallback['displayName'] ?? '',
        'email': fallback['email'] ?? '',
      }, fallbackEmail: currentUser.email);

      try {
        await _upsertAdminProfile(
          user: currentUser,
          firstName: fallback['firstName'] ?? 'Admin',
          lastName: fallback['lastName'] ?? '',
        );
      } catch (error) {
        debugPrint('AuthProvider profile seed error: $error');
      }

      return fallback;
    }

    _applyProfileData(data, fallbackEmail: currentUser.email);

    return <String, String>{
      'firstName': _profileFirstName ?? '',
      'lastName': _profileLastName ?? '',
      'displayName': _profileDisplayName ?? currentAdminDisplayName,
      'email': _profileEmail ?? currentUser.email ?? '',
    };
  }

  Future<void> _upsertAdminProfile({
    required User user,
    required String firstName,
    required String lastName,
  }) async {
    final String displayName = '$firstName $lastName'.trim();
    await _profileDoc(user.uid).set(<String, dynamic>{
      'adminId': user.uid,
      'email': user.email?.trim() ?? '',
      'firstName': firstName,
      'lastName': lastName,
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> createAdmin({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final UserCredential credential = await _auth
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

    final String fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
    if (credential.user != null && fullName.isNotEmpty) {
      await credential.user!.updateDisplayName(fullName);
      await _upsertAdminProfile(
        user: credential.user!,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
      );
      await credential.user!.reload();
      _user = _auth.currentUser;
      _applyProfileData(<String, dynamic>{
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'displayName': fullName,
        'email': credential.user!.email ?? '',
      }, fallbackEmail: credential.user!.email);
      notifyListeners();
    }
  }

  Future<void> updateAdminProfile({
    required String firstName,
    required String lastName,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Aucun administrateur connecté.');
    }

    final String fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
    if (fullName.isEmpty) {
      throw Exception('Le nom de profil ne peut pas être vide.');
    }

    await currentUser.updateDisplayName(fullName);
    await _upsertAdminProfile(
      user: currentUser,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
    );
    await currentUser.reload();
    _user = _auth.currentUser;
    _applyProfileData(<String, dynamic>{
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'displayName': fullName,
      'email': currentUser.email ?? '',
    }, fallbackEmail: currentUser.email);
    notifyListeners();
  }

  Future<void> sendPasswordReset() async {
    final String? email = _auth.currentUser?.email;
    if (email == null || email.trim().isEmpty) {
      throw Exception('Aucun email disponible pour la réinitialisation.');
    }

    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
