import 'package:flutter/material.dart';
import 'package:portal/Models/project.dart';
import 'package:portal/Screens/Home/project_view.dart';
import 'package:portal/Screens/Home/Mobile/mobile_project_view.dart'; // Import mobile view
import 'package:portal/Screens/Home/responsive_project_view.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Widgets/Common/loading_indicator.dart';

class ProjectListView extends StatefulWidget {
  const ProjectListView({super.key});

  @override
  ProjectListViewState createState() => ProjectListViewState();
}

class ProjectListViewState extends State<ProjectListView> {
  void _navigateToProject(Project project) async {
    // Prevent navigation if project ID is empty
    if (project.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid project: missing ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    try {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => ResponsiveProjectView(
                  projectId: project.id,
                  newProject: false,
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening project: $e')));
      }
    }
  }

  Color _avatarColor(String input) {
    // Generate a color from the project name for avatar background
    final hash = input.codeUnits.fold(0, (prev, elem) => prev + elem);
    final colors = [
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.cyan,
    ];
    return colors[hash % colors.length].withOpacity(0.85);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Project>>(
      stream: api.getProjectsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: LoadingIndicator(size: 50, color: Colors.white),
          );
        }
        final projects = snapshot.data ?? [];
        if (projects.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_music_outlined,
                  color: Colors.white,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'No projects found',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Create a new project to get started',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          itemCount: projects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final project = projects[index];
            final isInvalid = project.id.isEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              child: Material(
                color: Colors.transparent,
                elevation: 2,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: isInvalid ? null : () => _navigateToProject(project),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isInvalid
                              ? Colors.red.withOpacity(0.15)
                              : Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: _avatarColor(project.name),
                        radius: 24,
                        child: Text(
                          project.name.isNotEmpty
                              ? project.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      title: Text(
                        project.name,
                        style: TextStyle(
                          color: isInvalid ? Colors.red : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        project.artist,
                        style: TextStyle(
                          color: isInvalid ? Colors.redAccent : Colors.white70,
                          fontWeight: FontWeight.w400,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: isInvalid ? Colors.red : Colors.white,
                        ),
                        tooltip: isInvalid ? 'Invalid project' : 'Edit project',
                        onPressed:
                            isInvalid
                                ? null
                                : () => _navigateToProject(project),
                      ),
                    ),
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
