---
name: registry-manager
description: >-
  Adds new items to registry.json by scanning a given folder recursively,
  producing a valid shadcn CLI registry entry, and wiring it into the UI
  (section page, API route for recipes, sidebar auto-updates). Use when the
  user wants to register a folder or file in the registry, add a
  component/hook/recipe to registry.json, or mentions updating the shadcn
  registry.
---

# Registry Manager Skill

Adds a new item to `registry.json` by scanning a given folder, collecting all files recursively, and producing a valid shadcn CLI registry entry.

## Trigger

The user provides a folder path (absolute or relative to the workspace root) and asks to register it in the registry.

## Step 1 — Read the current registry

Read `registry.json` at the workspace root. Parse the `items` array so you know every existing `name` (to avoid duplicates) and can append to the end.

## Step 2 — Scan the folder recursively

Collect **every** file inside the given folder, recursively, preserving the full relative path from the workspace root (e.g. `registry/components/table/data-table.tsx`). Ignore hidden files (`.DS_Store`, `.gitkeep`, etc.) and common non-source artifacts (`node_modules`, `__pycache__`, `.terraform`, etc.).

## Step 3 — Determine the registry item type

Use the table below to infer the item-level `type`. The type applies to the **item** object in the `items` array.

| Folder pattern            | Inferred type        | File-level type      | `target` required? |
| ------------------------- | -------------------- | -------------------- | ------------------ |
| `registry/components/**`  | `registry:component` | `registry:component` | No                 |
| `registry/hooks/**`       | `registry:hook`      | `registry:hook`      | No                 |
| `registry/lib/**`         | `registry:lib`       | `registry:lib`       | No                 |
| `registry/recipes/**`     | `registry:file`      | `registry:file`      | **Yes**            |
| `registry/blocks/**`      | `registry:block`     | `registry:block`     | No                 |
| `registry/pages/**`       | `registry:page`      | `registry:page`      | **Yes**            |
| `registry/themes/**`      | `registry:theme`     | `registry:theme`     | No                 |
| Anything else / ambiguous | **ASK the user**     | —                    | —                  |

### When to ask

If the folder does not clearly match one of the patterns above, or if the folder contains a mix of types that doesn't fit a single item type, **stop and ask the user** which `type` to use. Present the valid enum values:

```
registry:lib, registry:block, registry:component, registry:ui,
registry:hook, registry:theme, registry:page, registry:file,
registry:style, registry:base, registry:font, registry:item
```

For `registry:file` and `registry:page` types, the `target` field is **required** on each file entry. Also ask the user what the target base path should be (i.e. where these files land in the consumer project). Derive each file's `target` by mapping the source subfolder structure onto that base path.

## Step 4 — Build the registry item object

Construct the item following the **shadcn registry-item schema** (`https://ui.shadcn.com/schema/registry-item.json`). All items in this registry must conform to it.

### Required fields

| Field  | How to populate                                                                         |
| ------ | --------------------------------------------------------------------------------------- |
| `name` | Kebab-case identifier. Derive from the folder name. Must be unique across the registry. |
| `type` | From Step 3.                                                                            |

### Recommended fields

| Field                  | How to populate                                                                                                                                                                                                                                        |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `title`                | Title-cased human-readable name derived from `name`.                                                                                                                                                                                                   |
| `description`          | Short sentence: "A {title} {type-noun}" — e.g. "A data table component". Ask the user if unclear.                                                                                                                                                      |
| `dependencies`         | Array of **npm** (or other package manager) packages the code imports that are **not** part of the project itself. Inspect the source files' import/require statements. Leave as `[]` if none.                                                         |
| `devDependencies`      | Same as above but for dev-only deps. Omit the field entirely if empty.                                                                                                                                                                                 |
| `registryDependencies` | Array of other **registry item names** this item depends on. Use the shadcn base name for shadcn/ui components (e.g. `"button"`, `"input"`). Prefix with `@faktion/` for items from this registry (e.g. `"@faktion/combobox"`). Leave as `[]` if none. |
| `files`                | Array of file objects — see below.                                                                                                                                                                                                                     |
| `categories`           | Array of category strings. Infer from the folder structure or ask. Existing categories in this registry: `forms`, `chat`, `table`, `hooks`, `recipes`.                                                                                                 |

### File entry shape

```json
{
  "path": "registry/components/example.tsx",
  "type": "registry:component"
}
```

For `registry:file` and `registry:page` types, add `target`:

```json
{
  "path": "registry/recipes/server/example/handler.ts",
  "type": "registry:file",
  "target": "src/modules/example/handler.ts"
}
```

Rules for `path`:

- Always relative to the **workspace root** (not the `registry/` folder).
- Use forward slashes.
- Must point to the actual file on disk.

Rules for `target` (when required):

- The path where the file should land in the **consumer** project.
- Strip the registry-internal prefix. For example, if the source is `registry/recipes/infrastructure/aws/modules/vpc/main.tf`, and the logical base is `infrastructure/`, the target might be `infrastructure/modules/vpc/main.tf`.
- When the target mapping is ambiguous, ask the user.

### Detecting dependencies from source files

Scan each file for:

- `import ... from '...'` / `require('...')` — JavaScript/TypeScript
- Other language-specific import patterns as applicable

Classify each import:

- **npm dependency** → add to `dependencies` (e.g. `lucide-react`, `@tanstack/react-table`)
- **relative import within the same item** → skip
- **shadcn/ui component** → add to `registryDependencies` by base name (e.g. `button`, `popover`)
- **another item in this registry** → add to `registryDependencies` prefixed with `@faktion/` (e.g. `@faktion/combobox`)
- **project-internal alias** (`@/...`) → evaluate whether it references a registry item or a local module

Do **not** include `react` or `react-dom` in dependencies — they are peer dependencies.

## Step 5 — Validate and insert

1. Validate the item object against the schema mentally:
   - `name` and `type` are present.
   - Every file entry has `path` and `type`.
   - File entries with type `registry:file` or `registry:page` also have `target`.
   - `name` is unique in the registry.
2. Read the current `registry.json` again right before editing (to avoid conflicts).
3. Append the new item object to the end of the `items` array.
4. Ensure the resulting JSON is valid and properly formatted (2-space indent, trailing newline).

## Step 6 — Add the item to the UI

The sidebar (`components/blocks/sidebar/app-sidebar.tsx`) updates **automatically** — it reads categories from `registry.json` via `useCategories()`. No changes needed there.

The **section pages** are manual. Each registry item must be rendered explicitly in the correct section file. The approach differs by type:

### 6a. Components (`registry:component`)

Add a `<Component>` entry to the section file matching the item's category.

| Category        | Section file                   |
| --------------- | ------------------------------ |
| _(no category)_ | `app/sections/default.tsx`     |
| `forms`         | `app/sections/forms.tsx`       |
| `chat`          | `app/sections/chat.tsx`        |
| `table`         | `app/sections/table.tsx`       |
| _new category_  | Create a new section — see 6d. |

Steps:

1. **Import** the component from `@/registry/components/{path}`.
2. **Add a `<Component>` block** inside the section's fragment (`<>...</>`):

```tsx
<Component
  name='{name}'
  description='{description}'
  code={`
    <MyComponent prop="value" />
  `}>
  <MyComponent prop='value' />
</Component>
```

- `code` — a short, representative **usage example** as a string (shown in the Code tab).
- `children` — the **live rendered** component (shown in the Preview tab). If the component cannot be previewed without server-side data or external services, use a placeholder: `<span>Check \`code\` tab for usage</span>`.

### 6b. Hooks (`registry:hook`)

Add to `app/sections/hooks.tsx`.

```tsx
<Component
  name='{name}'
  description='{description}'
  code={`
    const { result } = useMyHook();
  `}>
  <span> Check `code` tab for usage</span>
</Component>
```

Hooks never have a live preview — always use the placeholder children.

### 6c. Recipes (`registry:file` with category `recipes`)

Recipes require **three** changes:

#### 1. Ensure a markdown file exists

The recipe folder must contain a `.MD` documentation file (e.g. `MY-RECIPE.MD`). If it doesn't exist, **create one** with a brief description of the recipe, its purpose, and basic usage instructions.

#### 2. Create an API route

Create `app/api/recipes/{slug}/route.ts` that serves the markdown. Follow this exact pattern:

```typescript
import { NextResponse } from 'next/server';
import fs from 'node:fs/promises';
import path from 'node:path';

export async function GET() {
  try {
    const markdownPath = path.join(
      process.cwd(),
      'registry',
      'recipes',
      '{...path segments to the .MD file}'
    );
    const md = await fs.readFile(markdownPath, 'utf8');
    return new Response(md, {
      headers: {
        'content-type': 'text/markdown; charset=utf-8',
        'cache-control': 's-maxage=300, stale-while-revalidate=86400',
      },
    });
  } catch (error) {
    console.error('Failed to load {title} recipe.', error);
    return NextResponse.json(
      { error: 'Failed to load {title} recipe.' },
      { status: 500 }
    );
  }
}
```

The `{slug}` in the route folder name should be a short kebab-case identifier for the recipe (e.g. `microsoft-sso`, `prompthandler`, `aws-iac`).

#### 3. Add to the Recipes section

In `app/sections/recipes.tsx`, add a `<Markdown>` entry:

```tsx
<Markdown
  name='{name}'
  description='{description}'
  url='/api/recipes/{slug}'
/>
```

`<Markdown>` (from `@/components/markdown`) fetches the markdown from the API route and renders it in a code viewer. No live preview — it shows "Check `code` tab for recipe".

### 6d. New category / new section

If the item's category doesn't match an existing section file:

1. Create `app/sections/{category}.tsx`:

```tsx
'use client';

import Component from '@/components/component';
// or: import Markdown from '@/components/markdown';

const { CategoryPascal } = () => <>{/* items go here */}</>;

export default { CategoryPascal };
```

2. Import and render the new section in `app/page.tsx` inside `<main>`:

```tsx
import {CategoryPascal} from '@/app/sections/{category}';
// ...
<main className='flex flex-col flex-1 gap-8'>
  {/* ...existing sections... */}
  <{CategoryPascal} />
</main>
```

## Step 7 — Confirm to the user

After writing all files, summarize what was done:

- Item name and type
- Number of files registered
- Any dependencies or registry dependencies detected
- The categories assigned
- Which section file was updated (or created)
- Whether an API route was created (recipes only)
- Whether a markdown file was created (recipes only)

## Examples

### Adding a single component

Given folder: `registry/components/my-widget.tsx` (single file, not a folder)

**registry.json entry:**

```json
{
  "name": "my-widget",
  "type": "registry:component",
  "title": "My Widget",
  "description": "A my widget component",
  "dependencies": [],
  "registryDependencies": [],
  "files": [
    {
      "path": "registry/components/my-widget.tsx",
      "type": "registry:component"
    }
  ],
  "categories": ["forms"]
}
```

**UI change** — append to `app/sections/forms.tsx`:

```tsx
import MyWidget from '@/registry/components/my-widget';
// inside the fragment:
<Component
  name='my-widget'
  description='A my widget component'
  code={`<MyWidget value="hello" />`}>
  <MyWidget value='hello' />
</Component>;
```

### Adding a recipe folder

Given folder: `registry/recipes/server/microsoft-sso/`

**registry.json entry:**

```json
{
  "name": "microsoft-sso",
  "type": "registry:file",
  "title": "Microsoft SSO",
  "description": "A Microsoft SSO recipe",
  "dependencies": [
    "@nestjs/common",
    "@nestjs/passport",
    "@nestjs/axios",
    "passport-oauth2"
  ],
  "registryDependencies": [],
  "files": [
    {
      "path": "registry/recipes/server/microsoft-sso/microsoft.strategy.ts",
      "type": "registry:file",
      "target": "src/modules/auth/microsoft.strategy.ts"
    },
    {
      "path": "registry/recipes/server/microsoft-sso/microsoft.guard.ts",
      "type": "registry:file",
      "target": "src/modules/auth/microsoft.guard.ts"
    }
  ],
  "categories": ["recipes"]
}
```

**UI changes** — three files:

1. Ensure `registry/recipes/server/microsoft-sso/MICROSOFT-SSO.MD` exists.
2. Create `app/api/recipes/microsoft-sso/route.ts` serving that markdown.
3. Add to `app/sections/recipes.tsx`:

```tsx
<Markdown
  name='microsoft-sso'
  description='A Microsoft SSO recipe'
  url='/api/recipes/microsoft-sso'
/>
```

### Adding a hook

Given file: `registry/hooks/use-debounce.tsx`

**UI change** — append to `app/sections/hooks.tsx`:

```tsx
<Component
  name='use-debounce'
  description='A hook to debounce a value'
  code={`const debouncedValue = useDebounce(value, 300);`}>
  <span> Check `code` tab for usage</span>
</Component>
```

### Adding a subfolder of components (e.g. table/)

Given folder: `registry/components/table/`

Each file becomes a **separate** registry item (following the existing pattern in this registry where `column-header`, `selectable-row`, `pagination`, and `data-table` are each their own item). Only group multiple files into one item when they clearly form a single logical unit (like a recipe with supporting files). Each item gets its own `<Component>` entry in the matching section file.

## Important rules

### Registry

- **Never remove or reorder existing items** — only append.
- **Never modify existing items** unless the user explicitly asks to update one.
- **Always use the shadcn registry schema** — do not invent custom fields.
- **Preserve the `$schema`, `name`, and `homepage` top-level fields** exactly as they are.
- **Ask when in doubt** — it is better to ask the user than to guess wrong on type, target path, or categories.
- **Inspect file contents** — do not guess dependencies; read the actual imports.

### UI

- **Always add the item to the UI** — a registry entry without a UI entry is incomplete.
- **Recipes always need all three**: markdown file, API route, and `<Markdown>` in the section.
- **Follow existing patterns exactly** — read the target section file before editing to match its import style, spacing, and JSX structure.
- **The sidebar is automatic** — do not edit `components/blocks/sidebar/app-sidebar.tsx`; it reads from `registry.json` via `useCategories()`.
- **Components use `<Component>`** from `@/components/component` — hooks and recipes also use it (recipes via `<Markdown>` wrapper from `@/components/markdown`).
- **The `code` prop is a usage example string** — keep it short and representative. It is displayed in a code viewer, not executed.
- **Provide a live preview when possible** for components — if the component needs external data or services to render, use a placeholder child instead.
