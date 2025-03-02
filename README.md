<div align="center"><img src="https://raw.githubusercontent.com/bateman/PyRays/main/images/logo/logo.png" width="250"></div>

![PyPI - Version](https://img.shields.io/pypi/v/PyRays?style=flat-square&color=%23007EC6)
![GitHub Release](https://img.shields.io/github/v/release/bateman/PyRays?style=flat-square)
![GitHub top language](https://img.shields.io/github/languages/top/bateman/PyRays?style=flat-square)
![Codecov](https://img.shields.io/codecov/c/github/bateman/PyRays?style=flat-square)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/bateman/PyRays/release.yml?style=flat-square)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/bateman/PyRays/docker.yml?style=flat-square&label=docker)
![GitHub Pages Status](https://img.shields.io/badge/docs-passing-46cc14?style=flat-square)
![GitHub License](https://img.shields.io/github/license/bateman/PyRays?style=flat-square)

A template repository for GitHub projects using Python and uv.

## Makefile

The project relies heavily on `make`, which is used to run *all* commands. It has been tested on macOS and Ubuntu 22.04. Windows users need to install [WSL](https://learn.microsoft.com/en-us/windows/wsl/install).

Run `make` to see the list of the available targets.

```console
$ make [help]

Usage:
  make [target] [ARGS="..."]

Info
  help                  Show this help message
  info                  Show development environment info
System
  python                Check if Python is installed
  virtualenv            Check if virtualenv exists and activate it - create it if not
  uv                    Check if uv is installed
  uv-update             Update uv
Project
  install               Install the project for development
  production            Install the project for production
  update                Update all project dependencies
  clean                 Clean the project - removes all cache dirs and stamp files
  reset                 Cleans plus removes the virtual environment (use ARGS="hard" to re-initialize the project)
  run                   Run the project
  test                  Run the tests
  build                 Build the project as a package
  build-all             Build the project package and generate the documentation
  publish               Publish the project to PyPI (use ARGS="<PyPI token>")
  publish-all           Publish the project package to PyPI and the documentation to GitHub Pages
  export-deps           Export the project's dependencies to requirements*.txt files
Check
  format                Format the code
  lint                  Lint the code
  precommit             Run all pre-commit checks
Release
  tag                   Tag a new release version (use ARGS="..." to specify the version)
  release               Push the tagged version to origin - triggers the release and docker actions
Docker
  docker-build          Build the Docker image
  docker-run            Run the Docker container
  docker-all            Build and run the Docker container
  docker-stop           Stop the Docker container
  docker-remove         Remove the Docker image, container, and volumes
Documentation
  docs-build            Generate the project documentation
  docs-serve            Serve the project documentation locally
  docs-publish          Publish the project documentation to GitHub Pages (use ARGS="--force" to force the deployment)
```

## Installation

This is a template repository, so first, create a new GitHub repository and choose this as its template. Then, follow the installation steps below.

1. Clone the repository: `git clone https://github.com/<your-github-name>/<your-project-name>.git `
2. Navigate to the project directory: `cd <your-project-name>`
3. Check the status of the dev environment: `make info` will list the tools currently installed and the default value of project vars, as in the example below:

        pyrays v0.1.0

        System:
          OS: Darwin
          Shell: /bin/bash - GNU bash, version 3.2.57(1)-release (arm64-apple-darwin24)
          Make: GNU Make 3.81
          Git: git version 2.39.5 (Apple Git-154)
        Project:
          Project name: pyrays
          Project description: 'A GitHub template for Python projects using uv'
          Project author: Fabio Calefato (bateman <fcalefato@gmail.com>)
          Project version: 0.1.0
          Project license: MIT
          Project repository: https://github.com/bateman/PyRays
          Project directory: /Users/fabio/Dev/git/PyRays
        Python:
          Python version: 3.11.11
          Virtualenv name: .venv
          uv version: uv 0.6.2 (6d3614eec 2025-02-19)
        Docker:
          Docker: Docker version 27.5.1, build 9f9e405
          Docker Compose: Docker Compose version v2.32.4-desktop.1
          Docker image name: pyrays
          Docker container name: pyrays

4. If any needed tools are missing, they will be marked as '*not installed*'. Install them and re-run `make info` to ensure the tools are now correctly installed and in your PATH.
5. Update the project variables values by editing `pyproject.toml`. In addition, you can add any of the variables in the list below to a `Makefile.env` file to override the default values used in the  `Makefile`. You can check the configuration of each variable using `make info`.

        PYTHON_VERSION=3.11.11
        DOCKER_CONTAINER_NAME=pyrays
        DOCKER_IMAGE_NAME=pyrays

6. To create the virtual environment, run `make virtualenv`. Note that this will also check for the requested Python version; if not available, it will ask you to use `uv` to install it.
7. To complete the installation for development purposes, run `make install` -- this will install all development dependencies. Otherwise, for production purposes only, run `make production`.

> [!TIP]
> The installation step will install some 'default' dependencies, such as `rich` and `pretty-errors`, but also dev-dependecies, such as `ruff` and `pytest`.
> Edit the `pyproject.toml` to add/remove dependencies before running `make install`. Otherwise, you can add and remove dependencies later using `uv add` and `uv remove` commands.

> [!NOTE]
> The `name` field in `pyproject.toml` will be converted to lowercase and whitespaces will be replaced by `_`. This value will be the name of your project module.

> [!CAUTION]
> The `Makefile.env` should specify at least the `PYTHON_VERSION=...`. Otherwise, the GitHub Actions will fail. Also, make sure that the Python version specified in `Makefile.env` (e.g., 3.12.1) satisfies the requirements in `pyproject.toml` file (e.g., python = "^3.12").

## Development

The project uses the following development libraries:

* `ruff`: for code linting, formatting, and security analysis.
* `mypy`: for static type-checking.
* `pre-commit`: for automating all the checks above before committing.

> [!TIP]
> To manually run code formatting and linting, run `make format` and `make lint`, respectively.
> To execute all the checks, stage your changes, then run `make precommit`.

## Execution

* To run the project: `make run`

> [!TIP]
> Pass parameters using the ARGS variable (e.g., `make run ARGS="--text Ciao --color red"`).

## Testing

* To run the tests: `make test`

> [!TIP]
> Pass parameters using the ARGS variable (e.g., `make test ARGS="--cov-report=xml"`).

> [!NOTE]
> Tests are executed using `pytest`. Test coverage is calculated using the plugin `pytest-cov`.

> [!WARNING]
> Pushing new commits to GitHub, will trigger the GitHub Action defined in `tests.yml`, which will upload the coverage report to [Codecov](https://about.codecov.io/). To ensure correct execution, first log in to Codecov and enable the coverage report for your repository; this will generate a `CODECOV_TOKEN`. Then, add the `CODECOV_TOKEN` to your repository's 'Actions secrets and variables' settings page.

## Update

Run `make update` to update all the dependencies using `uv`.

## Build

Run `make build` to build the project as a Python package.
The `*.tar.gz` and `*.whl` will be placed in the `BUILD` directory (by default `dist/`).

> [!TIP]
> Run `make build-all` to build both the project's wheel and tarball, as well as the documentation site.

## Release

* Run `make release ARGS="<semvertag>"` to bump the version of the project and write the new version back to `pyproject.toml`, where `<semvertag>` is one of the following rules: `patch`, `minor`, `major`, `prepatch`, `preminor`, `premajor`, `prerelease`.

  The table below illustrates the effect of these rules with concrete examples.

  | **Rule**     | **Before** | **After** |
  |--------------|-----------:|----------:|
  | `major`      |    1.3.0   |   2.0.0   |
  | `minor`      |    2.1.4   |   2.2.0   |
  | `patch`      |    4.1.1   |   4.1.2   |
  | `premajor`   |    1.0.2   |  2.0.0a0  |
  | `preminor`   |    1.0.2   |  1.1.0a0  |
  | `prepatch`   |    1.0.2   |  1.0.3a0  |
  | `prerelease` |    1.0.2   |  1.0.3a0  |
  | `prerelease` |   1.0.3a0  |  1.0.3a1  |
  | `prerelease` |   1.0.3b0  |  1.0.3b1  |

* Run `make release ARGS="<semvertag>"` to:
1. Push the tagged version to the origin repository
2. Trigger two GitHub Actions workflows:
   - `release.yml`: Creates and uploads a new release to GitHub
   - `docker.yml`: Builds and pushes a new Docker image to DockerHub

   The specific workflows are detailed in the GitHub Actions section below.

## GitHub Actions

As shown in the table below, there are four GitHub Actions workflow. Take note on the event triggering the run and the Secrets needed for a successful execution.

| **Action name** | **Purpose**                                 | **Runs on**                                            | **Secrets**                             |
|:---------------:|---------------------------------------------|--------------------------------------------------------|-----------------------------------------|
|  `release.yml`  | Release package to PyPI and GitHub 📦       | tag push                                               | -                                       |
|   `docker.yml`  | Push image to DockerHub 🚀                  | tag push                                               | `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` |
|   `tests.yml`   | Run tests and upload coverage to Codecov 📊 | commit push on branches != `main`, manual              | `CODECOV_TOKEN`                         |
|    `docs.yml`   | Upload documentation to GitHub Pages 📓     | commit push on `docs/**` path of `main` branch, manual | `RELEASE_TOKEN`                         |

> [!CAUTION]
> Follow this [guide](https://packaging.python.org/en/latest/guides/publishing-package-distribution-releases-using-github-actions-ci-cd-workflows/#configuring-trusted-publishing) and configure PyPI’s trusted publishing implementation to connect to GitHub Actions CI/CD. Otherwise, the release workflow will fail.

## Publish to PyPI

To manually publish your package to PyPI, run `make publish`. If necessary, this will build the project as a Python package and upload the generated `*.tar.gz` and `*.whl` files to PyPI.

> [!TIP]
> Run `make publish-all` to manually publish the package to PyPI and the documentation site to GitHub Pages.

> [!WARNING]
> Before trying to manually publish your package to PyPI, make sure you have a valid API token. Then, you need to create a `.env' file formatted as follows:
> ```
> UV_PUBLISH_PASSWORD=<your-PyPI-token-here>
> UV_PUBLISH_USERNAME=__token__
> ```

> [!TIP]
> I recommend installing `autoenv` via [homebrew](https://brew.sh) to automatically load the environment variables whenever you cd into the project directory.

## Documentation

* Run `make docs-build` to build the project documentation using `mkdocs`. The documentation will be generated from your project files' comments in docstring format, thanks to the `mkdocstrings` plugin.
The documentation files will be stored in the `DOCS_SITE` directory (by default `site/`).
* Run `make docs-serve` to browse the built site locally, at http://127.0.0.1:8000/your-github-name/your-project-name/
* Run `make docs-publish` to publish the documentation site as GitHub pages. The content will be published to a separate branch, named `gh-pages`. Access the documentation online at https://your-github-name.github.io/your-project-name/

> [!TIP]
> You can edit the `mkdocs.yml` file to adapt it to your project's specifics. For example, you can change the `material` theme or adjust the logo and colors. Refer to this [guide](https://squidfunk.github.io/mkdocs-material/setup/) for more.

> [!NOTE]
> After the first deployment to your GitHub repository, your repository Pages settings (Settings > Pages) will be automatically updated to point to the documentation site content stored in the `gh-pages` branch.

> [!WARNING]
> Before being able to successfully publish the project documentation to GitHub Pages, you need to add a `RELEASE_TOKEN` to your repository's 'Actions secrets and variables' settings page. The `RELEASE_TOKEN` is generated from your GitHub 'Developer Settings' page. Make sure to select the full `repo` scope when generating it.

## Docker

* To build the Docker container: `make docker-build`
* To start the Docker container and run the application: `make docker-run`
* To build and run: `make docker-all`

> [!NOTE]
> Before building the container, you can edit `Makefile.env` and change the name of the image and or container (by default they will match the name of your project).

> [!WARNING]
> Pushing a new tag to GitHub will trigger the GitHub Action defined in `docker.yml`. To ensure correct execution, you first need to add the `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets to your repository's 'Actions secrets and variables' settings page.

## Contributing

Contributions are welcome! Follow these steps:

1. Fork the repository.
2. Create a new branch: `git checkout -b feature-name`
3. Make your changes and commit: `git commit -m 'Add feature'`
4. Push to the branch: `git push origin feature-name`
5. Submit a pull request.

## License

This project is licensed under the MIT License.
