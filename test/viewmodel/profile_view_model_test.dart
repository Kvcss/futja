import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:futja_app/models/user_profile.dart';
import 'package:futja_app/services/profile_service.dart';
import 'package:futja_app/viewmodels/profile_view_model.dart';

class FakeProfileService implements IProfileService {
  UserProfile? storedProfile = UserProfile(
    uid: 'user_1',
    displayName: 'Kaio',
    position: 'Atacante',
    age: 23,
    weight: 72.5,
    email: 'kaio@email.com',
  );

  @override
  Future<UserProfile?> getProfile(String uid) async {
    return storedProfile;
  }

  @override
  Future<List<UserProfile>> getProfilesForUids(List<String> uids) async {
    return storedProfile == null ? [] : [storedProfile!];
  }

  @override
  Future<UserProfile> updateProfile({
    required String uid,
    String? displayName,
    String? position,
    int? age,
    double? weight,
    File? photoFile,
  }) async {
    storedProfile = UserProfile(
      uid: uid,
      displayName: displayName,
      position: position,
      age: age,
      weight: weight,
      email: 'kaio@email.com',
    );
    return storedProfile!;
  }
}

void main() {
  group('ProfileViewModel', () {
    test('deve carregar perfil com sucesso', () async {
      final service = FakeProfileService();
      final viewModel = ProfileViewModel(
        profileService: service,
        uid: 'user_1',
      );

      await viewModel.loadProfile();

      expect(viewModel.profile, isNotNull);
      expect(viewModel.profile!.displayName, 'Kaio');
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
    });

    test('deve salvar perfil com sucesso', () async {
      final service = FakeProfileService();
      final viewModel = ProfileViewModel(
        profileService: service,
        uid: 'user_1',
      );

      await viewModel.saveProfile(
        displayName: 'Kaio Silva',
        position: 'Meia',
        age: 24,
        weight: 74.0,
      );

      expect(viewModel.profile, isNotNull);
      expect(viewModel.profile!.displayName, 'Kaio Silva');
      expect(viewModel.profile!.position, 'Meia');
      expect(viewModel.isSaving, false);
      expect(viewModel.errorMessage, isNull);
    });
  });
}