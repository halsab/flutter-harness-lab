# Reproducible E2E checks for PR #5

## Web (Playwright + Chromium)

Build and serve the release Flutter Web bundle:

~~~sh
flutter pub get
flutter build web
python3 -m http.server 8080 --directory build/web
~~~

In another terminal, from the repository root:

~~~sh
npm install --no-save --no-package-lock --no-audit --no-fund @playwright/test@1.56.1
npx playwright install chromium
npx playwright test tests/web/my_tasks.spec.mjs --browser=chromium --reporter=line
~~~

Override the server URL with WEB_E2E_BASE_URL if necessary.
The test verifies that the input clears after submission, the task row is
rendered, completed state survives browser reload, and deletion survives reload.
It explicitly activates the Flutter Web semantics DOM and performs UI actions
rather than injecting application state. A title-only smoke test is insufficient.

## Android (Maestro 2.12.1)

Build/install the current branch on a booted Android emulator, then run:

~~~sh
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
maestro test maestro/flows/my_tasks_android.yaml
~~~

The Android app ID (dev.halsab.flutter_harness_lab) differs from the
iOS app ID (dev.halsab.flutterHarnessLab). The Android scenario checks
the real created row (not merely text in the input), completion, relaunch
persistence, deletion, and absence after a second relaunch.

The pull-request workflow runs Web Playwright and Android Maestro on hosted
GitHub runners. Those checks are separate from Dart widget tests and Web build.
