const List<Map<String, String>> metadataLanguages = [
  {'code': 'en', 'name': 'English'},
  {'code': 'es', 'name': 'Spanish'},
  {'code': 'fr', 'name': 'French'},
  {'code': 'de', 'name': 'German'},
  {'code': 'it', 'name': 'Italian'},
  {'code': 'pt', 'name': 'Portuguese'},
  {'code': 'ja', 'name': 'Japanese'},
  {'code': 'zh', 'name': 'Chinese'},
  {'code': 'ru', 'name': 'Russian'},
  // Add more as needed
];

class MetadataLanguage {
  final String code;
  final String name;
  const MetadataLanguage(this.code, this.name);

  factory MetadataLanguage.fromMap(Map<String, dynamic> map) {
    return MetadataLanguage(
      map['code'] as String,
      map['name'] as String,
    );
  }
}

const List<MetadataLanguage> metadataLanguagesList = [
  MetadataLanguage('en', 'English'),
  MetadataLanguage('es', 'Spanish'),
  MetadataLanguage('fr', 'French'),
  MetadataLanguage('de', 'German'),
  MetadataLanguage('it', 'Italian'),
  MetadataLanguage('pt', 'Portuguese'),
  MetadataLanguage('ja', 'Japanese'),
  MetadataLanguage('zh', 'Chinese'),
  MetadataLanguage('ru', 'Russian'),
];

const List<String> genres = [
  'Pop', 'Rock', 'Hip-Hop', 'Jazz', 'Classical', 'Electronic', 'Country',
  'Reggae', 'Blues', 'Folk', 'Metal', 'Latin', 'R&B', 'Soul', 'Other'
];

const List<String> subgenres = [
  'Synthpop', 'Alternative Rock', 'Trap', 'Smooth Jazz', 'Baroque', 'Techno',
  'Bluegrass', 'Dub', 'Delta Blues', 'Indie Folk', 'Death Metal', 'Salsa',
  'Neo Soul', 'Other'
];

const List<String> productTypes = [
  'Single', 'EP', 'Album', 'Compilation', 'Mixtape', 'Other'
];

const List<String> prices = [
  'Free', '0.99', '1.99', '2.99', '4.99', '9.99'
];
