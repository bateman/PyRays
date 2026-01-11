"""The config is a package that does XYZ."""

import os

from .config import Config

__all__ = ["Config", "config"]

# Use path relative to this file's location for portability
_config_dir = os.path.dirname(os.path.abspath(__file__))
_config_path = os.path.join(_config_dir, "config.json")

config = Config(_config_path)
