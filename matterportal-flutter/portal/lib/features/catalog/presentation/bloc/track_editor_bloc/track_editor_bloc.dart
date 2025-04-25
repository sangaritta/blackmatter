// Removed unused import: 'package:bloc/bloc.dart';
import 'package:portal/models/track.dart';

enum TrackEditorStatus { initial, loading, saving, success, failure }

class TrackEditorState {
  final Track? trackData;
  final TrackEditorStatus status;
  final bool hasUnsavedChanges;
  final Map<String, String> validationErrors;
  final bool isTrackValid;
  final String? errorMessage;

  TrackEditorState({
    this.trackData,
    this.status = TrackEditorStatus.initial,
    this.hasUnsavedChanges = false,
    this.validationErrors = const {},
    this.isTrackValid = false,
    this.errorMessage,
  });

  TrackEditorState copyWith({
    Track? trackData,
    TrackEditorStatus? status,
    bool? hasUnsavedChanges,
    Map<String, String>? validationErrors,
    bool? isTrackValid,
    String? errorMessage,
  }) {
    return TrackEditorState(
      trackData: trackData ?? this.trackData,
      status: status ?? this.status,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      validationErrors: validationErrors ?? this.validationErrors,
      isTrackValid: isTrackValid ?? this.isTrackValid,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

abstract class TrackEditorEvent {}

class InitializeRequested extends TrackEditorEvent {
  final String projectId;
  final String productId;
  final String trackId;
  final Track initialTrackData;
  InitializeRequested({
    required this.projectId,
    required this.productId,
    required this.trackId,
    required this.initialTrackData,
  });
}

class TrackTitleChanged extends TrackEditorEvent {
  final String title;
  TrackTitleChanged(this.title);
}

class TrackArtistsChanged extends TrackEditorEvent {
  final List<String> artists;
  TrackArtistsChanged(this.artists);
}

class TrackVersionChanged extends TrackEditorEvent {
  final String? version;
  TrackVersionChanged(this.version);
}

class TrackExplicitChanged extends TrackEditorEvent {
  final bool isExplicit;
  TrackExplicitChanged(this.isExplicit);
}

class TrackOwnershipChanged extends TrackEditorEvent {
  final String? ownership;
  TrackOwnershipChanged(this.ownership);
}

class TrackISRCChanged extends TrackEditorEvent {
  final String? isrc;
  TrackISRCChanged(this.isrc);
}

class TrackCountryChanged extends TrackEditorEvent {
  final String? country;
  TrackCountryChanged(this.country);
}

class TrackNationalityChanged extends TrackEditorEvent {
  final String? nationality;
  TrackNationalityChanged(this.nationality);
}

class TrackFileNameChanged extends TrackEditorEvent {
  final String? fileName;
  TrackFileNameChanged(this.fileName);
}

class TrackDownloadUrlChanged extends TrackEditorEvent {
  final String? downloadUrl;
  TrackDownloadUrlChanged(this.downloadUrl);
}

class TrackStoragePathChanged extends TrackEditorEvent {
  final String? storagePath;
  TrackStoragePathChanged(this.storagePath);
}

class TrackArtworkUrlChanged extends TrackEditorEvent {
  final String? artworkUrl;
  TrackArtworkUrlChanged(this.artworkUrl);
}

class TrackLyricsChanged extends TrackEditorEvent {
  final String? lyrics;
  TrackLyricsChanged(this.lyrics);
}

class TrackPerformersChanged extends TrackEditorEvent {
  final List<Map<String, dynamic>>? performers;
  TrackPerformersChanged(this.performers);
}

class TrackSongwritersChanged extends TrackEditorEvent {
  final List<Map<String, dynamic>>? songwriters;
  TrackSongwritersChanged(this.songwriters);
}

class TrackProductionChanged extends TrackEditorEvent {
  final List<Map<String, dynamic>>? production;
  TrackProductionChanged(this.production);
}

class SaveTrackRequested extends TrackEditorEvent {}

class TrackValidationRequested extends TrackEditorEvent {}
