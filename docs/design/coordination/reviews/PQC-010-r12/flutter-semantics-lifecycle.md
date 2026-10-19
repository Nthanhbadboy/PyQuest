# Flutter semantics lifecycle — source evidence

Fetched via GitHub API at revision `abaf9c523780a608bd46686fd5e53740a07077f8`, matching the CI-reported revision.
These are SDK excerpts, **not retrieved CI failure traces**. No local Flutter run.

## widget_tester.dart:108–111

[Exact source](https://github.com/flutter/flutter/blob/abaf9c523780a608bd46686fd5e53740a07077f8/packages/flutter_test/lib/src/widget_tester.dart#L108-L111)

```dart
/// If the `semanticsEnabled` parameter is set to `true`,
/// [WidgetTester.ensureSemantics] will have been called before the tester is
/// passed to the `callback`, and that handle will automatically be disposed
/// after the callback is finished. It defaults to true.
```

## widget_tester.dart:148–154

[Exact source](https://github.com/flutter/flutter/blob/abaf9c523780a608bd46686fd5e53740a07077f8/packages/flutter_test/lib/src/widget_tester.dart#L148-L154)

```dart
void testWidgets(
  String description,
  WidgetTesterCallback callback, {
  bool? skip,
  test_package.Timeout? timeout,
  bool semanticsEnabled = true,
  TestVariant<Object?> variant = const DefaultTestVariant(),
```

## widget_tester.dart:174–201

[Exact source](https://github.com/flutter/flutter/blob/abaf9c523780a608bd46686fd5e53740a07077f8/packages/flutter_test/lib/src/widget_tester.dart#L174-L201)

```dart
    test(
      combinedDescription,
      () {
        tester._testDescription = combinedDescription;
        SemanticsHandle? semanticsHandle;
        tester._recordNumberOfSemanticsHandles();
        if (semanticsEnabled) {
          semanticsHandle = tester.ensureSemantics();
        }
        test_package.addTearDown(binding.postTest);
        return binding.runTest(
          () async {
            debugResetSemanticsIdCounter();
            Object? memento;
            try {
              memento = await variant.setUp(value);
              binding.reset(); // TODO(ianh): the binding should just do this itself in _runTest
              maybeSetupLeakTrackingForTest(experimentalLeakTesting, combinedDescription);
              await callback(tester);
            } finally {
              await variant.tearDown(value, memento);
              maybeTearDownLeakTrackingForTest();
            }
            semanticsHandle?.dispose();
          },
          tester._endOfTestVerifications,
          description: combinedDescription,
        );
```

## widget_tester.dart:1061–1094

[Exact source](https://github.com/flutter/flutter/blob/abaf9c523780a608bd46686fd5e53740a07077f8/packages/flutter_test/lib/src/widget_tester.dart#L1061-L1094)

```dart
  void _endOfTestVerifications() {
    verifyTickersWereDisposed('at the end of the test');
    _verifySemanticsHandlesWereDisposed();
  }

  void _verifySemanticsHandlesWereDisposed() {
    assert(_lastRecordedSemanticsHandles != null);
    // TODO(goderbauer): Fix known leak in web engine when running integration tests and remove this "correction", https://github.com/flutter/flutter/issues/121640.
    final knownWebEngineLeakForLiveTestsCorrection =
        kIsWeb && binding is LiveTestWidgetsFlutterBinding ? 1 : 0;

    if (_currentSemanticsHandles - knownWebEngineLeakForLiveTestsCorrection >
        _lastRecordedSemanticsHandles!) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('A SemanticsHandle was active at the end of the test.'),
        ErrorDescription(
          'All SemanticsHandle instances must be disposed by calling dispose() on '
          'the SemanticsHandle.',
        ),
      ]);
    }
    _lastRecordedSemanticsHandles = null;
  }

  int? _lastRecordedSemanticsHandles;

  // TODO(goderbauer): Only use binding.debugOutstandingSemanticsHandles when deprecated binding.pipelineOwner is removed.
  int get _currentSemanticsHandles =>
      binding.debugOutstandingSemanticsHandles +
      binding.pipelineOwner.debugOutstandingSemanticsHandles;

  void _recordNumberOfSemanticsHandles() {
    _lastRecordedSemanticsHandles = _currentSemanticsHandles;
  }
```

## binding.dart:1952–1975

[Exact source](https://github.com/flutter/flutter/blob/abaf9c523780a608bd46686fd5e53740a07077f8/packages/flutter_test/lib/src/binding.dart#L1952-L1975)

```dart
    // run the test
    await testBody();
    asyncBarrier(); // drains the microtasks in `flutter test` mode (when using AutomatedTestWidgetsFlutterBinding)

    if (_pendingExceptionDetails == null) {
      // We only try to clean up and verify invariants if we didn't already
      // fail. If we got an exception already, then we instead leave everything
      // alone so that we don't cause more spurious errors.
      runApp(
        Container(key: UniqueKey(), child: _postTestMessage),
      ); // Unmount any remaining widgets.
      await pump();
      _restorationManager?.dispose();
      _restorationManager = null;
      if (registerTestTextInput) {
        _testTextInput.unregister();
      }
      invariantTester();
      _verifyAutoUpdateGoldensUnset(autoUpdateGoldensBeforeTest && !isBrowser);
      _verifyReportTestExceptionUnset(reportTestExceptionBeforeTest);
      _verifyErrorWidgetBuilderUnset(errorWidgetBuilderBeforeTest);
      _verifyShouldPropagateDevicePointerEventsUnset(shouldPropagateDevicePointerEventsBeforeTest);
      _verifyInvariants();
    }
```
