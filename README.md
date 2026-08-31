# ProfitTrack

ProfitTrack is a local-first Flutter application for reseller profit tracking, goals, marketplace reporting thresholds, and sales analytics.

## Run

1. Install the current stable Flutter SDK.
2. Run `flutter create --platforms=android,ios .` once to generate the native runners.
3. Run `flutter pub get`.
4. Run `flutter analyze` and `flutter test`.
5. Run `flutter run`.

The app seeds an editable demonstration month on first launch so the supplied dashboard designs can be reviewed immediately. New sales are saved locally in SQLite through Drift.
