import 'package:flutter/material.dart';
import 'package:portal/Models/songwriter.dart';
import 'package:portal/Screens/Home/Forms/edit_songwriter_form.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Widgets/Common/loading_indicator.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SongwritersTab extends StatefulWidget {
  const SongwritersTab({super.key});

  @override
  State<SongwritersTab> createState() => _SongwritersTabState();
}

class _SongwritersTabState extends State<SongwritersTab> {
  // Future<QuerySnapshot<Map<String, dynamic>>>? _songwritersFuture;

  // @override
  // void initState() {
  //   super.initState();
  //   _loadSongwriters();
  // }

  // void _loadSongwriters() {
  //   setState(() {
  //     _songwritersFuture = api.getSongwriters();
  //   });
  // }

  Future<void> _showEditDialog(Map<String, dynamic> songwriter) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EditSongwriterForm(songwriter: Songwriter.fromMap(songwriter)),
    );
    if (result == true) {
      // _loadSongwriters();
    }
  }

  @override
  Widget build(BuildContext context) {
    // DEPRECATED: Future-based songwriter loading. Use stream-based below.
    // return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
    //   future: _songwritersFuture,
    //   builder: ...
    // );
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: api.getSongwritersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: LoadingIndicator(
              size: 50,
              color: Colors.white,
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.edit_note,
                  color: Colors.white,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'No songwriters found',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Create a new songwriter to get started',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final songwriters = snapshot.data!;
        return ListView.builder(
          itemCount: songwriters.length,
          itemBuilder: (context, index) {
            final songwriter = songwriters[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: Colors.grey[850],
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[800],
                    child: const Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  title: Text(
                    songwriter['name'] ?? '',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: songwriter['email'] != null && songwriter['email'].isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            songwriter['email'],
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (songwriter['email'] != null && songwriter['email'].isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.email, color: Colors.white),
                          tooltip: 'Send email',
                          onPressed: () async {
                            final emailUrl = 'mailto:${songwriter['email']}';
                            if (await canLaunchUrlString(emailUrl)) {
                              await launchUrlString(emailUrl);
                            }
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        tooltip: 'Edit songwriter',
                        onPressed: () => _showEditDialog(songwriter),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}