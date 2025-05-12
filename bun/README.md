# state-transition-utils-bun
State transition utilities for Bun, which is Bun binding using [state-transition-z](https://github.com/ChainSafe/state-transition-z)

To consume this libraries, application needs to call these apis:
- `initBinding()`: at application startup, before calling any apis of this library
- `closeBinding()`: at application close()