# ADR-002: Reactive programming scope in Flutter

- Status: Accepted
- Date: 2026-03-07

## Decision
Use RxDart only for input/event streams (search debounce/cancel), not as a global state replacement.

## Trade-off
Clear boundaries and maintainability vs introducing one more abstraction.
