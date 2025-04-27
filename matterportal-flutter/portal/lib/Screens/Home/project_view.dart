import 'package:flutter/material.dart';
import 'package:portal/Widgets/ProjectCard/project_card.dart';

class ProjectView extends StatelessWidget {
  final String projectId;
  final String? productUPC;
  final bool newProject;
  final String? initialProductId;

  const ProjectView({
    super.key,
    required this.projectId,
    this.productUPC,
    this.newProject = false,
    this.initialProductId,
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
          newProject: newProject,
          initialProductId: initialProductId,
        ));
  }
}
