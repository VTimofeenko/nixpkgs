{
  lib,
  fetchFromGitLab,
  git,
  buildGoModule,
}:
let
  data = lib.importJSON ../data.json;
in
buildGoModule rec {
  pname = "gitlab-workhorse";

  version = "18.1.1";

  # nixpkgs-update: no auto update
  src = fetchFromGitLab {
    owner = data.owner;
    repo = data.repo;
    rev = data.rev;
    sha256 = data.repo_hash;
  };

  sourceRoot = "${src.name}/workhorse";

  vendorHash = "sha256-jsp68duGIW1p8ltfSlK0jPd22iscjiIOyrxfsr+2QY0=";
  buildInputs = [ git ];
  ldflags = [ "-X main.Version=${version}" ];
  doCheck = false;
  prodyVendor = true;

  meta = with lib; {
    homepage = "http://www.gitlab.com/";
    platforms = platforms.linux;
    teams = [ teams.gitlab ];
    license = licenses.mit;
  };
}
