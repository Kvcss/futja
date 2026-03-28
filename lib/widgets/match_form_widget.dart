import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_constants.dart';
import '../core/app_theme.dart';
import '../core/date_time_formatter.dart';
import '../core/form_validators.dart';

class MatchFormData {
  final String title;
  final String city;
  final String locationName;
  final DateTime dateTime;
  final String level;
  final int maxPlayers;
  final File? imageFile;

  MatchFormData({
    required this.title,
    required this.city,
    required this.locationName,
    required this.dateTime,
    required this.level,
    required this.maxPlayers,
    this.imageFile,
  });
}

class MatchFormWidget extends StatefulWidget {
  final bool isSaving;
  final String? errorMessage;
  final String submitLabel;
  final String? greetingName;
  final String? successMessage;
  final bool resetAfterSuccess;
  final Future<bool> Function(MatchFormData data) onSubmit;
  final VoidCallback? onSuccess;

  const MatchFormWidget({
    super.key,
    required this.isSaving,
    required this.submitLabel,
    required this.onSubmit,
    this.errorMessage,
    this.greetingName,
    this.successMessage,
    this.resetAfterSuccess = false,
    this.onSuccess,
  });

  @override
  State<MatchFormWidget> createState() => _MatchFormWidgetState();
}

class _MatchFormWidgetState extends State<MatchFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxPlayersController = TextEditingController(text: '10');
  final _picker = ImagePicker();

  String? _selectedCity;
  String _selectedLevel = 'intermediário';
  DateTime? _selectedDateTime;
  File? _selectedImage;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _maxPlayersController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 35,
      maxWidth: 900,
      maxHeight: 900,
    );

    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
    });
  }
  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        now.add(const Duration(hours: 1)),
      ),
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

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _locationController.clear();
    _maxPlayersController.text = '10';

    setState(() {
      _selectedCity = null;
      _selectedLevel = 'intermediário';
      _selectedDateTime = null;
      _selectedImage = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a data e horário do jogo.'),
        ),
      );
      return;
    }

    final data = MatchFormData(
      title: _titleController.text.trim(),
      city: _selectedCity!,
      locationName: _locationController.text.trim(),
      dateTime: _selectedDateTime!,
      level: _selectedLevel,
      maxPlayers: int.parse(_maxPlayersController.text.trim()),
      imageFile: _selectedImage,
    );

    final ok = await widget.onSubmit(data);

    if (!mounted || !ok) return;

    if (widget.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.successMessage!),
        ),
      );
    }

    if (widget.resetAfterSuccess) {
      _resetForm();
    }

    widget.onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    final greetingName = widget.greetingName;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (greetingName != null) ...[
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
                        'Olá, ${greetingName.split('@').first}!',
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
            ],
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Nome da partida',
              ),
              validator: (value) {
                return FormValidators.validateRequired(
                  value,
                  'o nome da partida',
                );
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCity,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Cidade',
              ),
              items: AppConstants.cities
                  .map(
                    (city) => DropdownMenuItem(
                  value: city,
                  child: Text(city),
                ),
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
                labelText: 'Local (quadra, rua, clube...)',
              ),
              validator: (value) {
                return FormValidators.validateRequired(
                  value,
                  'o local',
                );
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
                          : AppDateTimeFormatter.shortDateTime(
                        _selectedDateTime!,
                      ),
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
                      return FormValidators.validatePositiveInt(
                        value,
                        'o número de vagas',
                      );
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
              items: AppConstants.levels
                  .map(
                    (level) => DropdownMenuItem(
                  value: level,
                  child: Text(
                    level[0].toUpperCase() + level.substring(1),
                  ),
                ),
              )
                  .toList(),
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
            if (widget.errorMessage != null) ...[
              Text(
                widget.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.isSaving ? null : _handleSubmit,
                child: widget.isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(widget.submitLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}