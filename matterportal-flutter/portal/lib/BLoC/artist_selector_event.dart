import 'package:equatable/equatable.dart';

abstract class ArtistSelectorEvent extends Equatable {
  const ArtistSelectorEvent();
  @override
  List<Object?> get props => [];
}

class LoadArtists extends ArtistSelectorEvent {
  final String collection;
  const LoadArtists(this.collection);
  @override
  List<Object?> get props => [collection];
}

class AddArtist extends ArtistSelectorEvent {
  final String artist;
  const AddArtist(this.artist);
  @override
  List<Object?> get props => [artist];
}

class RemoveArtist extends ArtistSelectorEvent {
  final String artist;
  const RemoveArtist(this.artist);
  @override
  List<Object?> get props => [artist];
}

class ReorderArtists extends ArtistSelectorEvent {
  final List<String> artists;
  const ReorderArtists(this.artists);
  @override
  List<Object?> get props => [artists];
}
