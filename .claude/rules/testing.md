---
paths:
  - "test/**/*.dart"
---

# Testing

- Name tests by behavior and expected outcome.
- Use Arrange, Act, Assert structure where it improves clarity.
- Test success plus the highest-risk failure or offline path.
- Avoid real network calls in unit and widget tests.
- Use fakes at repository boundaries rather than mocking Flutter internals.
- Verify the selected CV identity when testing editor and preview flows.
- Do not depend on execution order, real credentials, current time, or production data.
- Keep smoke tests small; place feature behavior in focused test files.

