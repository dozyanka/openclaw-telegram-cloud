# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses semantic versioning for tagged releases.

## [Unreleased]

### Added
- MIT license.
- Repository safety checks in GitHub Actions.
- Repository finalization helper for description, topics, commit/push, and optional release creation.
- Expanded documentation of architecture, privacy boundaries, threat model, and deployment requirements.

### Changed
- GitHub Actions now checks for accidentally tracked secrets and required hardening controls before building the container.
- Security documentation now distinguishes public-DM risk from host-access risk.

## [1.0.0] - 2026-09-15

### Added
- Dockerized OpenClaw `2026.9.4` Telegram bot.
- Google Gemini provider configured through environment-backed secrets.
- Tool-less public Telegram mode with per-sender sessions.
- Stateless OpenClaw workspace and loopback-only Gateway.
- GitHub Actions Docker build validation.
