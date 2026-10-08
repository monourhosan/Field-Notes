import '../widgets/note_photo.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/field_note.dart';
import '../bloc/note/field_note_bloc.dart';
import '../bloc/note/field_note_event.dart';
import '../bloc/note/field_note_state.dart';
import '../bloc/site/site_bloc.dart';
import '../bloc/site/site_event.dart';
import '../bloc/site/site_state.dart';
import '../bloc/settings/settings_bloc.dart';
import '../bloc/settings/settings_state.dart';

class FieldNoteEditorScreen extends StatefulWidget {
  final FieldNote? existingNote;
  final String? preselectedSiteId;

  const FieldNoteEditorScreen({
    super.key,
    this.existingNote,
    this.preselectedSiteId,
  });

  @override
  State<FieldNoteEditorScreen> createState() => _FieldNoteEditorScreenState();
}

class _FieldNoteEditorScreenState extends State<FieldNoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedSiteId;
  String _selectedStatus = 'DRAFT';
  DateTime _selectedDateTime = DateTime.now();
  String? _photoBase64;
  bool _isGettingLocation = false;
  bool _isSaving = false;

  final List<String> _statuses = [
    'DRAFT',
    'IN_PROGRESS',
    'COMPLETED',
    'PENDING',
  ];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<SiteBloc>().add(const LoadSites());

    if (widget.existingNote != null) {
      final note = widget.existingNote!;
      _selectedSiteId = note.siteId;
      _titleController.text = note.title;
      _descriptionController.text = note.description ?? '';
      _locationController.text = note.location ?? '';
      _selectedStatus = note.status;
      _selectedDateTime = note.dateTime.toLocal();
      _photoBase64 = note.photo;
    } else {
      _selectedSiteId = widget.preselectedSiteId;
      // Initialize with default status from local settings
      final settingsState = context.read<SettingsBloc>().state;
      if (settingsState is SettingsLoaded) {
        _selectedStatus = settingsState.defaultNoteStatus;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Location capture with robust permission handling
  Future<void> _captureLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location services are disabled. Please enable GPS.',
              ),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
        }
        if (mounted) setState(() => _isGettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permissions are denied. Coordinates cannot be captured.',
                ),
              ),
            );
          }
          if (mounted) setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location permissions are permanently denied. Please enable them in app settings.',
              ),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        if (mounted) setState(() => _isGettingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;
      setState(() {
        _locationController.text =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS Coordinates captured successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not fetch location: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  // Camera and Gallery image capture
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (photo != null && mounted) {
        final bytes = await photo.readAsBytes();
        if (!mounted) return;
        if (bytes.length > 1400000) {
          throw StateError('Photo too large. Choose a smaller image.');
        }
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _photoBase64 = base64String;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image selection failed: $e')));
      }
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo (Camera)'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_photoBase64 != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.errorColor,
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() => _photoBase64 = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveNote() {
    if (_isSaving) return;
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedSiteId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a site.')));
        return;
      }

      setState(() => _isSaving = true);
      if (widget.existingNote == null) {
        context.read<FieldNoteBloc>().add(
          CreateFieldNoteEvent(
            siteId: _selectedSiteId!,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            location: _locationController.text.trim(),
            dateTime: _selectedDateTime,
            status: _selectedStatus,
            photo: _photoBase64,
          ),
        );
      } else {
        context.read<FieldNoteBloc>().add(
          UpdateFieldNoteEvent(
            id: widget.existingNote!.id,
            siteId: _selectedSiteId!,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            location: _locationController.text.trim(),
            dateTime: _selectedDateTime,
            status: _selectedStatus,
            photo: _photoBase64,
          ),
        );
      }
    }
  }

  void _deleteNote() {
    if (widget.existingNote == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Field Note'),
        content: const Text('Are you sure you want to delete this field note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () {
              context.read<FieldNoteBloc>().add(
                DeleteFieldNoteEvent(widget.existingNote!.id),
              );
              Navigator.of(ctx).pop();
              setState(() => _isSaving = true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingNote != null;
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Field Note' : 'New Field Note'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.errorColor,
              ),
              onPressed: _deleteNote,
            ),
        ],
      ),
      body: BlocListener<FieldNoteBloc, FieldNoteState>(
        listener: (context, state) {
          if (!_isSaving) return;
          if (state is FieldNoteSaved) Navigator.of(context).pop();
          if (state is FieldNoteError) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Site Selector
                BlocBuilder<SiteBloc, SiteState>(
                  builder: (context, state) {
                    List<DropdownMenuItem<String>> items = [];
                    if (state is SiteLoaded) {
                      items = state.sites.map((site) {
                        return DropdownMenuItem(
                          value: site.id,
                          child: Text(
                            '${site.siteName} (${site.customerName ?? "Customer"})',
                          ),
                        );
                      }).toList();

                      if (_selectedSiteId == null && state.sites.isNotEmpty) {
                        _selectedSiteId = state.sites.first.id;
                      }
                    }

                    if (items.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: const Text(
                          'No sites available. Please create a customer and site first!',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      key: ValueKey(items.map((item) => item.value).join('|')),
                      initialValue:
                          items.any((item) => item.value == _selectedSiteId)
                          ? _selectedSiteId
                          : null,
                      decoration: const InputDecoration(labelText: 'Site *'),
                      items: items,
                      onChanged: (val) {
                        setState(() => _selectedSiteId = val);
                      },
                      validator: (val) =>
                          val == null ? 'Please select a site' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Note Title *'),
                  maxLength: 255,
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Please enter a title'
                      : null,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description / Observations',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                // Status Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status *'),
                  items: _statuses.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
                const SizedBox(height: 16),

                // Date & Time Picker field
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Inspection Date & Time',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(dateFormat.format(_selectedDateTime)),
                  ),
                ),
                const SizedBox(height: 16),

                // Location field with GPS capture
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location Coordinates',
                          hintText: 'e.g. 37.7749, -122.4194',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isGettingLocation ? null : _captureLocation,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      child: _isGettingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.my_location),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Photo Section
                const Text(
                  'Photo Attachment (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                if (_photoBase64 != null) ...[
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: NotePhoto(data: _photoBase64!),
                        ),
                      ),
                      IconButton(
                        icon: const CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 16,
                          child: Icon(
                            Icons.close,
                            color: AppTheme.errorColor,
                            size: 18,
                          ),
                        ),
                        onPressed: () => setState(() => _photoBase64 = null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                OutlinedButton.icon(
                  onPressed: _showImagePickerSheet,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                    _photoBase64 != null
                        ? 'Change Photo'
                        : 'Attach Photo (Camera / Gallery)',
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveNote,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isSaving
                        ? 'Saving...'
                        : (isEditing ? 'Save Changes' : 'Record Field Note'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
