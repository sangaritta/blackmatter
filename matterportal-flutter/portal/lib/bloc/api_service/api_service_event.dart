import 'package:equatable/equatable.dart';
import 'package:portal/models/product.dart';
import '../../models/track.dart';
import '../../models/index_entry.dart';

// Events for ApiServiceBloc
abstract class ApiServiceEvent extends Equatable {
  const ApiServiceEvent();
  @override
  List<Object?> get props => [];
}

class CreateProductEvent extends ApiServiceEvent {
  final Product product;
  final IndexEntry indexEntry;
  const CreateProductEvent(this.product, this.indexEntry);
  @override
  List<Object?> get props => [product, indexEntry];
}

class UpdateProductEvent extends ApiServiceEvent {
  final Product product;
  final IndexEntry updatedIndexEntry;
  const UpdateProductEvent(this.product, this.updatedIndexEntry);
  @override
  List<Object?> get props => [product, updatedIndexEntry];
}

class DeleteProductEvent extends ApiServiceEvent {
  final String productId;
  const DeleteProductEvent(this.productId);
  @override
  List<Object?> get props => [productId];
}

class SaveTrackEvent extends ApiServiceEvent {
  final Track track;
  final String projectId;
  final String productId;
  const SaveTrackEvent(this.track, this.projectId, this.productId);
  @override
  List<Object?> get props => [track, projectId, productId];
}

class DeleteTrackEvent extends ApiServiceEvent {
  final String trackId;
  final String productId;
  const DeleteTrackEvent(this.trackId, this.productId);
  @override
  List<Object?> get props => [trackId, productId];
}
