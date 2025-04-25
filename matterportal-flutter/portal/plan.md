# Backend Service (ApiService) BLoC Reimplementation Plan

This checklist is focused on reimplementing the core backend service (ApiService) logic in the new app using beautiful, robust BLoC state management. UI is not a priority yet—focus is on clean architecture, modularity, and testability.

## :dart: Objective
- Rebuild the Firestore-backed product and track management logic from `refactor.md` using BLoC for all stateful operations.
- Ensure all operations (CRUD, batch, index sync) are transactional, testable, and provide clear state updates (loading, success, error).

---

## :white_check_mark: Checklist

### 1. Project Structure
- [x] Create `bloc/api_service/` directory for all ApiService-related BLoC code.
- [x] Define `ApiService` in `lib/services/api_service.dart` (or similar).
- [x] Separate data models (e.g., Product, Track, IndexEntry) into their own files.

### 2. Data Models
- [x] Define `Product`, `Track`, and `IndexEntry` models with `fromMap`/`toMap` methods.
- [x] Add serialization/deserialization and equality overrides.

### 3. ApiService Core Logic
- [x] Implement Firestore CRUD methods for:
    - [x] Create Product (with batch index update)
    - [x] Update Product (with batch index update)
    - [x] Delete Product (with batch index removal; plan for future track/file cleanup)
    - [x] Save Track (and update track count in index)
    - [x] Delete Track (and update track count in index)
- [x] Ensure all methods throw clear exceptions on error.

### 4. BLoC Layer
- [x] For each operation (create, update, delete, etc.):
    - [x] Define Events (e.g., `CreateProduct`, `DeleteProduct`, `SaveTrack`, etc.)
    - [x] Define States (Initial, Loading, Success, Failure, etc.)
    - [x] Implement `ApiServiceBloc` to handle all events and emit appropriate states.
    - [x] Provide error details and loading indicators via state.
- [x] Ensure BLoC is modular and testable (no direct UI dependencies).

### 5. Testing
- [ ] Write unit tests for all ApiService methods (mock Firestore).
- [ ] Write BLoC tests for all events and state transitions.

### 6. Documentation
- [ ] Document all BLoC events, states, and major service methods.
- [ ] Add code comments for complex Firestore batch/transaction logic.

---

## :rocket: Next Steps
Once the backend logic and BLoC are robust and tested, proceed to integrate with UI screens.

---

*This checklist is for internal/AI use to ensure a beautiful, maintainable, and scalable backend service in the new app. UI and navigation will be addressed after state management is solid.*
