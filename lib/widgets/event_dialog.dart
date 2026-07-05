import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../providers/category_provider.dart';
import '../providers/event_provider.dart';

class EventDialog extends ConsumerStatefulWidget {
  final Event? event; // Null for Add Event, non-null for Edit Event
  final DateTime? initialDate;

  const EventDialog({super.key, this.event, this.initialDate});

  @override
  ConsumerState<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends ConsumerState<EventDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _venueController;
  late TextEditingController _orgController;
  late TextEditingController _regLinkController;

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  
  String? _selectedCategoryId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;

    _titleController = TextEditingController(text: event?.title ?? '');
    _descController = TextEditingController(text: event?.description ?? '');
    _venueController = TextEditingController(text: event?.venue ?? '');
    _orgController = TextEditingController(text: event?.organizerName ?? '');
    _regLinkController = TextEditingController(text: event?.registrationLink ?? '');

    if (widget.initialDate != null) {
      _startDate = widget.initialDate!;
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endDate = widget.initialDate!.add(const Duration(hours: 1));
      _endTime = const TimeOfDay(hour: 10, minute: 0);
    } else if (event != null) {
      _startDate = event.startDatetime;
      _startTime = TimeOfDay.fromDateTime(event.startDatetime);
      _endDate = event.endDatetime;
      _endTime = TimeOfDay.fromDateTime(event.endDatetime);
      _selectedCategoryId = event.categoryId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _venueController.dispose();
    _orgController.dispose();
    _regLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }


  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final start = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final end = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End Date & Time must be after Start Date & Time')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final newEvent = Event(
      id: widget.event?.id ?? 'temp',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      venue: _venueController.text.trim(),
      organizerName: _orgController.text.trim(),
      startDatetime: start,
      endDatetime: end,
      categoryId: _selectedCategoryId,
      bannerUrl: widget.event?.bannerUrl,
      registrationLink: _regLinkController.text.trim().isEmpty ? null : _regLinkController.text.trim(),
      createdAt: widget.event?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.event == null) {
        await ref.read(eventProvider.notifier).createEvent(newEvent);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!'), backgroundColor: Colors.green),
        );
      } else {
        await ref.read(eventProvider.notifier).updateEvent(newEvent);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event updated successfully!'), backgroundColor: Colors.green),
        );
      }
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(widget.event == null ? 'Create Event' : 'Edit Event'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title *',
                    hintText: 'e.g. IEEE Extreme Hackathon',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe details of your event',
                  ),
                ),
                const SizedBox(height: 16),

                categoriesAsync.when(
                  data: (categories) {
                    return DropdownButtonFormField<String?>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category (Optional)',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None (No Category)'),
                        ),
                        ...categories.map((cat) {
                          final catColor = Color(int.parse(cat.color.replaceAll('#', '0xFF')));
                          return DropdownMenuItem<String?>(
                            value: cat.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: catColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(cat.name),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                        });
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading categories: $e'),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Date & Time', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _pickStartDate,
                            icon: const Icon(Icons.calendar_today_rounded),
                            label: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _pickStartTime,
                            icon: const Icon(Icons.access_time_rounded),
                            label: Text(_startTime.format(context)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Date & Time', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _pickEndDate,
                            icon: const Icon(Icons.calendar_today_rounded),
                            label: Text(DateFormat('yyyy-MM-dd').format(_endDate)),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _pickEndTime,
                            icon: const Icon(Icons.access_time_rounded),
                            label: Text(_endTime.format(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _venueController,
                        decoration: const InputDecoration(labelText: 'Venue (Optional)'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _orgController,
                        decoration: const InputDecoration(labelText: 'Organizer Name (Optional)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _regLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Registration Link',
                    hintText: 'https://...',
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (widget.event != null)
          TextButton(
            onPressed: _isSubmitting ? null : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Event'),
                  content: const Text('Are you sure you want to delete this event?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(eventProvider.notifier).deleteEvent(widget.event!.id);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
              : Text(widget.event == null ? 'Create' : 'Save Changes'),
        ),
      ],
    );
  }
}
