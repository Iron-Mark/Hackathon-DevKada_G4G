import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:kudlit_ph/app/constants.dart';
import 'package:kudlit_ph/app/router/router_listenable.dart';
import 'package:kudlit_ph/core/auth/user_role.dart';
import 'package:kudlit_ph/features/auth/domain/entities/auth_user.dart';
import 'package:kudlit_ph/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:kudlit_ph/features/auth/presentation/screens/home_screen.dart';
import 'package:kudlit_ph/features/auth/presentation/screens/login_screen.dart';
import 'package:kudlit_ph/features/auth/presentation/screens/privacy_policy_screen.dart';
import 'package:kudlit_ph/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:kudlit_ph/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:kudlit_ph/features/auth/presentation/screens/terms_screen.dart';
import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';
import 'package:kudlit_ph/features/home/presentation/screens/model_setup_screen.dart';
import 'package:kudlit_ph/features/home/presentation/screens/settings_screen.dart';
import 'package:kudlit_ph/features/home/presentation/screens/splash_screen.dart';
import 'package:kudlit_ph/features/learning/presentation/screens/lesson_stage_screen.dart';
import 'package:kudlit_ph/features/admin/presentation/screens/stroke_recording_screen.dart';
import 'package:kudlit_ph/features/learning/presentation/screens/character_gallery_screen.dart';
import 'package:kudlit_ph/features/learning/presentation/screens/quiz_screen.dart';
import 'package:kudlit_ph/features/home/presentation/screens/butty_data_screen.dart';
import 'package:kudlit_ph/features/home/presentation/screens/learning_progress_screen.dart';
import 'package:kudlit_ph/features/home/presentation/screens/translation_history_screen.dart';
import 'package:kudlit_ph/features/scanner/presentation/screens/scan_history_screen.dart';

part 'app_router.g.dart';

@visibleForTesting
bool isGuestAccessibleRoute(String matchedLocation) {
  return matchedLocation == AppConstants.routeHome ||
      matchedLocation == AppConstants.routeSettings ||
      matchedLocation == AppConstants.routeCharacterGallery ||
      matchedLocation == AppConstants.routeQuiz ||
      matchedLocation == AppConstants.routeLesson ||
      matchedLocation.startsWith('${AppConstants.routeLesson}/');
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final RouterListenable listenable = ref.watch(routerListenableProvider);

  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    refreshListenable: listenable,
    redirect: (BuildContext context, GoRouterState state) {
      final AsyncValue<AuthUser?> authState = listenable.authState;
      final AsyncValue<AppPreferences> prefsState = listenable.prefsState;
      final bool isAuthenticated =
          authState.hasValue && authState.value != null;

      // Password recovery: a `passwordRecovery` event from Supabase establishes
      // a session but the user has not chosen a new password yet. Force the
      // dedicated reset-password screen until the flow completes. This must
      // run before any other redirect so a cached session can't bounce the
      // user to /home and skip the password update.
      if (listenable.passwordRecoveryPending &&
          state.matchedLocation != AppConstants.routeResetPassword) {
        return AppConstants.routeResetPassword;
      }

      // Splash: hold while loading, then route to correct destination.
      if (state.matchedLocation == AppConstants.routeSplash) {
        if (authState.isLoading || prefsState.isLoading) return null;
        final AppPreferences? prefs = prefsState.value;
        // Show model setup if models are not yet ready and the user has not
        // already acknowledged the prompt (legacy skip or completed setup).
        final bool needsModelSetup =
            !(prefs?.hasDownloadedModels ?? false) &&
            !(prefs?.hasSeenModelPrompt ?? false) &&
            !listenable.sessionSkipped;
        if (needsModelSetup) return AppConstants.routeModelSetup;
        return isAuthenticated
            ? AppConstants.routeHome
            : AppConstants.routeLogin;
      }

      // Model setup: hold if loading; skip if already handled.
      if (state.matchedLocation == AppConstants.routeModelSetup) {
        if (authState.isLoading || prefsState.isLoading) {
          return AppConstants.routeSplash;
        }
        final AppPreferences? prefs = prefsState.value;
        final bool handled =
            (prefs?.hasDownloadedModels ?? false) ||
            (prefs?.hasSeenModelPrompt ?? false) ||
            listenable.sessionSkipped;
        if (handled) {
          return isAuthenticated
              ? AppConstants.routeHome
              : AppConstants.routeLogin;
        }
        return null; // stay on setup
      }

      // Still loading auth on other routes — don't redirect.
      if (authState.isLoading) return null;

      // Admin route gate: only allow users whose `profiles.role == admin`.
      // Default-deny while the role is still loading or on error so a
      // non-admin can't briefly slip through during the async resolve.
      if (state.matchedLocation == AppConstants.routeAdminStrokeRecorder) {
        if (!isAuthenticated) return AppConstants.routeLogin;
        final AsyncValue<UserRole> roleState = listenable.roleState;
        final bool isAdmin =
            roleState.hasValue && (roleState.value?.isAdmin ?? false);
        if (!isAdmin) return AppConstants.routeHome;
      }

      final bool isOnAuthRoute =
          state.matchedLocation == AppConstants.routeLogin ||
          state.matchedLocation == AppConstants.routeSignUp ||
          state.matchedLocation == AppConstants.routeForgotPassword ||
          state.matchedLocation == AppConstants.routeAuthReset ||
          state.matchedLocation == AppConstants.routeTerms ||
          state.matchedLocation == AppConstants.routePrivacyPolicy;

      if (!isAuthenticated &&
          !isOnAuthRoute &&
          !isGuestAccessibleRoute(state.matchedLocation)) {
        return AppConstants.routeLogin;
      }
      if (isAuthenticated && isOnAuthRoute) return AppConstants.routeHome;
      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.routeModelSetup,
        builder: (BuildContext context, GoRouterState state) =>
            const ModelSetupScreen(),
      ),
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeSignUp,
        builder: (BuildContext context, GoRouterState state) =>
            const SignUpScreen(),
      ),
      GoRoute(
        path: AppConstants.routeForgotPassword,
        builder: (BuildContext context, GoRouterState state) =>
            const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppConstants.routeHome,
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(),
      ),
      GoRoute(
        // OAuth callback (Google) lands here; password-recovery sessions are
        // intercepted by the top-level redirect above and forwarded to
        // `/reset-password` before this builder is reached.
        path: AppConstants.routeAuthReset,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeResetPassword,
        builder: (BuildContext context, GoRouterState state) =>
            const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppConstants.routeSettings,
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsScreen(),
      ),
      GoRoute(
        path: '${AppConstants.routeLesson}/:id',
        builder: (BuildContext context, GoRouterState state) =>
            LessonStageScreen(lessonId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppConstants.routeTerms,
        builder: (BuildContext context, GoRouterState state) =>
            const TermsScreen(),
      ),
      GoRoute(
        path: AppConstants.routePrivacyPolicy,
        builder: (BuildContext context, GoRouterState state) =>
            const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAdminStrokeRecorder,
        builder: (BuildContext context, GoRouterState state) =>
            const StrokeRecordingScreen(),
      ),
      GoRoute(
        path: AppConstants.routeCharacterGallery,
        builder: (BuildContext context, GoRouterState state) =>
            const CharacterGalleryScreen(),
      ),
      GoRoute(
        path: AppConstants.routeQuiz,
        builder: (BuildContext context, GoRouterState state) =>
            const QuizScreen(),
      ),
      GoRoute(
        path: AppConstants.routeScanHistory,
        builder: (BuildContext context, GoRouterState state) =>
            const ScanHistoryScreen(),
      ),
      GoRoute(
        path: AppConstants.routeTranslationHistory,
        builder: (BuildContext context, GoRouterState state) =>
            const TranslationHistoryScreen(),
      ),
      GoRoute(
        path: AppConstants.routeLearningProgress,
        builder: (BuildContext context, GoRouterState state) =>
            const LearningProgressScreen(),
      ),
      GoRoute(
        path: AppConstants.routeButtyData,
        builder: (BuildContext context, GoRouterState state) =>
            const ButtyDataScreen(),
      ),
    ],
  );
}
