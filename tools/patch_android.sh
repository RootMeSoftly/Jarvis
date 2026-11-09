#!/usr/bin/env bash
set -e
M=android/app/src/main/AndroidManifest.xml
# INTERNET permission
grep -q 'android.permission.INTERNET' "$M" || \
  sed -i 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$M"
# app name
sed -i 's#android:label="[^"]*"#android:label="JARVIS"#' "$M"
# minSdk 23 (needed by secure storage)
for f in android/app/build.gradle android/app/build.gradle.kts; do
  if [ -f "$f" ]; then
    sed -i 's/minSdk = flutter.minSdkVersion/minSdk = 23/; s/minSdkVersion flutter.minSdkVersion/minSdkVersion 23/' "$f"
  fi
done
echo "patched OK"
