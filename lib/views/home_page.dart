import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/match.dart';
import '../models/match_service.dart';
import '../models/storage_service.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/match_form_view_model.dart';
import '../viewmodels/match_list_view_model.dart';
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
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
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
                  leading: const Icon(Icons.logout),
                  title: const Text('Sair'),
                  onTap: () async {
                    final authViewModel = context.read<AuthViewModel>();
                    await authViewModel.signOut();
                    Navigator.of(context).pop();
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
                  _MatchesTab(),
                  _CreateMatchTab(userName: user?.email),
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
    final matchViewModel = context.watch<MatchListViewModel>();

    final user = authViewModel.user;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            value: matchViewModel.selectedCity,
            decoration: const InputDecoration(
              labelText: 'Selecione a cidade',
            ),
            items: _cities
                .map(
                  (c) => DropdownMenuItem(
                value: c,
                child: Text(c),
              ),
            )
                .toList(),
            onChanged: (value) => matchViewModel.setCity(value),
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
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: matchViewModel.matches.length,
                itemBuilder: (context, index) {
                  final match = matchViewModel.matches[index];
                  final formattedDate = _formatDateTime(match.dateTime);

                  final isOrganizer =
                      user != null && user.uid == match.organizerId;
                  final isParticipant =
                      user != null && match.participants.contains(user.uid);

                  return _MatchCard(
                    match: match,
                    formattedDate: formattedDate,
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
                    style: TextStyle(
                      color: AppColors.greyText,
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Vagas: ${match.spotsLeft}/${match.maxPlayers}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
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
  final String? userName;

  const _CreateMatchTab({this.userName});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.user;

    if (user == null) {
      return const Center(
        child: Text('Você precisa estar logado para criar uma partida.'),
      );
    }

    final matchService = context.read<MatchService>();
    final storageService = context.read<StorageService>();

    return ChangeNotifierProvider(
      create: (_) => MatchFormViewModel(
        matchService: matchService,
        storageService: storageService,
      ),
      child: _CreateMatchForm(
        displayName: userName ?? user.email ?? 'Jogador',
        userId: user.uid,
        userEmail: user.email,
      ),
    );
  }
}

class _CreateMatchForm extends StatefulWidget {
  final String displayName;
  final String userId;
  final String? userEmail;

  const _CreateMatchForm({
    required this.displayName,
    required this.userId,
    required this.userEmail,
  });

  @override
  State<_CreateMatchForm> createState() => _CreateMatchFormState();
}

class _CreateMatchFormState extends State<_CreateMatchForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxPlayersController = TextEditingController(text: '10');

  String? _selectedCity;
  String _selectedLevel = 'intermediário';
  DateTime? _selectedDateTime;
  File? _selectedImage;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _maxPlayersController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MatchFormViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.person_outline),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${widget.displayName.split('@').first}!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Bora jogar',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Nome da partida',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome da partida';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: const InputDecoration(
                labelText: 'Cidade',
              ),
              items: _cities
                  .map(
                    (c) => DropdownMenuItem(value: c, child: Text(c)),
              )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCity = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecione a cidade';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Local (quadra, lote, clube...)',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o local';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      _selectedDateTime == null
                          ? 'Data / Hora'
                          : '${_selectedDateTime!.day.toString().padLeft(2, '0')}/'
                          '${_selectedDateTime!.month.toString().padLeft(2, '0')} '
                          'às '
                          '${_selectedDateTime!.hour.toString().padLeft(2, '0')}:'
                          '${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _maxPlayersController,
                    decoration: const InputDecoration(
                      labelText: 'Número de vagas',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe as vagas';
                      }
                      final n = int.tryParse(value);
                      if (n == null || n <= 0) {
                        return 'Número inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedLevel,
              decoration: const InputDecoration(
                labelText: 'Nível técnico',
              ),
              items: const [
                DropdownMenuItem(value: 'iniciante', child: Text('Iniciante')),
                DropdownMenuItem(
                    value: 'intermediário', child: Text('Intermediário')),
                DropdownMenuItem(value: 'avançado', child: Text('Avançado')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value ?? 'intermediário';
                });
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  if (_selectedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.greyText,
                      ),
                    ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Foto do local'),
                  ),
                ],
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
                  if (!(_formKey.currentState?.validate() ?? false)) {
                    return;
                  }
                  if (_selectedDateTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                        Text('Selecione a data e horário do jogo.'),
                      ),
                    );
                    return;
                  }

                  final maxPlayers =
                  int.parse(_maxPlayersController.text);

                  final ok = await vm.createMatch(
                    title: _titleController.text.trim(),
                    city: _selectedCity!,
                    locationName: _locationController.text.trim(),
                    dateTime: _selectedDateTime!,
                    level: _selectedLevel,
                    maxPlayers: maxPlayers,
                    organizerId: widget.userId,
                    organizerName: widget.userEmail,
                    imageFile: _selectedImage,
                  );

                  if (!mounted) return;

                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Partida criada com sucesso!'),
                      ),
                    );
                    _formKey.currentState?.reset();
                    setState(() {
                      _selectedCity = null;
                      _selectedDateTime = null;
                      _selectedImage = null;
                      _selectedLevel = 'intermediário';
                      _maxPlayersController.text = '10';
                    });
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
                    : const Text('Criar partida'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
