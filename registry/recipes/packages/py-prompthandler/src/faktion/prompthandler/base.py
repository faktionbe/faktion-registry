import re
from abc import ABC, abstractmethod
from typing import Any


class BasePromptHandler(ABC):
    """Base class for all prompt handlers."""

    @abstractmethod
    def create_prompt(self, name: str, content: str, *args, **kwargs):
        """
        Create a new prompt with the given name and content.

        Args:
            name (str): Name of the prompt.
            content (str): Content of the prompt.
        """
        pass

    @abstractmethod
    def _get_prompt(self, name: str, context: dict[str, Any] | None = None, *args, **kwargs) -> str:
        """
        Get the content of a prompt with the given name.

        Args:
            name (str): Name of the prompt.
            context (dict[str, str] | None, optional): A dictionary of parameters to be used for replacing variables in the prompt content. Defaults to None.

        Returns:
            str: The content of the prompt.
        """
        pass

    def get_prompt(
        self,
        name: str,
        context: (
            dict[str, Any] | None
        ) = None,  # This can be used to retrieve nested prompts. If context is None, the prompt is returned as is without looking for nested prompts.
        max_recursion: int = 5,
        auto_compile: bool = False,
        raise_on_missing_input: bool = True,
        _is_recursive: bool = False,
        *args,
        **kwargs,
    ) -> str:
        """
        Get the prompt content for a given name. Each prompt handler fetches the prompt content from the corresponding source. This function can be used to retrieve nested prompts by providing a context dictionary.

        Args:
            name (str): The name of the prompt.
            context (dict[str, str]  |  None, optional): A dictionary of parameters to be used for replacing variables in the prompt content. Defaults to None.
            auto_compile (bool, optional): Whether to automatically compile the prompt content by replacing variables with their corresponding values. Defaults to False.
            raise_on_missing_input (bool, optional): Whether to raise an error if any input parameters are missing. Defaults to True.
            _is_recursive (bool, optional): Internal flag to indicate if the function is being called recursively. Defaults to False.

        Raises:
            ValueError: If the prompt with the given name is not found.
            ValueError: If any input parameters are missing and the maximum recursion depth is reached.
            ValueError: If any other error occurs while retrieving the prompt.

        Returns:
            str: The prompt content.
        """
        name = name.strip()
        try:
            content = self._get_prompt(name=name, *args, **kwargs)  # type: ignore[misc]
        except Exception:
            if not _is_recursive:
                raise ValueError(f'Prompt or variable with name "{name}" not found.')
            else:
                if raise_on_missing_input:
                    raise ValueError(f'Prompt or variable with name "{name}" not found.')
                else:
                    return f"{{{name}}}"

        if context is None:
            return content
        prompt_variables = set(re.findall(r"\{(.*?)\}", content))
        missing_context_keys = list(prompt_variables - set(context.keys()))
        if len(missing_context_keys) > 0:
            if max_recursion == 0:
                if raise_on_missing_input:
                    raise ValueError(f"Missing input context: {missing_context_keys} - max recursion reached.")
                else:
                    return content
            for missing_variable in missing_context_keys:
                try:
                    inner_content = self.get_prompt(  # type: ignore[misc]
                        name=missing_variable,
                        context=context,
                        raise_on_missing_input=raise_on_missing_input,
                        max_recursion=max_recursion - 1,
                        _is_recursive=True,
                        *args,
                        **kwargs,
                    )
                except ValueError as e:
                    raise e
                content = content.replace(f"{{{missing_variable}}}", inner_content)
        if not _is_recursive and auto_compile:
            for key, value in context.items():
                content = content.replace(f"{{{key}}}", str(value))
        return content

    def compile_prompt(self, content: str, context: dict[str, Any]) -> str:
        """
        Compile the prompt by replacing placeholders with provided parameters.

        Args:
            content (str): The content of the prompt with placeholders.
            context (dict[str, str]): A dictionary containing the parameter values to replace the placeholders.

        Returns:
            str: The compiled prompt with placeholders replaced by parameter values.
        """
        return content.format(**context)

    @abstractmethod
    def update_prompt(self, name: str, content: str, *args, **kwargs):
        """
        Update the content of an existing prompt with the given name.

        Args:
            name (str): Name of the prompt.
            content (str): New content of the prompt.
        """
        pass
