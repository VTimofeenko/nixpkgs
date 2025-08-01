{
  lib,
  buildPythonPackage,
  callPackage,
  fetchFromGitHub,
  click,
  h11,
  httptools,
  python-dotenv,
  pyyaml,
  typing-extensions,
  uvloop,
  watchfiles,
  websockets,
  hatchling,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "uvicorn";
  version = "0.34.2";
  disabled = pythonOlder "3.8";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "encode";
    repo = "uvicorn";
    tag = version;
    hash = "sha256-r5G3Z2sMFCs5HlUpVQ05Vip+3MjlSy+3Dkv6FO52uh4=";
  };

  outputs = [
    "out"
    "testsout"
  ];

  build-system = [ hatchling ];

  dependencies = [
    click
    h11
  ] ++ lib.optionals (pythonOlder "3.11") [ typing-extensions ];

  optional-dependencies.standard = [
    httptools
    python-dotenv
    pyyaml
    uvloop
    watchfiles
    websockets
  ];

  postInstall = ''
    mkdir $testsout
    cp -R tests $testsout/tests
  '';

  pythonImportsCheck = [ "uvicorn" ];

  # check in passthru.tests.pytest to escape infinite recursion with httpx/httpcore
  doCheck = false;

  passthru.tests = {
    pytest = callPackage ./tests.nix { };
  };

  meta = with lib; {
    homepage = "https://www.uvicorn.org/";
    changelog = "https://github.com/encode/uvicorn/blob/${src.tag}/CHANGELOG.md";
    description = "Lightning-fast ASGI server";
    mainProgram = "uvicorn";
    license = licenses.bsd3;
    maintainers = with maintainers; [ wd15 ];
  };
}
