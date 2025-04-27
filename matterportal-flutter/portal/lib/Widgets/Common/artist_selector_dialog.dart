import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portal/BLoC/artist_selector_bloc.dart';
import 'package:portal/BLoC/artist_selector_event.dart' as artist_event;
import 'package:portal/BLoC/artist_selector_state.dart' as artist_state;
import 'package:portal/Services/api_service.dart';

class ArtistSelectorDialog extends StatefulWidget {
  final String collection;

  const ArtistSelectorDialog({
    required this.collection,
    super.key,
  });

  @override
  State<ArtistSelectorDialog> createState() => _ArtistSelectorDialogState();
}

class _ArtistSelectorDialogState extends State<ArtistSelectorDialog> {
  late ArtistSelectorBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ArtistSelectorBloc(fetchArtists: (collection) async {
      if (collection == 'songwriters') {
        return await api.fetchAllSongwriters();
      } else {
        return await api.fetchAllArtists();
      }
    });
    _bloc.add(artist_event.LoadArtists(widget.collection));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<ArtistSelectorBloc, artist_state.ArtistSelectorState>(
        builder: (context, state) {
          if (state is artist_state.ArtistSelectorLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is artist_state.ArtistSelectorError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          } else if (state is artist_state.ArtistSelectorLoaded) {
            return Dialog(
              backgroundColor: const Color(0xFF1E1E2D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 800,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search artists...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF151521),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (query) {
                        // Filtering can be handled with a local cubit or state, or extend the bloc if needed
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selected Artists Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selected Artists',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Selected artists list would go here
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Unselected Artists Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Unselected Artists',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 300,
                                child: ListView.builder(
                                  itemCount: state.artists.length,
                                  itemBuilder: (context, index) {
                                    final artist = state.artists[index];
                                    final isSelected = state.selectedArtists.contains(artist);
                                    return ListTile(
                                      leading: FutureBuilder<String?>(
                                        future: api.getArtistProfileImage(artist),
                                        builder: (context, snapshot) {
                                          return CircleAvatar(
                                            radius: 20,
                                            backgroundImage: snapshot.data != null ?
                                              NetworkImage(snapshot.data!) :
                                              const AssetImage('assets/images/placeholder.png') as ImageProvider,
                                          );
                                        },
                                      ),
                                      title: Text(artist, style: const TextStyle(color: Colors.white)),
                                      trailing: isSelected
                                          ? IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                              onPressed: () => _bloc.add(artist_event.RemoveArtist(artist)),
                                            )
                                          : IconButton(
                                              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                              onPressed: () => _bloc.add(artist_event.AddArtist(artist)),
                                            ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
