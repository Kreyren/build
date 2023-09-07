# Configuration file for Nix(OS) to provide a temporary development enviroment

{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    nativeBuildInputs = with pkgs.buildPackages; [
      util-linux # uuidgen
      fakeroot # Building bsp-cli
    ];
}
