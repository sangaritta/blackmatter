import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:portal/models/project.dart';
import 'package:portal/services/api_service.dart';

part 'project_event.dart';
part 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final ApiService apiService;
  ProjectBloc({required this.apiService}) : super(ProjectInitial()) {
    on<LoadProjects>((event, emit) async {
      emit(ProjectLoading());
      try {
        final projects = await apiService.getProjectsRaw();
        emit(ProjectLoaded(projects));
      } catch (e) {
        emit(ProjectError(e.toString()));
      }
    });
    on<SelectProject>((event, emit) async {
      emit(ProjectLoading());
      try {
        final project = await apiService.getProjectById(event.projectId);
        if (project == null) {
          emit(ProjectError('Project not found'));
        } else {
          emit(ProjectSelected(project));
        }
      } catch (e) {
        emit(ProjectError(e.toString()));
      }
    });
    // Add create, update, delete events as needed
  }
}
