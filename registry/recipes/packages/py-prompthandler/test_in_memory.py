"""Tests for InMemoryPromptHandler class."""

import pytest

from faktion.prompthandler.in_memory import InMemoryPromptHandler


class TestInMemoryPromptHandler:
    """Test cases for InMemoryPromptHandler class."""

    def test_initialization_empty(self):
        """Test initialization with no prompts."""
        handler = InMemoryPromptHandler()
        assert handler.prompts == {}

    def test_initialization_with_prompts(self, sample_prompts):
        """Test initialization with existing prompts."""
        handler = InMemoryPromptHandler(prompts=sample_prompts)
        assert handler.prompts == sample_prompts

    def test_create_prompt(self, empty_handler):
        """Test creating a new prompt."""
        empty_handler.create_prompt("test", "Hello {name}!")
        assert empty_handler.prompts["test"] == "Hello {name}!"

    def test_create_prompt_overwrite(self, empty_handler):
        """Test creating a prompt that overwrites existing one."""
        empty_handler.create_prompt("test", "Original")
        empty_handler.create_prompt("test", "Updated")
        assert empty_handler.prompts["test"] == "Updated"

    def test_get_prompt_basic(self, populated_handler):
        """Test getting a prompt without context."""
        result = populated_handler.get_prompt("GREETING")
        assert result == "Hello {name}!"

    def test_get_prompt_with_context_no_autocompile(self, populated_handler):
        """Test getting a prompt with context."""
        result = populated_handler.get_prompt("GREETING", context={"name": "Alice"})
        assert result == "Hello {name}!"

    def test_get_prompt_with_context_autocompile(self, populated_handler):
        """Test getting a prompt with context."""
        result = populated_handler.get_prompt("GREETING", context={"name": "Alice"}, auto_compile=True)
        assert result == "Hello Alice!"

    def test_get_prompt_missing(self, empty_handler):
        """Test getting a non-existent prompt."""
        with pytest.raises(ValueError, match='Prompt or variable with name "missing" not found'):
            empty_handler.get_prompt("missing", auto_compile=True)

    def test_update_prompt(self, populated_handler):
        """Test updating an existing prompt."""
        populated_handler.update_prompt("GREETING", "Updated greeting: {name}!")
        assert populated_handler.prompts["GREETING"] == "Updated greeting: {name}!"

    def test_update_prompt_new(self, empty_handler):
        """Test updating a non-existent prompt (should create it)."""
        empty_handler.update_prompt("NEW", "New prompt: {name}!")
        assert empty_handler.prompts["NEW"] == "New prompt: {name}!"

    def test_jinja_template_processing(self, empty_handler):
        """Test Jinja2 template processing in get_prompt."""
        empty_handler.create_prompt("jinja_test", "Hello [[ user_name ]]! Count: [[ count ]]")

        result = empty_handler.get_prompt("jinja_test", user_name="Alice", count=5, auto_compile=True)
        assert result == "Hello Alice! Count: 5"

    def test_jinja_template_with_mixed_syntax(self, empty_handler):
        """Test Jinja2 template with mixed {variable} and [[variable]] syntax."""
        empty_handler.create_prompt("mixed", "Hello {name}! Count: [[ count ]]")

        result = empty_handler.get_prompt("mixed", context={"name": "Bob"}, count=10, auto_compile=True)
        assert result == "Hello Bob! Count: 10"

    def test_jinja_template_whitespace_handling(self, empty_handler):
        """Test Jinja2 template with whitespace in variables."""
        empty_handler.create_prompt("whitespace", "Hello [[ user_name ]]! Count: [[ count ]]")

        result = empty_handler.get_prompt("whitespace", user_name="Charlie", count=15, auto_compile=True)
        assert result == "Hello Charlie! Count: 15"

    def test_jinja_template_missing_variable(self, empty_handler):
        """Test Jinja2 template with missing variable."""
        empty_handler.create_prompt("missing_var", "Hello [[ user_name ]]! Count: [[ count ]]")

        # with pytest.raises(Exception):  # Jinja2 will raise an exception
        prompt = empty_handler.get_prompt("missing_var", user_name="David", auto_compile=True)
        assert "Count: " in prompt

    def test_jinja_template_autoescape(self, empty_handler):
        """Test Jinja2 autoescape functionality."""
        empty_handler.create_prompt("escape_test", "Hello [[ user_name ]]! HTML: [[ html ]]")

        result = empty_handler.get_prompt(
            "escape_test", user_name="Eve", html="<script>alert('xss')</script>", auto_compile=True
        )
        assert "&lt;script&gt;" in result  # Should be escaped

    def test_complex_jinja_template(self, empty_handler):
        """Test complex Jinja2 template with multiple variables."""
        template = """
        User: [[ user_name ]]
        Age: [[ age ]]
        Status: [[ status ]]
        Messages: [[ message_count ]]
        """
        empty_handler.create_prompt("complex", template)

        result = empty_handler.get_prompt(
            "complex", user_name="Grace", age=30, status="active", message_count=42, auto_compile=True
        )
        assert "User: Grace" in result
        assert "Age: 30" in result
        assert "Status: active" in result
        assert "Messages: 42" in result