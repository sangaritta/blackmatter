import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:portal/models/product.dart';
import 'package:portal/services/api_service.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ApiService apiService;
  ProductBloc({required this.apiService}) : super(ProductInitial()) {
    on<LoadProducts>((event, emit) async {
      emit(ProductLoading());
      try {
        final products = await apiService.getProductsByProjectId(event.projectId);
        emit(ProductLoaded(products));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    });
    on<SelectProduct>((event, emit) async {
      emit(ProductLoading());
      try {
        final product = await apiService.getProductById(event.projectId, event.productId);
        if (product == null) {
          emit(ProductError('Product not found'));
        } else {
          emit(ProductSelected(product));
        }
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    });
    // Add create, update, delete events as needed
  }
}
