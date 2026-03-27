# Chordboard iOS

A SwiftUI chord pad instrument for iPhone and iPad with CoreMIDI support.

## Overview

Chordboard lets you assign chords to a grid of pads and trigger them via touch, with expressive controls for velocity, strum, aftertouch, and humanization. MIDI output works over USB and Bluetooth.

## Tech Stack

- SwiftUI + Swift, iOS 17+
- CoreMIDI, CoreAudioKit
- `@Observable` models
- `Codable` + JSON persistence

## Implementation Plan

See [chordboard-ios-plan.md](chordboard-ios-plan.md) for the full implementation plan.
