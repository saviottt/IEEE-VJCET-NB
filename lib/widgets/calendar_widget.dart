import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/event.dart';

class CalendarWidget extends StatelessWidget {
  final List<Event> events;
  final CalendarView currentView;
  final Function(Event) onEventTapped;

  const CalendarWidget({
    super.key,
    required this.events,
    required this.currentView,
    required this.onEventTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SfCalendar(
        view: currentView,
        dataSource: EventDataSource(events),
        headerStyle: CalendarHeaderStyle(
          textStyle: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        viewHeaderStyle: ViewHeaderStyle(
          dayTextStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
          dateTextStyle: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        todayHighlightColor: colorScheme.primary,
        appointmentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        timeSlotViewSettings: TimeSlotViewSettings(
          timeTextStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        onTap: (CalendarTapDetails details) {
          if (details.targetElement == CalendarElement.appointment &&
              details.appointments != null &&
              details.appointments!.isNotEmpty) {
            final Event event = details.appointments!.first as Event;
            onEventTapped(event);
          }
        },
      ),
    );
  }
}

// Data Source class mapping Syncfusion Calendar appointments to Event Model
class EventDataSource extends CalendarDataSource {
  EventDataSource(List<Event> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].startDatetime;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].endDatetime;
  }

  @override
  String getSubject(int index) {
    return appointments![index].title;
  }

  @override
  Color getColor(int index) {
    final hexColor = appointments![index].category?.color;
    if (hexColor != null) {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    }
    return const Color(0xFF6366F1); // Fallback color
  }

  @override
  bool isAllDay(int index) {
    return false;
  }
}
