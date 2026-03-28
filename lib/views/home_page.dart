import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../core/app_theme.dart';
import '../core/date_time_formatter.dart';
import '../models/match.dart';
import '../services/match_service.dart';
import '../services/storage_service.dart';
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
                  final isOrganizer =
                      user != null && user.uid == match.organizerId;
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Hero(
                    tag: 'match-image-${match.id}',
                    child: _MatchCoverImage(
                      imageUrl: match.imageUrl,
                      imageBase64: match.imageBase64,
                      height: 160,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${match.spotsLeft}/${match.maxPlayers} vagas',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.greyText,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            match.locationName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.greyText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: formattedDate,
                        ),
                        _InfoChip(
                          icon: Icons.sports_soccer_outlined,
                          label: match.level,
                        ),
                        _InfoChip(
                          icon: Icons.location_city_outlined,
                          label: match.city,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchCoverImage extends StatelessWidget {
  final String? imageUrl;
  final String? imageBase64;
  final double height;
  final BorderRadius borderRadius;

  const _MatchCoverImage({
    required this.imageUrl,
    required this.imageBase64,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final hasNetworkImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final hasBase64Image =
        imageBase64 != null && imageBase64!.trim().isNotEmpty;

    if (hasBase64Image) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.memory(
          base64Decode(imageBase64!),
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _fallbackContainer(height);
          },
        ),
      );
    }

    if (hasNetworkImage) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          imageUrl!,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: height,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
          errorBuilder: (_, __, ___) {
            return _fallbackContainer(height);
          },
        ),
      );
    }

    return _fallbackContainer(height);
  }

  Widget _fallbackContainer(double height) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        height: height,
        color: Colors.grey[200],
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_outlined,
                size: 34,
                color: AppColors.greyText,
              ),
              SizedBox(height: 8),
              Text(
                'Foto do local',
                style: TextStyle(color: AppColors.greyText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.greyText),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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