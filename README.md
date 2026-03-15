# FocusFlow

FocusFlow is a cross-platform productivity app built with Flutter. It combines task planning, notes, projects, study workflows, habits, reminders, backup, and device sync experiments in a single offline-first app with a custom neumorphic UI system.

## Highlights

- Todo management with priorities, due dates, repeat rules, subtasks, and reminder scheduling
- Markdown-based notes with notebooks, tags, linked notes, and voice note attachments
- Kanban-style task tracking with effort sizing, checklists, blockers, and activity logs
- Project planning with milestones, health status, due dates, and linked notes
- Study planning with spaced repetition, pomodoro sessions, streaks, and heatmap-style activity views
- Habit tracking with frequency rules, reminders, daily targets, and archived history
- Backup and restore flows for local Hive data
- Experimental sync flows for device pairing, QR-based exchange, and nearby discovery
- Light, dark, and neon themes built on a reusable neumorphic component library

## Stack

- Flutter 3.x
- Dart 3.11+
- Riverpod 2.x with StateNotifier-based feature providers
- Hive for local persistence
- GoRouter for navigation
- flutter_local_notifications for reminders
- fl_chart, table_calendar, audioplayers, permission_handler, mobile_scanner, flutter_blue_plus, and network_info_plus for feature integrations

## Project Structure

```text
lib/
	core/
		constants/
		services/
		theme/
		utils/
		widgets/
	features/
		analytics/
		backup/
		calendar/
		habits/
		home/
		knowledge_graph/
		notes/
		onboarding/
		projects/
		settings/
		splash/
		study/
		sync/
		tasks/
		todo/
		voice_notes/
	routing/
```

Each feature follows a feature-first layout with `data`, `providers`, and `presentation` layers where needed.

## Verified Architecture Notes

- App startup initializes Hive through `DatabaseService.initialize()` before `runApp()`.
- Notifications are initialized on boot through a singleton `NotificationService`.
- Navigation is driven by `GoRouter` with a `ShellRoute` wrapping the main app shell.
- Data is persisted locally in Hive boxes for todos, notes, notebooks, tasks, projects, study plans, study sessions, voice notes, habits, habit entries, paired devices, sync logs, and settings.
- The app is offline-first. There is no backend service requirement for core usage.

## Feature Overview

### Productivity

- Todos for quick capture and reminders
- Tasks for board-based execution tracking
- Projects for higher-level planning and milestones
- Notes and notebooks for long-form information capture

### Learning

- Study plans organized into weekly topic buckets
- Session timer and study streak tracking
- Review scheduling and progress visualization

### Personal Systems

- Habit tracking with per-day targets and reminder time
- Calendar and analytics surfaces for planning and review
- Knowledge graph views for linked information

### Data Safety and Sharing

- Backup export and import for local data
- Experimental sync models for trusted devices and sync logs

## Getting Started

### Prerequisites

- Flutter SDK compatible with Dart `^3.11.0`
- A configured platform toolchain for the target you want to run

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run -d windows
```

Other supported targets include `android`, `ios`, `macos`, and `chrome` when your local toolchain is configured.

## Useful Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

## Local Persistence

FocusFlow uses Hive for storage. The project keeps hand-written Hive adapters in `.g.dart` files rather than generating them from `build_runner`, so model changes need matching adapter updates.

## Current Limitations

- Audio recording is scaffolded through `AudioRecorderService`, but the actual recording path is still a placeholder implementation.
- Device discovery and sync flows are partially stubbed and do not yet perform full peer-to-peer transfer.
- The app contains several advanced modules in active development, so some integrations are more complete than others.

## Platforms

- Android
- iOS
- macOS
- Windows

## Repository Notes

- Build outputs, Flutter tool state, and local instruction files are excluded from version control.
- `CLAUDE.md` is treated as a local-only file and is not intended to be published to the remote repository.
