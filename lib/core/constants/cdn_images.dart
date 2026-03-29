/// CDN Image URLs Mapping
/// All images are hosted on Cloudflare CDN for optimal performance
class CdnImages {
  static const String _baseUrl = 'https://imagedelivery.net/JNNt29TDY0xWT64sZ4K8wQ';
  
  // Core App Images (Keep as assets - critical for app launch)
  static const String logoAsset = 'assets/images/SKS_Logo.png';
  
  // Main Images - CDN URLs
  static const String guruji = '$_baseUrl/f30a1be3-73ca-4e16-c569-7dbcdab40200/public';
  static const String gurujiLogo = '$_baseUrl/e0220a2b-4a2f-4f47-3d7f-1b738c940300/public';
  static const String gurujiMeditation = '$_baseUrl/7aa53ff0-74aa-4899-f302-f266de90a400/public';
  static const String gurujiSmile = '$_baseUrl/0e3f2822-9484-4459-4d13-614155030500/public';
  static const String kallaBairava = '$_baseUrl/a1f20499-9b0c-42ac-260f-1e026b9a5000/public';
  static const String kundalini = '$_baseUrl/d217ca22-e83e-4fd3-194e-8624734dd700/public';
  static const String meditation = '$_baseUrl/0fe562b7-d18d-4ff7-c2ab-6515b93c9300/public';
  static const String chakras = '$_baseUrl/4f1ddd25-dddf-4b46-44da-1e5890ce8e00/public';
  static const String shivaratri = '$_baseUrl/662a34c7-d32b-4fe2-c1de-a4a8b5591900/public';
  
  // Chakra Images - CDN URLs
  static const String muladhara = '$_baseUrl/be9479ca-8737-4634-fc9b-551ff265b700/public';
  static const String swadhisthana = '$_baseUrl/9a4e2191-cf76-4db5-284f-166e91393600/public';
  static const String manipura = '$_baseUrl/21e14fad-a781-400f-62f5-05f4e660a800/public';
  static const String anahatha = '$_baseUrl/163faac1-565f-4ce9-e404-5847d8c4d900/public';
  static const String vishuddha = '$_baseUrl/5638f518-cf4e-4907-4ea8-1461c97e9800/public';
  static const String ajna = '$_baseUrl/cbda3722-bf20-497e-4336-4fe7cd0d6c00/public';
  static const String sahasrara = '$_baseUrl/9eb84fdc-17e5-46da-dc7a-d38d26014700/public';
  
  // Daily Wisdom Images - CDN URLs
  static const String guruji25 = '$_baseUrl/d0da59a6-1a48-4f0c-9628-36d013e6b400/public';
  static const String guruji26 = '$_baseUrl/f18ff032-4ab6-47a0-c40b-01de26fc2200/public';
  static const String guruji30 = '$_baseUrl/d82f348e-6b86-4be8-31c9-565ef2112300/public';
  static const String guruji32 = '$_baseUrl/238879d8-5b8d-473d-5061-cb28c7e2b700/public';
  
  // Recent Gatherings Images - CDN URLs (to be added)
  static const String blissCenter = 'https://imagedelivery.net/JNNt29TDY0xWT64sZ4K8wQ/bliss-center-id/public'; // TODO: Add actual ID
  static const String guruPoornima2025 = 'https://imagedelivery.net/JNNt29TDY0xWT64sZ4K8wQ/guru-poornima-id/public'; // TODO: Add actual ID
  static const String mahaSivaratri2025 = 'https://imagedelivery.net/JNNt29TDY0xWT64sZ4K8wQ/maha-sivaratri-id/public'; // TODO: Add actual ID
  static const String sks8thAnniversary = 'https://imagedelivery.net/JNNt29TDY0xWT64sZ4K8wQ/sks-8th-id/public'; // TODO: Add actual ID
  static const String vastraDaanam = 'https://imagedelivery.net/JNNt29TDY0xWT64sZ4K8wQ/vastra-daanam-id/public'; // TODO: Add actual ID
  
  // Image mapping for easy reference
  static const Map<String, String> imageMap = {
    // Main images
    'Guruji.JPG': guruji,
    'Guruji_logo.JPG': gurujiLogo,
    'Guruji_Meditation.PNG': gurujiMeditation,
    'Guruji_smile.jpeg': gurujiSmile,
    'kalla_bairava.jpeg': kallaBairava,
    'kundalini.jpg': kundalini,
    'meditation.jpg': meditation,
    'chakras.jpg': chakras,
    'Shivaratri.png': shivaratri,
    
    // Chakras
    'Muladhara.png': muladhara,
    'Swadhisthana.png': swadhisthana,
    'Manipura.png': manipura,
    'Anahatha.png': anahatha,
    'Vishuddha.png': vishuddha,
    'Ajna.png': ajna,
    'Sahasrara.png': sahasrara,
    
    // Daily wisdom
    'Guruji_25.webp': guruji25,
    'Guruji_26.webp': guruji26,
    'Guruji_30.webp': guruji30,
    'Guruji_32.jpeg': guruji32,
  };
  
  /// Get CDN URL for an image by filename
  static String? getUrl(String filename) {
    return imageMap[filename];
  }
  
  /// Check if an image should be loaded from CDN
  static bool isCdnImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }
}
