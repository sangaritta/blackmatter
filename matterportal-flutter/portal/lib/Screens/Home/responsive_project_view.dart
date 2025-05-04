import 'package:flutter/material.dart';
import 'package:portal/Screens/Home/project_view.dart';
import 'package:portal/Screens/Home/Mobile/mobile_project_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portal/Widgets/ProjectCard/ProductBuilder/title_bloc.dart';

class ResponsiveProjectView extends StatefulWidget {
  final String projectId;
  final bool newProject;
  final String productUPC;
  final String initialProductId;
  final bool? useDesktopUI;

  const ResponsiveProjectView({
    Key? key,
    required this.projectId,
    required this.newProject,
    required this.productUPC,
    required this.initialProductId,
    this.useDesktopUI,
  }) : super(key: key);

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
    // Debug: entering ResponsiveProjectView
    debugPrint('[ResponsiveProjectView] build: projectId=${widget.projectId}, newProject=${widget.newProject}, productUPC=${widget.productUPC}, initialProductId=${widget.initialProductId}, useDesktopUI=${widget.useDesktopUI}');

    String initialTitle = '';
    return BlocProvider<TitleBloc>(
      create: (_) {
        debugPrint('[ResponsiveProjectView] Creating TitleBloc for projectId=${widget.projectId}');
        return TitleBloc(initialTitle: initialTitle);
      },
      child: Builder(
        builder: (context) {
          debugPrint('[ResponsiveProjectView] Inside BlocProvider<TitleBloc> builder');
          if (widget.useDesktopUI != null) {
            if (widget.useDesktopUI!) {
              debugPrint('[ResponsiveProjectView] Returning ProjectView');
              return ProjectView(
                projectId: widget.projectId,
                newProject: widget.newProject,
                productUPC: widget.productUPC,
                initialProductId: widget.initialProductId,
              );
            } else {
              debugPrint('[ResponsiveProjectView] Returning MobileProjectView');
              return MobileProjectView(
                projectId: widget.projectId,
                newProject: widget.newProject,
                productUPC: widget.productUPC,
                initialProductId: widget.initialProductId,
              );
            }
          }
          final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
          final screenWidth = MediaQuery.of(context).size.width;
          final isNarrowScreen = screenWidth < 600;
          if (isPortrait || isNarrowScreen) {
            debugPrint('[ResponsiveProjectView] Returning MobileProjectView (auto)');
            return MobileProjectView(
              projectId: widget.projectId,
              newProject: widget.newProject,
              productUPC: widget.productUPC,
              initialProductId: widget.initialProductId,
            );
          }
          debugPrint('[ResponsiveProjectView] Returning ProjectView (auto)');
          return ProjectView(
            projectId: widget.projectId,
            newProject: widget.newProject,
            productUPC: widget.productUPC,
            initialProductId: widget.initialProductId,
          );
        },
      ),
    );
  }
}
