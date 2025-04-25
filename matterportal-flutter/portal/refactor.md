Okay, this is a significant refactoring task. We need to shift from a stateful `ApiService` directly interacting potentially with UI logic (implied by its usage pattern) to a stateless data access layer (`ApiService`) used by BLoCs, and fundamentally change how product lists are retrieved and updated.

Here is an **ULTRA DETAILED, LONG, AND SPECIFIC** plan for an AI Agent to implement this refactoring:

**Goal:** Refactor the Flutter application's data layer (`ApiService`) to be BLoC compatible, implementing a real-time product list sourced from a Firestore index (`allProductsIndex`) within the user's catalog document.

**Core Architectural Shift:**

1.  **`ApiService` Role:** Becomes a stateless data provider. It performs Firestore operations (reads, writes, updates, deletes) and returns raw data (`Future<T>`, `Stream<T>`) or throws specific exceptions on failure. It **does not** manage application state, hold caches internally (unless strategically for *very* short-lived, non-state data like the `platformIds` map, which is fine), or interact with UI elements.
2.  **BLoC Layer:** Manages application state. BLoCs listen to user actions (Events), interact with the `ApiService` to fetch/modify data, and emit new States reflecting the current data, loading status, or errors.
3.  **UI Layer:** Reacts to BLoC states. Widgets use `BlocBuilder`, `BlocListener`, `BlocProvider` etc., to display data, show loading indicators, handle errors, and dispatch events to BLoCs based on user interaction.
4.  **Product Listing:** The primary mechanism for displaying lists of products will be a `Stream` from Firestore listening directly to the `catalog/{userId}` document, specifically targeting the `allProductsIndex` map field.
5.  **Product Index (`allProductsIndex`):**
    *   **Location:** `/catalog/{userId}` document.
    *   **Type:** Firestore `Map` field.
    *   **Keys:** Product IDs (`String`).
    *   **Values:** A nested `Map<String, dynamic>` for each product containing *essential listing data*:
        *   `productName`: `String`
        *   `productArtists`: `List<String>` (Names)
        *   `artworkUrl`: `String` (URL to cover image)
        *   `type`: `String` (e.g., 'Album', 'Single', 'EP')
        *   `releaseDate`: `Timestamp` (or `String` ISO 8601 - be consistent)
        *   `version`: `String` (e.g., 'Remastered', 'Live', '')
        *   `state`: `String` (e.g., 'Draft', 'Processing', 'Live', 'Error', 'Takedown')
        *   `originalPath`: `Map<String, String>` { `projectId`: "...", `productId`: "..." } (Crucial for linking back to the full product document)
        *   `projectId`: `String` (Redundant with originalPath, but useful for quick filtering/grouping if needed directly in the index)
        *   `trackCount`: `int` (Useful for display)
        *   `upc`: `String` (Maybe useful for quick checks, optional)
        *   `createdAt`: `Timestamp` (Optional, for sorting)
        *   `updatedAt`: `Timestamp` (For detecting changes)

**Phase 1: Setup and Foundation (BLoC & Models)**

1.  **Dependencies:** Ensure `flutter_bloc`, `equatable` (for BLoC states/events), `cloud_firestore`, `firebase_auth`, `http` are in `pubspec.yaml`.
2.  **Project Structure:** Organize code into features (e.g., `auth`, `catalog`, `artists`, `finance`, `settings`) with subdirectories for `bloc`, `data` (models, api service *interface* or implementation), and `presentation` (widgets/screens).
3.  **Core Models:**
    *   Define/Refine `Project`, `Artist`, `Songwriter`, `Track`, `Label`, `Product` models. Ensure they have `fromMap`, `toMap` methods and potentially use `copyWith` for easier state updates. Ensure `Product` can represent *both* the full detailed product *and* the subset of data used in the index.
    *   **Define `ProductIndexEntry` Model:** Create a specific Dart class (`ProductIndexEntry`) representing the structure of the value within the `allProductsIndex` map. Include `fromMap` and `toMap`.
        ```dart
        import 'package:cloud_firestore/cloud_firestore.dart';
        import 'package:equatable/equatable.dart';

        class ProductIndexEntry extends Equatable {
          final String productName;
          final List<String> productArtists;
          final String artworkUrl;
          final String type;
          final Timestamp releaseDate; // Or String
          final String version;
          final String state;
          final String projectId;
          final String productId; // The key in the map
          final int trackCount;
          final String? upc; // Optional
          final Timestamp? createdAt;
          final Timestamp updatedAt;

          const ProductIndexEntry({
            required this.productName,
            required this.productArtists,
            required this.artworkUrl,
            required this.type,
            required this.releaseDate,
            required this.version,
            required this.state,
            required this.projectId,
            required this.productId,
            required this.trackCount,
            this.upc,
            this.createdAt,
            required this.updatedAt,
          });

          // originalPath map is implicitly represented by projectId and productId

          factory ProductIndexEntry.fromMap(Map<String, dynamic> map, String id) {
            return ProductIndexEntry(
              productId: id, // Get the ID from the map key
              productName: map['productName'] ?? 'Unknown Product',
              productArtists: List<String>.from(map['productArtists'] ?? []),
              artworkUrl: map['artworkUrl'] ?? '',
              type: map['type'] ?? 'Unknown Type',
              // Handle Timestamp carefully - might be null initially
              releaseDate: map['releaseDate'] ?? Timestamp.now(), // Provide default or handle null
              version: map['version'] ?? '',
              state: map['state'] ?? 'Draft',
              projectId: map['projectId'] ?? '',
              trackCount: map['trackCount'] ?? 0,
              upc: map['upc'],
              createdAt: map['createdAt'],
              updatedAt: map['updatedAt'] ?? Timestamp.now(), // Provide default or handle null
            );
          }

          Map<String, dynamic> toMap() {
            return {
              'productName': productName,
              'productArtists': productArtists,
              'artworkUrl': artworkUrl,
              'type': type,
              'releaseDate': releaseDate,
              'version': version,
              'state': state,
              'projectId': projectId,
              // productId is the key, not stored in the value
              'trackCount': trackCount,
              'upc': upc,
              'createdAt': createdAt ?? FieldValue.serverTimestamp(), // Set on create
              'updatedAt': FieldValue.serverTimestamp(), // Always update on write
              // originalPath is derived, not stored directly here
            };
          }

          @override
          List<Object?> get props => [
                productId, productName, productArtists, artworkUrl, type,
                releaseDate, version, state, projectId, trackCount, upc,
                createdAt, updatedAt
              ];
        }
        ```
4.  **Authentication BLoC:** Create `AuthBloc`, `AuthEvent`, `AuthState`. Handle login, logout, user state changes. This BLoC will provide the essential `userId` needed by other BLoCs/ApiService.

**Phase 2: Refactor `ApiService` - Make it Stateless & BLoC-Friendly**

1.  **Remove State:** Delete all internal caches (`_projectCache`, `_productCache`, `_artistImageCache`). These will be managed by BLoCs or handled differently (e.g., product stream).
2.  **Remove `auth` Dependency:** Instead of `auth.getUser()`, methods requiring `userId` should accept it as a parameter. BLoCs will get the `userId` from the `AuthBloc`'s state and pass it to `ApiService` methods.
3.  **Return Types:**
    *   Methods fetching single items: `Future<Model?>` (e.g., `Future<Project?> getProjectById(...)`). Return `null` if not found.
    *   Methods fetching lists (not using the new index): `Future<List<Model>>` (e.g., `Future<List<Project>> getProjectsForUser(...)`). Return empty list if none found. Remove pagination logic from `ApiService` for non-streamed lists for now, or make it explicit via parameters (`startAfter`, `limit`). BLoCs will manage pagination state if needed.
    *   Methods performing writes/updates/deletes: `Future<void>` or `Future<String>` if an ID is generated/returned.
    *   **Crucially:** The *new* method for getting the product list will return a `Stream<List<ProductIndexEntry>>`.
4.  **Error Handling:** Replace `print` statements and generic `Exception`s with specific, custom exceptions (e.g., `ProductNotFoundException`, `FirestoreOperationException`, `AuthenticationRequiredException`). BLoCs will catch these and map them to error states.
5.  **Firestore Instance:** Keep `final db = FirebaseFirestore.instance;`. This is fine. Initialization happens in `main.dart`.
6.  **Refactor Method Signatures (Examples):**
    *   `getProjects` -> `Future<List<Project>> fetchProjects(String userId, {DocumentSnapshot? startAfter, int limit = 30})` (Keep pagination optional if still needed for projects separate from products).
    *   `getArtists` -> `Future<List<Artist>> fetchArtists(String userId, {DocumentSnapshot? startAfter, int limit = 30})` (Return `List<Artist>` model, not `QuerySnapshot`).
    *   `createProject` -> `Future<void> createProject(String userId, Project project)`
    *   `getArtistProfileImage` -> `Future<String?> fetchArtistImageUrl(String userId, String artistName)`
    *   `saveFcmTokenAndIp` -> `Future<void> saveFcmTokenAndIp(String userId, String fcmToken)` (Keep this, but BLoC triggers it).
    *   `createProduct`, `updateProduct`, `deleteProduct` -> These need *major* changes (See Phase 3).
    *   `distributeProduct` -> Needs major changes (See Phase 3).
    *   `getTracksForProduct` -> `Future<List<Track>> fetchTracksForProduct(String userId, String projectId, String productId)`
    *   `saveTrack` -> `Future<void> saveTrack(String userId, String projectId, String productId, String trackId, Map<String, dynamic> trackData)` (This still saves to the subcollection, but might need to trigger an index update if `trackCount` is in the index).
    *   `updateProductTrackCount` -> This logic will be integrated into `saveTrack`, `deleteTrack`, and potentially product updates.
    *   `getProduct` -> `Future<Product?> fetchProductDetails(String userId, String projectId, String productId)` (Fetches the *full* product from its original path).

**Phase 3: Implement Product Index Stream and CRUD Logic**

1.  **`ApiService`: Stream Product Index:**
    *   Create a new method: `Stream<List<ProductIndexEntry>> streamProducts(String userId)`
    *   **Implementation:**
        ```dart
        Stream<List<ProductIndexEntry>> streamProducts(String userId) {
          final userCatalogRef = db.collection('catalog').doc(userId);
          return userCatalogRef.snapshots().map((docSnapshot) {
            if (!docSnapshot.exists || docSnapshot.data() == null) {
              return <ProductIndexEntry>[]; // No catalog doc or empty
            }
            final data = docSnapshot.data()!;
            final indexMap = data['allProductsIndex'] as Map<String, dynamic>?; // Safely cast

            if (indexMap == null || indexMap.isEmpty) {
              return <ProductIndexEntry>[]; // Index field doesn't exist or is empty
            }

            // Convert the map values to ProductIndexEntry objects
            final entries = indexMap.entries.map((entry) {
              // entry.key is the productId
              // entry.value is the product data map
              try {
                 // Ensure the value is actually a map before passing
                 if (entry.value is Map<String, dynamic>) {
                    return ProductIndexEntry.fromMap(entry.value as Map<String, dynamic>, entry.key);
                 } else {
                    developer.log('Invalid data type in allProductsIndex for key ${entry.key}: ${entry.value?.runtimeType}', name: 'ApiService.streamProducts');
                    return null; // Skip invalid entries
                 }
              } catch (e, stackTrace) {
                developer.log('Error parsing product index entry for key ${entry.key}: $e', name: 'ApiService.streamProducts', error: e, stackTrace: stackTrace);
                return null; // Skip entries that cause parsing errors
              }
            }).whereType<ProductIndexEntry>().toList(); // Filter out nulls from errors/skips

            // Optional: Sort the list here if needed (e.g., by release date, name)
            entries.sort((a, b) => b.releaseDate.compareTo(a.releaseDate)); // Example: sort descending by date

            return entries;

          }).handleError((error, stackTrace) {
             developer.log('Error in product stream for user $userId: $error', name: 'ApiService.streamProducts', error: error, stackTrace: stackTrace);
             // Depending on BLoC strategy, you might re-throw or emit an empty list/error state
             // For simplicity here, let's return an empty list on stream error. BLoC should handle this.
             return <ProductIndexEntry>[];
             // Or: throw FirestoreOperationException('Failed to stream products: $error');
          });
        }
        ```

2.  **`ApiService`: Create Product:**
    *   Method: `Future<String> createProduct(String userId, String projectId, Product productData)`
    *   **Implementation:**
        *   Generate a new `productId` (e.g., `db.collection(...).doc().id`). Assign it to `productData.id`.
        *   Ensure `productData` has all necessary fields populated (UPC generation if auto, timestamps, etc.).
        *   Create the `ProductIndexEntry` data map from `productData`.
        *   **Use a `WriteBatch` for atomicity.**
        *   `batch.set(productDocRef, productData.toMap());` (Save full product to `/catalog/{userId}/projects/{projectId}/products/{productId}`)
        *   `batch.update(userCatalogRef, {'allProductsIndex.$productId': indexEntry.toMap()});` (Add entry to index using dot notation)
        *   `await batch.commit();`
        *   Return the `productId`.

3.  **`ApiService`: Update Product:**
    *   Method: `Future<void> updateProduct(String userId, String projectId, String productId, Map<String, dynamic> updateData)` (Or pass a full `Product` object).
    *   **Implementation:**
        *   Fetch the *current* full product data if needed to construct the updated index entry (or ensure `updateData` contains everything needed for the index).
        *   Create the *updated* `ProductIndexEntry` data map.
        *   **Use a `WriteBatch`.**
        *   `batch.update(productDocRef, updateData);` (Update specific fields in the full product document)
        *   `batch.update(userCatalogRef, {'allProductsIndex.$productId': updatedIndexEntry.toMap()});` (Overwrite the entry in the index with updated data)
        *   `await batch.commit();`

4.  **`ApiService`: Delete Product:**
    *   Method: `Future<void> deleteProduct(String userId, String projectId, String productId)`
    *   **Implementation:**
        *   **Use a `WriteBatch`.**
        *   `batch.delete(productDocRef);` (Delete the full product document)
        *   `batch.update(userCatalogRef, {'allProductsIndex.$productId': FieldValue.delete()});` (Remove the entry from the index map using `FieldValue.delete()`)
        *   `await batch.commit();`
        *   **Consider:** Also delete associated tracks and storage files (requires more complex logic, potentially a Cloud Function triggered by product deletion).

5.  **`ApiService`: Update Track Count (Integration):**
    *   Modify `saveTrack` and `deleteTrack`. After successfully saving/deleting a track *document*, they must also update the `trackCount` in the *product index*.
    *   **Inside `saveTrack` (after `trackRef.set`):**
        ```dart
        // ... save track document ...
        final count = (await trackCollectionRef.count().get()).count; // Use aggregate query
        await userCatalogRef.update({'allProductsIndex.$productId.trackCount': count, 'allProductsIndex.$productId.updatedAt': FieldValue.serverTimestamp()});
        ```
    *   **Inside `deleteTrack` (after `trackRef.delete`):**
        ```dart
        // ... delete track document ...
        final count = (await trackCollectionRef.count().get()).count; // Use aggregate query
        await userCatalogRef.update({'allProductsIndex.$productId.trackCount': count, 'allProductsIndex.$productId.updatedAt': FieldValue.serverTimestamp()});
        ```
    *   **Note:** Using `count()` is efficient. Ensure appropriate Firestore indexes are created if needed. Updating the index might be done via a Cloud Function triggered by track writes/deletes for better separation of concerns, but direct update is feasible.

6.  **`ApiService`: Distribute Product:**
    *   Method: `Future<void> distributeProduct(String userId, String projectId, String productId, List<String> selectedStores, ...)`
    *   **Implementation:**
        *   Fetch the full product data.
        *   Prepare the update data: `state: 'Processing'`, `platformsSelected`, `releaseDate`, etc.
        *   Prepare the *updated* `ProductIndexEntry` data, specifically changing the `state` field.
        *   **Use a `WriteBatch`.**
        *   `batch.update(productDocRef, updateDataForDistribution);` (Update the original product)
        *   `batch.update(userCatalogRef, {'allProductsIndex.$productId': updatedIndexEntry.toMap()});` (Update the index entry, crucially updating the state)
        *   `batch.set(pendingRef, fullProductDataWithDistributionInfo);` (Write to `_private/{userId}/pending/{productId}`)
        *   `await batch.commit();`

**Phase 4: Implement BLoCs**

1.  **`CatalogBloc` (or `ProductsBloc`):**
    *   **Dependencies:** `ApiService`, `AuthBloc` (to get userId).
    *   **Events:** `LoadProducts`, `_ProductsUpdated` (internal event triggered by the stream), `AddProduct`, `UpdateProduct`, `DeleteProduct`, `DistributeProduct`.
    *   **States:** `CatalogInitial`, `CatalogLoading`, `CatalogLoaded(List<ProductIndexEntry> products)`, `CatalogError(String message)`.
    *   **Logic:**
        *   On `LoadProducts`: Get `userId`. Subscribe to `apiService.streamProducts(userId)`. On each emission from the stream, add `_ProductsUpdated(products)` event. Handle stream errors. Emit `CatalogLoading` initially, then `CatalogLoaded` on first data, `CatalogError` on stream error.
        *   On `_ProductsUpdated`: Emit `CatalogLoaded(products)`.
        *   On `AddProduct`: Call `apiService.createProduct(...)`. Handle success/failure. (Stream will automatically update the list). Show temporary loading/feedback via state if needed.
        *   On `UpdateProduct`: Call `apiService.updateProduct(...)`. Handle success/failure.
        *   On `DeleteProduct`: Call `apiService.deleteProduct(...)`. Handle success/failure.
        *   On `DistributeProduct`: Call `apiService.distributeProduct(...)`. Handle success/failure.

2.  **`ProductDetailsBloc`:**
    *   **Dependencies:** `ApiService`, `AuthBloc`.
    *   **Events:** `LoadProductDetails(projectId, productId)`, `LoadTracks`, `AddTrack`, `UpdateTrack`, `DeleteTrack`, `UpdateProductDetails`.
    *   **States:** `ProductDetailsInitial`, `ProductDetailsLoading`, `ProductDetailsLoaded(Product product, List<Track> tracks)`, `ProductDetailsError`.
    *   **Logic:**
        *   On `LoadProductDetails`: Get `userId`. Call `apiService.fetchProductDetails(...)`. If successful, potentially trigger `LoadTracks`. Emit states.
        *   On `LoadTracks`: Get `userId`, `projectId`, `productId`. Call `apiService.fetchTracksForProduct(...)`. Emit `ProductDetailsLoaded` with updated tracks.
        *   On `AddTrack`: Call `apiService.saveTrack(...)`. On success, trigger `LoadTracks` to refresh.
        *   On `UpdateTrack`: Call `apiService.saveTrack(...)` (or `updateMultipleTracks`). On success, trigger `LoadTracks`.
        *   On `DeleteTrack`: Call `apiService.deleteTrack(...)`. On success, trigger `LoadTracks`.
        *   On `UpdateProductDetails`: Call `apiService.updateProduct(...)`. On success, trigger `LoadProductDetails` to refresh.

3.  **Other BLoCs:** Create similar BLoCs for `Projects`, `Artists`, `Songwriters`, `Finance`, `Settings/Profile`, `Sessions` etc., following the pattern: Event -> BLoC interacts with `ApiService` -> BLoC emits new State.

**Phase 5: Integrate with UI**

1.  **`main.dart`:** Wrap the app in `MultiBlocProvider` to provide essential BLoCs like `AuthBloc`, `CatalogBloc`.
2.  **Product List Screen:**
    *   Use `BlocProvider` (if needed locally) or access `CatalogBloc` from context.
    *   Use `BlocBuilder<CatalogBloc, CatalogState>` to build the UI.
    *   Show `CircularProgressIndicator` when state is `CatalogLoading`.
    *   Show error message when state is `CatalogError`.
    *   Build `ListView` (or similar) when state is `CatalogLoaded`, using the `products` list (`List<ProductIndexEntry>`). Each item displays data from `ProductIndexEntry`.
    *   Buttons (Add, Delete, Edit) dispatch events to `CatalogBloc`.
    *   Tapping an item navigates to the Product Details screen, passing `projectId` and `productId`.
3.  **Product Details Screen:**
    *   Wrap with `BlocProvider<ProductDetailsBloc>`.
    *   Dispatch `LoadProductDetails(projectId, productId)` in `initState` or via an initial event.
    *   Use `BlocBuilder<ProductDetailsBloc, ProductDetailsState>` to display product details and tracks from the `ProductDetailsLoaded` state.
    *   Buttons for saving changes, adding/deleting tracks dispatch events to `ProductDetailsBloc`.
4.  **Other Screens:** Refactor all screens to use their respective BLoCs for data fetching and state management.

**Phase 6: Refactor Remaining Features**

1.  Systematically go through *every* method in the old `ApiService`.
2.  For each method:
    *   Ensure its `ApiService` counterpart is stateless and accepts `userId` if needed.
    *   Identify the appropriate BLoC to manage the state related to this feature.
    *   Create necessary Events and States in the BLoC.
    *   Implement the logic in the BLoC to call the `ApiService` method and emit states.
    *   Refactor the UI widgets to use the new BLoC via `BlocBuilder`/`BlocListener`.
3.  **Specific Attention:**
    *   **Caching:** Re-evaluate caching. Artist images *could* still be cached locally by an `ArtistBloc` or a dedicated image caching service, but avoid caching large, frequently changing lists in the `ApiService`. The product stream *is* the real-time cache.
    *   **Pagination:** If pagination is still needed for things like Projects or Artists (not handled by the product index stream), the BLoC should manage the `lastDocument` state and pass it to the `ApiService` fetch methods.
    *   **Finance/Sessions:** Apply the same BLoC pattern. `FinanceBloc`, `SessionBloc`.

**Phase 7: Testing and Refinement**

1.  **Unit Tests:** Test BLoC logic (given event, expect specific state sequence) using `bloc_test`. Mock `ApiService`. Test `ApiService` methods by mocking `FirebaseFirestore` (using `fake_cloud_firestore` or manual mocks). Test model `fromMap`/`toMap`.
2.  **Widget Tests:** Test UI widgets' reactions to different BLoC states.
3.  **Integration Tests:** Test key user flows involving UI, BLoCs, and `ApiService` interactions (potentially with `fake_cloud_firestore`).
4.  **Firestore Rules:** Update Firestore security rules to allow reads of `/catalog/{userId}` document (specifically the `allProductsIndex` field) and writes based on authentication. Secure product subcollections and other areas (`artists`, `songwriters`, `_private`, `finance`).
5.  **Index Size:** Monitor the size of the `catalog/{userId}` document. Firestore documents have a 1 MiB limit. If a user has *thousands* of products, the `allProductsIndex` map could exceed this. If this becomes a concern, strategies might include:
    *   Splitting the index (e.g., `allProductsIndex_A-M`, `allProductsIndex_N-Z`).
    *   Using a dedicated top-level collection for the index (e.g., `/userProductIndex/{userId}/products/{productId}`). This loses the atomicity of updating the user doc and the index in one go unless using transactions carefully.
    *   Relying more on Collection Group queries (though these might be slower for general listing and don't offer real-time updates as easily as a single document stream). *For now, assume the single document index is feasible.*
6.  **Performance:** Profile the app. Ensure stream parsing and list building are efficient. Optimize Firestore queries.

**Phase 8: Deployment & Monitoring**

1.  Deploy the refactored application.
2.  Monitor Firestore usage (reads, writes, document size).
3.  Monitor application performance and errors (e.g., using Firebase Crashlytics, Performance Monitoring).

This detailed plan provides a roadmap for the AI agent. Each step involves careful implementation, adherence to BLoC principles, and thorough testing to ensure the refactored application is robust, maintainable, and provides the desired real-time product updates. The most critical part is correctly implementing the read stream and the atomic write operations involving both the product document and the `allProductsIndex`.