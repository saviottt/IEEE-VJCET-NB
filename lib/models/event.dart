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
  final Category? category; // Joined from Categories
  final String? bannerUrl;
  final String? registrationLink;
  final DateTime createdAt;
  final DateTime updatedAt;
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

  // Getter for backward compatibility and database schema mapping
  String get organizer => organizerName;

  factory Event.fromJson(Map<String, dynamic> json) {
    Category? cat;
    if (json['categories'] != null) {
      cat = Category.fromJson(json['categories'] as Map<String, dynamic>);
    }

    return Event(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      venue: json['venue'] as String? ?? '',
      organizerName: json['organizer_name'] as String? ?? json['organizer'] as String? ?? '',
      startDatetime: DateTime.parse(json['start_datetime'] as String),
      endDatetime: DateTime.parse(json['end_datetime'] as String),
      categoryId: json['category_id'] as String?,
      category: cat,
      bannerUrl: json['banner_url'] as String?,
      registrationLink: json['registration_link'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : DateTime.now(),
      maxParticipants: json['max_participants'] as int?,
      isPinned: json['is_pinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty && id != 'temp') 'id': id,
      'title': title,
      'description': description,
      'venue': venue,
      'organizer_name': organizerName,
      'organizer': organizerName, // Include both for database compatibility
      'start_datetime': startDatetime.toIso8601String(),
      'end_datetime': endDatetime.toIso8601String(),
      'category_id': categoryId,
      'banner_url': bannerUrl,
      'registration_link': registrationLink,
      'max_participants': maxParticipants,
      'is_pinned': isPinned,
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
