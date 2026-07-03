import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../providers/category_provider.dart';
import '../providers/theme_provider.dart';
import '../services/supabase_service.dart';
import '../services/export_service.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/event_dialog.dart';
import 'event_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEventDetail(Event event) {
    showDialog(
      context: context,
      builder: (context) => EventDetailDialog(event: event),
    );
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => const EventDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(eventProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isMockMode = SupabaseService.instance.isMockMode;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width <= 768;
    final isTablet = size.width > 768 && size.width <= 1100;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final weekEnd = todayStart.add(const Duration(days: 7));

    final todayEvents = eventState.events.where((e) {
      return e.startDatetime.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          e.startDatetime.isBefore(todayEnd.add(const Duration(seconds: 1)));
    }).toList();

    final thisWeekEvents = eventState.events.where((e) {
      return e.startDatetime.isAfter(todayEnd) && e.startDatetime.isBefore(weekEnd);
    }).toList();

    final upcomingEvents = eventState.events.where((e) {
      return e.startDatetime.isAfter(weekEnd);
    }).toList();

    Widget buildSidebar() {
      return Container(
        width: 260,
        color: colorScheme.surfaceContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'IEEE Keeper',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(indent: 20, endIndent: 20),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'FILTER CATEGORY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: Colors.grey,
                ),
              ),
            ),

            Expanded(
              child: categoriesAsync.when(
                data: (categories) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outline),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: const Text('All Categories', style: TextStyle(fontSize: 14)),
                        selected: eventState.selectedCategoryId == null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () => ref.read(eventProvider.notifier).setCategoryId('ALL'),
                      ),
                      ...categories.map((cat) {
                        final catColor = Color(int.parse(cat.color.replaceAll('#', '0xFF')));
                        final isSelected = eventState.selectedCategoryId == cat.id;
                        return ListTile(
                          leading: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: catColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(cat.name, style: const TextStyle(fontSize: 14)),
                          selected: isSelected,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onTap: () => ref.read(eventProvider.notifier).setCategoryId(cat.id),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading categories: $err'),
                ),
              ),
            ),

            const Divider(indent: 20, endIndent: 20),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                    icon: Icon(
                      themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    ),
                    tooltip: 'Toggle Theme',
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget buildTopBar() {
      return Row(
        children: [
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => ref.read(eventProvider.notifier).setSearchQuery(val),
                decoration: const InputDecoration(
                  hintText: 'Search by title, venue, organizer...',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMockMode 
                  ? Colors.amber.withOpacity(0.1) 
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isMockMode ? Colors.amber : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isMockMode ? 'Mock Sync' : 'Real-time Live',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isMockMode ? Colors.amber[800] : Colors.green[800],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          PopupMenuButton<String>(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export calendar',
            onSelected: (val) {
              if (val == 'csv') {
                ExportService.instance.exportToCSV(eventState.filteredEvents);
              } else if (val == 'pdf') {
                ExportService.instance.exportToPDF(
                  eventState.filteredEvents,
                  eventState.selectedCategoryId != null 
                      ? 'Filtered Category Schedule' 
                      : 'All Calendar Events',
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.grid_on_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Export as CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Print / Export as PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget buildSchedulePanel() {
      Widget buildEventList(String title, List<Event> list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            ...list.map((event) {
              final catColor = event.category != null
                  ? Color(int.parse(event.category!.color.replaceAll('#', '0xFF')))
                  : colorScheme.primary;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => _showEventDetail(event),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 36,
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
                                event.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat('MMM d, h:mm a').format(event.startDatetime)} • ${event.venue}',
                                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      }

      return Container(
        width: 320,
        color: colorScheme.surfaceContainer.withOpacity(0.4),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Agenda Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: eventState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: [
                        buildEventList("TODAY'S EVENTS", todayEvents),
                        buildEventList('THIS WEEK', thisWeekEvents),
                        buildEventList('UPCOMING EVENTS', upcomingEvents),
                        if (eventState.events.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Text(
                              'No events created yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: isMobile ? buildSidebar() : null,
      body: Row(
        children: [
          if (!isMobile) buildSidebar(),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildTopBar(),
                  const SizedBox(height: 20),
                  
                  if (isMobile) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showAddEventDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _showAddEventDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Event'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 20),

                  Expanded(
                    child: eventState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CalendarWidget(
                            events: eventState.filteredEvents,
                            currentView: sf.CalendarView.month,
                            onEventTapped: _showEventDetail,
                          ),
                  ),
                ],
              ),
            ),
          ),
          
          if (!isMobile && !isTablet) buildSchedulePanel(),
        ],
      ),
    );
  }
}
