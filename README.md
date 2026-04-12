# EndlessRunner

A minimal 2D Subway Surfers-style endless runner for iOS, built with SwiftUI +
SpriteKit. All visuals are colored shapes — no assets required.

## Gameplay

- Three horizontal lanes. Player auto-runs at a fixed X.
- Swipe **left / right** to switch lanes.
- Swipe **up** to jump (clears low barriers).
- Swipe **down** to slide (ducks under tall barriers).
- Avoid red barriers, gray full blocks, and long gray trains.
- Collect yellow coins between obstacles for bonus points.
- Speed increases every 30 seconds, capped at 2x base.

## Requirements

- iOS 16.0+
- Xcode 15+ (Swift 5 compatible)
- Portrait orientation only

## Building

Unsigned build for sideloading:

```bash
xcodebuild archive \
  -project EndlessRunner.xcodeproj \
  -scheme EndlessRunner \
  -archivePath EndlessRunner.xcarchive \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  DEVELOPMENT_TEAM=""
```

Then package into an `.ipa` by zipping `Payload/EndlessRunner.app`.

CI builds happen via `.github/workflows/build-ipa.yml`.

## Project Layout

```
EndlessRunner/
├── App/              SwiftUI @main entry
├── Views/            SwiftUI menu/game-over views
├── Game/             SpriteKit scene, player, managers, config
└── Resources/        Assets.xcassets
```

## Notes

- No third-party dependencies.
- No `SKPhysicsBody` — collision is manual AABB in `GameScene.update`.
- All tunables live in `GameConfig.swift`.
