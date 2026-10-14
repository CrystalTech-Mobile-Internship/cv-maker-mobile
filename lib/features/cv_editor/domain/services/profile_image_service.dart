/// Selects a profile image and stores an app-owned offline copy.
abstract interface class ProfileImageService {
  Future<String?> pickAndStoreImage();
}
