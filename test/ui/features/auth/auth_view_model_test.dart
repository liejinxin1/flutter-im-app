import 'package:agora_im_flutter/ui/core/localization/app_error.dart';
import 'package:agora_im_flutter/ui/features/auth/view_models/auth_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  group('AuthViewModel', () {
    test('restores a cached session', () async {
      final session = FakeSessionRepository()..restoreUserId = 'alice';
      addTearDown(session.dispose);
      final viewModel = AuthViewModel(session);
      addTearDown(viewModel.dispose);

      await viewModel.restoreSession();

      expect(viewModel.userId, 'alice');
      expect(viewModel.isRestoring, isFalse);
    });

    test('clears the session when the SDK invalidates it', () async {
      final session = FakeSessionRepository()..restoreUserId = 'alice';
      addTearDown(session.dispose);
      final viewModel = AuthViewModel(session);
      addTearDown(viewModel.dispose);

      await viewModel.restoreSession();
      session.invalidate();
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.userId, isNull);
      expect(viewModel.error?.code, AppErrorCode.sessionExpired);
    });

    test('validates empty credentials before calling the SDK', () async {
      final session = FakeSessionRepository();
      addTearDown(session.dispose);
      final viewModel = AuthViewModel(session);
      addTearDown(viewModel.dispose);

      final success = await viewModel.login(
        userId: '  ',
        credential: '',
        usePassword: true,
      );

      expect(success, isFalse);
      expect(viewModel.error?.code, AppErrorCode.missingPasswordCredentials);
      expect(session.loginCalls, 0);
    });

    test('surfaces login failures and succeeds on retry', () async {
      final session = FakeSessionRepository()
        ..loginError = Exception('bad credentials');
      addTearDown(session.dispose);
      final viewModel = AuthViewModel(session);
      addTearDown(viewModel.dispose);

      final failed = await viewModel.login(
        userId: 'alice',
        credential: 'wrong',
        usePassword: true,
      );
      expect(failed, isFalse);
      expect(viewModel.userId, isNull);
      expect(viewModel.error?.detail, contains('bad credentials'));

      session.loginError = null;
      final success = await viewModel.login(
        userId: 'alice',
        credential: 'right',
        usePassword: true,
      );

      expect(success, isTrue);
      expect(viewModel.userId, 'alice');
      expect(session.loggedInUserId, 'alice');
    });
  });
}
