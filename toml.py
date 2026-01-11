"""The module is used to update the 'pyproject.toml' file with the provided command line arguments."""

import argparse
import os
import sys
from typing import Optional

import tomlkit

# Path to pyproject.toml relative to this script's location
_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
_PYPROJECT_PATH = os.path.join(_SCRIPT_DIR, "pyproject.toml")


def get_dict() -> dict | None:
    """Get the 'pyproject.toml' file as a dictionary."""
    with open(_PYPROJECT_PATH, "r") as file:
        data = tomlkit.loads(file.read())
        return data


def update_toml(
    name: Optional[str],
    version: Optional[str],
    description: Optional[str],
    repository: Optional[str],
    license: Optional[str],
) -> None:
    """Update the 'pyproject.toml' file with the provided parameters.

    Args:
        name: The name of the project
        version: The version of the project
        description: A short description of the project
        repository: The URL of the project's repository
        license: The license of the project

    """
    with open(_PYPROJECT_PATH, "r") as file:
        data = tomlkit.loads(file.read())

    if name:
        data["project"]["name"] = name
    if version:
        data["project"]["version"] = version
    if description:
        data["project"]["description"] = description
    if repository:
        data["project"]["repository"] = repository
    if license:
        data["project"]["license"] = license

    with open(_PYPROJECT_PATH, "w") as file:
        file.write(tomlkit.dumps(data))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--name", help="The name of project")
    parser.add_argument("--ver", help="The version of the project")
    parser.add_argument("--desc", help="A short description of the project")
    parser.add_argument("--repo", help="The URL of the project's repository")
    parser.add_argument("--lic", help="The license of the project")
    args = parser.parse_args()

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)
    else:
        update_toml(args.name, args.ver, args.desc, args.repo, args.lic)
