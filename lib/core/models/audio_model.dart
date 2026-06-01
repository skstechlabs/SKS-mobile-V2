class AudioModel {
  final int id;
  final String title;
  final String? artist;
  final String? description;
  final String audioUrl; // Cloudflare R2 URL
  final String? thumbnailUrl;
  final int durationSeconds;
  final String category; // 'meditation', 'bhajan', 'chant', etc.
  final String? lyrics;
  final String language; // 'telugu', 'english', 'sanskrit', etc.
  final int orderIndex; // For sorting
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AudioModel({
    required this.id,
    required this.title,
    this.artist,
    this.description,
    required this.audioUrl,
    this.thumbnailUrl,
    required this.durationSeconds,
    required this.category,
    this.lyrics,
    required this.language,
    required this.orderIndex,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert from JSON
  factory AudioModel.fromJson(Map<String, dynamic> json) {
    return AudioModel(
      id: json['id'] as int,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      description: json['description'] as String?,
      audioUrl: json['audio_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationSeconds: json['duration_seconds'] as int,
      category: json['category'] as String,
      lyrics: json['lyrics'] as String?,
      language: json['language'] as String,
      orderIndex: json['order_index'] as int,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'description': description,
      'audio_url': audioUrl,
      'thumbnail_url': thumbnailUrl,
      'duration_seconds': durationSeconds,
      'category': category,
      'lyrics': lyrics,
      'language': language,
      'order_index': orderIndex,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Convert to Map for audio player
  Map<String, String> toPlayerMap() {
    return {
      'id': id.toString(),
      'title': title,
      'artist': artist ?? description ?? '',
      'url': audioUrl,
      'imageUrl': thumbnailUrl ?? '',
      'description': description ?? '',
      'duration': formatDuration(durationSeconds),
    };
  }

  // Format duration as MM:SS
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Copy with method
  AudioModel copyWith({
    int? id,
    String? title,
    String? artist,
    String? description,
    String? audioUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    String? category,
    String? lyrics,
    String? language,
    int? orderIndex,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AudioModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      category: category ?? this.category,
      lyrics: lyrics ?? this.lyrics,
      language: language ?? this.language,
      orderIndex: orderIndex ?? this.orderIndex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
