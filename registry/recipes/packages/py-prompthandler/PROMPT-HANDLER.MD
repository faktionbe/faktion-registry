## py-prompthandler

`py-prompthandler` is a small Python library used as the **ML backend prompt handler** in this repository.  
It provides an abstract `BasePromptHandler` plus a concrete `InMemoryPromptHandler` implementation to:

- **Create** prompts and store them (e.g. in memory or in another backend you implement).
- **Retrieve** prompts by name, including **nested prompts** that can reference each other.
- **Render / compile** prompts with:
  - Python-style `{variable}` placeholders.
  - Jinja2-style `[[ variable ]]` expressions with auto-escaping.

This package is intended to be embedded inside ML services or workers that need a simple but flexible prompt-management layer.

---

## What the package does

- **`BasePromptHandler` (`base.py`)**
  - Defines the core interface for any prompt handler:
    - `create_prompt(name, content, **kwargs)`: create or register a prompt.
    - `_get_prompt(name, context=None, **kwargs) -> str`: low-level retrieval method, to be implemented by subclasses.
    - `get_prompt(name, context=None, max_recursion=5, auto_compile=False, ...) -> str`:
      - Fetches a prompt by name.
      - Supports **nested prompts**: missing `{variable}` placeholders can be resolved by calling `get_prompt` recursively on other prompt names.
      - Optionally compiles placeholders using the provided `context`.
    - `compile_prompt(content, context) -> str`: convenience `{key}`-style string formatting.
    - `update_prompt(name, content, **kwargs)`: update an existing prompt.

- **`InMemoryPromptHandler` (`in_memory.py`)**
  - Stores prompts in a simple in-memory `dict[str, str]`.
  - Normalizes mixed Jinja / format syntax:
    - Converts `{{ var }}` to `{var}` so it can be handled by the base class.
  - Uses **Jinja2** with `[[ ... ]]` delimiters for templating, with auto-escaping enabled.
  - Offers a `from_module(prompt_module)` helper:
    - Scans a Python module for **UPPER_CASE string constants** and turns them into prompts.

- **Tests (`test_in_memory.py`)**
  - Cover initialization, creation, update, nested / auto-compiled prompts and various Jinja2 rendering behaviours.

---

## Python dependencies

The canonical dependency list is defined in `pyprompt.toml`:

- **Runtime dependencies**
  - `pydantic>=2.11`
  - `jinja2>=3.1.6`

- **Dev / tooling dependencies**
  - `pytest>=7.4.0` (test runner)
  - `ruff>=0.1.0` (linting & formatting)
  - `mypy>=1.6.0` (type checking)

The project uses **setuptools** for packaging and expects `src`-based layout per `pyprompt.toml`.

---

## Recommended installation (local dev / ML environment)

You can install dependencies either with `uv` (preferred in this repo) or with `pip`.

### Option 1 – Using `uv` (recommended)

From `registry/recipes/packages/prompt-handler/`:

```bash
uv sync
```

This will install both runtime and dev dependencies as defined in `pyprompt.toml`.

### Option 2 – Using `pip`

If you prefer a plain `pip` workflow, install the equivalent dependencies manually:

```bash
pip install "pydantic>=2.11" "jinja2>=3.1.6"

# For development / running tests:
pip install "pytest>=7.4.0" "ruff>=0.1.0" "mypy>=1.6.0"
```

---

## Basic usage examples

### In-memory handler

```python
from faktion.prompthandler.in_memory import InMemoryPromptHandler

handler = InMemoryPromptHandler()
handler.create_prompt("GREETING", "Hello {name}!")

# Just retrieve the template
template = handler.get_prompt("GREETING")
# "Hello {name}!"

# Retrieve and compile with context
prompt = handler.get_prompt("GREETING", context={"name": "Alice"}, auto_compile=True)
# "Hello Alice!"
```

### Using nested prompts

```python
handler = InMemoryPromptHandler(
    prompts={
        "BASE": "User: {USER_NAME}",
        "USER_NAME": "{first_name} {last_name}",
    }
)

prompt = handler.get_prompt(
    "BASE",
    context={"first_name": "Ada", "last_name": "Lovelace"},
    auto_compile=True,
)
# "User: Ada Lovelace"
```

### Using Jinja2-style `[[ ... ]]` variables

```python
handler = InMemoryPromptHandler()
handler.create_prompt("STATS", "Hello [[ user_name ]]! Count: [[ count ]]")

prompt = handler.get_prompt("STATS", user_name="Alice", count=5, auto_compile=True)
# "Hello Alice! Count: 5"
```

---

## How to use this in an ML service

- **Centralise prompt definitions** in a Python module or config, then:
  - Load them into an `InMemoryPromptHandler` (or your own subclass backed by DB / files / API).
  - Use `get_prompt(...)` to assemble the final prompt just before calling your LLM.
- **Leverage nested prompts** for reusable sub-components (headers, footers, system messages).
- **Use Jinja2 templating** for more complex logic while keeping the base API simple.

This gives your ML service a clear, testable layer for prompt management, decoupled from the rest of the application logic.