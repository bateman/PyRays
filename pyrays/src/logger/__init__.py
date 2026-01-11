"""Logger module."""

from pyrays.config import config

from .logger import Logger

logger = Logger()
Logger.set_log_level(config.log_level)
