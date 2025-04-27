import 'package:flutter/material.dart';
import 'package:portal/Models/project.dart';
import 'package:portal/Screens/Home/project_view.dart';
import 'package:portal/Screens/Home/Mobile/mobile_project_view.dart';
import 'package:provider/provider.dart';

class ResponsiveProjectView extends StatefulWidget {
  final String projectId;
  final bool newProject;
  final String? productUPC;
  final String? initialProductId;
  final bool? useDesktopUI; // Optional flag to explicitly use desktop UI

  const ResponsiveProjectView({
    super.key,
    required this.projectId,
    required this.newProject,
    this.productUPC,
    this.initialProductId,
    this.useDesktopUI,
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
    projectNameController = TextEditingController();
    artistNameController = TextEditingController();
    notesController = TextEditingController();
    idController = TextEditingController();
    uuidNameController = TextEditingController();
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
    final project = Provider.of<Project>(context);
    // If useDesktopUI flag is explicitly set, respect that choice
    if (widget.useDesktopUI != null) {
      if (widget.useDesktopUI!) {
        // Use desktop UI when explicitly requested
        return ProjectView(
          projectId: widget.projectId,
          newProject: widget.newProject,
          productUPC: widget.productUPC,
          initialProductId: widget.initialProductId,
        );
      } else {
        // Use mobile UI when explicitly requested
        return MobileProjectView(
          projectId: widget.projectId,
          newProject: widget.newProject,
          productUPC: widget.productUPC,
          initialProductId: widget.initialProductId,
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
        newProject: widget.newProject,
        productUPC: widget.productUPC,
        initialProductId: widget.initialProductId,
      );
    }

    // Otherwise, use the desktop layout
    return ProjectView(
      projectId: widget.projectId,
      newProject: widget.newProject,
      productUPC: widget.productUPC,
      initialProductId: widget.initialProductId,
    );
  }
}
