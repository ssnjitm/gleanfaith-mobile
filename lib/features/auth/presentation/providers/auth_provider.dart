import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/providers/core_providers.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/register_request.dart';
import '../../domain/usecases/verify_otp.dart';
import '../../domain/usecases/resend_otp.dart';
import '../../domain/usecases/forgot_password.dart';
import '../../domain/usecases/reset_password.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/get_current_user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? message;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.message,
  });

  AuthState copyWith({AuthStatus? status, User? user, String? message}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return AuthRepositoryImpl(
    AuthRemoteDataSource(dio),
    storage,
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerRequestUseCaseProvider = Provider<RegisterRequestUseCase>((ref) {
  return RegisterRequestUseCase(ref.watch(authRepositoryProvider));
});

final verifyOtpUseCaseProvider = Provider<VerifyOtpUseCase>((ref) {
  return VerifyOtpUseCase(ref.watch(authRepositoryProvider));
});

final resendOtpUseCaseProvider = Provider<ResendOtpUseCase>((ref) {
  return ResendOtpUseCase(ref.watch(authRepositoryProvider));
});

final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>((ref) {
  return ForgotPasswordUseCase(ref.watch(authRepositoryProvider));
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  return ResetPasswordUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, message: null);
    final result = await _ref.read(loginUseCaseProvider).call(email, password).run();
    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        message: failure.message,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<String?> registerRequest({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, message: null);
    final result = await _ref.read(registerRequestUseCaseProvider).call(
      email: email,
      password: password,
      fullName: fullName,
      username: username,
    ).run();
    return result.fold(
      (failure) {
        state = state.copyWith(status: AuthStatus.error, message: failure.message);
        return failure.message;
      },
      (_) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return null;
      },
    );
  }

  Future<String?> verifyOtp(String email, String otp) async {
    state = state.copyWith(status: AuthStatus.loading, message: null);
    final result = await _ref.read(verifyOtpUseCaseProvider).call(email, otp).run();
    return result.fold(
      (failure) {
        state = state.copyWith(status: AuthStatus.error, message: failure.message);
        return failure.message;
      },
      (_) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return null;
      },
    );
  }

  Future<String?> resendOtp(String email) async {
    state = state.copyWith(status: AuthStatus.loading, message: null);
    final result = await _ref.read(resendOtpUseCaseProvider).call(email).run();
    return result.fold(
      (failure) {
        state = state.copyWith(status: AuthStatus.error, message: failure.message);
        return failure.message;
      },
      (_) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return null;
      },
    );
  }

  Future<String?> forgotPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, message: null);
    final result = await _ref.read(forgotPasswordUseCaseProvider).call(email).run();
    return result.fold(
      (failure) {
        state = state.copyWith(status: AuthStatus.error, message: failure.message);
        return failure.message;
      },
      (_) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return null;
      },
    );
  }

  Future<String?> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, message: null);
    final result = await _ref.read(resetPasswordUseCaseProvider).call(
      email: email,
      otp: otp,
      newPassword: newPassword,
    ).run();
    return result.fold(
      (failure) {
        state = state.copyWith(status: AuthStatus.error, message: failure.message);
        return failure.message;
      },
      (_) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return null;
      },
    );
  }

  Future<void> logout() async {
    await _ref.read(logoutUseCaseProvider).call().run();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> checkAuth() async {
    final hasToken = await _ref.read(storageProvider).containsKey('auth_token');
    if (hasToken) {
      final result = await _ref.read(getCurrentUserUseCaseProvider).call().run();
      result.fold(
        (_) => state = const AuthState(status: AuthStatus.unauthenticated),
        (user) => state = AuthState(status: AuthStatus.authenticated, user: user),
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void clearMessage() {
    state = state.copyWith(message: null);
  }
}
