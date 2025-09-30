---
description: Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts.
scripts:
  sh: scripts/bash/check-prerequisites.sh --json
  ps: scripts/powershell/check-prerequisites.ps1 -Json
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

1. Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute.
2. Load and analyze available design documents:
   - Always read plan.md for tech stack and libraries
   - IF EXISTS: Read architecture.md for system architecture and infrastructure
   - IF EXISTS: Read component-design.md for component breakdown and dependencies
   - IF EXISTS: Read ui-ux-mockup.md for UI/UX implementation requirements
   - IF EXISTS: Read error-handling.md for error handling patterns
   - IF EXISTS: Read data-model.md for entities
   - IF EXISTS: Read contracts/ for API endpoints
   - IF EXISTS: Read research.md for technical decisions
   - IF EXISTS: Read quickstart.md for test scenarios

   Note: Not all projects have all documents. For example:
   - CLI tools might not have contracts/ or ui-ux-mockup.md
   - Simple libraries might not need data-model.md or component-design.md
   - Backend-only projects skip ui-ux-mockup.md
   - Generate tasks based on what's available

3. Generate tasks following the **Hybrid: Contract-First + Bottom-Up** approach:
   - Use `.specify/templates/tasks-template.md` as the base
   - Replace example tasks with actual tasks based on:

   **Phase 1: Contract-First Tasks**
   * **Contract setup**: OpenAPI specs, TypeScript types, mock servers
   * **Contract validation**: Pact tests, type checking, schema validation
   * **Contract testing [P]**: One per API contract, one per type definition

   **Phase 2: Bottom-Up Implementation (Parallel Tracks)**
   * **Frontend Track [P]** (guided by contracts):
     - UI components with type safety
     - API clients with contract compliance
     - Form validation with TypeScript types
   * **Backend Track [P]** (guided by contracts):
     - Data models with contract alignment
     - Services with OpenAPI compliance
     - Endpoints with schema validation

   **Phase 3: Integration & Validation**
   * **Integration tasks**: Contract compliance verification, E2E tests
   * **Validation tasks**: Performance testing, contract testing integration

4. Hybrid task generation rules:
   - Each OpenAPI spec → contract test task marked [P]
   - Each TypeScript type → type validation task marked [P]
   - Each mock server → infrastructure setup task marked [S]
   - Each architecture component → infrastructure setup task
   - Each component in component-design → contract-compliant implementation task [P]
   - Each UI screen/flow in ui-ux-mockup → type-safe UI implementation task [P]
   - Each error handling pattern → contract-aware error handling task
   - Each entity in data-model → contract-aligned model creation task [P]
   - Each endpoint → OpenAPI spec compliance task
   - Each user story → contract-based integration test marked [P]
   - Different files = can be parallel [P]
   - Same file = sequential (no [P])

5. Order tasks by **Hybrid Contract-First + Bottom-Up** dependencies:
   **Phase 1: Contract-First (Sequential)**
   - Contract setup (OpenAPI specs, TypeScript types)
   - Mock server infrastructure
   - Contract validation tools
   - Contract tests [P]

   **Phase 2: Bottom-Up Implementation (Parallel Tracks)**
   - **Frontend Track [P]**: UI components → API clients → Forms/Validation
   - **Backend Track [P]**: Models → Services → Endpoints
   - Both tracks guided by contracts from Phase 1

   **Phase 3: Integration & Validation (Sequential)**
   - Contract compliance verification
   - End-to-end integration tests
   - Performance validation
   - Polish and documentation

   **Cross-Phase Dependencies**:
   - Setup before everything
   - Contracts before implementation
   - Mock servers before parallel implementation
   - Core implementation before integration
   - Integration before validation

6. Include parallel execution examples:
   - Group [P] tasks that can run together
   - Show actual Task agent commands

7. Create FEATURE_DIR/tasks.md with:
   - Correct feature name from implementation plan
   - Numbered tasks (T001, T002, etc.)
   - Clear file paths for each task
   - Dependency notes
   - Parallel execution guidance

Context for task generation: {ARGS}

The tasks.md should be immediately executable - each task must be specific enough that an LLM can complete it without additional context.
