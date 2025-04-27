class ProductData {
  final String id;
  final String releaseTitle;
  final String releaseVersion;
  final List<String> primaryArtists;
  final List<String>? primaryArtistIds; // Add support for artist IDs
  final String? metadataLanguage;
  final String? genre;
  final String? subgenre;
  final String? type;
  final String? price;
  final String upc;
  final String uid;
  final String label;
  final String cLine;
  final String pLine;
  final String cLineYear;
  final String pLineYear;
  final String coverImage;
  final String previewArtUrl; // New field for 300x300 preview image
  final String state;
  final bool autoGenerateUPC;
  ProductData({
    required this.id,
    required this.releaseTitle,
    required this.releaseVersion,
    required this.primaryArtists,
    this.primaryArtistIds, // Add to constructor
    this.metadataLanguage,
    this.genre,
    this.subgenre,
    this.type,
    this.price,
    required this.upc,
    required this.uid,
    required this.label,
    required this.cLine,
    required this.pLine,
    required this.cLineYear,
    required this.pLineYear,
    required this.coverImage,
    this.previewArtUrl = '', // Default empty string if not provided
    required this.state,
    required this.autoGenerateUPC,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'releaseTitle': releaseTitle,
      'releaseVersion': releaseVersion,
      'primaryArtists': primaryArtists,
      'primaryArtistIds': primaryArtistIds, // Include in map
      'metadataLanguage': metadataLanguage,
      'genre': genre,
      'subgenre': subgenre,
      'type': type,
      'price': price,
      'upc': upc,
      'uid': uid,
      'label': label,
      'cLine': cLine,
      'pLine': pLine,
      'cLineYear': cLineYear,
      'pLineYear': pLineYear,
      'coverImage': coverImage,
      'previewArtUrl': previewArtUrl,
      'state': state,
      'autoGenerateUPC': autoGenerateUPC,
    }..removeWhere((key, value) => value == null);
  }
  factory ProductData.fromMap(Map<String, dynamic> map) {
    return ProductData(
      id: map['id'],
      releaseTitle: map['releaseTitle'],
      releaseVersion: map['releaseVersion'],
      primaryArtists: List<String>.from(map['primaryArtists']),
      primaryArtistIds: map['primaryArtistIds'] != null
          ? List<String>.from(map['primaryArtistIds'])
          : null, // Extract from map
      metadataLanguage: map['metadataLanguage'],
      genre: map['genre'],
      subgenre: map['subgenre'],
      type: map['type'],
      price: map['price'],
      upc: map['upc'],
      uid: map['uid'],
      label: map['label'],
      cLine: map['cLine'],
      pLine: map['pLine'],
      cLineYear: map['cLineYear'],
      pLineYear: map['pLineYear'],
      coverImage: map['coverImage'],
      previewArtUrl: map['previewArtUrl'] ?? '',
      state: map['state'],
      autoGenerateUPC: map['autoGenerateUPC'] ?? false,
    );
  }
}
