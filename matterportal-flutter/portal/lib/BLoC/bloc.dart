import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portal/BLoC/state.dart';
import 'package:portal/BLoC/event.dart';

class SidebarMenuBloc extends Bloc<SidebarMenuEvent, SidebarMenuState> {
  SidebarMenuBloc() : super(SidebarMenuInitial()) {
    on<FetchSidebarMenuEvent>((event, emit) async {
      try {
        emit(SidebarMenuSuccess(event.menu!));
      } catch (e) {
        emit(
          SidebarMenuError(e.toString()),
        );
      }
    });
  }
}
