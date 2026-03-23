import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfile();
});

final technicianStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getTechnicianStats();
});

final updateProfileProvider =
    StateNotifierProvider<UpdateProfileNotifier, UpdateProfileState>(
  (ref) => UpdateProfileNotifier(ref.watch(profileRepositoryProvider)),
);

class UpdateProfileNotifier extends StateNotifier<UpdateProfileState> {
  final ProfileRepository _profileRepository;

  UpdateProfileNotifier(this._profileRepository)
      : super(const UpdateProfileState.initial());

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    state = const UpdateProfileState.loading();
    try {
      final result = await _profileRepository.updateProfile(
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      state = UpdateProfileState.success(result);
    } catch (e) {
      state = UpdateProfileState.error(e.toString());
    }
  }

  void reset() {
    state = const UpdateProfileState.initial();
  }
}

sealed class UpdateProfileState {
  const UpdateProfileState();

  const factory UpdateProfileState.initial() = _Initial;
  const factory UpdateProfileState.loading() = _Loading;
  const factory UpdateProfileState.success(Map<String, dynamic> profile) =
      _Success;
  const factory UpdateProfileState.error(String message) = _Error;
}

class _Initial extends UpdateProfileState {
  const _Initial();
}

class _Loading extends UpdateProfileState {
  const _Loading();
}

class _Success extends UpdateProfileState {
  final Map<String, dynamic> profile;

  const _Success(this.profile);
}

class _Error extends UpdateProfileState {
  final String message;

  const _Error(this.message);
}

extension UpdateProfileStateX on UpdateProfileState {
  bool get isLoading {
    return switch (this) {
      _Loading() => true,
      _ => false,
    };
  }

  String? get errorMessage {
    return switch (this) {
      _Error(:final message) => message,
      _ => null,
    };
  }

  Map<String, dynamic>? get updatedProfile {
    return switch (this) {
      _Success(:final profile) => profile,
      _ => null,
    };
  }
}
