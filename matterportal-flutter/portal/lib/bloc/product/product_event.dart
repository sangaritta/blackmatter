part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {
  final String userId;
  final String projectId;
  const LoadProducts(this.userId, this.projectId);
  @override
  List<Object?> get props => [userId, projectId];
}
class SelectProduct extends ProductEvent {
  final String userId;
  final String projectId;
  final String productId;
  const SelectProduct(this.userId, this.projectId, this.productId);
  @override
  List<Object?> get props => [userId, projectId, productId];
}
// Add more events as needed
