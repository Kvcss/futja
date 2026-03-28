import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../core/app_theme.dart';
import '../core/date_time_formatter.dart';
import '../models/match.dart';
import '../models/match_service.dart';
import '../models/storage_service.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/match_form_view_model.dart';
import '../viewmodels/match_list_view_model.dart';
import '../widgets/match_form_widget.dart';
import 'match_detail_page.dart';
import 'profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final matchService = context.read<IMatchService>();

    return ChangeNotifierProvider(
      create: (_) => MatchListViewModel(
        matchService: matchService,
        initialCity: 'São Paulo',
      ),
      child: const _HomePageContent(),
    );
  }
}

class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.user;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 72,
          automaticallyImplyLeading: false,
          leadingWidth: 0,
          centerTitle: false,
          titleSpacing: 0,
          title: Row(
            children: [
              Image.asset(
                'images/futja_logo_clean.png',
                height: 150,
              ),
              const Text(
                'FUT JÁ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          actions: [
            Builder(
              builder: (context) {
                return IconButton(
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                  icon: const Icon(Icons.menu_rounded),
                );
              },
            ),
          ],
        ),
        endDrawer: Drawer(
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Perfil'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfilePage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sair'),
                  onTap: () async {
                    await context.read<AuthViewModel>().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _HomeTabs(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  const _MatchesTab(),
                  _CreateMatchTab(userEmail: user?.email),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTabs extends StatelessWidget {
  const _HomeTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(28),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textDark,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Jogar'),
          Tab(text: 'Criar'),
        ],
      ),
    );
  }
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab();

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final matchViewModel = context.watch<MatchListViewModel>();
    final user = authViewModel.user;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            value: matchViewModel.selectedCity,
            isExpanded: true,
            items: AppConstants.cities
                .map(
                  (city) => DropdownMenuItem(
                value: city,
                child: Text(city),
              ),
            )
                .toList(),
            onChanged: matchViewModel.setCity,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Builder(
            builder: (context) {
              if (matchViewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (matchViewModel.errorMessage != null) {
                return Center(
                  child: Text(
                    matchViewModel.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (matchViewModel.matches.isEmpty) {
                return const Center(
                  child: Text('Nenhuma partida encontrada.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: matchViewModel.matches.length,
                itemBuilder: (context, index) {
                  final match = matchViewModel.matches[index];
                  final isOrganizer = user != null && user.uid == match.organizerId;
                  final isParticipant =
                      user != null && match.participants.contains(user.uid);

                  return _MatchCard(
                    match: match,
                    formattedDate: AppDateTimeFormatter.shortDateTime(
                      match.dateTime,
                    ),
                    isOrganizer: isOrganizer,
                    isParticipant: isParticipant,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Match match;
  final String formattedDate;
  final bool isOrganizer;
  final bool isParticipant;

  const _MatchCard({
    required this.match,
    required this.formattedDate,
    required this.isOrganizer,
    required this.isParticipant,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MatchDetailPage(
              match: match,
              isOrganizer: isOrganizer,
              isParticipant: isParticipant,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: match.imageUrl != null
                  ? Image.network(
                match.imageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Container(
                height: 120,
                color: Colors.grey[200],
                child: const Center(
                  child: Text(
                    'Foto do local',
                    style: TextStyle(color: AppColors.greyText),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          match.locationName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.greyText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$formattedDate   ${match.level}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Vagas: ${match.spotsLeft}/${match.maxPlayers}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateMatchTab extends StatelessWidget {
  final String? userEmail;

  const _CreateMatchTab({this.userEmail});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.user;

    if (user == null) {
      return const Center(
        child: Text('Você precisa estar logado para criar uma partida.'),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => MatchFormViewModel(
        matchService: context.read<IMatchService>(),
        storageService: context.read<IStorageService>(),
      ),
      child: Consumer<MatchFormViewModel>(
        builder: (context, vm, _) {
          return MatchFormWidget(
            greetingName: userEmail ?? user.email ?? 'Jogador',
            isSaving: vm.isSaving,
            errorMessage: vm.errorMessage,
            submitLabel: 'Criar partida',
            successMessage: 'Partida criada com sucesso!',
            resetAfterSuccess: true,
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
          );
        },
      ),
    );
  }
}