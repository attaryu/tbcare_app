# TBCare - Copilot Instructions

You are an expert Flutter developer working on "BCare," a collaborative app for TB patients and their caregivers. Helping TB patients take their medication consistently with precise history recording. Always adhere strictly to the following architectural guidelines, tech stack constraints, and project-specific rules.

**CRITICAL FALLBACK RULE:**
If you are ever confused, unsure about the project structure, or need more context on how to implement a specific layer, **ALWAYS read the documentation files located in the `docs/` directory** (`docs/01-getting-started.md`, `docs/02-architecture-flow.md`, `docs/03-state-management.md`, `docs/04-development-rules.md`) before generating code.

---

## Core Tech Stack

- **Framework**: Flutter (SDK >= 3.10.8)
- **State Management**: Bloc/Cubit (`flutter_bloc`)
- **Dependency Injection**: GetIt & Injectable (`get_it`, `injectable`)
- **Networking**: Dio
- **Routing**: GoRouter
- **Code Generation**: Injectable

---

## Architecture & Layering (Pragmatic Clean Architecture)

The app is divided into `core/` (shared configurations, generic widgets, utils) and `features/` (business modules). Inside each feature, adhere to this Pragmatic Clean Architecture:

1. **Domain Layer**: Entities, Repository Interfaces, and UseCases.
2. **Data Layer**: Models, Repository Implementations, Remote/Local Data Sources.
3. **Presentation Layer**: Pages, Widgets, and Cubits/States.

**Pragmatic Rules:**

- **No Passthrough UseCases**: Only create a UseCase if there is complex business logic, validation, or multiple repository calls involved. For simple CRUD operations, the Cubit should call the Repository directly.
- **Event-Driven Synchronization**: To synchronize data across different parts of the app (e.g., updating the dashboard after adding a transaction), rely entirely on the **Event Bus Pattern** at the Cubit level. The example, `AddTransactionCubit` will emit a signal to trigger specific Cubits to fetch the latest data.

---

## State Management (Cubit) & Dependency Injection

We use `injectable` for Dependency Injection. Pay extreme attention to DI lifecycles to prevent memory leaks and state bleeding:

### 1. Cubit Lifecycles & Providing

- **Long-Lived Cubits** (Global state, main tabs like Dashboard or History):
  - Mark with `@singleton` or `@lazySingleton`.
  - Provide via `BlocProvider.value(value: getIt<MyCubit>())`. NEVER use `create:` for singletons, to prevent `flutter_bloc` from destroying them on navigation.
- **Temporary/Scoped Cubits** (Forms, detail pages, single-use screens):
  - Mark with `@injectable` (creates a factory/new instance every time).
  - Provide via `BlocProvider(create: (_) => getIt<MyCubit>())`.

### 2. Inter-Cubit Communication

- Cubits must NEVER depend on or directly call other Cubits.
- Use the **Event Bus Pattern**:
  - A mutating Cubit completes an action and fires an event: `getIt<EventBus>().fire(MyEvent())`.
  - An observing Cubit listens to this event in its constructor to trigger a data refresh.
  - **CRITICAL**: Always cancel `StreamSubscription` in the observing Cubit's `close()` method.

---

## UI & Presentation Rules (Dumb UI)

1. **Dumb Widgets**:
   - Widgets must only handle layout, rendering, and triggering Cubit functions (e.g., `onPressed: () => context.read<MyCubit>().doSomething()`).
   - NO API calls, NO complex data transformation, and NO business logic inside `build()` methods.
2. **Strict Theming**:
   - **Colors**: ALWAYS use `AppColors` (e.g., `AppColors.primary`). No hardcoded colors like `Colors.blue` or `Color(0xFF...)`.
   - **Sizes/Spacing**: ALWAYS use `AppSizes` (e.g., `AppSizes.spacing4`). No hardcoded numbers for paddings, margins, or dimensions.
   - **Typography**: ALWAYS use `AppTextStyles` (e.g., `AppTextStyles.body1`). Apply `.copyWith()` if minor adjustments are needed.

---

## Error Handling & Logging

1. **NO Print Statements**: Never use `print()` or `debugPrint()`. Use `Logger.root.info()`, `warning()`, or `severe()` (from the `logging` package).
2. **Exceptions vs. Failures**:
   - Data sources throw `Exceptions`.
   - Repositories catch exceptions and return `Failure` objects (using `Either` from the `fpdart` or `dartz` package).
   - Cubits process the `Failure` to emit an error state with a localized message.

---

## Naming Conventions

- **Files**: `lowercase_with_underscores.dart`
- **Classes**: `UpperCamelCase`
- **Suffixes**: Append the architectural layer to the class name (e.g., `LoginCubit`, `UserEntity`, `AuthRepositoryImpl`, `HistoryPage`).
