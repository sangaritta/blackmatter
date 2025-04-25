import 'package:flutter_bloc/flutter_bloc.dart';
import 'api_service_event.dart';
import 'api_service_state.dart';
import '../../services/api_service.dart';

class ApiServiceBloc extends Bloc<ApiServiceEvent, ApiServiceState> {
  final ApiService apiService;
  ApiServiceBloc({required this.apiService}) : super(ApiServiceInitial()) {
    on<CreateProductEvent>((event, emit) async {
      emit(ApiServiceLoading());
      try {
        await apiService.createProduct(event.product, event.indexEntry);
        emit(ApiServiceSuccess());
      } catch (e) {
        emit(ApiServiceFailure(e.toString()));
      }
    });
    on<UpdateProductEvent>((event, emit) async {
      emit(ApiServiceLoading());
      try {
        await apiService.updateProduct(event.product, event.updatedIndexEntry);
        emit(ApiServiceSuccess());
      } catch (e) {
        emit(ApiServiceFailure(e.toString()));
      }
    });
    on<DeleteProductEvent>((event, emit) async {
      emit(ApiServiceLoading());
      try {
        await apiService.deleteProduct(event.productId);
        emit(ApiServiceSuccess());
      } catch (e) {
        emit(ApiServiceFailure(e.toString()));
      }
    });
    on<SaveTrackEvent>((event, emit) async {
      emit(ApiServiceLoading());
      try {
        await apiService.saveTrack(event.track, event.projectId, event.productId);
        emit(ApiServiceSuccess());
      } catch (e) {
        emit(ApiServiceFailure(e.toString()));
      }
    });
    on<DeleteTrackEvent>((event, emit) async {
      emit(ApiServiceLoading());
      try {
        await apiService.deleteTrack(event.trackId, event.productId);
        emit(ApiServiceSuccess());
      } catch (e) {
        emit(ApiServiceFailure(e.toString()));
      }
    });
  }
}
