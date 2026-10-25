# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

Bun + TypeScript project (no build step).

- `bun run start` — runs the composition root in [src/main.ts](src/main.ts) (one hard-coded borrow request, prints the response)
- `bun test` — run all tests; single file: `bun test tests/borrow-book.test.ts`; by name: `bun test -t "<pattern>"`
- `bun run typecheck` — `tsc --noEmit` (strict, plus `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes`)

Imports use the `@/*` alias for `src/*` (configured in tsconfig).

## Architecture

Clean/hexagonal architecture for a library "borrow a book" use case. Dependencies point inward: `adapters` → `application` → `domain`.

- `src/domain/` — immutable entities (`Book`, `Member`, `Loan`, `LoanPeriod`, `LocalDate`) and branded ids ([identifiers.ts](src/domain/identifiers.ts)). Entities have private constructors and static `create` factories that throw `DomainRuleViolation` on invalid construction. Business operations (e.g. `Book.borrowCopy()`, `Member.registerLoan()`) do not mutate: they return a result union `{ ok: true, <new entity> } | { ok: false, reason }`, so expected rule failures are values, not exceptions.
- `src/application/` — use cases ([borrow-book.ts](src/application/borrow-book.ts)) that orchestrate domain objects through ports in `src/application/ports/` (`BorrowingRepository`, `Clock`, `IdGenerator`). `BorrowBook.execute` returns a `BorrowBookResult` union whose `reason` codes are the contract the HTTP adapter maps to status codes. Persistence is a single `saveBorrowing({ book, member, loan })` so the three changes are saved together.
- `src/adapters/` — implementations of ports (in-memory repository, system/fixed clock, incremental id generator) and the HTTP controller, which validates the raw body, calls the use case, and maps results (400 invalid input, 404 not found, 409 rule violation, 201 success). The controller depends on the `BorrowBookUseCase` interface, not the class.
- [src/main.ts](src/main.ts) is the only place where concrete adapters are wired together.

Adding a new rejection reason means updating the domain result type, `BorrowBookResult`, and the controller's status mapping.

## Requirements

[requirements/spec.md](requirements/spec.md) (in Spanish) and [requirements/borrow-book.feature](requirements/borrow-book.feature) are the source of truth for business rules: a copy must be available, the member must not be suspended or at their loan limit; standard members get 3 loans for 14 days, premium members 5 loans for 28 days. Tests in `tests/` mirror these scenarios, so use `FixedClock` for deterministic dates.
