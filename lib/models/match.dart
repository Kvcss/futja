import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id;
  final String title;
  final String city;
  final String locationName;
  final String? imageUrl;
  final String? imageBase64;
  final DateTime dateTime;
  final String level;
  final int maxPlayers;
  final String organizerId;
  final String? organizerName;
  final List<String> participants;
  final bool cancelled;

  Match({
    required this.id,
    required this.title,
    required this.city,
    required this.locationName,
    required this.dateTime,
    required this.level,
    required this.maxPlayers,
    required this.organizerId,
    this.organizerName,
    this.imageUrl,
    this.imageBase64,
    required this.participants,
    this.cancelled = false,
  });

  int get spotsLeft => maxPlayers - participants.length;

  bool get isFull => spotsLeft <= 0;

  bool get isPast => dateTime.isBefore(DateTime.now());

  factory Match.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Match(
      id: doc.id,
      title: data['title'] as String? ?? 'Partida',
      city: data['city'] as String? ?? '',
      locationName: data['locationName'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      imageBase64: data['imageBase64'] as String?,
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      level: data['level'] as String? ?? 'intermediário',
      maxPlayers: (data['maxPlayers'] as num?)?.toInt() ?? 10,
      organizerId: data['organizerId'] as String? ?? '',
      organizerName: data['organizerName'] as String?,
      participants: (data['participants'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      cancelled: data['cancelled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'city': city,
      'locationName': locationName,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
      'dateTime': Timestamp.fromDate(dateTime),
      'level': level,
      'maxPlayers': maxPlayers,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'participants': participants,
      'cancelled': cancelled,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}