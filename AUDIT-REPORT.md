# AUDIT REPORT — Agentic Fullstack Composition

## Starter identity

ID: agentic-fullstack-composition  
Type: composition  
Version: 0.1.0

---

## Intended install path

app/composition

---

## Purpose

Provide deterministic local runtime composition for Agentic platform projects.

---

## Owned paths

app/composition

---

## Expected contents

app/composition

---

## Dependencies

### Required

None.

### Optional

- agentic-clean-backend
- agentic-react-spa
- agentic-flutter-client
- agentic-api-contracts-api
- agentic-postgres-dev

---

## Runtime and services

Typical runtime stack:

- Docker
- Docker Compose

Optional integration:

- backend starter
- web starter
- Flutter client starter
- contracts starter
- PostgreSQL dev starter

---

## Post-install checks

1. Verify composition directory exists.
2. Verify composition files are present.
3. Verify compose configuration is valid.
4. Verify local startup command is valid.

---

## Known integration points

Composition may integrate with:

- backend starter
- React SPA starter
- Flutter client starter
- contracts starter
- PostgreSQL dev starter

---

## Known risks / attention points

- Keep composition generic and environment-focused.
- Avoid embedding business-specific runtime assumptions.
- Keep service boundaries aligned with platform module ownership.

---

## Exit criteria

- composition directory installed
- composition files present
- compose validation works
- startup command works
- no placeholder values remain
