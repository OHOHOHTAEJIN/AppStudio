#!/usr/bin/env python3
"""Patch generated Flutter Android Gradle target and display name."""
from pathlib import Path
import sys

LABELS = {
    "pulse_puzzle": "펄스 퍼즐",
    "pixel_slim": "픽셀 슬림",
    "docu_snap": "도큐 스냅",
    "daily_quiz": "데일리 퀴즈",
}
if len(sys.argv) != 2:
    raise SystemExit("Usage: patch_android.py apps/pulse_puzzle")
root = Path(sys.argv[1])
name = root.name
if name not in LABELS:
    raise SystemExit("Unknown app: " + name)
gradle = root / "android/app/build.gradle.kts"
if not gradle.exists():
    gradle = root / "android/app/build.gradle"
if not gradle.exists():
    raise SystemExit("Generate the Android host using flutter create first")
data = gradle.read_text(encoding="utf-8")
for old, new in [
    ("compileSdk = flutter.compileSdkVersion", "compileSdk = 36"),
    ("targetSdk = flutter.targetSdkVersion", "targetSdk = 36"),
    ("minSdk = flutter.minSdkVersion", "minSdk = 24"),
    ("compileSdkVersion flutter.compileSdkVersion", "compileSdkVersion 36"),
    ("targetSdkVersion flutter.targetSdkVersion", "targetSdkVersion 36"),
    ("minSdkVersion flutter.minSdkVersion", "minSdkVersion 24"),
]:
    data = data.replace(old, new)
if name == "docu_snap" and "com.google.mlkit:text-recognition-korean:16.0.1" not in data:
    if gradle.suffix == ".kts":
        data += '\n\ndependencies {\n    implementation("com.google.mlkit:text-recognition-korean:16.0.1")\n}\n'
    else:
        data += "\n\ndependencies {\n    implementation 'com.google.mlkit:text-recognition-korean:16.0.1'\n}\n"
gradle.write_text(data, encoding="utf-8")
manifest = root / "android/app/src/main/AndroidManifest.xml"
if manifest.exists():
    data = manifest.read_text(encoding="utf-8")
    data = data.replace(f'android:label="{name}"', f'android:label="{LABELS[name]}"')
    manifest.write_text(data, encoding="utf-8")
generated = root / "test/widget_test.dart"
if generated.exists() and "await tester.pumpWidget(const MyApp())" in generated.read_text(encoding="utf-8"):
    generated.unlink()
print("Updated Android settings:", name)
