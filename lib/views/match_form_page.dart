import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/match_service.dart';
import '../models/storage_service.dart' show StorageService;
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/match_form_view_model.dart';


class MatchFormPage extends StatelessWidget {
  const MatchFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final matchService = context.read<MatchService>();
    final storageService = context.read<StorageService>();

    return ChangeNotifierProvider(
      create: (_) => MatchFormViewModel(
        matchService: matchService,
        storageService: storageService,
      ),
      child: const _MatchFormPageContent(),
    );
  }
}

class _MatchFormPageContent extends StatefulWidget {
  const _MatchFormPageContent();

  @override
  State<_MatchFormPageContent> createState() => _MatchFormPageContentState();
}

class _MatchFormPageContentState extends State<_MatchFormPageContent> {
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
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Você precisa estar logado para criar uma partida.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar partida'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Título
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
                items: const [
                  DropdownMenuItem(value: 'Campinas', child: Text('Campinas')),
                  DropdownMenuItem(
                      value: 'São Paulo', child: Text('São Paulo')),
                  DropdownMenuItem(
                      value: 'Rio de Janeiro', child: Text('Rio de Janeiro')),
                  DropdownMenuItem(
                      value: 'Belo Horizonte', child: Text('Belo Horizonte')),
                  DropdownMenuItem(
                      value: 'Curitiba', child: Text('Curitiba')),
                ],
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
                  labelText: 'Local (quadra, rua, clube...)',
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
                    child: Text(
                      _selectedDateTime == null
                          ? 'Selecione data e horário'
                          : 'Jogo em: '
                          '${_selectedDateTime!.day.toString().padLeft(2, '0')}/'
                          '${_selectedDateTime!.month.toString().padLeft(2, '0')} '
                          'às '
                          '${_selectedDateTime!.hour.toString().padLeft(2, '0')}:'
                          '${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Data / Hora'),
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
                  DropdownMenuItem(
                      value: 'iniciante', child: Text('Iniciante')),
                  DropdownMenuItem(
                      value: 'intermediário', child: Text('Intermediário')),
                  DropdownMenuItem(
                      value: 'avançado', child: Text('Avançado')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLevel = value ?? 'intermediário';
                  });
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _maxPlayersController,
                decoration: const InputDecoration(
                  labelText: 'Número de vagas',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o número de vagas';
                  }
                  final n = int.tryParse(value);
                  if (n == null || n <= 0) {
                    return 'Número inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Imagem
              Row(
                children: [
                  if (_selectedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[300],
                      ),
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo),
                    label: const Text('Foto do local'),
                  ),
                ],
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
                      organizerId: user.uid,
                      organizerName: user.email,
                      imageFile: _selectedImage,
                    );

                    if (!mounted) return;

                    if (ok) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: vm.isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Criar partida'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
