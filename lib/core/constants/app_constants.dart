class AppConstants {
  // App Info
  static const String appName = 'Siva Kundalini Sadhana';
  static const String appShortName = 'SKS';
  
  // Navigation
  static const String homeRoute = '/';
  static const String learningsRoute = '/learnings';
  static const String gurujiConnectRoute = '/guruji-connect';
  static const String eventsRoute = '/events';
  static const String notificationsRoute = '/notifications';
  
  // Image Assets
  static const String gurujiImageUrl = 'assets/images/Guruji_Meditation.PNG';
  static const String gurujiLogoUrl = 'assets/images/Guruji_logo.JPG';
  static const String gurujiSmileUrl = 'assets/images/Guruji_smile.jpeg';
  static const String kallaBairavaUrl = 'assets/images/kalla_bairava.jpeg';
  static const String gurujiMainUrl = 'assets/images/Guruji.JPG';
  static const String kundaliniImageUrl = 'assets/images/kundalini.jpg';
  static const String meditationImageUrl = 'assets/images/meditation.jpg';
  static const String chakrasGeneralImageUrl = 'assets/images/chakras.jpg';
  
  // Home Page Card Background Images
  static const String guruJourneyImageUrl = 'assets/images/daily_wisdom_images/Guruji_32.jpeg';
  static const String kundaliniScienceImageUrl = 'assets/images/kundalini.jpg';
  static const String benefitsImageUrl = 'assets/images/meditation.jpg';
  static const String chakrasImageUrl = 'assets/images/chakras.jpg';
  
  // Guruji Connect Page Images
  static const String gurujiMeditationHeroImageUrl = 'assets/images/Guruji_Meditation.PNG';
  static const String gurujiTeachingImageUrl = 'assets/images/Guruji_Meditation.PNG';
  
  // Chakra Detail Images
  static const String rootChakraImageUrl = 'assets/images/chakras/Muladhara.png';
  static const String sacralChakraImageUrl = 'assets/images/chakras/Swadhisthana.png';
  static const String solarPlexusChakraImageUrl = 'assets/images/chakras/Manipura.png';
  static const String heartChakraImageUrl = 'assets/images/chakras/Anahatha.png';
  static const String throatChakraImageUrl = 'assets/images/chakras/Vishuddha.png';
  static const String thirdEyeChakraImageUrl = 'assets/images/chakras/Ajna.png';
  static const String crownChakraImageUrl = 'assets/images/chakras/Sahasrara.png';
  
  // Coming Soon Messages
  static const String comingSoonTitle = 'Coming Soon';
  static const String comingSoonMessage = 'This feature is under development.\n\nStay tuned for amazing spiritual content and features that will enhance your spiritual journey!';
  static const String stayTunedMessage = 'We are working hard to bring you the best spiritual experience.';
  
  // About Guruji
  static const String aboutGuruji = '''Our revered Guru is an enlightened Sadguru who has dedicated over three decades to the study and practice of Kundalini Sadhana. Having attained the highest states of consciousness, the Guru now shares this divine knowledge to help humanity transcend its limitations and realize its true potential.

Through deep meditation and spiritual practices, our Guru guides disciples on the path of self-realization, helping them awaken their dormant spiritual energy and achieve lasting peace and bliss.''';
  
  // Daily Wisdom Card Images (one for each quote)
  static const List<String> dailyWisdomImages = [
    'assets/images/daily_wisdom_images/Guruji_25.webp', // Quote 1
    'assets/images/daily_wisdom_images/Guruji_22.webp', // Quote 2
    'assets/images/daily_wisdom_images/Guruji_30.webp', // Quote 3
    'assets/images/daily_wisdom_images/Guruji_24.webp', // Quote 4
    'assets/images/daily_wisdom_images/Guruji_17.webp', // Quote 5
    'assets/images/daily_wisdom_images/Guruji_9.webp', // Quote 6
    'assets/images/daily_wisdom_images/Guruji_4.webp', // Quote 7
    'assets/images/daily_wisdom_images/Guruji_29.webp', // Quote 8
    'assets/images/daily_wisdom_images/Guruji_26.webp', // Quote 9
    'assets/images/daily_wisdom_images/Guruji_5.webp', // Quote 10
  ];
  
  static const List<String> dailyQuotes = [
    'Meditation is the most natural state of mind.',
    'Meditation is not a necessity, it is an emergency.',
    "I'm not here to prove that I'm God, I'm here to prove that you are God.",
    'There is no difference between Siva and Shakthi; Siva is Shakthi and Shakthi is Siva.',
    'You are already enlightened, just realize it.',
    'Meditation is Medication!',
    'Spirituality is Practicality!',
    'The divine light within you is waiting to be awakened.',
    'In silence, you will find your true self.',
    'Kundalini is the key to unlock your infinite potential.'
  ];
  
  static const List<Map<String, String>> meditationMusic = [
    {'title': 'Daily Meditation (15 min)', 'duration': '15:00', 'url': 'assets/audio/Sivoham_Mantra_15min_guided_Meditation.mp3', 'description': 'Guided meditation with Sivoham mantra'},
    {'title': 'Daily Meditation (10 min)', 'duration': '10:00', 'url': 'assets/audio/Sivoham_Mantra_10min_guided_Meditation.mp3', 'description': 'Short guided meditation session'},
  ];
  
  static const List<Map<String, String>> bhajans = [
    {'title': 'Sri Jeeveswarastakam', 'artist': 'Sai Vijay', 'duration': '5:09', 'imageUrl': 'assets/images/daily_wisdom_images/Guruji_30.webp', 'url': 'assets/audio/Sri_Jeeveswarastakam_song.mp3', 'description': 'Sacred eight-verse hymn glorifying the divine qualities and spiritual teachings of Parama Pujya Sri Jeeveswara Yogi Gurudev'},
    {'title': 'Gundello Gudi', 'artist': 'Divine Voices', 'duration': '4:23', 'imageUrl': 'assets/images/Guruji_smile.jpeg', 'url': 'assets/audio/Gundello_gudi_song.mp3', 'description': 'Soulful Telugu devotional song celebrating the divine temple within the heart, awakening inner consciousness'},
    {'title': 'Nirvana Shatkam', 'artist': 'Sacred Sounds', 'duration': '5:47', 'imageUrl': 'assets/images/Guruji_Meditation.PNG', 'url': 'assets/audio/Nirvana_Shatkam_song.mp3', 'description': 'Timeless Advaita composition by Adi Shankaracharya declaring the pure consciousness beyond all dualities'},
    {'title': 'Jeeveswara Yogi Taluva', 'artist': 'Temple Bells', 'duration': '6:12', 'imageUrl': 'assets/images/Guruji_logo.JPG', 'url': 'assets/audio/Jeeveswara_yogi_taluva_song.mp3', 'description': 'Melodious devotional tribute expressing deep reverence and gratitude to the enlightened master Sri Jeeveswara Yogi'},
    {'title': 'Pralaya Kala Beekara', 'lyrics' : 'Chitran', 'artist': 'Aravvind Raama', 'duration': '3:58', 'imageUrl': 'assets/images/kalla_bairava.jpeg', 'url': 'assets/audio/Pralaya_kala_beekara_song.mp3', 'description': 'Powerful invocation to Lord Kala Bhairava, the fierce guardian deity who destroys negativity and grants spiritual liberation'},
    {'title': 'Ni Namamalo Undhi Moksha Dwaram', 'artist': 'Sacred Chants', 'duration': '3:58', 'imageUrl': 'assets/images/daily_wisdom_images/Guruji_26.webp', 'url': 'assets/audio/Ni_Namamalo_Undhi_Moksha_Dwaram_song.mp3', 'description': 'Inspirational Telugu bhajan proclaiming that the gateway to liberation lies within the sacred name of the divine Guru'}
  ];
  
  static const List<Map<String, String>> experienceVideos = [
    {'title': 'Journey to Inner Peace', 'thumbnail': 'https://img.youtube.com/vi/58X02gfQVFc/maxresdefault.jpg', 'duration': '5:30', 'youtubeId': '58X02gfQVFc'},
    {'title': 'Transformation Story', 'thumbnail': 'https://img.youtube.com/vi/IyH-7BgEy00/maxresdefault.jpg', 'duration': '10:31', 'youtubeId': 'IyH-7BgEy00'},
    {'title': 'Divine Experiences', 'thumbnail': 'https://img.youtube.com/vi/R2goDa9crdM/maxresdefault.jpg', 'duration': '11:07', 'youtubeId': 'R2goDa9crdM'},
    {'title': 'Spiritual Awakening', 'thumbnail': 'https://img.youtube.com/vi/Yp-BPYOGwrE/maxresdefault.jpg', 'duration': '8:45', 'youtubeId': 'Yp-BPYOGwrE'},
    {'title': 'Kundalini Meditation', 'thumbnail': 'https://img.youtube.com/vi/wkjk-8MkKjE/maxresdefault.jpg', 'duration': '12:20', 'youtubeId': 'wkjk-8MkKjE'},
  ];
  
  // YouTube Channel
  static const String youtubeChannelUrl = 'https://www.youtube.com/@SivaKundaliniSadhanaChannel';
  
  // Vision & Mission
  static const String vision = '''To create a world where every human being is given the opportunity to realize their highest potential and transform into a divine being — living with wisdom, compassion, and unity with universal consciousness. We aspire to build an environment that nurtures inner growth, uplifts humanity, and fosters harmony across the planet.''';
  
  static const String mission = '''To guide the transformation of human consciousness (Jeeva) into divine consciousness (Shiva) — helping individuals move beyond limitations of the ego and awaken to higher awareness, inner peace, and oneness with the universal Self.''';
  
  // Contact Information
  static const String organizationName = 'Siva Kundalini Sadhana';
  static const String organizationDescription = '''Siva Kundalini Sadhana (SKS) is a non-profit organization founded by Parama Pujya Sri Jeeveswara Yogi, with a divine purpose of transforming every human life into a healthy and blissful journey towards self-realisation, through simple, safe and powerful Siva Kundalini Sadhana.''';
  
  static const String contactEmail = 'sivakundalini@gmail.com';
  static const String contactPhone = '+91 78010 46111';
  static const String whatsappNumber = '+91 6304429254';
  static const String contactAddress = 'Nayal, Dunagiri, Himalayas\nUttarakhand, India';
  
  static const String facebookUrl = 'https://www.facebook.com/SivaKundaliniSadhana';
  static const String instagramUrl = 'https://www.instagram.com/sivakundalinisadhana';
  static const String whatsappUrl = 'https://wa.me/916304429254';
  // YouTube URL already defined above as youtubeChannelUrl
  
  // Recent Gatherings
  static const List<Map<String, dynamic>> recentGatherings = [
    {
      'title': 'Grand celebrations of SKS 8th Anniversary',
      'date': 'December 2025',
      'description': 'A magnificent celebration marking 8 years of spiritual transformation and divine guidance under Pujya Gurudev\'s blessed presence',
      'image': 'assets/images/recentGatherings/SKS_8th_anniversary.jpg',
      'videoUrl': 'https://www.youtube.com/watch?v=XbOO1XNkkMM'
    },
    {
      'title': 'Vastra Daanam',
      'date': 'September 2025',
      'description': 'Pujya Gurudev graciously donated sarees to the women of Karwan as part of the Navratri–Sivaratri Deeksha Sep 2025',
      'image': 'assets/images/recentGatherings/Vastra_Daanam.jpeg',
      'videoUrl': 'https://youtu.be/mIranj1ZYu8'
    },
    {
      'title': 'Meditation in SKS Bliss Center',
      'date': 'September 2025',
      'description': 'Awaken your consciousness and embrace stillness with meditation at SKS Bliss Center.',
      'image': 'assets/images/recentGatherings/Bliss_Center.jpeg',
      'videoUrl': 'https://youtube.com/shorts/Rxctghk1WSA'
    },
    {
      'title': 'Guru Poornima & Gurudev Janmadinam',
      'date': 'July 2025',
      'description': 'A day of gratitude and reverence—honoring Gurudev on Guru Poornima and his Janmadinam.',
      'image': 'assets/images/recentGatherings/GuruPoornima_2025.jpg',
      'videoUrl': 'https://youtu.be/PUygC2i_QDs'
    },
    {
      'title': 'MahaSivaratri 2025',
      'date': 'February 2025',
      'participants': '5000+ global attendees',
      'description': 'A Night of Spiritual Awakening, devotion, and union with the Divine.',
      'image': 'assets/images/recentGatherings/MahaSivaratri_2025.jpg',
      'videoUrl': 'https://youtu.be/xHoLBEr9FgM'
    }
  ];
  
  static const List<Map<String, dynamic>> upcomingEvents = [
    {
      'title': 'Maha Shivaratri Celebration',
      'date': '15-02-2026',
      'location': 'SKS Ashram',
      'imageUrl': 'assets/images/Shivaratri.png',
      'description': 'Night of divine worship and meditation',
    },
    // {
    //   'title': 'Satsang Evening',
    //   'date': '2024-02-20',
    //   'location': 'Community Hall',
    //   'imageUrl': 'https://images.unsplash.com/photo-1447452001602-7090c7ab2db3?w=600',
    //   'description': 'Evening of spiritual discourse and bhajans',
    // },
    // {
    //   'title': 'Yoga Workshop',
    //   'date': '2024-02-25',
    //   'location': 'Wellness Center',
    //   'imageUrl': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=600',
    //   'description': 'Learn ancient yoga practices',
    // },
  ];
}
