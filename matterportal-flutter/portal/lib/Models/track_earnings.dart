class TrackEarnings {
  final String trackId;
  final String title;
  final String artist;
  final double totalEarnings;
  final Map<String, double> platformEarnings;
  final Map<String, double> royaltySplits;
  final DateTime lastUpdated;

  TrackEarnings({
    required this.trackId,
    required this.title,
    required this.artist,
    required this.totalEarnings,
    required this.platformEarnings,
    required this.royaltySplits,
    required this.lastUpdated,
  });

  // Factory constructor to create a TrackEarnings object from JSON
  factory TrackEarnings.fromJson(Map<String, dynamic> json) {
    return TrackEarnings(
      trackId: json['trackId'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      totalEarnings: json['totalEarnings'] as double,
      platformEarnings: Map<String, double>.from(json['platformEarnings']),
      royaltySplits: Map<String, double>.from(json['royaltySplits']),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  // Convert TrackEarnings object to JSON
  Map<String, dynamic> toJson() {
    return {
      'trackId': trackId,
      'title': title,
      'artist': artist,
      'totalEarnings': totalEarnings,
      'platformEarnings': platformEarnings,
      'royaltySplits': royaltySplits,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
} 