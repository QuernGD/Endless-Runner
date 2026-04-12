# EndlessRunner — Claude Code Project Config

## Project Overview

A 2D Subway Surfers-style endless runner for iOS. The player runs forward automatically on 3 lanes, swipes left/right to switch lanes, swipes up to jump, swipes down to slide. Obstacles approach from the right. Score is distance traveled. Coins can be collected. Game gradually speeds up. Self-contained, no backend, no network, no third-party dependencies. Sideloaded via certificate (Feather/Esign).

## Tech Stack

- **Language**: Swift 6
- **Framework**: SpriteKit (gameplay) + SwiftUI (menus)
- **Minimum Target**: iOS 16.0
- **Build System**: Xcode project (.xcodeproj)
- **Orientation**: Portrait (like Subway Surfers)

## Build Requirements

Unsigned IPA for sideloading:

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

## Core Game Mechanics

### 3-Lane System

- Three horizontal lanes: bottom, middle, top (side-view)
- Player starts in center lane
- Swipe left → lane down, right → lane up
- Lane switching animates over 0.15s, can be triggered mid-jump/slide

### Movement

- Player stays at fixed X (screen width * 0.2)
- World scrolls right to left
- Base scroll speed 300 pts/s, +8% every 30s, max 600 pts/s

### Jump / Slide

- Jump arcs 80 pts over 0.5s, no double jump
- Slide shrinks hitbox to half for 0.6s

### Obstacles

- lowBarrier (jump), tallBarrier (slide), fullBlock (switch), train (long, switch)
- Never block all 3 lanes at once

### Coins

- Yellow circles in lines / arcs, worth 10 each

### Scoring

- Distance-based primary score, coin bonus, saved to UserDefaults

## Visual Style — COLORED SHAPES ONLY

- Player: blue rectangle
- Obstacles: red/dark gray rectangles
- Coins: yellow circles
- Ground: brown strip with white dashed lane dividers
- Background: light blue

## Coding Standards

- @Observable not ObservableObject
- No force unwraps
- All tunables in GameConfig
- No Storyboards, no XIBs
- No third-party dependencies
- Manual AABB collision, no SKPhysicsBody

## What NOT To Do

- No SKPhysicsBody / SKPhysicsContactDelegate
- No code signing
- No networking / analytics
- No deprecated APIs
- No 3D
