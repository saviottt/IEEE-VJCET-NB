import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import 'event_dialog.dart';
import '../screens/event_detail_screen.dart';

class DateEventsDialog extends ConsumerWidget {
  final DateTime date;

  const DateEventsDialog({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventState = ref.watch(eventProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter events for this selected date
    final dayEvents = eventState.events.where((e) {
      final startDay = DateTime(e.startDatetime.year, e.startDatetime.month, e.startDatetime.day);
      final endDay = DateTime(e.endDatetime.year, e.endDatetime.month, e.endDatetime.day);
      final targetDay = DateTime(date.year, date.month, date.day);
      return (targetDay.isAtSameMomentAs(startDay) || targetDay.isAfter(startDay)) &&
             (targetDay.isAtSameMomentAs(endDay) || targetDay.isBefore(endDay));
    }).toList();

    final dateHeaderString = DateFormat('EEEE, MMMM d, yyyy').format(date);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Events on',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateHeaderString,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: dayEvents.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_busy_rounded,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No events scheduled for this day',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: dayEvents.length,
                itemBuilder: (context, index) {
                  final event = dayEvents[index];
                  final catColor = event.category != null
                      ? Color(int.parse(event.category!.color.replaceAll('#', '0xFF')))
                      : colorScheme.primary;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        // Open details dialog
                        showDialog(
                          context: context,
                          builder: (context) => EventDetailDialog(event: event),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category color indicator
                                Container(
                                  width: 4,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: catColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.category?.name.toUpperCase() ?? 'OTHER',
                                        style: TextStyle(
                                          color: catColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        event.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Event times & details
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 8),
                                Text(
                                  '${DateFormat('h:mm a').format(event.startDatetime)} - ${DateFormat('h:mm a').format(event.endDatetime)}',
                                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                            if (event.venue.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      event.venue,
                                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (event.organizerName.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.business_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      event.organizerName,
                                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            // Delete button in the right bottom
                            Align(
                              alignment: Alignment.bottomRight,
                              child: TextButton.icon(
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Event'),
                                      content: const Text('Are you sure you want to delete this event?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    try {
                                      await ref.read(eventProvider.notifier).deleteEvent(event.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Event deleted successfully!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error deleting event: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                label: const Text('Delete'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red[700],
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            showDialog(
              context: context,
              builder: (context) => EventDialog(initialDate: date),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Event'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
