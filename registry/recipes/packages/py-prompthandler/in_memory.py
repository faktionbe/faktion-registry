import re
from types import ModuleType

from jinja2 import BaseLoader, Environment

from .base import BasePromptHandler


class InMemoryPromptHandler(BasePromptHandler):
    """
    InMemoryPromptHandler handles prompts in memory.
    """

    def __init__(self, prompts: dict[str, str] | None = None) -> None:
        """
        Initialize a Prompt handler that saves prompts in memory.

        Args:
            prompts (dict[str, str] | None, optional): A dictionary of prompts, If None an empty dictionary is used meaning there are no existing prompts yet. Defaults to None.
        """
        super().__init__()
        self.prompts = prompts or dict()

    def create_prompt(self, name: str, content: str, *args, **kwargs):
        """
        Create a new prompt with the given name and content.

        Args:
            name (str): Name of the prompt.
            content (str): Content of the prompt.
        """
        self.prompts[name] = content

    def _get_prompt(
        self,
        name: str,
        *args,
        **kwargs,
    ) -> str:
        """
        Get the content of a prompt with the given name.

        Args:
            name (str): Name of the prompt.

        Returns:
            str: The content of the prompt.
        """
        content = self.prompts[name]
        content = re.sub(r"{{\s*(\w+)\s*}}", r"{\g<1>}", content)
        env = Environment(
            loader=BaseLoader(),
            autoescape=True,
            variable_start_string="[[",
            variable_end_string="]]",
        ).from_string(content)
        prompt = env.render(**kwargs)
        return prompt

    def update_prompt(self, name: str, content: str, *args, **kwargs):
        """
        Update the content of a prompt with the given name.

        Args:
            name (str): The name of the prompt.
            content (str): The content of the prompt.
        """
        return self.create_prompt(name=name, content=content, *args, **kwargs)  # type: ignore[misc]

    @staticmethod
    def from_module(prompt_module: ModuleType) -> "InMemoryPromptHandler":
        """Create a handler from a Python module with prompts as constants.

        Converts string variables with upper-case names into prompts.
        """
        module_attrs = vars(prompt_module)

        prompts = {}
        for name, value in module_attrs.items():
            if name.startswith("_"):
                continue
            if not name.isupper():
                continue
            if not isinstance(value, str):
                continue

            prompts[name] = value

        if not prompts:
            raise ValueError("No prompts found in module", prompt_module.__package__, list(module_attrs.keys()))

        handler = InMemoryPromptHandler(prompts=prompts)
        return handler