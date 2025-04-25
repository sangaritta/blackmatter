Okay, let's create a detailed set of instructions for an AI agent or developer (assuming **no prior knowledge** of your old codebase) to build the **exact same multi-tab Product Builder UI** as described by your provided code snippets, but using the **BLoC pattern for state management**.

The focus is on replicating the visual structure, components, and flow, driven by `ProductBloc` and `TrackEditorBloc`.

---

```markdown
# AI Agent Instructions: Building the Product Builder UI with BLoC

## Goal

Construct a Flutter feature for creating and editing music "Products" within a larger application. This feature must visually replicate the UI structure and components detailed in the reference code snippets (`ProductBuilder`, `InformationTab`, `UploadTab`, `ReleaseTab`, `TrackEditor`, `MobileProductBuilder`, `MobileTrackEditor`). State management **must** be implemented using the BLoC pattern (`ProductBloc`, `TrackEditorBloc`), interacting with abstract Repositories for data operations. Assume **no knowledge** of any previous implementation (`ApiService`, etc.).

## Target Architecture

*   **UI:** Flutter Widgets, visually matching the reference code. Responsive layout (Desktop/Mobile).
*   **State Management:** `ProductBloc` (overall product state), `TrackEditorBloc` (single track editing state). Use `flutter_bloc` package.
*   **Navigation:** Assumed `GoRouter` manages navigation to/from this feature.
*   **Business Logic:** Abstract `Repositories` (e.g., `CatalogRepository`, `StorageRepository`).
*   **Models:** `Product`, `Track` data classes (use `freezed` recommended). BLoC States/Events (use `freezed` recommended).
*   **Dependency Injection (DI):** Assume `get_it` + `injectable` are set up for providing Repositories and BLoCs.

## Phase 1: Define Models, BLoC States, and Events

**1.1 Models (Define or ensure these exist, preferably using `freezed`)**

*   **`Product` Model:** (`lib/data/models/product.model.dart`)
    *   Must contain fields corresponding to all data collected in the `InformationTab`, `UploadTab`, and `ReleaseTab`:
        *   `id`: String (Product ID)
        *   `projectId`: String
        *   `releaseTitle`: String
        *   `releaseVersion`: String?
        *   `primaryArtists`: List<String> (Names)
        *   `primaryArtistIds`: List<String>? (IDs, if available)
        *   `metadataLanguage`: String? (Language code)
        *   `genre`: String?
        *   `subgenre`: String?
        *   `type`: String? (e.g., "Single", "Album")
        *   `price`: String? (Price tier identifier)
        *   `upc`: String?
        *   `autoGenerateUPC`: bool (Default: true)
        *   `label`: String?
        *   `cLine`: String? (Full C Line text, e.g., "© 2024 Label Name")
        *   `pLine`: String? (Full P Line text, e.g., "℗ 2024 Label Name")
        *   `cLineYear`: String?
        *   `pLineYear`: String?
        *   `coverImage`: String? (URL of the uploaded artwork)
        *   `songs`: List<Track> (List of associated tracks)
        *   `state`: String (e.g., "Draft", "Processing", "Approved" - managed by backend/distribution)
        *   `releaseDate`: DateTime?
        *   `releaseTime`: String? (Format like "HH:mm")
        *   `useSpecificTime`: bool?
        *   `useRollingRelease`: bool?
        *   `timeZone`: String?
        *   `platformsSelected`: List<Map<String, String>>? (e.g., `[{'name': 'Spotify', 'id': 'spotify_001'}, ...]`)
        *   `originalPath`: Map<String, String>? (For distributed products)
        *   `trackCount`: int? (Number of tracks)
*   **`Track` Model:** (`lib/data/models/track.model.dart`)
    *   Must contain fields corresponding to all data collected in the `TrackEditor`:
        *   `uid`: String (Unique Track ID)
        *   `trackNumber`: int?
        *   `title`: String
        *   `version`: String?
        *   `primaryArtists`: List<String> (Names)
        *   `primaryArtistIds`: List<String>? (IDs, if available)
        *   `featuringArtists`: List<String>? (Names)
        *   `remixers`: List<String>? (Names)
        *   `performers`: List<Map<String, dynamic>>? (`[{'name': 'Artist Name', 'roles': ['Role1', 'Role2']}]`)
        *   `songwriters`: List<Map<String, dynamic>>?
        *   `production`: List<Map<String, dynamic>>?
        *   `isExplicit`: bool (Default: false)
        *   `ownership`: String? (e.g., "Original", "Acquired")
        *   `isrc`: String? (ISRC code or "AUTO")
        *   `country`: String? (Country code)
        *   `nationality`: String? (Country code)
        *   `fileName`: String? (Original uploaded filename)
        *   `downloadUrl`: String? (URL for audio preview/download)
        *   `storagePath`: String? (Path in cloud storage)
        *   `artworkUrl`: String? (Inherited from Product, potentially overridable later)
        *   `lyrics`: String? (Or structure for synced lyrics)
*   **`MetadataLanguage` Model/Constant:** (`lib/constants/product.dart`) - Define a class or use a `Map` for language options (code, name).
*   **`Failure` Class:** (`lib/core/error/failures.dart`) - Base class for errors (e.g., `ServerFailure`, `ValidationFailure`, `StorageFailure`).

**1.2 BLoC Definitions (Use `freezed` for generation)**

*   Create directories:
    *   `lib/features/catalog/presentation/bloc/product_bloc/`
    *   `lib/features/catalog/presentation/bloc/track_editor_bloc/`
*   Define `ProductEvent`, `ProductState`, `TrackEditorEvent`, `TrackEditorState` **exactly as specified in the previous detailed instructions** (Phase 1, Step 1.2). Include all necessary events for field changes, loading, saving, validation, tracks, and distribution. Ensure states hold all required data, status flags, validation errors, and helper getters (`isInformationTabValid`, `canDistribute`, etc.). Use a `Status` enum (`initial`, `loading`, `saving`, `uploading`, `distributing`, `success`, `failure`).

## Phase 2: Implement BLoC Logic

**2.1 `ProductBloc` (`product_bloc.dart`)**

*   Annotate with `@injectable`.
*   Inject required Repository interfaces (`CatalogRepository`, `StorageRepository`, `AuthRepository`, `LabelRepository`).
*   Implement handlers for **all** `ProductEvent`s defined previously.
    *   **`LoadProductRequested`:** Fetch data via `CatalogRepository.getProduct`. Handle new vs. existing. Populate `ProductState` with fetched/default data. Store original data representation for change detection.
    *   **Field Change Events (e.g., `TitleChanged`, `ArtistsChanged`, `ArtworkSelected`):** Update the corresponding field in `state.productData` using `copyWith`. Set `hasUnsavedChanges = true`. Trigger internal validation and update `validationErrors` map in the state. Emit the new state.
    *   **`LabelChanged`:** Fetch C/P Lines from `LabelRepository` based on `labelName` and update `state.productData` accordingly along with the label name itself.
    *   **`SaveProductRequested`:**
        *   Emit `saving` status.
        *   Perform validation using helper methods based on `state.productData`. If invalid, emit `failure` with `validationErrors`.
        *   If artwork bytes exist (`state.selectedArtworkBytes`), call `StorageRepository.uploadArtwork`. On success, update `productData.coverImage` with the returned URL. Handle upload progress updates if needed.
        *   Call `CatalogRepository.saveProduct` with the validated `state.productData`.
        *   On success, update `state.productData` with the result (if repo returns updated data), set `hasUnsavedChanges = false`, store new original data representation, emit `success` status.
        *   On failure (upload or save), emit `failure` status with error.
    *   **Track Events (`UploadTrackFileRequested`, `TrackUpdateReceived`, `TracksReordered`, `DeleteTrackRequested`):** Implement logic interacting with `StorageRepository` and `CatalogRepository` for track operations. Update the `state.productData.songs` list accordingly. Manage `trackUploadStatus`, `trackUploadingFileName`, `trackUploadProgress` state fields during uploads.
    *   **Distribution Events (`ReleaseDateChanged`, etc.):** Update release-specific fields in the `ProductState` directly. Set `hasUnsavedChanges = true`.
    *   **`DistributeProductRequested`:** Emit `distributing` status. Perform final validation on the *entire* product and tracks. Call `CatalogRepository.distributeProduct`. Emit `success` or `failure`.
    *   **Helper Methods:** Include private methods for `_validateInformationTab()`, `_validateTracks()`, `_validateReleaseTab()`, `_canDistribute()`.

**2.2 `TrackEditorBloc` (`track_editor_bloc.dart`)**

*   Annotate with `@injectable`.
*   Inject `CatalogRepository`.
*   Implement handlers for **all** `TrackEditorEvent`s.
    *   **`InitializeRequested`:** Set initial `trackData` in state. Store original representation.
    *   **Field Change Events:** Update `state.trackData` using `copyWith`. Set `hasUnsavedChanges = true`. Validate and update `validationErrors`. Emit new state.
    *   **`SaveTrackRequested`:** Emit `saving` status. Validate `state.trackData`. Call `CatalogRepository.saveTrack`. Emit `success` (include the saved track data) or `failure`. On success, reset `hasUnsavedChanges`.

## Phase 3: Define Repository Interfaces

Define abstract classes (interfaces) for the repositories the BLoCs depend on. Implementations will be created separately.

*   **`CatalogRepository` (`lib/domain/repositories/catalog_repository.dart`)**
    *   Methods matching BLoC needs: `Future<Either<Failure, Product?>> getProduct(...)`, `Future<Either<Failure, Product>> saveProduct(...)`, `Future<Either<Failure, List<Track>>> getTracks(...)`, `Future<Either<Failure, Track>> saveTrack(...)`, `Future<Either<Failure, void>> updateTrackOrder(...)`, `Future<Either<Failure, void>> deleteTrack(...)`, `Future<Either<Failure, void>> distributeProduct(...)`, `Future<Either<Failure, String>> generateUPC(...)`, `Future<Either<Failure, Map<String, dynamic>>> getLabelDetails(String labelName)`.
*   **`StorageRepository` (`lib/domain/repositories/storage_repository.dart`)**
    *   Methods: `Future<Either<Failure, String>> uploadArtwork({required Uint8List bytes, required String productId, Function(double)? onProgress})`, `Future<Either<Failure, Map<String, String>>> uploadTrackAudio({required dynamic fileData, required String path, Function(double)? onProgress})`, `Future<Either<Failure, void>> deleteTrackAudio(...)`.
*   **(Other Repositories)** `AuthRepository`, `LabelRepository`, `ArtistRepository`, `SongwriterRepository` assumed to exist with necessary methods (e.g., `getCurrentUserId`, `fetchLabels`, `fetchArtists`).

## Phase 4: Implement UI (Replicating Visuals)

**Goal:** Rebuild the UI widgets using `BlocBuilder`/`BlocListener` to react to state changes from the BLoCs, ensuring the visual output matches the reference code snippets.

**4.1 `ProjectCard` / `ProjectView` Modifications:**

*   When navigating *to* the `ProductBuilder` (e.g., by selecting a product in `ProductListTile` or clicking "Add Product"), ensure the `projectId` and `productId` (or a signal for a new product) are passed correctly.
*   When adding a new product, potentially pass the `project.artist` name to pre-populate the `ProductBloc` initial state.

**4.2 `ProductBuilder` / `MobileProductBuilder` Refactoring:**

*   **Stateful to Stateless/Stateful:** Can likely become a `StatelessWidget` if all state is managed by BLoC, or remain `StatefulWidget` only for `TabController` initialization/disposal.
*   **Remove Local State:** Delete local state variables like `_product`, `productStatus`, `_selectedImageBytes`, `selectedArtists`, `_isInformationComplete`, etc. These will come from `ProductBloc`.
*   **Provide BLoC:** Wrap the root widget (`Expanded` or `Scaffold`) with `BlocProvider<ProductBloc>`. Dispatch `LoadProductRequested` in `create`.
    ```dart
     BlocProvider<ProductBloc>(
       create: (context) => getIt<ProductBloc>() // Assuming getIt setup
         ..add(ProductEvent.loadProductRequested(
           projectId: widget.projectId,
           productId: widget.productId,
           isNewProduct: widget.isNewProduct,
           initialType: widget.selectedProductType, // Pass type if new
           // Pass initial artists from project if needed
         )),
       child: // Builder based on ProductState status
     )
    ```
*   **Build based on State:** Use `BlocBuilder<ProductBloc, ProductState>` around the main `Column`/`Stack`.
    *   Show `LoadingIndicator` if `state.status == Status.loading`.
    *   Show error message if `state.status == Status.failure`.
    *   Build the `TabBar` and `TabBarView` if `state.status == Status.success` and `state.productData != null`.
*   **TabBar Indicator:** The check/error icon next to the "Information" tab label should be driven by `state.isInformationTabValid`.
*   **TabBarView Children:** Pass relevant data from `state.productData` and `state.selectedArtworkBytes` down to the specific tab widgets (`InformationTab`, `UploadTab`, `ReleaseTab`).
*   **Status Overlay:** Show `ProductStatusOverlay` based on `state.productData?.state`.
*   **Responsiveness:** Use `MediaQuery` or `LayoutBuilder` to conditionally render `MobileProductBuilder` structure or `ProductBuilder` structure based on screen size (this logic might live *outside* the builder itself, perhaps in the routing or a parent widget).

**4.3 `InformationTab` Refactoring:**

*   **Keep StatefulWidget:** Retain `StatefulWidget` for managing `TextEditingController`s, focus nodes, and local UI interactions (like dropdown selections before dispatching).
*   **Remove Local State:** Delete `_isLoading`, `_autoGenerateUPC`, `_selectedImageBytes`, `_coverImageUrl`, `artistSuggestions`, `_selectedMetadataLanguage`, `_selectedGenre`, `_selectedSubgenre`, `_selectedPrice`, `_cLineYear`, `_pLineYear`, `_labels`, `_isLoadingProduct`, `_hasUnsavedChanges`, `_originalData`, `_hasBeenSaved`, `_uploadProgress`, `_apiProgress`, `_isUploadingImage`, `_isProcessingApi`.
*   **Connect to BLoC:** Assume `ProductBloc` is provided by the parent (`ProductBuilder`).
*   **Initialize Controllers:** In `initState`, initialize controllers using values from `context.read<ProductBloc>().state.productData` if available.
*   **Use `BlocBuilder`:** Wrap the main `ListView` or `Column` with `BlocBuilder<ProductBloc, ProductState>`.
    *   **Populate Fields:** Inside the builder, get `state.productData`, `state.selectedArtworkBytes`, `state.validationErrors`. Update controller text *conditionally* (`if (controller.text != state.productData.title) ...`) to avoid cursor jumps. Set dropdown values based on state.
    *   **CoverImageSection:** Pass `state.selectedArtworkBytes` and `state.productData?.coverImage`. `onImageSelected` dispatches `ProductEvent.artworkSelected`.
    *   **ProductMetadataFields, ArtistSection, ProductIdentityFields, RightsFields:** Pass relevant controller instances and values from `state.productData`. `onChanged` callbacks for dropdowns, artists, etc., should dispatch the corresponding `ProductEvent` (e.g., `GenreChanged`, `ArtistsChanged`).
    *   **UPC Field:** Enable/disable based on `state.productData.autoGenerateUPC`. `onAutoGenerateChanged` dispatches `AutoGenerateUpcChanged`. `onUpcChanged` dispatches `UpcChanged`.
    *   **Label Dropdown:** Populate items from fetched labels (maybe load labels once in `ProductBloc` or via a separate `LabelBloc`). `onLabelChanged` dispatches `LabelChanged` (passing label name and fetched C/P lines).
*   **`_buildSaveButton`:**
    *   Check `state.saveStatus == Status.saving` for loading indicator.
    *   Enable based on `state.hasUnsavedChanges` and overall validation status (e.g., `state.isInformationTabValid`).
    *   `onPressed` dispatches `ProductEvent.saveProductRequested()`.
*   **Validation:** Display error icons/text based on `state.validationErrors`. `onInformationComplete` callback is no longer needed; status comes directly from BLoC state (`state.isInformationTabValid`).

**4.4 `UploadTab` / Mobile Upload Part Refactoring:**

*   **Stateless/Stateful:** Can likely be `StatelessWidget` or basic `StatefulWidget` for animation controllers if needed.
*   **Remove Local State:** Delete `fileUploadProgress`, `isUploading`, `fileUrls`, `_trackDataMap`, `isDragging`.
*   **Connect to BLoC:** Read `ProductBloc` state.
*   **Build Track List:** Use `BlocBuilder<ProductBloc, ProductState>` to get `state.productData.songs`. Build the `ReorderableListView`.
    *   Display track info (title, artists) from the `Track` objects in the list.
    *   Show upload progress for the *specific* track being uploaded: check if `track.uid` (or maybe `track.fileName` temporarily) matches `state.trackUploadingFileName` and use `state.trackUploadProgress`. Display progress bar conditionally.
    *   `onTap`: Navigate to `TrackEditor`/`MobileTrackEditor`, passing the `Track` object and `projectId`, `productId`. Handle the result (updated `Track` object) when the editor pops and dispatch `ProductEvent.trackUpdateReceived`.
    *   `onReorder`: Dispatch `ProductEvent.tracksReordered(oldIndex, newIndex)`.
*   **Drag/Drop Area / Upload Button:**
    *   Use `BlocBuilder` to check `state.trackUploadStatus == Status.uploading` to potentially disable the upload button/area or show a global progress indicator.
    *   `onDragDone`/`onPressed`: Dispatch `ProductEvent.uploadTrackFileRequested` for each file.

**4.5 `ReleaseTab` Refactoring:**

*   **Stateless/Stateful:** Likely `StatefulWidget` for local interaction state before dispatching.
*   **Remove Local State:** Delete `selectedPlatforms`, `selectedStores`, `selectedDate`, `selectedTime`, `useSpecificTime`, `useRollingRelease`, `selectedTimeZone`, `_currentState`, `_isLoading`.
*   **Connect to BLoC:** Read `ProductBloc` state.
*   **Build UI:** Use `BlocBuilder<ProductBloc, ProductState>`.
    *   Initialize date/time pickers, checkboxes, dropdowns, and platform selection based on `state.releaseDate`, `state.releaseTime`, `state.useSpecificTime`, `state.useRollingRelease`, `state.selectedTimeZone`, `state.selectedPlatforms`.
    *   **Interactions:**
        *   Date/Time Picker `onTap`: Show pickers. On selection, dispatch `ProductEvent.releaseDateChanged` / `ProductEvent.releaseTimeChanged`.
        *   Checkboxes `onChanged`: Dispatch `UseSpecificTimeChanged` / `UseRollingReleaseChanged`.
        *   TimeZone Dropdown `onChanged`: Dispatch `TimeZoneChanged`.
        *   Platform Grid `onTap`: Create the *new* list of selected platform names and dispatch `ProductEvent.platformsSelectedChanged(newList)`.
*   **`_buildSaveButton` / Distribute Button:**
    *   Check `state.distributionStatus == Status.distributing` for loading indicator.
    *   Enable based on `state.canDistribute`.
    *   `onPressed` dispatches `ProductEvent.distributeProductRequested()`.

**4.6 `TrackEditor` / `MobileTrackEditor` Refactoring:**

*   **Stateful to Stateless/Stateful:** Keep `StatefulWidget` for controllers, audio player state listeners.
*   **Remove Local State:** Delete `_isSaving`, `_isAutoISRC`, `_hasBeenSaved`, `_trackData`, `_performersWithRoles`, `_songwritersWithRoles`, `_productionWithRoles`, etc.
*   **Provide BLoC:** Wrap root with `BlocProvider<TrackEditorBloc>`. Dispatch `InitializeRequested` in `create`, passing the initial `Track` data received via the widget constructor.
    ```dart
     BlocProvider<TrackEditorBloc>(
       create: (context) => getIt<TrackEditorBloc>()
         ..add(TrackEditorEvent.initializeRequested(
           projectId: widget.projectId,
           productId: widget.productId,
           trackId: widget.track.uid, // Assuming Track object passed in
           initialTrackData: widget.track,
         )),
       child: // Builder based on TrackEditorState status
     )
    ```
*   **Build based on State:** Use `BlocBuilder<TrackEditorBloc, TrackEditorState>`.
    *   Show loading/error based on `state.status`.
    *   Populate all form fields (`TextField` controllers, dropdowns, artist selectors, switches) based on `state.trackData`. Update controllers conditionally (`if (controller.text != state.trackData.title) ...`).
*   **Interactions:** `onChanged` for all fields should dispatch the appropriate `TrackEditorEvent` (e.g., `TitleChanged`, `PerformersChanged`, `ExplicitChanged`).
*   **Audio Preview:** The `AudioPreview` widget's state (`_isPlaying`, `_position`, etc.) can remain managed locally within the `TrackEditor`'s `State` class using the `AudioPlayerService` listeners, as it's primarily UI feedback. However, ensure `_initAudioPlayer` is called correctly when the track data in the BLoC state changes.
*   **Save Button:**
    *   Check `state.saveStatus == Status.saving` for loading indicator.
    *   Enable based on `state.isTrackValid` and `state.hasUnsavedChanges`.
    *   `onPressed` dispatches `TrackEditorEvent.saveTrackRequested()`.
*   **Handle Save Success:** Use `BlocListener<TrackEditorBloc, TrackEditorState>` to listen for `state.saveStatus == Status.success`. When successful, call `Navigator.pop(context, state.trackData)` to return the updated track data to the calling screen (`UploadTab`).

**Phase 5: Validation Implementation**

*   Implement validation logic within the respective BLoCs (`ProductBloc`, `TrackEditorBloc`) triggered by field change events.
*   Update the `validationErrors` map in the BLoC states.
*   In the UI widgets (`InformationTab`, `TrackEditor`), use `BlocBuilder` to read the `validationErrors` map.
*   Display error messages using `InputDecoration(errorText: ...)` or other visual cues based on the presence of errors in the map for specific fields.
*   Use the validation status getters (e.g., `state.isInformationTabValid`, `state.isTrackValid`) to control UI elements like the tab indicator icon and button enabled states.

**Phase 6: Routing and Dependency Injection**

*   **Routing:** Configure `GoRouter` routes for `/projects/:projectId/products/new` and `/projects/:projectId/products/:productId`. Ensure the `ProductBuilder` widget is built for these routes, receiving `projectId`, `productId`, and `isNewProduct` flags. Navigation to the `MobileTrackEditor` should likely use `Navigator.push` from the `MobileProductBuilder`'s upload tab, handling the returned result.
*   **DI:** Ensure `ProductBloc`, `TrackEditorBloc`, and all required `Repository` implementations are registered with `get_it`/`injectable`. Run the build runner.

## Conclusion

By following these steps, the AI agent/developer can systematically refactor the provided UI components to use BLoC for state management, creating a clean separation of concerns while precisely replicating the desired user interface and user experience. Remember to handle loading states, error states, and validation feedback clearly in the UI based on the BLoC states.
```

Okay, here is a highly detailed set of instructions for an AI agent or developer, assuming **zero prior knowledge** of your existing codebase (like `ApiService`). The goal is to build the specified multi-tab Product Builder UI precisely as shown in the reference code snippets, but implement the state management and logic using the **BLoC pattern**.

This guide incorporates the *concepts* and *data requirements* evident in your `ApiService` file (like specific fields, operations) into the BLoC and Repository design, without referencing the `ApiService` class itself.

---

```markdown
# AI Agent Instructions: Rebuilding the Product Builder UI with BLoC

## Objective

Your primary task is to construct a Flutter feature module for creating and editing music "Products". This module **must visually replicate the UI structure, layout, components, and responsiveness (Desktop/Mobile)** shown in the reference code snippets (`ProductBuilder`, `MobileProductBuilder`, `InformationTab`, `UploadTab`, `ReleaseTab`, `TrackEditor`, `MobileTrackEditor`, `ProjectCard`, `ProjectView`).

Crucially, the **state management and data handling logic must be implemented exclusively using the BLoC pattern** (`ProductBloc`, `TrackEditorBloc`). These BLoCs will interact with abstract `Repositories` for data persistence and fetching. **Do NOT refer to or use any logic from a class named `ApiService` or similar direct data access classes from the old codebase.** Assume a clean slate implementation adhering to the specified BLoC architecture.

## Target Architecture

*   **UI Layer:** Flutter Widgets (`StatelessWidget`, `StatefulWidget`). Visually **identical** to the reference snippets. Responsive design distinguishing between mobile and desktop layouts as shown. Key UI elements to replicate include:
    *   Main container with `TabBar` (Information, Upload, Release) and `TabBarView`.
    *   `InformationTab` layout: Cover image uploader, metadata fields (title, version, artists, language, genre, etc.), identity fields (UPC, label), rights fields (C/P Line).
    *   `UploadTab` layout: Drag & drop area, reorderable list of uploaded tracks, track editor panel (desktop) or modal sheet (mobile).
    *   `ReleaseTab` layout: Date/time selection, store selection grid, distribution button.
    *   `TrackEditor` layout: Audio preview, detailed track metadata fields, role-based artist selectors, lyrics button, save button.
    *   Conditional overlays (e.g., `ProductStatusOverlay`).
*   **State Management:** `flutter_bloc` package.
    *   `ProductBloc`: Manages the state of the **entire product** being created/edited (metadata, artwork, list of tracks, release settings, validation, overall status).
    *   `TrackEditorBloc`: Manages the state of a **single track** being edited within the `TrackEditor`.
*   **Navigation:** Assume `GoRouter` is used externally to navigate to this Product Builder feature.
*   **Business Logic:** Abstract `Repository` interfaces define data operations.
*   **Data Layer:** Concrete Repository implementations interact with backend services (Firestore, Storage assumed) via Data Sources (implementation details are separate).
*   **Models:** `Product`, `Track` classes (use `freezed` recommended). BLoC `State` and `Event` classes (use `freezed` recommended). `Failure` class for error handling.
*   **Dependency Injection (DI):** Assume `get_it` + `injectable` are configured to provide Repositories and BLoCs.

## Phase 1: Define Models, BLoC States, and Events

**(Implement these first, preferably using the `freezed` package for code generation)**

**1.1 Models**

*   **`Product` Model (`lib/data/models/product.model.dart`)**:
    *   Ensure fields cover *all* data points managed across `InformationTab` and `ReleaseTab`. Reference the previous detailed instructions (Phase 1, Step 1.1) for the full list, including `id`, `projectId`, `releaseTitle`, `releaseVersion`, `primaryArtists` (List<String>), `primaryArtistIds` (List<String>?), `metadataLanguage` (String?), `genre`, `subgenre`, `type`, `price`, `upc`, `autoGenerateUPC` (bool), `label`, `cLine`, `pLine`, `cLineYear`, `pLineYear`, `coverImage` (String URL), `songs` (List<Track>), `state` (String), `releaseDate` (DateTime?), `releaseTime` (String?), `useSpecificTime` (bool?), `useRollingRelease` (bool?), `timeZone` (String?), `platformsSelected` (List<Map<String, String>>?).
*   **`Track` Model (`lib/data/models/track.model.dart`)**:
    *   Ensure fields cover *all* data points managed in `TrackEditor`. Reference the previous detailed instructions (Phase 1, Step 1.1) for the full list, including `uid`, `trackNumber`, `title`, `version`, `primaryArtists`, `primaryArtistIds`, `featuringArtists`, `remixers`, `performers` (List<Map<String, dynamic>>), `songwriters` (List<Map<String, dynamic>>), `production` (List<Map<String, dynamic>>), `isExplicit` (bool), `ownership` (String?), `isrc` (String?), `country` (String?), `nationality` (String?), `fileName` (String?), `downloadUrl` (String?), `storagePath` (String?), `lyrics` (String?).
*   **Other Constants/Models:**
    *   Define constants for `metadataLanguages`, `genres`, `subgenres`, `productTypes`, `prices` (as seen in `InformationTab` props).
    *   Define constants for `platformIds` and `timeZones` (as seen in `ReleaseTab`).
    *   Define constants for roles (`performerRoles`, `writerRoles`, `productionRoles`).
    *   Define `Failure` class (`lib/core/error/failures.dart`).

**1.2 BLoC States & Events**

*   Create directories: `lib/features/catalog/presentation/bloc/product_bloc/` and `lib/features/catalog/presentation/bloc/track_editor_bloc/`.
*   **Define `ProductEvent`, `ProductState`, `TrackEditorEvent`, `TrackEditorState` EXACTLY as specified in the previous detailed instructions (Phase 1, Step 1.2).**
    *   **Crucially include:**
        *   Events for every single field change (`TitleChanged`, `GenreChanged`, `ArtworkSelected`, `TracksReordered`, `ReleaseDateChanged`, etc.).
        *   Events for loading, saving, uploading, distributing (`LoadProductRequested`, `SaveProductRequested`, `UploadTrackFileRequested`, `DistributeProductRequested`).
        *   Event for track updates coming from `TrackEditorBloc` (`TrackUpdateReceived`).
        *   States holding the `Product` or `Track` data, `Status` enums (for loading, saving, uploading, distributing), `validationErrors` maps, `selectedArtworkBytes` (for ProductBloc), `trackUploadProgress`/`trackUploadingFileName`, release settings, `hasUnsavedChanges` flag.
        *   Helper getters in states (`isInformationTabValid`, `canDistribute`, etc.).

## Phase 2: Implement BLoC Logic

**(Implement the BLoC classes based on the defined states/events)**

**2.1 `ProductBloc` (`product_bloc.dart`)**

*   `@injectable` annotation.
*   Inject `CatalogRepository`, `StorageRepository`, `AuthRepository`, `LabelRepository`.
*   Implement event handlers as detailed previously (Phase 2, Step 2.1), ensuring:
    *   State updates use `copyWith`.
    *   Repositories are called for data fetching/saving/uploading/distribution.
    *   `Either<Failure, Success>` results from repositories are handled, emitting `success` or `failure` states.
    *   Validation logic is triggered on relevant field changes and before saving/distributing, updating the `validationErrors` state field.
    *   `hasUnsavedChanges` flag is managed correctly.
    *   Track list (`state.productData.songs`) is updated on upload success, reorder, delete, and when receiving `TrackUpdateReceived`.
    *   Artwork upload via `StorageRepository` happens *within* the `SaveProductRequested` handler if `state.selectedArtworkBytes` is present, updating `productData.coverImage` before saving product metadata via `CatalogRepository`.
    *   Track audio upload (`UploadTrackFileRequested`) uses `StorageRepository`, manages progress state, and calls `CatalogRepository` to save the initial track reference *after* successful upload.

**2.2 `TrackEditorBloc` (`track_editor_bloc.dart`)**

*   `@injectable` annotation.
*   Inject `CatalogRepository`.
*   Implement event handlers as detailed previously (Phase 2, Step 2.2), ensuring:
    *   `InitializeRequested` sets the initial `trackData`.
    *   Field change events update `state.trackData` via `copyWith`, set `hasUnsavedChanges`, and trigger validation.
    *   `SaveTrackRequested` validates, calls `CatalogRepository.saveTrack`, emits `success` (with the saved track data) or `failure`, and resets `hasUnsavedChanges`.

## Phase 3: Define Required Repository Interfaces

**(Define these abstract classes. Implementations are separate.)**

*   **`CatalogRepository` (`lib/domain/repositories/catalog_repository.dart`)**: Define methods like `getProduct`, `saveProduct`, `getTracks`, `saveTrack`, `updateTrackOrder`, `deleteTrack`, `distributeProduct`, `generateUPC`, `getLabelDetails`. Ensure return types use `Either<Failure, SuccessType>`.
*   **`StorageRepository` (`lib/domain/repositories/storage_repository.dart`)**: Define `uploadArtwork`, `uploadTrackAudio`, `deleteTrackAudio`, `getDownloadURL`. Use `Either` and handle progress callbacks.
*   **(Assumed Existing)** `AuthRepository`, `LabelRepository`, `ArtistRepository`, `SongwriterRepository` with necessary methods.

## Phase 4: Implement UI Widgets (Replicating Visuals with BLoC)**

**(Refactor the provided UI widget code to use BLoC state.)**

**4.1 General Refactoring Rules:**

*   **Remove `setState` for Data:** Only use `setState` for purely local UI state (animations, focus). Data display and loading states come from BLoC.
*   **Remove Direct API/DB Calls:** No `ApiService`, `FirebaseFirestore`, `FirebaseStorage` calls within widgets.
*   **Remove Redundant State:** Delete widget state variables that duplicate BLoC state (`_product`, `_tracks`, `_coverImageUrl`, etc.).
*   **Connect via `flutter_bloc`:** Use `BlocProvider`, `BlocBuilder`, `BlocListener`, `BlocConsumer`.
*   **Read from State:** Get data to display from the `state` object within `BlocBuilder`.
*   **Dispatch Events:** Trigger BLoC actions via `context.read<BlocType>().add(Event(...))` in callbacks (`onPressed`, `onChanged`, `onTap`, `onReorder`, file selection/drop).

**4.2 `ProductBuilder` / `MobileProductBuilder` Implementation:**

*   **Structure:** Use `BlocProvider<ProductBloc>` at the root. Dispatch `LoadProductRequested` in `create`.
*   **Build:** Use `BlocBuilder<ProductBloc, ProductState>` to handle `Status.loading`, `Status.failure`, and `Status.success`.
*   **Visuals:** Replicate the `Stack` (for overlay), `Column` with `TabBar` and `TabBarView`.
*   **TabBar:**
    *   The check/error icon on the "Information" tab MUST be controlled by `state.isInformationTabValid` (getter in `ProductState`).
*   **TabBarView:** Pass necessary slices of data down to child tabs:
    *   `InformationTab` needs `state.productData`, `state.selectedArtworkBytes`, `state.validationErrors`, `state.saveStatus`.
    *   `UploadTab` needs `state.productData?.songs`, `state.trackUploadStatus`, `state.trackUploadingFileName`, `state.trackUploadProgress`.
    *   `ReleaseTab` needs `state.releaseDate`, `state.releaseTime`, ..., `state.selectedPlatforms`, `state.distributionStatus`.
*   **Overlay:** Show `ProductStatusOverlay` based on `state.productData?.state`.
*   **Responsiveness:** Implement the logic to switch between the mobile and desktop layout structures based on `MediaQuery.of(context).size.width`, ensuring both layouts are driven by the *same* `ProductBloc` state.

**4.3 `InformationTab` Implementation:**

*   **Structure:** Keep `StatefulWidget` for controllers.
*   **State:** Remove all local state related to product data, loading, saving, validation.
*   **Connect:** Read `ProductBloc` state using `BlocBuilder`.
*   **Initialize:** In `initState`, initialize `TextEditingController`s from `context.read<ProductBloc>().state.productData` IF it's already loaded (handle null case).
*   **Build:**
    *   In `BlocBuilder`, update controller text *conditionally* (`if (controller.text != state.productData?.title) ...`).
    *   Set dropdown values based on `state.productData` fields (`_selectedGenre = state.productData?.genre`).
    *   **Replicate ALL UI Components:**
        *   `CoverImageSection`: Display based on `state.selectedArtworkBytes` (priority) or `state.productData?.coverImage`. `onImageSelected` dispatches `ProductEvent.artworkSelected`.
        *   `ProductMetadataFields`: Pass controllers, values from `state.productData`. Callbacks dispatch `TitleChanged`, `GenreChanged`, etc.
        *   `ArtistSection`: Display `state.productData.primaryArtists`. Use `buildArtistAutocomplete` which should dispatch `ArtistsChanged`.
        *   `ProductIdentityFields`: Display based on state. Callbacks dispatch `UpcChanged`, `AutoGenerateUpcChanged`, `LabelChanged`, `PriceTierChanged`. Use fetched labels (from BLoC or parent).
        *   `RightsFields`: Display based on state. Callbacks dispatch `CLineChanged`, `PLineChanged`, `CLineYearChanged`, `PLineYearChanged`.
*   **Save Button (`_buildSaveButton`):**
    *   Show loading indicator if `state.saveStatus == Status.saving`.
    *   Enable button based on `state.hasUnsavedChanges` AND `state.isInformationTabValid`.
    *   `onPressed` dispatches `ProductEvent.saveProductRequested()`.
*   **Validation:** Use `state.validationErrors` to show error messages on relevant fields.

**4.4 `UploadTab` / Mobile Upload Part Implementation:**

*   **Structure:** Can be `StatelessWidget`.
*   **Connect:** Read `ProductBloc` state using `BlocBuilder`.
*   **Build:**
    *   **Replicate `ReorderableListView`:** Build list using `state.productData.songs`.
        *   Display track title, artists, explicit tag using data from each `Track` object.
        *   Display upload progress bar *conditionally* if `track.fileName == state.trackUploadingFileName` and `state.trackUploadStatus == Status.uploading`, using `state.trackUploadProgress`.
        *   `onTap`: Navigate to `TrackEditor`/`MobileTrackEditor`, passing the `Track` object. Handle the returned updated `Track` via `Navigator.pop` result and dispatch `ProductEvent.trackUpdateReceived`.
        *   `onReorder`: Dispatch `ProductEvent.tracksReordered`.
    *   **Replicate Drag/Drop Area (`DottedBorder`, `DropTarget`) / Upload Button:**
        *   Visually style as per reference.
        *   `onDragDone` / `onPressed`: Dispatch `ProductEvent.uploadTrackFileRequested` for each file.
        *   Use `state.trackUploadStatus` to potentially disable or show global progress.

**4.5 `ReleaseTab` Implementation:**

*   **Structure:** `StatefulWidget` for local picker interactions.
*   **Connect:** Read `ProductBloc` state using `BlocBuilder`.
*   **Build:**
    *   **Replicate UI:** Date/time selection widgets, `CheckboxListTile` for time/rolling release, timezone `DropdownButtonFormField`, store selection `GridView`.
    *   Initialize UI values from `state.releaseDate`, `state.releaseTime`, `state.useSpecificTime`, `state.useRollingRelease`, `state.selectedTimeZone`, `state.selectedPlatforms`.
    *   **Interactions:** Callbacks dispatch corresponding `ProductEvent`s (`ReleaseDateChanged`, `UseSpecificTimeChanged`, `PlatformsSelectedChanged`, etc.).
    *   **Distribute Button:**
        *   Show loading if `state.distributionStatus == Status.distributing`.
        *   Enable based on `state.canDistribute` getter.
        *   `onPressed` dispatches `ProductEvent.distributeProductRequested()`.

**4.6 `TrackEditor` / `MobileTrackEditor` Implementation:**

*   **Structure:** `StatefulWidget` for controllers and audio player listeners.
*   **Provide BLoC:** Wrap root with `BlocProvider<TrackEditorBloc>`. Dispatch `InitializeRequested` in `create`, passing the `Track` object received via constructor.
*   **Connect:** Use `BlocBuilder<TrackEditorBloc, TrackEditorState>`.
*   **Build:**
    *   Show loading/error based on `state.status`.
    *   **Replicate UI EXACTLY:** `AudioPreview`, `TextField`s (`buildTextField`), `DropdownButtonFormField`s (Ownership, Country, Nationality), `SwitchListTile` (Explicit), Role Selectors (`_buildRoleSelector`), Lyrics Button, Save Button/FAB.
    *   Initialize controllers and UI elements from `state.trackData`. Update controllers conditionally in `BlocBuilder`.
*   **Interactions:** All `onChanged` callbacks dispatch the corresponding `TrackEditorEvent`.
*   **Audio Player:** Keep `AudioPlayerService` interaction logic within the `State` class, managed by listeners. Ensure `_initAudioPlayer` is called if the `trackData` in the BLoC state changes. Use `state.trackData` fields for metadata display in the preview.
*   **Save Button/FAB:**
    *   Show loading if `state.saveStatus == Status.saving`.
    *   Enable based on `state.isTrackValid` and `state.hasUnsavedChanges`.
    *   `onPressed` dispatches `TrackEditorEvent.saveTrackRequested()`.
*   **Save Success Handling:** Use `BlocListener<TrackEditorBloc, TrackEditorState>` to detect `state.saveStatus == Status.success`. When detected, call `Navigator.pop(context, state.trackData)` to return the saved data.

**Phase 5: Final Integration**

*   **Routing:** Ensure `GoRouter` routes (`/projects/:projectId/products/:productId` etc.) correctly instantiate `ProductBuilder` (or its parent) and provide the necessary arguments (`projectId`, `productId`, `isNewProduct`).
*   **DI Registration:** Verify `ProductBloc`, `TrackEditorBloc`, and all required Repository *implementations* are registered using `@injectable` / `@LazySingleton` and `configureDependencies` is called in `main.dart`. Run the build runner.
*   **Visual Polish:** Double-check fonts (`fontNameSemiBold`), colors (`Color(0xFF1E1B2C)`, etc.), padding, spacing, border radii, icons, and component layouts against the reference snippets to ensure exact replication. Pay attention to the appearance of dropdowns, text fields, buttons, list tiles, and the audio preview. Ensure mobile and desktop layouts match their respective reference implementations.

## Conclusion

Following these steps meticulously will allow the AI agent/developer to reconstruct the complex Product Builder UI with its distinct mobile and desktop variations, powered by a clean and maintainable BLoC architecture, without relying on any legacy code specifics. The key is to focus on replicating the visual end result while wiring the interactions and data flow through the defined BLoCs and Repositories.
```