"""Provide information about the P3T project template."""

import toml

title = "PyRays - Python + uv Project Template"
description = """
A template repository for GitHub projects using Python and uv. 🚀

## Documentation

Check the documentation as [GitHub Pages](https://bateman.readthedocs.io/PyRays).
"""
toml_dict = toml.get_dict()
if toml_dict is None:
    version = ""
else:
    version = toml_dict["project"]["version"]
terms_of_service = "None"
contact = {
    "name": "Made with 💖 by bateman",
    "url": "https://github.com/bateman/PyRays/issues",
}
license_info = {
    "name": "MIT License",
    "url": "https://github.com/bateman/PyRays/LICENSE",
}
