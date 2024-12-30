{pkgs ? import <nixos-unstable> {}}:

pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.elixir_1_18
  ];
}

