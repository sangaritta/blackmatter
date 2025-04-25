import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portal/models/product.dart';
import 'package:portal/models/track.dart';
import 'package:portal/models/metadata_language.dart';
import 'package:portal/domain/repositories/catalog_repository.dart';
import 'package:portal/domain/repositories/storage_repository.dart'
    as storage_repo;
import 'package:portal/domain/repositories/label_repository.dart' as label_repo;

enum Status {
  initial,
  loading,
  saving,
  uploading,
  distributing,
  success,
  failure,
}

class ProductState {
  final Product? productData;
  final Status status;
  final bool hasUnsavedChanges;
  final Map<String, String> validationErrors;
  final bool isInformationTabValid;
  final bool canDistribute;
  final List<int> selectedTrackIndexes;
  final List<int> selectedPlatformIndexes;
  final double trackUploadProgress;
  final String? trackUploadingFileName;
  final Status trackUploadStatus;
  final Status distributionStatus;
  final List<int> tracksOrder;
  final List<Track> tracks;
  final List<String> availableLabels;
  final List<String> availableGenres;
  final List<String> availableSubgenres;
  final List<String> availablePlatforms;
  final List<String> availableTimeZones;
  final String? errorMessage;

  ProductState({
    this.productData,
    this.status = Status.initial,
    this.hasUnsavedChanges = false,
    this.validationErrors = const {},
    this.isInformationTabValid = false,
    this.canDistribute = false,
    this.selectedTrackIndexes = const [],
    this.selectedPlatformIndexes = const [],
    this.trackUploadProgress = 0.0,
    this.trackUploadingFileName,
    this.trackUploadStatus = Status.initial,
    this.distributionStatus = Status.initial,
    this.tracksOrder = const [],
    this.tracks = const [],
    this.availableLabels = const [],
    this.availableGenres = const [],
    this.availableSubgenres = const [],
    this.availablePlatforms = const [],
    this.availableTimeZones = const [],
    this.errorMessage,
  });

  ProductState copyWith({
    Product? productData,
    Status? status,
    bool? hasUnsavedChanges,
    Map<String, String>? validationErrors,
    bool? isInformationTabValid,
    bool? canDistribute,
    List<int>? selectedTrackIndexes,
    List<int>? selectedPlatformIndexes,
    double? trackUploadProgress,
    String? trackUploadingFileName,
    Status? trackUploadStatus,
    Status? distributionStatus,
    List<int>? tracksOrder,
    List<Track>? tracks,
    List<String>? availableLabels,
    List<String>? availableGenres,
    List<String>? availableSubgenres,
    List<String>? availablePlatforms,
    List<String>? availableTimeZones,
    String? errorMessage,
  }) {
    return ProductState(
      productData: productData ?? this.productData,
      status: status ?? this.status,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      validationErrors: validationErrors ?? this.validationErrors,
      isInformationTabValid:
          isInformationTabValid ?? this.isInformationTabValid,
      canDistribute: canDistribute ?? this.canDistribute,
      selectedTrackIndexes: selectedTrackIndexes ?? this.selectedTrackIndexes,
      selectedPlatformIndexes:
          selectedPlatformIndexes ?? this.selectedPlatformIndexes,
      trackUploadProgress: trackUploadProgress ?? this.trackUploadProgress,
      trackUploadingFileName:
          trackUploadingFileName ?? this.trackUploadingFileName,
      trackUploadStatus: trackUploadStatus ?? this.trackUploadStatus,
      distributionStatus: distributionStatus ?? this.distributionStatus,
      tracksOrder: tracksOrder ?? this.tracksOrder,
      tracks: tracks ?? this.tracks,
      availableLabels: availableLabels ?? this.availableLabels,
      availableGenres: availableGenres ?? this.availableGenres,
      availableSubgenres: availableSubgenres ?? this.availableSubgenres,
      availablePlatforms: availablePlatforms ?? this.availablePlatforms,
      availableTimeZones: availableTimeZones ?? this.availableTimeZones,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

abstract class ProductEvent {}

class LoadProductRequested extends ProductEvent {
  final String projectId;
  final String userId;
  final String? productId;
  final bool isNewProduct;
  final String? initialType;
  final List<String>? initialArtists;
  LoadProductRequested({
    required this.projectId,
    required this.userId,
    this.productId,
    this.isNewProduct = false,
    this.initialType,
    this.initialArtists,
  });
}

class TitleChanged extends ProductEvent {
  final String title;
  TitleChanged(this.title);
}

class ArtistsChanged extends ProductEvent {
  final List<String> artists;
  ArtistsChanged(this.artists);
}

class ArtworkSelected extends ProductEvent {
  final dynamic artworkBytes;
  ArtworkSelected(this.artworkBytes);
}

class LabelChanged extends ProductEvent {
  final String labelName;
  LabelChanged(this.labelName);
}

class SaveProductRequested extends ProductEvent {}

class UploadTrackFileRequested extends ProductEvent {
  final dynamic fileData;
  final String fileName;
  UploadTrackFileRequested(this.fileData, this.fileName);
}

class TrackUpdateReceived extends ProductEvent {
  final Track updatedTrack;
  TrackUpdateReceived(this.updatedTrack);
}

class TracksReordered extends ProductEvent {
  final int oldIndex;
  final int newIndex;
  TracksReordered(this.oldIndex, this.newIndex);
}

class DeleteTrackRequested extends ProductEvent {
  final String trackId;
  DeleteTrackRequested(this.trackId);
}

class ReleaseDateChanged extends ProductEvent {
  final DateTime date;
  ReleaseDateChanged(this.date);
}

class ReleaseTimeChanged extends ProductEvent {
  final String time;
  ReleaseTimeChanged(this.time);
}

class UseSpecificTimeChanged extends ProductEvent {
  final bool useSpecificTime;
  UseSpecificTimeChanged(this.useSpecificTime);
}

class UseRollingReleaseChanged extends ProductEvent {
  final bool useRollingRelease;
  UseRollingReleaseChanged(this.useRollingRelease);
}

class TimeZoneChanged extends ProductEvent {
  final String timeZone;
  TimeZoneChanged(this.timeZone);
}

class PlatformsSelectedChanged extends ProductEvent {
  final List<Map<String, String>> platforms;
  PlatformsSelectedChanged(this.platforms);
}

class DistributeProductRequested extends ProductEvent {}

class ProductValidationRequested extends ProductEvent {}

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final CatalogRepository catalogRepository;
  final storage_repo.StorageRepository storageRepository;
  final label_repo.LabelRepository labelRepository;

  ProductBloc({
    required this.catalogRepository,
    required this.storageRepository,
    required this.labelRepository,
  }) : super(ProductState()) {
    on<LoadProductRequested>(_onLoadProductRequested);
    on<TitleChanged>(_onTitleChanged);
    on<ArtistsChanged>(_onArtistsChanged);
    on<ArtworkSelected>(_onArtworkSelected);
    on<LabelChanged>(_onLabelChanged);
    on<SaveProductRequested>(_onSaveProductRequested);
    on<UploadTrackFileRequested>(_onUploadTrackFileRequested);
    on<TrackUpdateReceived>(_onTrackUpdateReceived);
    on<TracksReordered>(_onTracksReordered);
    on<DeleteTrackRequested>(_onDeleteTrackRequested);
    on<ReleaseDateChanged>(_onReleaseDateChanged);
    on<ReleaseTimeChanged>(_onReleaseTimeChanged);
    on<UseSpecificTimeChanged>(_onUseSpecificTimeChanged);
    on<UseRollingReleaseChanged>(_onUseRollingReleaseChanged);
    on<TimeZoneChanged>(_onTimeZoneChanged);
    on<PlatformsSelectedChanged>(_onPlatformsSelectedChanged);
    on<DistributeProductRequested>(_onDistributeProductRequested);
    on<ProductValidationRequested>(_onProductValidationRequested);
  }

  Future<void> _onLoadProductRequested(
    LoadProductRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    try {
      Product? product;
      if (!event.isNewProduct && event.productId != null) {
        product = await catalogRepository.getProduct(
          projectId: event.projectId,
          productId: event.productId!,
        );
      } else {
        product = Product(
          id: '',
          userId: event.userId,
          projectId: event.projectId,
          releaseTitle: '',
          releaseVersion: '',
          label: '',
          genre: '',
          subgenre: '',
          metadataLanguage: MetadataLanguage('en', 'English'),
          type: '',
          price: '',
          state: 'Draft',
          coverImage: '',
          previewArtUrl: '',
          cLine: '',
          cLineYear: '',
          pLine: '',
          pLineYear: '',
          upc: '',
          uid: '',
          autoGenerateUPC: false,
          trackCount: 0,
          primaryArtists: event.initialArtists ?? [],
          primaryArtistIds: [],
          tracks: [],
        );
      }
      emit(
        state.copyWith(
          productData: product,
          status: Status.success,
          hasUnsavedChanges: false,
          validationErrors: {},
          isInformationTabValid: _validateInformationTab(product),
          canDistribute: _canDistribute(product),
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: Status.failure, errorMessage: e.toString()));
    }
  }

  void _onTitleChanged(TitleChanged event, Emitter<ProductState> emit) {
    if (state.productData == null) return;
    final updated = state.productData!.copyWith(releaseTitle: event.title);
    emit(
      state.copyWith(
        productData: updated,
        hasUnsavedChanges: true,
        validationErrors: _validateAll(updated),
        isInformationTabValid: _validateInformationTab(updated),
      ),
    );
  }

  void _onArtistsChanged(ArtistsChanged event, Emitter<ProductState> emit) {
    if (state.productData == null) return;
    final updated = state.productData!.copyWith(primaryArtists: event.artists);
    emit(
      state.copyWith(
        productData: updated,
        hasUnsavedChanges: true,
        validationErrors: _validateAll(updated),
        isInformationTabValid: _validateInformationTab(updated),
      ),
    );
  }

  void _onArtworkSelected(ArtworkSelected event, Emitter<ProductState> emit) {
    // For simplicity, just mark unsaved and store bytes in state (expand as needed)
    emit(
      state.copyWith(
        hasUnsavedChanges: true,
        // You may want to add a field to ProductState for selectedArtworkBytes
      ),
    );
  }

  Future<void> _onLabelChanged(
    LabelChanged event,
    Emitter<ProductState> emit,
  ) async {
    if (state.productData == null) return;
    try {
      final labelDetails = await labelRepository.getLabelDetails(
        event.labelName,
      );
      final updated = state.productData!.copyWith(
        label: event.labelName,
        cLine: labelDetails['cLine'],
        pLine: labelDetails['pLine'],
        cLineYear: labelDetails['cLineYear'],
        pLineYear: labelDetails['pLineYear'],
      );
      emit(
        state.copyWith(
          productData: updated,
          hasUnsavedChanges: true,
          validationErrors: _validateAll(updated),
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onSaveProductRequested(
    SaveProductRequested event,
    Emitter<ProductState> emit,
  ) async {
    if (state.productData == null) return;
    emit(state.copyWith(status: Status.saving));
    final validation = _validateAll(state.productData!);
    if (validation.isNotEmpty) {
      emit(
        state.copyWith(status: Status.failure, validationErrors: validation),
      );
      return;
    }
    try {
      // TODO: handle artwork upload if bytes exist
      final saved = await catalogRepository.saveProduct(state.productData!);
      emit(
        state.copyWith(
          productData: saved,
          status: Status.success,
          hasUnsavedChanges: false,
          validationErrors: {},
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: Status.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onUploadTrackFileRequested(
    UploadTrackFileRequested event,
    Emitter<ProductState> emit,
  ) async {
    // TODO: implement track upload logic using storageRepository
  }

  void _onTrackUpdateReceived(
    TrackUpdateReceived event,
    Emitter<ProductState> emit,
  ) {
    if (state.productData == null) return;
    final updatedTracks = List<Track>.from(state.productData!.tracks);
    final idx = updatedTracks.indexWhere(
      (t) => t.uid == event.updatedTrack.uid,
    );
    if (idx >= 0) {
      updatedTracks[idx] = event.updatedTrack;
    } else {
      updatedTracks.add(event.updatedTrack);
    }
    emit(
      state.copyWith(
        productData: state.productData!.copyWith(tracks: updatedTracks),
        hasUnsavedChanges: true,
      ),
    );
  }

  void _onTracksReordered(TracksReordered event, Emitter<ProductState> emit) {
    if (state.productData == null) return;
    final tracks = List<Track>.from(state.productData!.tracks);
    final track = tracks.removeAt(event.oldIndex);
    tracks.insert(event.newIndex, track);
    emit(
      state.copyWith(
        productData: state.productData!.copyWith(tracks: tracks),
        hasUnsavedChanges: true,
      ),
    );
  }

  void _onDeleteTrackRequested(
    DeleteTrackRequested event,
    Emitter<ProductState> emit,
  ) {
    if (state.productData == null) return;
    final tracks =
        state.productData!.tracks.where((t) => t.uid != event.trackId).toList();
    emit(
      state.copyWith(
        productData: state.productData!.copyWith(tracks: tracks),
        hasUnsavedChanges: true,
      ),
    );
  }

  void _onReleaseDateChanged(
    ReleaseDateChanged event,
    Emitter<ProductState> emit,
  ) {
    if (state.productData == null) return;
    final updated = state.productData!.copyWith(
      releaseTime: event.date.toIso8601String(),
    );
    emit(state.copyWith(productData: updated, hasUnsavedChanges: true));
  }

  void _onReleaseTimeChanged(
    ReleaseTimeChanged event,
    Emitter<ProductState> emit,
  ) {
    if (state.productData == null) return;
    final updated = state.productData!.copyWith(releaseTime: event.time);
    emit(state.copyWith(productData: updated, hasUnsavedChanges: true));
  }

  void _onUseSpecificTimeChanged(
    UseSpecificTimeChanged event,
    Emitter<ProductState> emit,
  ) {
    if (state.productData == null) return;
    // Remove useSpecificTime since it's not in Product model
    // Optionally, handle this in local state or ignore
    emit(
      state.copyWith(
        // productData unchanged
        hasUnsavedChanges: true,
      ),
    );
  }

  void _onUseRollingReleaseChanged(
    UseRollingReleaseChanged event,
    Emitter<ProductState> emit,
  ) {
    if (state.productData == null) return;
    final updated = state.productData!.copyWith(
      useRollingRelease: event.useRollingRelease,
    );
    emit(state.copyWith(productData: updated, hasUnsavedChanges: true));
  }

  void _onTimeZoneChanged(TimeZoneChanged event, Emitter<ProductState> emit) {
    if (state.productData == null) return;
    final updated = state.productData!.copyWith(timeZone: event.timeZone);
    emit(state.copyWith(productData: updated, hasUnsavedChanges: true));
  }

  void _onPlatformsSelectedChanged(
    PlatformsSelectedChanged event,
    Emitter<ProductState> emit,
  ) {
    if (state.productData == null) return;
    final updated = state.productData!.copyWith(
      platformsSelected: event.platforms,
    );
    emit(state.copyWith(productData: updated, hasUnsavedChanges: true));
  }

  Future<void> _onDistributeProductRequested(
    DistributeProductRequested event,
    Emitter<ProductState> emit,
  ) async {
    if (state.productData == null) return;
    emit(state.copyWith(distributionStatus: Status.distributing));
    // Final validation
    final validation = _validateAll(state.productData!);
    if (validation.isNotEmpty) {
      emit(
        state.copyWith(
          distributionStatus: Status.failure,
          validationErrors: validation,
        ),
      );
      return;
    }
    try {
      await catalogRepository.distributeProduct(state.productData!.id);
      emit(state.copyWith(distributionStatus: Status.success));
    } catch (e) {
      emit(
        state.copyWith(
          distributionStatus: Status.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onProductValidationRequested(
    ProductValidationRequested event,
    Emitter<ProductState> emit,
  ) {
    if (state.productData == null) return;
    final validation = _validateAll(state.productData!);
    emit(
      state.copyWith(
        validationErrors: validation,
        isInformationTabValid: _validateInformationTab(state.productData!),
        canDistribute: _canDistribute(state.productData!),
      ),
    );
  }

  // --- Validation Helpers ---
  Map<String, String> _validateAll(Product product) {
    final errors = <String, String>{};
    if (product.releaseTitle.isEmpty) errors['releaseTitle'] = 'Title required';
    if (product.primaryArtists.isEmpty)
      errors['primaryArtists'] = 'At least one artist required';
    // Add more field checks as needed
    return errors;
  }

  bool _validateInformationTab(Product? product) {
    if (product == null) return false;
    return product.releaseTitle.isNotEmpty && product.primaryArtists.isNotEmpty;
  }

  bool _canDistribute(Product? product) {
    if (product == null) return false;
    // Example: must have valid info and at least one track
    return _validateInformationTab(product) && product.tracks.isNotEmpty;
  }
}
