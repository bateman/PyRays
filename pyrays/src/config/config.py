"""Module for handling configuration file.

Configurations are loaded from a JSON file and can be accessed as attributes of the `Config` class.


``` py title="Example"
config = Config("path/to/config.json")
config.some_attribute
```

"""

import json


def _try_convert_to_number(value):
    """Try to convert a value to a number (int or float).

    Args:
        value: The value to convert.

    Returns:
        The converted number, or the original value if conversion fails.

    """
    if isinstance(value, (int, float)):
        return value
    if isinstance(value, str):
        try:
            # Try int first, then float
            if "." in value or "e" in value.lower():
                return float(value)
            return int(value)
        except ValueError:
            return value
    return value


class Config:
    """The configuration class that handles configuration files."""

    def __init__(self, filename: str) -> None:
        """Initialize the Config class by loading configurations from a given file.

        Args:
            filename (str): The name of the configuration file.

        """
        # ensure a file exists and is actually read
        if filename:
            try:
                with open(filename, "r") as f:
                    _config = json.load(f)
                    for key, val in _config.items():
                        if isinstance(val, dict):
                            for subkey, subval in val.items():
                                subval = _try_convert_to_number(subval)
                                setattr(self, subkey, subval)
                        else:
                            val = _try_convert_to_number(val)
                            setattr(self, key, val)
            except FileNotFoundError:
                raise FileNotFoundError(f"Config file {filename} not found.")

    def __getattr__(self, name: str):
        """Raise AttributeError for missing attributes.

        Args:
            name: The name of the attribute.

        Raises:
            AttributeError: Always raised for missing attributes.

        """
        raise AttributeError(
            f"'{type(self).__name__}' object has no attribute '{name}'"
        )
