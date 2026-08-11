# FlexFocus

## Overview

FlexFocus is a lightweight visual focus timer for macOS. Each focus session is assigned to one of three categories: Research, Teaching, or Others.

## Features

- Focus timer
    - Select a category before starting a focus session.
    - Save completed sessions automatically.
    - Use a break duration equal to one fifth of the focus duration, with a one-minute minimum.
- Statistics
    - Compare focus duration by Hour, Day, Week, or Month.
    - Show category proportions in a pie chart.
    - Hover over the day or week timeline to scope the pie chart to that interval.
    - Select any day directly from the weekly timeline.
    - Navigate the timeline with separate day and week selectors.
- Recent history
    - Show sessions from the most recent seven calendar days.
    - Edit a session category and its start and stop times.
- Settings
    - Configure DND automation, notifications, theme, and dark-mode colors.
    - Clear history or change the local data directory.

## Data storage

Focus history and settings are stored in a configurable directory. The default directory is:

```text
~/Library/Application Support/FlexFocus
```

The application can migrate its managed data files to another directory.

## Build and package

Requirements: macOS 14 or later and Swift 6.2 or later.

```bash
swift build
swift run
./scripts/package_app.sh
```

The packaged application is written to `dist/FlexFocus.app`.
