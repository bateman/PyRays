"""Script to bump version in pyproject.toml file."""

import argparse
import re
import sys

import tomlkit


def parse_version(version: str) -> tuple[int, int, int, str]:
    """Parse a semantic version string.

    Args:
    ----
        version (str): Version string (e.g., "1.2.3" or "1.2.3-beta.1")

    Returns:
    -------
        tuple: (major, minor, patch, prerelease)

    """
    match = re.match(r"^(\d+)\.(\d+)\.(\d+)(?:-(.+))?$", version)
    if not match:
        raise ValueError(f"Invalid version format: {version}")

    major, minor, patch, prerelease = match.groups()
    return int(major), int(minor), int(patch), prerelease or ""


def bump_version(current_version: str, bump_type: str) -> str:
    """Bump the version according to the specified type.

    Args:
    ----
        current_version (str): Current version string
        bump_type (str): Type of version bump (major, minor, patch, prepatch, preminor, premajor, prerelease, --next-phase)

    Returns:
    -------
        str: New version string

    """
    major, minor, patch, prerelease = parse_version(current_version)

    if bump_type == "major":
        return f"{major + 1}.0.0"
    elif bump_type == "minor":
        return f"{major}.{minor + 1}.0"
    elif bump_type == "patch":
        return f"{major}.{minor}.{patch + 1}"
    elif bump_type == "prepatch":
        return f"{major}.{minor}.{patch + 1}-beta.0"
    elif bump_type == "preminor":
        return f"{major}.{minor + 1}.0-beta.0"
    elif bump_type == "premajor":
        return f"{major + 1}.0.0-beta.0"
    elif bump_type == "prerelease":
        if not prerelease:
            return f"{major}.{minor}.{patch + 1}-beta.0"
        # Increment prerelease number
        match = re.match(r"^(.+?)\.(\d+)$", prerelease)
        if match:
            prefix, num = match.groups()
            return f"{major}.{minor}.{patch}-{prefix}.{int(num) + 1}"
        return f"{major}.{minor}.{patch}-{prerelease}.0"
    elif bump_type == "--next-phase":
        if not prerelease:
            raise ValueError("Cannot use --next-phase on a non-prerelease version")
        # Remove prerelease suffix to promote to stable
        return f"{major}.{minor}.{patch}"
    else:
        raise ValueError(f"Invalid bump type: {bump_type}")


def get_current_version() -> str:
    """Get the current version from pyproject.toml.

    Returns
    -------
        str: Current version string

    """
    with open("pyproject.toml", "r") as file:
        data = tomlkit.loads(file.read())
    return data["project"]["version"]


def update_version(new_version: str) -> None:
    """Update the version in pyproject.toml.

    Args:
    ----
        new_version (str): New version string

    """
    with open("pyproject.toml", "r") as file:
        data = tomlkit.loads(file.read())

    data["project"]["version"] = new_version

    with open("pyproject.toml", "w") as file:
        file.write(tomlkit.dumps(data))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Bump version in pyproject.toml",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Bump types:
  major        Increment major version (1.2.3 -> 2.0.0)
  minor        Increment minor version (1.2.3 -> 1.3.0)
  patch        Increment patch version (1.2.3 -> 1.2.4)
  prepatch     Increment patch and add beta (1.2.3 -> 1.2.4-beta.0)
  preminor     Increment minor and add beta (1.2.3 -> 1.3.0-beta.0)
  premajor     Increment major and add beta (1.2.3 -> 2.0.0-beta.0)
  prerelease   Increment prerelease version (1.2.3-beta.0 -> 1.2.3-beta.1)
  --next-phase Promote prerelease to stable (1.2.3-beta.0 -> 1.2.3)
        """,
    )
    parser.add_argument(
        "bump_type",
        choices=[
            "major",
            "minor",
            "patch",
            "prepatch",
            "preminor",
            "premajor",
            "prerelease",
            "--next-phase",
        ],
        help="Type of version bump",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without making changes",
    )

    args = parser.parse_args()

    try:
        current = get_current_version()
        new = bump_version(current, args.bump_type)

        if args.dry_run:
            print(f"{current} -> {new}")
        else:
            update_version(new)
            print(new)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
