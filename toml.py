"""The module is used to update the 'pyproject.toml' file with the provided command line arguments."""

import argparse
import sys

import tomlkit


def get_dict() -> dict | None:
    """Get the 'pyproject.toml' file as a dictionary."""
    with open("pyproject.toml", "r") as file:
        data = tomlkit.loads(file.read())
        try:
            return data
        except KeyError:
            return None


def update_toml(
    name: str, version: str, description: str, repository: str, license: str
) -> None:
    """Update the 'pyproject.toml' file with the provided parameters.

    Args:
    ----
        name (str): The name of the project
        version (str): The version of the project
        description (str): A short description of the project
        repository (str): The URL of the project's repository
        license (str): The license of the project

    Returns:
    -------
        None

    """
    with open("pyproject.toml", "r") as file:
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

    with open("pyproject.toml", "w") as file:
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
