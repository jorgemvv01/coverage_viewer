# Coverage viewer - examples

## Basic usage

Generate coverage for your Dart/Flutter project:
```bash
# For Flutter projects
flutter test --coverage

# For Dart projects
dart test --coverage=coverage
dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib

```

And visualize it.
If you have it installed globally
```bash
coverage_viewer
```

or as dev dependency:

```bash
dart run coverage_viewer
```