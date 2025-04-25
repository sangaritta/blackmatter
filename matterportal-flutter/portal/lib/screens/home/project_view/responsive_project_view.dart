import 'package:flutter/material.dart';
import 'package:portal/models/project.dart';
import 'package:portal/screens/home/project_view/mobile_project_view.dart';
import 'package:portal/screens/home/project_view/project_view.dart';

class ResponsiveProjectView extends StatefulWidget {
  final String projectId;
  final Project project;
  final bool newProject;
  final String? productUPC;
  final String? initialProductId;
  final bool? useDesktopUI; // Optional flag to explicitly use desktop UI

  const ResponsiveProjectView({
    super.key,
    required this.projectId,
    required this.project,
    required this.newProject,
    this.productUPC,
    this.initialProductId,
    this.useDesktopUI, // Add this parameter
  });

  @override
  State<ResponsiveProjectView> createState() => _ResponsiveProjectViewState();
}

class _ResponsiveProjectViewState extends State<ResponsiveProjectView> {
  // Shared controllers between mobile and desktop views
  late TextEditingController projectNameController;
  late TextEditingController artistNameController;
  late TextEditingController notesController;
  late TextEditingController idController;
  late TextEditingController uuidNameController;
  late FocusNode artistFocusNode;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with project data
    projectNameController = TextEditingController(text: widget.project.name);
    artistNameController = TextEditingController(
      text: widget.project.projectArtist,
    );
    notesController = TextEditingController(text: widget.project.notes);
    idController = TextEditingController(text: widget.project.id);
    uuidNameController = TextEditingController(text: widget.project.id);
    artistFocusNode = FocusNode();
  }

  @override
  void dispose() {
    // Clean up controllers when the widget is disposed
    projectNameController.dispose();
    artistNameController.dispose();
    notesController.dispose();
    idController.dispose();
    uuidNameController.dispose();
    artistFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If useDesktopUI flag is explicitly set, respect that choice
    if (widget.useDesktopUI != null) {
      if (widget.useDesktopUI!) {
        // Use desktop UI when explicitly requested
        return ProjectView(
          projectId: widget.projectId,
          project: widget.project,
          newProject: widget.newProject,
          productUPC: widget.productUPC,
          initialProductId: widget.initialProductId,
          // Pass the shared controllers
          projectNameController: projectNameController,
          artistNameController: artistNameController,
          idController: idController,
          uuidNameController: uuidNameController,
          notesController: notesController,
          artistFocusNode: artistFocusNode,
        );
      } else {
        // Use mobile UI when explicitly requested
        return MobileProjectView(
          projectId: widget.projectId,
          project: widget.project,
          newProject: widget.newProject,
          productUPC: widget.productUPC,
          initialProductId: widget.initialProductId,
          // Pass the shared controllers
          nameController: projectNameController,
          artistController: artistNameController,
          notesController: notesController,
        );
      }
    }

    // Otherwise, use the automatic responsive behavior based on screen size
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 600;

    // Use mobile layout if in portrait mode or screen is narrow
    if (isPortrait || isNarrowScreen) {
      return MobileProjectView(
        projectId: widget.projectId,
        project: widget.project,
        newProject: widget.newProject,
        productUPC: widget.productUPC,
        initialProductId: widget.initialProductId,
        // Pass the shared controllers
        nameController: projectNameController,
        artistController: artistNameController,
        notesController: notesController,
      );
    }

    // Otherwise, use the desktop layout
    return ProjectView(
      projectId: widget.projectId,
      project: widget.project,
      newProject: widget.newProject,
      productUPC: widget.productUPC,
      initialProductId: widget.initialProductId,
      // Pass the shared controllers
      projectNameController: projectNameController,
      artistNameController: artistNameController,
      idController: idController,
      uuidNameController: uuidNameController,
      notesController: notesController,
      artistFocusNode: artistFocusNode,
    );
  }
}
