# Calley — Flutter development assignment

Flutter implementation of the supplied Calley flow: English language selection, registration, email OTP verification/resend, sign-in, welcome/tutorial, dashboard, calling-list bottom sheet, dynamic totals, donut chart, user drawer, help and logout. The layout follows the supplied Figma colors and screen sequence, with an original icon-based tutorial panel.

## Install and run

The submitted `calley-debug.apk` is a debug Android build. The normal APK uses the real test API at `https://mock-api.calleyacd.com/api`. Register with an email inbox you control, then enter the emailed OTP. No account credentials are bundled. Mobile number is optional and is not transmitted because it is absent from the documented API schema.

```powershell
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --debug
```

SDK: Flutter 3.32.4 / Dart 3.8.1. Android Gradle 8.12, AGP 8.7.3, Kotlin 2.1.0, JDK 17, NDK 26.3.11579264. Local SDK paths and build caches are excluded from source control. The URL launcher plugin recommends NDK 27; the working machine has a complete NDK 26.3 and an incomplete NDK 27 installation, so the validated build uses 26.3.

## Demo and recording

```powershell
flutter run --dart-define=DEMO_MODE=true
flutter test integration_test/demo_flow_test.dart -d DEVICE_ID
```

Demo mode is visibly labeled. Use a validly formatted email and code **123456**. The recording shows the actual Android emulator screen: registration, OTP, welcome, list selection, chart and user drawer. No physical phone is claimed. `scripts/record_demo.py` runs the test on the dedicated emulator `emulator-5556`. The default APK uses the external test API; the recording uses deterministic sample data so it requires no private inbox or live account credentials.

## Implementation and validation

`lib/api.dart` provides typed profiles/lists/summaries, timeouts, errors and injected HTTP for tests. User/list IDs come from API responses. The list API supports the documented single-object response and arrays. Totals use server counters (27 pending + 23 called + 11 rescheduled = 61), rather than assuming the 50 sample call rows are the complete list.

`lib/main.dart` provides responsive forms, a custom donut chart, loading/error/empty states, retry and an in-memory session. Passwords are cleared after login and are not logged or persisted. The OTP screen correctly describes email delivery, despite the Figma WhatsApp heading. The tutorial opens the supplied video. Web-panel/help links open official Calley pages. No call-initiation or scheduling API was provided, so the app displays the requested statistics without initiating calls.

Tests cover wire mapping, server/malformed errors, empty/count states and registration → OTP → welcome → list statistics. Live email delivery is not exercised by mock tests. The Android integration test runs the complete demonstration in the installed Android runtime.

## References

- [Assignment](https://cstechmk.notion.site/Machine-Test-Flutter-Mobile-App-Developer-c6a13eb9445e49479c0b0eaeda49ca8e)
- [Figma](https://www.figma.com/design/rjv6EBHWOg4yNNJLhLOKjF/Get-Calley-App-Design?node-id=0-1)
- [API documentation](https://documenter.getpostman.com/view/38199901/2sB34Zpiy9)
- [Walkthrough](https://www.youtube.com/watch?v=bP4U-L4EHcg)
