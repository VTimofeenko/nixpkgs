{
  lib,
  python3Packages,
  fetchFromGitHub,
  installShellFiles,
  stdenv,
}:

python3Packages.buildPythonApplication rec {
  pname = "snowflake-cli";
  version = "3.3.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "snowflakedb";
    repo = "snowflake-cli";
    tag = "v${version}";
    hash = "sha256-nYP9FNeZi/ziW/ROKgpybdBmAIX5fFICvRApD680DQg=";
  };

  build-system = with python3Packages; [
    hatch-vcs
    hatchling
    pip
  ];

  nativeBuildInputs = [ installShellFiles ];

  dependencies = with python3Packages; [
    jinja2
    pluggy
    pyyaml
    rich
    requests
    requirements-parser
    setuptools
    tomlkit
    typer
    urllib3
    gitpython
    # `snowflake-cli` needs pydantic == 2.9.2. This override pins the version of pydantic.
    # Upstream PR to bump pydantic: https://github.com/snowflakedb/snowflake-cli/pull/1965
    (pydantic.overridePythonAttrs rec {
      version = "2.9.2";
      src = fetchFromGitHub {
        owner = "pydantic";
        repo = "pydantic";
        tag = "v${version}";
        hash = "sha256-Eb/9k9bNizRyGhjbW/LAE/2R0Ino4DIRDy5ZrQuzJ7o=";
      };
      dependencies = [
        annotated-types
        typing-extensions
        (pydantic-core.overrideAttrs (old: rec {
          version = "2.23.4";
          src = pkgs.fetchFromGitHub {
            owner = "pydantic";
            repo = "pydantic-core";
            tag = "v${version}";
            hash = "sha256-WSSwiqmdQN4zB7fqaniHyh4SHmrGeDHdCGpiSJZT7Mg=";
          };
          cargoDeps = old.cargoDeps.overrideAttrs {
            name = "pydantic-core-${version}.tar.gz";
            inherit src;
            outputHash = "sha256-Ya591IbP/jzkVS3N61S8v6vLfWAh/Fqk9NtrCz+ZlDw=";
          };
        }))
      ];
    })
    snowflake-connector-python
  ];

  nativeCheckInputs = with python3Packages; [
    pytestCheckHook
    syrupy
    coverage
    pytest-randomly
    pytest-factoryboy
    pytest-xdist
  ];

  pytestFlagsArray = [
    "-n"
    "$NIX_BUILD_CORES"
    "--snapshot-warn-unused" # Turn unused snapshots into a warning and not a failure
  ];

  disabledTests = [
    "integration"
    "spcs"
    "loaded_modules"
    "integration_experimental"
    "test_snow_typer_help_sanitization" # Snapshot needs update?
    "test_help_message" # Snapshot needs update?
    "test_executing_command_sends_telemetry_usage_data" # Fails on mocked version
    "test_generate_jwt_with_passphrase" # Fails, upstream PR https://github.com/snowflakedb/snowflake-cli/pull/1898
    "test_internal_application_data_is_sent_if_feature_flag_is_set"
  ];

  pythonRelaxDeps = true;

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''

    # Looks like the completion generation has some sort of a race
    # Occasionally one of the completion generations would fail with
    #
    # An unexpected exception occurred. Use --debug option to see the traceback. Exception message:
    # [Errno 17] File exists: '/build/tmp.W654FVhCPT/.config/snowflake/logs'
    #
    # This creates a fake config that prevents logging in the build sandbox.
    export HOME=$(mktemp -d)
    mkdir -p $HOME/.config/snowflake
    cat <<EOF > $HOME/.config/snowflake/config.toml
    [cli.logs]
    save_logs = false
    EOF
    # snowcli checks the config permissions upon launch and exits with an error code if it's not 0600.
    chmod 0600 $HOME/.config/snowflake/config.toml

    # Typer tries to guess the current shell by default
    export _TYPER_COMPLETE_TEST_DISABLE_SHELL_DETECTION=1

    installShellCompletion --cmd snow \
      --bash <($out/bin/snow --show-completion bash) \
      --fish <($out/bin/snow --show-completion fish) \
      --zsh <($out/bin/snow --show-completion zsh)
  '';

  meta = {
    changelog = "https://github.com/snowflakedb/snowflake-cli/blob/main/RELEASE-NOTES.md";
    homepage = "https://docs.snowflake.com/en/developer-guide/snowflake-cli-v2/index";
    description = "Command-line tool explicitly designed for developer-centric workloads in addition to SQL operations";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ vtimofeenko ];
    mainProgram = "snow";
    # Broken because of incompatible pydantic in nixpkgs.
    # Upstream PR:
    # https://github.com/snowflakedb/snowflake-cli/pull/1965
    # broken = true;
  };
}
