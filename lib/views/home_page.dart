import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/match.dart';
import '../models/match_service.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/match_list_view_model.dart';
import 'match_form_page.dart';
import 'match_detail_page.dart';

const _cities = <String>[
  'Campinas',
  'São Paulo',
  'Rio de Janeiro',
  'Belo Horizonte',
  'Curitiba',
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final matchService = context.read<MatchService>();

    return ChangeNotifierProvider(
      create: (_) => MatchListViewModel(matchService: matchService),
      child: const _HomePageContent(),
    );
  }
}

class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  String _formatDateTime(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd/$mm às $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final vm = context.watch<MatchListViewModel>();

    final user = authViewModel.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FutJá - Partidas'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  user.email ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          IconButton(
            onPressed: () => authViewModel.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: user == null
            ? null
            : () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MatchFormPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Criar partida'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('Cidade:'),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: vm.selectedCity,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: _cities
                        .map(
                          (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    )
                        .toList(),
                    onChanged: (value) => vm.setCity(value),
                    hint: const Text('Selecione a cidade'),
                  ),
                ),
                IconButton(
                  onPressed: () => vm.setCity(null),
                  icon: const Icon(Icons.clear),
                  tooltip: 'Limpar filtro',
                ),
              ],
            ),
          ),
          if (vm.isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (vm.errorMessage != null)
            Expanded(
              child: Center(
                child: Text(
                  vm.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          else if (vm.matches.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Nenhuma partida encontrada.'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: vm.matches.length,
                  itemBuilder: (context, index) {
                    final match = vm.matches[index];
                    return _MatchCard(
                      match: match,
                      formattedDate: _formatDateTime(match.dateTime),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Match match;
  final String formattedDate;

  const _MatchCard({
    required this.match,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.user;

    final isOrganizer = user != null && user.uid == match.organizerId;
    final isParticipant =
        user != null && match.participants.contains(user.uid);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            match.city.isNotEmpty ? match.city[0].toUpperCase() : '?',
          ),
        ),
        title: Text(match.title),
        subtitle: Text(
          '${match.city} • ${match.locationName}\n'
              '$formattedDate • ${match.level}\n'
              'Vagas: ${match.spotsLeft}/${match.maxPlayers}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
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
      ),
    );
  }
}
