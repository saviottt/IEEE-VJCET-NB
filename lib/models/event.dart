import 'category.dart';

class Event {
  final String id;
  final String title;
  final String? description;
  final String venue;
  final String organizerName;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final String? categoryId;
  final Category? category;
  final String? bannerUrl;
  final String? registrationLink;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Compatibility fields
  final int? maxParticipants;
  final bool isPinned;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.venue,
    required this.organizerName,
    required this.startDatetime,
    required this.endDatetime,
    this.categoryId,
    this.category,
    this.bannerUrl,
    this.registrationLink,
    required this.createdAt,
    required this.updatedAt,
    this.maxParticipants,
    this.isPinned = false,
  });

  /// Backward compatibility
  String get organizer => organizerName;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      venue: json['venue'] ?? '',
      organizerName:
          json['organizer_name'] ?? json['organizer'] ?? '',
      startDatetime: DateTime.parse(json['start_datetime']),
      endDatetime: DateTime.parse(json['end_datetime']),
      categoryId: json['category_id'],
      category: json['categories'] != null
          ? Category.fromJson(json['categories'])
          : null,
      bannerUrl: json['banner_url'],
      registrationLink: json['registration_link'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      maxParticipants: json['max_participants'],
      isPinned: json['is_pinned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty && id != 'temp') 'id': id,
      'title': title,
      'description': description,
      'venue': venue,
      'organizer_name': organizerName,
      'start_datetime': startDatetime.toIso8601String(),
      'end_datetime': endDatetime.toIso8601String(),
      'category_id': categoryId,
      'banner_url': bannerUrl,
      'registration_link': registrationLink,
      // Do NOT send max_participants or is_pinned
      // because your current Supabase table doesn't have them.
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? venue,
    String? organizerName,
    DateTime? startDatetime,
    DateTime? endDatetime,
    String? categoryId,
    Category? category,
    String? bannerUrl,
    String? registrationLink,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? maxParticipants,
    bool? isPinned,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      venue: venue ?? this.venue,
      organizerName: organizerName ?? this.organizerName,
      startDatetime: startDatetime ?? this.startDatetime,
      endDatetime: endDatetime ?? this.endDatetime,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      registrationLink: registrationLink ?? this.registrationLink,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}