import 'package:flutter_test/flutter_test.dart';
import 'package:kudlit_ph/app/constants.dart';
import 'package:kudlit_ph/app/router/app_router.dart';

void main() {
  group('isGuestAccessibleRoute', () {
    test('allows guest learn study surfaces', () {
      expect(isGuestAccessibleRoute(AppConstants.routeHome), isTrue);
      expect(isGuestAccessibleRoute(AppConstants.routeSettings), isTrue);
      expect(
        isGuestAccessibleRoute(AppConstants.routeCharacterGallery),
        isTrue,
      );
      expect(isGuestAccessibleRoute(AppConstants.routeQuiz), isTrue);
      expect(
        isGuestAccessibleRoute('${AppConstants.routeLesson}/vowels-01'),
        isTrue,
      );
      expect(isGuestAccessibleRoute('${AppConstants.routeLesson}/:id'), isTrue);
    });

    test('keeps account data and admin surfaces protected for guests', () {
      expect(isGuestAccessibleRoute(AppConstants.routeScanHistory), isFalse);
      expect(
        isGuestAccessibleRoute(AppConstants.routeTranslationHistory),
        isFalse,
      );
      expect(
        isGuestAccessibleRoute(AppConstants.routeLearningProgress),
        isFalse,
      );
      expect(isGuestAccessibleRoute(AppConstants.routeButtyData), isFalse);
      expect(
        isGuestAccessibleRoute(AppConstants.routeAdminStrokeRecorder),
        isFalse,
      );
    });
  });
}
