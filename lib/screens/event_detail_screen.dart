import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../widgets/event_dialog.dart';

class EventDetailDialog extends ConsumerWidget {
  final Event event;

  const EventDetailDialog({super.key, required this.event});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch registration link: $url')),
      );
    }
  }

  void _copyLink(BuildContext context) {
    final link = 'https://ieee-event-keeper.vercel.app/events/${event.id}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event link copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQrCode(BuildContext context) {
    final link = 'https://ieee-event-keeper.vercel.app/events/${event.id}';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Event QR Code', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan this code to view the event details on mobile devices.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: link,
                  version: QrVersions.auto,
                  size: 200.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                link,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final catColor = event.category != null
        ? Color(int.parse(event.category!.color.replaceAll('#', '0xFF')))
        : colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (event.bannerUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: Image.network(
                    event.bannerUrl!,
                    height: 240,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 140,
                      color: catColor.withOpacity(0.2),
                      child: Icon(Icons.broken_image, color: catColor, size: 48),
                    ),
                  ),
                )
              else
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.15),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.category?.name.toUpperCase() ?? 'OTHER',
                        style: TextStyle(
                          color: catColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateFormat.format(event.startDatetime),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              Text(
                                '${timeFormat.format(event.startDatetime)} - ${timeFormat.format(event.endDatetime)}',
                                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            event.venue.isEmpty ? 'No venue specified' : event.venue,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: event.venue.isEmpty ? colorScheme.onSurfaceVariant.withOpacity(0.6) : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Icon(Icons.business_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            event.organizerName.isEmpty ? 'Organizer not specified' : 'Organized by: ${event.organizerName}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: event.organizerName.isEmpty ? colorScheme.onSurfaceVariant.withOpacity(0.6) : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    const Divider(height: 32),

                    const Text(
                      'About the Event',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description ?? 'No description provided.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    
                    const Divider(height: 32),

                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => _copyLink(context),
                          icon: const Icon(Icons.link),
                          tooltip: 'Copy Link',
                        ),
                        const SizedBox(width: 8),
                        
                        IconButton.filledTonal(
                          onPressed: () => _showQrCode(context),
                          icon: const Icon(Icons.qr_code_2_rounded),
                          tooltip: 'Show QR Code',
                        ),
                        
                        const Spacer(),

                        if (event.registrationLink != null && event.registrationLink!.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () => _launchUrl(context, event.registrationLink!),
                            icon: const Icon(Icons.launch),
                            label: const Text('Register Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),

                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
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
                                  Navigator.of(context).pop();
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
                          icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                          label: const Text('Delete Event', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder: (context) => EventDialog(event: event),
                            );
                          },
                          icon: const Icon(Icons.edit_rounded, color: Colors.white),
                          label: const Text('Edit Event', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                          ),
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
