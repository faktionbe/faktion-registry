"""Test configuration and fixtures for the prompt handler package."""

from types import ModuleType

import pytest

from faktion.prompthandler.in_memory import InMemoryPromptHandler


@pytest.fixture
def sample_prompts():
    """Sample prompts for testing."""
    return {
        "GREETING": "Hello {name}!",
        "FAREWELL": "Goodbye {name}, see you later!",
        "NESTED_PROMPT": "This is a nested prompt: {GREETING}",
        "COMPLEX_PROMPT": "User: {name}, Age: {age}, City: {city}",
        "JINJA_TEMPLATE": "Hello [[ name ]]! You have [[ count ]] messages.",
        "MIXED_TEMPLATE": "Hello {name}! You have [[ count ]] messages and [[ status ]] status.",
    }


@pytest.fixture
def empty_handler():
    """Empty InMemoryPromptHandler for testing."""
    return InMemoryPromptHandler()


@pytest.fixture
def populated_handler(sample_prompts):
    """InMemoryPromptHandler with sample prompts."""
    return InMemoryPromptHandler(prompts=sample_prompts)


@pytest.fixture
def sample_module():
    """Sample module with prompts as constants for testing from_module method."""
    module = ModuleType("test_module")
    module.GREETING = "Hello {name}!"
    module.FAREWELL = "Goodbye {name}!"
    module._PRIVATE = "This should be ignored"
    module.not_upper = "This should be ignored"
    module.NOT_STRING = 123
    return module
