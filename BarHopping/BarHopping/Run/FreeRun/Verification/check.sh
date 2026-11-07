#!/bin/zsh
set -eu
verification_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
app_source_dir="$(cd -- "$verification_dir/../../.." && pwd)"
verification_temp="$(mktemp -d /tmp/bh-run4-checks.XXXXXX)"
trap 'rm -rf -- "$verification_temp"' EXIT
swiftc -D FREE_RUN_LOGIC_CHECKS -module-cache-path "$verification_temp/cache" \
  "$app_source_dir/Core/Models.swift" \
  "$app_source_dir/Core/PopularRoute.swift" \
  "$app_source_dir/Core/PopularRouteHeatmap.swift" \
  "$app_source_dir/Services/BundledJSON.swift" \
  "$app_source_dir/Run/FreeRun/FreeRunHeatmapCache.swift" \
  "$app_source_dir/Services/JSONCoding.swift" \
  "$app_source_dir/Run/FreeRun/FreeRunSession.swift" \
  "$app_source_dir/Run/FreeRun/NextBarRecommender.swift" \
  "$app_source_dir/Run/FreeRun/FreeRunDemoPath.swift" \
  "$app_source_dir/Run/FreeRun/FreeRunDemoJourney.swift" \
  "$app_source_dir/Run/FreeRun/FreeRunDemoScript.swift" \
  "$app_source_dir/Run/FreeRun/FreeRunDrinkFeedback.swift" \
  "$app_source_dir/Run/DrinkPassEvent.swift" \
  "$app_source_dir/Run/DrinkPassMockData.swift" \
  "$app_source_dir/Run/DrinkPassPurchase.swift" \
  "$app_source_dir/Run/DrinkPassStore.swift" \
  "$app_source_dir/Run/DrinkPassArtwork.swift" \
  "$app_source_dir/Run/FreeRun/Friends/FriendLocation.swift" \
  "$app_source_dir/Run/FreeRun/Friends/DemoFriendMotion.swift" \
  "$verification_dir/FreeRunLogicChecks.swift" \
  -o "$verification_temp/checks"
"$verification_temp/checks" "$app_source_dir/Resources/Data"
