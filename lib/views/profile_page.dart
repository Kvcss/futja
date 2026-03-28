import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../services/profile_service.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/profile_view_model.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Você precisa estar logado para acessar o perfil.'),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(
        profileService: context.read<IProfileService>(),
        uid: user.uid,
      )..loadProfile(),
      child: const _ProfilePageContent(),
    );
  }
}

class _ProfilePageContent extends StatefulWidget {
  const _ProfilePageContent();

  @override
  State<_ProfilePageContent> createState() => _ProfilePageContentState();
}

class _ProfilePageContentState extends State<_ProfilePageContent> {
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();

  final _picker = ImagePicker();
  bool _initializedFromVm = false;

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ProfileViewModel vm) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 20,
      maxWidth: 600,
      maxHeight: 600,
    );

    if (picked != null) {
      vm.setPendingPhoto(File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    if (!_initializedFromVm && !vm.isLoading) {
      final profile = vm.profile;
      _nameController.text = profile?.displayName ?? '';
      _positionController.text = profile?.position ?? '';
      _ageController.text = profile?.age?.toString() ?? '';
      _weightController.text = profile?.weight?.toString() ?? '';
      _initializedFromVm = true;
    }

    final profile = vm.profile;
    final currentPhotoFile = vm.pendingPhotoFile;
    final photoBase64 = profile?.photoBase64;
    final photoUrl = profile?.photoUrl;

    Widget avatar;

    if (currentPhotoFile != null) {
      avatar = CircleAvatar(
        radius: 44,
        backgroundImage: FileImage(currentPhotoFile),
      );
    } else if (photoBase64 != null && photoBase64.trim().isNotEmpty) {
      avatar = CircleAvatar(
        radius: 44,
        backgroundImage: MemoryImage(base64Decode(photoBase64)),
      );
    } else if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      avatar = CircleAvatar(
        radius: 44,
        backgroundImage: NetworkImage(photoUrl),
      );
    } else {
      avatar = const CircleAvatar(
        radius: 44,
        child: Icon(Icons.person_outline, size: 34),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _pickPhoto(vm),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  avatar,
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryGreen,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _positionController,
              decoration: const InputDecoration(
                labelText: 'Posição que joga',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Idade',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 24),
            if (vm.errorMessage != null) ...[
              Text(
                vm.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: vm.isSaving
                    ? null
                    : () async {
                  int? age;
                  double? weight;

                  if (_ageController.text.trim().isNotEmpty) {
                    age = int.tryParse(_ageController.text.trim());
                  }

                  if (_weightController.text.trim().isNotEmpty) {
                    weight = double.tryParse(
                      _weightController.text
                          .trim()
                          .replaceAll(',', '.'),
                    );
                  }

                  await vm.saveProfile(
                    displayName: _nameController.text.trim(),
                    position: _positionController.text.trim(),
                    age: age,
                    weight: weight,
                  );

                  if (mounted && vm.errorMessage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Perfil salvo com sucesso!'),
                      ),
                    );
                  }
                },
                child: vm.isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}