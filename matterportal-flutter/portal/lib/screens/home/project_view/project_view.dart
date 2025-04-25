import 'package:flutter/material.dart';
import 'package:portal/widgets/project_card/project_card.dart';
import 'package:portal/models/project.dart';

class ProjectView extends StatelessWidget {
  final String projectId;
  final String? productUPC;
  final Project project;
  final bool newProject;
  final String? initialProductId;
  // Add parameters to receive shared controllers
  final TextEditingController projectNameController;
  final TextEditingController uuidNameController;
  final TextEditingController artistNameController;
  final TextEditingController idController;
  final TextEditingController notesController;
  final FocusNode artistFocusNode;

  const ProjectView({
    super.key,
    required this.projectId,
    this.productUPC,
    required this.project,
    this.newProject = false,
    this.initialProductId,
    // Make these required to ensure they're passed
    required this.projectNameController,
    required this.uuidNameController,
    required this.artistNameController,
    required this.idController,
    required this.notesController,
    required this.artistFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        title: Image.asset('assets/images/ico.png'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // TODO: Implement your logout functionality here
            },
          ),
        ],
      ),
      body: ProjectCard(
        projectId: projectId,
        projectNameController: projectNameController,
        uuidNameController: uuidNameController,
        artistNameController: artistNameController,
        idController: idController,
        artistFocusNode: artistFocusNode,
        newProject: newProject,
        notesController: notesController,
        isExistingProject: !newProject,
        initialProductId: initialProductId,
      ),
    );
  }
}
