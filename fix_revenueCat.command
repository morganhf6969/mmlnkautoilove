#!/bin/bash
source "$HOME/.zshrc" 2>/dev/null || source "$HOME/.bash_profile" 2>/dev/null || true
export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin"

LOCAL="$HOME/Developer/memolinkV4-main"

echo ""
echo "========================================="
echo "  Fix RevenueCat — Fresh Pod Download"
echo "========================================="
echo ""

echo "▶ Copia Podfile aggiornato..."
cp "$HOME/kDrive/memolinkV4-main/ios/Podfile" "$LOCAL/ios/Podfile"
echo "✅ Podfile copiato."
echo ""

echo "▶ Pulizia DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
echo "✅ DerivedData pulito."
echo ""

echo "▶ Pulizia cache CocoaPods per RevenueCat (download corrotto)..."
rm -rf ~/Library/Caches/CocoaPods/Pods/Release/RevenueCat*
rm -rf ~/Library/Caches/CocoaPods/Pods/Release/PurchasesHybridCommon*
rm -rf ~/Library/Caches/CocoaPods/Pods/Release/RevenueCatUI*
rm -rf ~/Library/Caches/CocoaPods/Pods/Release/PurchasesHybridCommonUI*
echo "✅ Cache CocoaPods pulita."
echo ""

echo "▶ Rimozione Pods esistenti per RevenueCat..."
rm -rf "$LOCAL/ios/Pods/RevenueCat"
rm -rf "$LOCAL/ios/Pods/RevenueCatUI"
rm -rf "$LOCAL/ios/Pods/PurchasesHybridCommon"
rm -rf "$LOCAL/ios/Pods/PurchasesHybridCommonUI"
echo "✅ Pod esistenti rimossi."
echo ""

echo "▶ pod install (da $LOCAL/ios)..."
cd "$LOCAL/ios"
pod install
POD_RESULT=$?
if [ $POD_RESULT -ne 0 ]; then
  echo "❌ pod install fallito."
  read -p "Premi Invio per chiudere..."
  exit 1
fi
echo "✅ pod install completato."
echo ""

echo "▶ Verifica Logger.swift scaricato..."
LOGGER_COUNT=$(find "$LOCAL/ios/Pods/RevenueCat/Sources/Logging" -maxdepth 1 -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
if [ "$LOGGER_COUNT" -gt "0" ]; then
  echo "✅ Logger trovato! ($LOGGER_COUNT file in Sources/Logging/)"
else
  echo "⚠️  ATTENZIONE: Logger ancora mancante da Sources/Logging/"
  echo "   Il problema è nel podspec di RevenueCat 5.67.1."
  echo "   Passare al Piano B (downgrade purchases_flutter a 8.x)."
fi
echo ""

echo "========================================="
echo "✅ Fix completato! Apertura Xcode..."
echo "========================================="
echo ""
open -a Xcode "$LOCAL/ios/Runner.xcworkspace"

read -p "Premi Invio per chiudere..."
