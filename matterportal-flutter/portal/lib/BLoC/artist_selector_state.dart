import 'package:equatable/equatable.dart';

abstract class ArtistSelectorState extends Equatable {
  const ArtistSelectorState();
  @override
  List<Object?> get props => [];
}

class ArtistSelectorInitial extends ArtistSelectorState {}

class ArtistSelectorLoading extends ArtistSelectorState {}

class ArtistSelectorLoaded extends ArtistSelectorState {
  final List<String> artists;
  final List<String> selectedArtists;
  const ArtistSelectorLoaded({required this.artists, required this.selectedArtists});
  @override
  List<Object?> get props => [artists, selectedArtists];
}

class ArtistSelectorError extends ArtistSelectorState {
  final String message;
  const ArtistSelectorError(this.message);
  @override
  List<Object?> get props => [message];
}
