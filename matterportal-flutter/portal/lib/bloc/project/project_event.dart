part of 'project_bloc.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();
  @override
  List<Object?> get props => [];
}

class LoadProjects extends ProjectEvent {}
class SelectProject extends ProjectEvent {
  final String projectId;
  const SelectProject(this.projectId);
  @override
  List<Object?> get props => [projectId];
}
// Add more events as needed
