class AppConstants {
  // App Info
  static const String appName = 'SKS';
  
  // Navigation
  static const String homeRoute = '/';
  static const String learningsRoute = '/learnings';
  static const String gurujiConnectRoute = '/guruji-connect';
  static const String eventsRoute = '/events';
  static const String notificationsRoute = '/notifications';
  
  // Mock Data
  static const String gurujiImageUrl = 'assets/images/Guruji_Meditation.PNG';
  
  static const String aboutGuruji = '''Our revered Guru is an enlightened Sadguru who has dedicated over three decades to the study and practice of Kundalini Sadhana. Having attained the highest states of consciousness, the Guru now shares this divine knowledge to help humanity transcend its limitations and realize its true potential.''';
  
  static const List<String> dailyQuotes = [
    'Meditation is the most natural state of mind.',
    'Meditation is not a necessity, it is an emergency.',
    "I'm not here to prove that I'm God, I'm here to prove that you are God.",
    'There is no difference between Siva and Shakthi; Siva is Shakthi and Shakthi is Siva.',
    'You are already enlightened, just realize it.',
    'Meditation is Medication!',
    'Spirituality is Practicality!'
  ];
  
  static const List<Map<String, String>> meditationMusic = [
    {'title': 'Morning Meditation', 'duration': '15:00', 'url': ''},
    {'title': 'Om Chanting', 'duration': '10:30', 'url': ''},
    {'title': 'Peaceful Sleep', 'duration': '20:00', 'url': ''},
    {'title': 'Chakra Healing', 'duration': '25:00', 'url': ''},
  ];
  
  static const List<Map<String, String>> bhajans = [
    {'title': 'Shanti Mantra', 'artist': 'Divine Voices', 'imageUrl': 'assets/images/Guruji_smile.jpeg'},
    {'title': 'Guru Vandana', 'artist': 'Sacred Sounds', 'imageUrl': 'assets/images/Guruji_Meditation.PNG'},
    {'title': 'Aarti Sangrah', 'artist': 'Temple Bells', 'imageUrl': 'assets/images/Guruji_logo.JPG'},
  ];
  
  static const List<Map<String, String>> experienceVideos = [
    {'title': 'Journey to Inner Peace', 'thumbnail': 'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=600', 'duration': '5:30'},
    {'title': 'Transformation Story', 'thumbnail': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600', 'duration': '8:15'},
    {'title': 'Divine Experiences', 'thumbnail': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600', 'duration': '6:45'},
  ];
  
  static const List<Map<String, dynamic>> upcomingEvents = [
    {
      'title': 'Meditation Retreat',
      'date': '2024-02-15',
      'location': 'Spiritual Center',
      'imageUrl': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=600',
      'description': 'A 3-day immersive meditation retreat',
    },
    {
      'title': 'Satsang Evening',
      'date': '2024-02-20',
      'location': 'Community Hall',
      'imageUrl': 'https://images.unsplash.com/photo-1447452001602-7090c7ab2db3?w=600',
      'description': 'Evening of spiritual discourse and bhajans',
    },
    {
      'title': 'Yoga Workshop',
      'date': '2024-02-25',
      'location': 'Wellness Center',
      'imageUrl': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=600',
      'description': 'Learn ancient yoga practices',
    },
  ];
}
