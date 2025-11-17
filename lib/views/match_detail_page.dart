import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match.dart';
import '../models/match_service.dart';
import '../models/user_profile.dart';
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

  String _formatDateTime(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd/$mm às $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.user;
    final matchService = context.read<MatchService>();

    final isPast = match.isPast;

    return Scaffold(
      appBar: AppBar(
        title: Text(match.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (match.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  match.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              '${match.city} • ${match.locationName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Quando: ${_formatDateTime(match.dateTime)}'),
            const SizedBox(height: 4),
            Text('Nível: ${match.level}'),
            const SizedBox(height: 4),
            Text(
              'Vagas: ${match.spotsLeft}/${match.maxPlayers}',
            ),
            const SizedBox(height: 8),
            Text(
              'Organizador: ${match.organizerName ?? match.organizerId}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Text(
              'Jogadores confirmados (${match.participants.length}):',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            if (match.participants.isEmpty)
              const Text('Nenhum jogador confirmado ainda.')
            else
              _ParticipantsCarousel(
                participantIds: match.participants,
              ),

            const SizedBox(height: 24),
            if (user == null)
              const Text(
                'Faça login para participar desta partida.',
                style: TextStyle(color: Colors.red),
              )
            else if (isPast)
              const Text(
                'Essa partida já aconteceu.',
                style: TextStyle(color: Colors.red),
              )
            else ...[
                if (isOrganizer)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancelar partida'),
                            content: const Text(
                                'Tem certeza que deseja cancelar esta partida?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(false),
                                child: const Text('Não'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(true),
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
                              SnackBar(
                                content: Text(e.toString()),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar partida'),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
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
                              SnackBar(
                                content: Text(e.toString()),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        isParticipant
                            ? 'Cancelar presença'
                            : 'Confirmar presença',
                      ),
                    ),
                  ),
              ],
          ],
        ),
      ),
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
    final profileService = context.read<ProfileService>();

    return FutureBuilder<List<UserProfile>>(
      future: profileService.getProfilesForUids(participantIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
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

        if (profiles.isEmpty) {
          // Fallback: se ainda não tiver perfil salvo, mostra IDs
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: participantIds.map((id) => Text('- $id')).toList(),
          );
        }

        return SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: profiles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final p = profiles[index];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: p.photoUrl != null
                        ? NetworkImage(p.photoUrl!)
                        : null,
                    child: p.photoUrl == null
                        ? const Icon(Icons.person_outline)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 80,
                    child: Text(
                      p.displayName ?? p.email ?? 'Jogador',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
