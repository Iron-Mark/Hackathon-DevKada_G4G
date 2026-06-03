class AppConstants {
  const AppConstants._();

  static const String appName = 'Kudlit';

  static const String routeSplash = '/';
  static const String routeModelSetup = '/model-setup';
  static const String routeLogin = '/login';
  static const String routeSignUp = '/sign-up';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeHome = '/home';
  static const String routeSettings = '/settings';
  static const String routeAuthReset = '/auth/reset';
  static const String routeResetPassword = '/reset-password';
  static const String routeLesson = '/learn/lesson';
  static const String routeTerms = '/terms';
  static const String routePrivacyPolicy = '/privacy-policy';
  static const String routeAdminStrokeRecorder = '/admin/stroke-recorder';
  static const String routeCharacterGallery = '/learn/gallery';
  static const String routeQuiz = '/learn/quiz';
  static const String routeScanHistory = '/scan-history';
  static const String routeTranslationHistory = '/translation-history';
  static const String routeLearningProgress = '/learning-progress';
  static const String routeButtyData = '/butty-data';

  static const String loginTitle = appName;
  static const String loginSubtitle =
      'Read Baybayin, practice kudlit marks, and keep your progress ready '
      'for every session.';
  static const String loginHelper =
      'Sign in to continue to the Kudlit learning and translation tools.';
  static const String loginAction = 'Sign In';
  static const String forgotPasswordAction = 'Forgot password?';
  static const String noAccountPrompt = 'Don\'t have an account?';
  static const String createOneAction = 'Create one';

  static const String signUpHeading = 'Join Kudlit';
  static const String signUpSubtitle =
      'Create an account to start translating Baybayin.';
  static const String signUpAction = 'Create Account';
  static const String existingAccountPrompt = 'Already have an account?';
  static const String backToSignInAction = 'Back to Sign In';

  static const String createAccountTitle = 'Create Account';
  static const String resetPasswordTitle = 'Reset Password';
  static const String resetPasswordSubtitle =
      'Enter your email to receive a reset link.';
  static const String sendResetEmailAction = 'Send Reset Email';
  static const String backToLoginAction = 'Back to login';
  static const String signOutTooltip = 'Sign out';
  static const String welcomeMessagePrefix = 'Welcome, ';
  static const String confirmationTitle = 'Check your inbox';
  static const String confirmationMessage =
      'We sent a confirmation link to your email. '
      'Click it to activate your account.';

  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String confirmPasswordLabel = 'Confirm Password';

  static const String unexpectedError = 'Unexpected error. Please try again.';
  static const String unexpectedErrorOccurred = 'An unexpected error occurred.';
  static const String networkErrorPrefix = 'Network error: ';
  static const String noAccountFoundMessage =
      'No account found with this email.';
  static const String emailAlreadyInUseMessage =
      'An account with this email already exists.';
  static const String weakPasswordMessage =
      'Password is too weak. Use at least 6 characters.';
  static const String weakPasswordShortMessage = 'Password is too weak.';
  static const String tooManyAttemptsMessage =
      'Too many attempts. Please wait.';
  static const String tooManyRequestsMessage =
      'Too many requests. Please wait.';
  static const String invalidCredentialsMessage = 'Invalid email or password.';
  static const String sessionExpiredMessage =
      'Session expired. Please sign in again.';
  static const String passwordResetEmailSentMessage =
      'Password reset email sent.';
  static const String resetEmailSentSuccessMessage =
      'Check your email for a reset link.';

  static const String emailRequiredMessage = 'Email is required.';
  static const String invalidEmailMessage = 'Enter a valid email address.';
  static const String passwordRequiredMessage = 'Password is required.';
  static const String confirmPasswordRequiredMessage =
      'Confirm password is required.';
  static const String passwordTooShortMessage =
      'Password must be at least 6 characters.';
  static const String passwordsDoNotMatchMessage = 'Passwords do not match.';
}
