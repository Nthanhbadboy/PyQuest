#!/usr/bin/env bash
# Runs inside reactivecircus/android-emulator-runner (cwd = app/).
# Note: `flutter drive` uninstalls the app when it finishes unless
# --keep-app-running is passed, which would wipe the saved progress.
set +e
PKG=com.pyquest.pyquest
mkdir -p ../docs/screenshots
adb wait-for-device
adb shell getprop ro.build.version.release > ../journey.txt 2>&1
adb shell wm size >> ../journey.txt 2>&1
adb uninstall $PKG >> ../journey.txt 2>&1

echo "=== journey (fresh install) ===" >> ../journey.txt
timeout 1500 flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart \
  --target=integration_test/journey_test.dart -d emulator-5554 >> ../journey.txt 2>&1
echo "journey=$?" >> ../status.txt

echo "=== restart with the regular app build (same debug signature keeps data) ===" > ../relaunch.txt
adb shell am force-stop $PKG
adb install -r ../pyquest-debug.apk >> ../relaunch.txt 2>&1
echo "install_regular_apk=$?" >> ../status.txt
adb logcat -c
adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >> ../relaunch.txt 2>&1
sleep 20
adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS >> ../relaunch.txt 2>&1
sleep 2
adb exec-out screencap -p > ../docs/screenshots/34_relaunch_real_app.png
echo "relaunch_screencap=$?" >> ../status.txt
adb shell pidof $PKG >> ../relaunch.txt 2>&1
echo "app_alive_after_relaunch=$?" >> ../status.txt
adb logcat -d -t 300 flutter:V AndroidRuntime:E '*:S' >> ../relaunch.txt 2>&1
adb shell am force-stop $PKG

echo "=== returning player checks ===" >> ../relaunch.txt
timeout 900 flutter drive --no-pub --keep-app-running --driver=test_driver/integration_test.dart \
  --target=integration_test/returning_test.dart -d emulator-5554 >> ../relaunch.txt 2>&1
echo "returning=$?" >> ../status.txt
exit 0
