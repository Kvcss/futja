
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileService profileService;
  final String uid;

  UserProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  File? _pendingPhotoFile;

  ProfileViewModel({
    required this.profileService,
    required this.uid,
  });

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  File? get pendingPhotoFile => _pendingPhotoFile;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await profileService.getProfile(uid);
    } catch (e) {
      _errorMessage = 'Erro ao carregar perfil.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPendingPhoto(File? file) {
    _pendingPhotoFile = file;
    notifyListeners();
  }

  Future<void> saveProfile({
    String? displayName,
    String? position,
    int? age,
    double? weight,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await profileService.updateProfile(
        uid: uid,
        displayName: displayName,
        position: position,
        age: age,
        weight: weight,
        photoFile: _pendingPhotoFile,
      );
      _pendingPhotoFile = null;
    } catch (e) {
      _errorMessage = 'Erro ao salvar perfil.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
