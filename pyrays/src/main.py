"""The main module of your application package."""

import argparse
from typing import Optional, Tuple

from pyrays.logger import logger
from rich.console import Console


class OneClass:
    """The main class of your application package.

    This class is used to encapsulate the main functionality of your application.
    You can define methods and properties here to perform the main tasks of your application.

    """

    console: Console  # An instance of rich console

    def __init__(self) -> None:  # noqa: D107
        logger.debug("Initializing OneClass.")
        self.console = Console()

    _DEFAULT_COLOR = "rgb(128,128,128)"
    _DEFAULT_TEXT = "\nHello, world!"

    def print(
        self,
        text: Optional[str] = None,
        color: Optional[str] = None,
    ) -> None:
        """Print a message in a specified color.

        Args:
            text (Optional[str]): The message to print. Defaults to "Hello, world!".
            color (Optional[str]): The color to print the message in.
                                   This should be a string specifying a color recognized by the `rich` library,
                                   or an RGB color in the format "rgb(r,g,b)" where r, g, and b are integers between 0 and 255.
                                   If not provided, defaults to mid-grey rgb(128,128,128).

        """
        if text is None:
            text = self._DEFAULT_TEXT
        if color is None:
            color = self._DEFAULT_COLOR

        self.console.print(text, style=color)


def run() -> None:
    """Run the main functionality of your application package.

    This function is called when your application is run as a package.
    You can use this function to perform the main tasks of your application.

    Example:
    ``` bash
    python -m pyrays -t "Ciao" -c "red"
    python -m pyrays --text "Mondo" --color "green"
    python -m pyrays -t "Ciao mondo"
    ```
    """
    logger.info("Running the main module.")
    text, color = parse_args()

    oc = OneClass()
    oc.print(text, color)


def parse_args() -> Tuple[str, str]:
    """Parse command line arguments.

    Returns:
        Tuple[str, str]: The text to print in color.

    """
    logger.debug("Parsing command line arguments.")
    parser = argparse.ArgumentParser(description="Prints any text in color.")
    parser.add_argument("-t", "--text", type=str, help="The text to print.")
    parser.add_argument(
        "-c", "--color", type=str, help="The color to print the text in."
    )
    args = parser.parse_args()
    return args.text, args.color


if __name__ == "__main__":
    run()
