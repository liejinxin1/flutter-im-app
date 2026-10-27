# Project guidance

## Scope

Build the Agora Chat client for Android and iOS first. Flutter Web may share presentation code, but the Agora Flutter plugin is native-only; Web messaging requires a separate Chat Web SDK adapter.

Currently implemented: password/token login, inbox, direct and group conversations, paginated history, text/image/voice messages, a sealed SDK-agnostic `ChatMessageContent` model (file/video/location/contact/custom/system/unknown are mapped or safely fall back), send status and retry, incoming updates, unread/read state, contacts and persistent friend requests, group creation, go_router navigation, account-scoped offline cache, persistent outbox replay, cached user profiles (nickname/avatar/remark), English/Chinese UI, and responsive phone/wide layouts. Do not add registration, audio/video calling, or push notifications until separately scoped. Deferred items and the RTC plan live in `docs/architecture.md`.

## Architecture

Use a feature-first MVVM structure with strict data boundaries:

```text
lib/
  app/                 # app bootstrap, go_router, root navigator key, dependency wiring, coordinators
  domain/
    models/            # immutable app-owned models
    repositories/      # repository contracts
    services/          # ChatService, MediaGateway, ApiClient, LocalStore, UserDirectory
    errors/            # AppFailure + friendlyError
  data/
    local/             # account-scoped cache, outbox, profile cache, friend-request store
    services/          # Agora adapter, callback streams, HTTP client, platform adapters
    repositories/      # data entry points for ViewModels; cache/outbox live here
  l10n/                # ARB files + generated AppLocalizations
  previews/            # @Preview pages + in-memory fakes
  ui/
    core/              # theme, layout, localization, shared widgets, ViewModel base
    features/
      auth/            # password/token login and session state
      inbox/           # conversation list, unread state, profile enrichment
      conversation/    # timeline, composer, message actions, outbox-aware pending messages
      contacts/        # contacts, friend requests, persisted pending requests
      groups/          # group creation
      profile/ more/ shell/
```

- Views render state and forward user actions. Keep SDK calls, plugin calls, file-system access, and data transformations out of widgets.
- ViewModels own screen state and depend on repository/service interfaces, not the Agora SDK.
- The Agora adapter maps SDK objects to `domain` models; repositories are the only data entry point for ViewModels. Add caching, paging, and offline queues there, not in widgets.
- `domain/services/chat_service.dart` is the transport seam. Repositories and `ChatConnection` depend on it; only `data/services` may import a concrete IM SDK.
- Application messages use `ChatMessageContent` + `ChatMessageEnvelope` (`app.im.message`). `MESSAGE_TRANSPORT` controls native/custom/hybrid behavior; attachments must never leak local paths. See `docs/message-protocol.md`.
- Application REST calls go through `domain/services/api_client.dart`; UI/ViewModels must not import `package:http` directly. Agora Chat traffic stays inside the Chat SDK adapter.
- All user-facing copy goes through `AppLocalizations` (`context.l10n`). ViewModels expose `AppError` codes, not Chinese/English strings. Update both `lib/l10n/app_en.arb` and `app_zh.arb`.
- Use `AppBreakpoints`/`AppContentFrame` for wide layouts; do not hardcode desktop widths in a feature.
- Device media (image picker, recorder, audio player) goes through `domain/services/media_gateway.dart`; the plugin implementation stays in `data/services`. UI must not import `image_picker`, `record`, `audioplayers`, or `dart:io`.
- Persistence goes through `domain/services/local_store.dart` and account-scoped repositories. Never share conversation, message, outbox, or friend-request keys across user IDs.
- Navigation uses `go_router` and `appRootNavigatorKey` (`lib/app/navigation/app_navigation.dart`). New cross-screen flows should use a route, not reach into a screen's `BuildContext`.
- Every stream subscription, `Timer`, `TextEditingController`, `ScrollController`, `ValueNotifier`, router, and coordinator must have an explicit dispose/cancel path. After `await`, check `isDisposed` (ViewModel) or `mounted` (View) before writing state or navigating.
- Keep reusable widgets and tokens in `ui/core/`; keep feature-specific UI beside its feature.
- Split a ViewModel when it starts owning independent concerns (timeline vs composer vs page shell) instead of growing one god object.
- Avoid introducing a generic use-case layer for simple CRUD. Add `app/coordinators/` or a use case only for cross-feature, stateful flows such as calls.
- Use constructor injection and the small `AppDependencies` composition root; do not add a service locator unless dependencies become unwieldy.
- Keep credentials out of source control. Password login is for local testing; production authentication should obtain a user token from a trusted server. App Certificate must never ship in the client.
- The Chat AppKey is provided at build/run time via `--dart-define=AGORA_APP_KEY=...`; no key is committed. It is an app identifier, not the App Certificate; do not put the Certificate or server secrets there.

## Chat MVP scope

Prioritize password/token login, inbox, direct conversation, paginated history, text/image/voice messages, send status and retry, incoming-message updates, unread/read state, offline cache/outbox, and empty/loading/error states. Match the supplied Figma screens once they are accessible. Push notifications and RTC are deferred until separately scoped; see `docs/architecture.md` for the intended design.

## Changes and verification

- Keep Android and iOS behavior aligned unless the SDK has a platform-specific limitation.
- Add or update a page preview in `lib/previews/app_previews.dart` for new/changed screens. Previews must use the fake repositories in `lib/previews/preview_fakes.dart`; never call the Agora SDK, native plugins, or `dart:io`. Run `flutter test test/previews/preview_smoke_test.dart` and `flutter widget-preview start`.
- Verify SDK API names against the resolved `agora_chat_sdk` package version before use.
- After implementation changes run:

```shell
dart format lib test
flutter analyze
flutter test
```

- Web chat is deferred. Do not run `flutter build web` for routine Android/iOS changes; run it only when touching conditional imports, Web stubs, or Web UI behavior.
- ViewModel/repository tests should use the fakes in `test/support/fakes.dart`; never initialize the real Agora SDK or SharedPreferences plugin in unit tests.
- When adding async work, add a disposal regression test if the work can outlive the screen (recording, playback, profile/contact fetch, outbox replay).
