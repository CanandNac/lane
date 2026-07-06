#!/bin/bash
# Запускать ПОСЛЕ `flutter create .` в корне проекта (когда уже появилась папка ios/).
# Патчит Info.plist: добавляет доступ к медиатеке и фоновый аудио-режим.
# Работает на macOS/Linux с установленным plutil или python3 (для xml).

set -e

INFO_PLIST="ios/Runner/Info.plist"

if [ ! -f "$INFO_PLIST" ]; then
  echo "Не найден $INFO_PLIST. Сначала запусти 'flutter create .' в этой папке."
  exit 1
fi

# Добавляем NSAppleMusicUsageDescription, если его ещё нет
if ! grep -q "NSAppleMusicUsageDescription" "$INFO_PLIST"; then
  python3 - "$INFO_PLIST" << 'PYEOF'
import sys, plistlib

path = sys.argv[1]
with open(path, 'rb') as f:
    data = plistlib.load(f)

data['NSAppleMusicUsageDescription'] = 'Приложению нужен доступ к вашей медиатеке для воспроизведения музыки'
data['UIBackgroundModes'] = list(set(data.get('UIBackgroundModes', []) + ['audio']))

with open(path, 'wb') as f:
    plistlib.dump(data, f)

print('Info.plist обновлён: добавлены NSAppleMusicUsageDescription и UIBackgroundModes=audio')
PYEOF
else
  echo "NSAppleMusicUsageDescription уже присутствует, пропускаю."
fi

echo ""
echo "Готово. Дальше на macOS:"
echo "  1. cd ios && pod install && cd .."
echo "  2. flutter run  (или открой ios/Runner.xcworkspace в Xcode и запусти оттуда)"
