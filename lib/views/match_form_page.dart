import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/match_service.dart';
import '../services/storage_service.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/match_form_view_model.dart';
import '../widgets/match_form_widget.dart';

class MatchFormPage extends StatelessWidget {
  const MatchFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Você precisa estar logado para criar uma partida.'),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => MatchFormViewModel(
        matchService: context.read<IMatchService>(),
        storageService: context.read<IStorageService>(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Criar partida'),
        ),
        body: Consumer<MatchFormViewModel>(
          builder: (context, vm, _) {
            return MatchFormWidget(
              isSaving: vm.isSaving,
              errorMessage: vm.errorMessage,
              submitLabel: 'Criar partida',
              onSubmit: (formData) {
                return vm.createMatch(
                  title: formData.title,
                  city: formData.city,
                  locationName: formData.locationName,
                  dateTime: formData.dateTime,
                  level: formData.level,
                  maxPlayers: formData.maxPlayers,
                  organizerId: user.uid,
                  organizerName: user.email,
                  imageFile: formData.imageFile,
                );
              },
              onSuccess: () {
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
    );
  }
}