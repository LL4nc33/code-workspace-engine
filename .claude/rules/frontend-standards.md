---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/components/**"
  - "**/pages/**"
---

# Frontend Standards

## Component Structure
- One component per directory with co-located test and styles
- Functional components only (no class components)
- Props always explicitly typed with named interface
- Named exports for reusable, default exports only for pages
- Max 200 lines per component

## Naming
- Components: PascalCase (`UserProfile`)
- Props: `{ComponentName}Props`
- Hooks: `use{Purpose}` (`useAuth`, `useFormState`)
- Handlers: `handle{Event}` internal, `on{Event}` for props
- State: descriptive camelCase (`isLoading`, `userData`)

## Accessibility
- All interactive elements: keyboard accessible
- Images: alt text required
- Forms: labels required for inputs
- Color: never sole information carrier
- Semantic HTML over div soup

## State Management
- Local: useState for component-scoped
- Shared: Context or state library
- Server: React Query / SWR pattern
- URL: Router params for shareable state

## Design Tokens
- CSS Custom Properties with semantic prefixes (`--color-`, `--font-`, `--space-`, `--radius-`, `--shadow-`)
- No hardcoded color/spacing values — always reference tokens
- T-Shirt size scale for typography and spacing (xs → 3xl)
- Dark Mode via `[data-theme="dark"]` overrides

## Reference
- @workflow/standards/frontend/components.md
- @workflow/standards/frontend/design-tokens.md
