import 'package:flutter_bloc/flutter_bloc.dart';
import 'artist_selector_event.dart';
import 'artist_selector_state.dart';

// Bloc
class ArtistSelectorBloc extends Bloc<ArtistSelectorEvent, ArtistSelectorState> {
  final Future<List<String>> Function(String collection) fetchArtists;

  ArtistSelectorBloc({required this.fetchArtists}) : super(ArtistSelectorInitial()) {
    on<LoadArtists>((event, emit) async {
      emit(ArtistSelectorLoading());
      try {
        final artists = await fetchArtists(event.collection);
        emit(ArtistSelectorLoaded(artists: artists, selectedArtists: []));
      } catch (e) {
        emit(ArtistSelectorError(e.toString()));
      }
    });
    on<AddArtist>((event, emit) {
      if (state is ArtistSelectorLoaded) {
        final loaded = state as ArtistSelectorLoaded;
        if (!loaded.selectedArtists.contains(event.artist)) {
          emit(ArtistSelectorLoaded(
            artists: loaded.artists,
            selectedArtists: List.from(loaded.selectedArtists)..add(event.artist),
          ));
        }
      }
    });
    on<RemoveArtist>((event, emit) {
      if (state is ArtistSelectorLoaded) {
        final loaded = state as ArtistSelectorLoaded;
        emit(ArtistSelectorLoaded(
          artists: loaded.artists,
          selectedArtists: List.from(loaded.selectedArtists)..remove(event.artist),
        ));
      }
    });
    on<ReorderArtists>((event, emit) {
      if (state is ArtistSelectorLoaded) {
        final loaded = state as ArtistSelectorLoaded;
        emit(ArtistSelectorLoaded(
          artists: loaded.artists,
          selectedArtists: event.artists,
        ));
      }
    });
  }
}
