import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/date_time_formatter.dart';
import '../models/match.dart';
import '../models/user_profile.dart';
import '../services/match_service.dart';
import '../services/profile_service.dart';
import '../viewmodels/auth_view_model.dart';

class MatchDetailPage extends StatelessWidget {
  final Match match;
  final bool isOrganizer;
  final bool isParticipant;

  const MatchDetailPage({
    super.key,
    required this.match,
    required this.isOrganizer,
    required this.isParticipant,
  });

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.user;
    final isPast = match.isPast;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'match-image-${match.id}',
                    child: _DetailHeaderImage(
                      imageUrl: match.imageUrl,
                      imageBase64: match.imageBase64,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.15),
                          Colors.black.withOpacity(0.60),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _HeaderBadge(label: match.city),
                            _HeaderBadge(label: match.level),
                            if (isOrganizer)
                              const _HeaderBadge(label: 'Você organiza'),
                            if (!isOrganizer && isParticipant)
                              const _HeaderBadge(label: 'Você participa'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          match.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          match.locationName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user == null)
                    const _StatusBanner(
                      icon: Icons.login_outlined,
                      text: 'Faça login para participar desta partida.',
                    )
                  else if (isPast)
                    const _StatusBanner(
                      icon: Icons.event_busy_outlined,
                      text: 'Essa partida já aconteceu.',
                    )
                  else if (match.isFull && !isParticipant && !isOrganizer)
                      const _StatusBanner(
                        icon: Icons.group_off_outlined,
                        text: 'Essa partida está lotada no momento.',
                      ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Informações da partida',
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          title: 'Data e horário',
                          value: AppDateTimeFormatter.shortDateTime(
                            match.dateTime,
                          ),
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          title: 'Local',
                          value: match.locationName,
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.sports_soccer_outlined,
                          title: 'Nível técnico',
                          value: match.level,
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.people_alt_outlined,
                          title: 'Vagas',
                          value:
                          '${match.spotsLeft}/${match.maxPlayers} disponíveis',
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.person_outline,
                          title: 'Organizador',
                          value: match.organizerName ?? match.organizerId,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title:
                    'Jogadores confirmados (${match.participants.length})',
                    child: match.participants.isEmpty
                        ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhum jogador confirmado ainda.',
                        style: TextStyle(
                          color: AppColors.greyText,
                        ),
                      ),
                    )
                        : _ParticipantsCarousel(
                      participantIds: match.participants,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _MatchDetailBottomBar(
        match: match,
        isOrganizer: isOrganizer,
        isParticipant: isParticipant,
      ),
    );
  }
}

class _MatchDetailBottomBar extends StatelessWidget {
  final Match match;
  final bool isOrganizer;
  final bool isParticipant;

  const _MatchDetailBottomBar({
    required this.match,
    required this.isOrganizer,
    required this.isParticipant,
  });

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.user;
    final matchService = context.read<IMatchService>();
    final isPast = match.isPast;
    final isFull = match.isFull && !isParticipant && !isOrganizer;

    if (user == null || isPast || isFull) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: isOrganizer
              ? ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size.fromHeight(54),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cancelar partida'),
                  content: const Text(
                    'Tem certeza que deseja cancelar esta partida?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Não'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Sim'),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              try {
                await matchService.cancelMatch(
                  matchId: match.id,
                  organizerId: user.uid,
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar partida'),
          )
              : ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            onPressed: () async {
              try {
                if (isParticipant) {
                  await matchService.leaveMatch(
                    matchId: match.id,
                    userId: user.uid,
                  );
                } else {
                  await matchService.joinMatch(
                    matchId: match.id,
                    userId: user.uid,
                  );
                }

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            icon: Icon(
              isParticipant
                  ? Icons.logout_outlined
                  : Icons.check_circle_outline,
            ),
            label: Text(
              isParticipant
                  ? 'Cancelar presença'
                  : 'Confirmar presença',
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailHeaderImage extends StatelessWidget {
  final String? imageUrl;
  final String? imageBase64;

  const _DetailHeaderImage({
    required this.imageUrl,
    required this.imageBase64,
  });

  @override
  Widget build(BuildContext context) {
    final hasNetworkImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final hasBase64Image =
        imageBase64 != null && imageBase64!.trim().isNotEmpty;

    if (hasBase64Image) {
      return Image.memory(
        base64Decode(imageBase64!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    if (hasNetworkImage) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 60,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final String label;

  const _HeaderBadge({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StatusBanner({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE2A8)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB7791F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF8A5A12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.greyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParticipantsCarousel extends StatelessWidget {
  final List<String> participantIds;

  const _ParticipantsCarousel({
    required this.participantIds,
  });

  @override
  Widget build(BuildContext context) {
    final profileService = context.read<IProfileService>();

    return FutureBuilder<List<UserProfile>>(
      future: profileService.getProfilesForUids(participantIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            'Erro ao carregar jogadores.',
            style: TextStyle(color: Colors.red),
          );
        }

        final profiles = snapshot.data ?? [];

        return SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: profiles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final profile = profiles[index];

              ImageProvider? imageProvider;

              if (profile.photoBase64 != null &&
                  profile.photoBase64!.trim().isNotEmpty) {
                imageProvider = MemoryImage(
                  base64Decode(profile.photoBase64!),
                );
              } else if (profile.photoUrl != null &&
                  profile.photoUrl!.trim().isNotEmpty) {
                imageProvider = NetworkImage(profile.photoUrl!);
              }

              return Container(
                width: 100,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFB),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFECEFF3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(Icons.person_outline)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.displayLabel,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}