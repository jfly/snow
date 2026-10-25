# Linux 6.8.58 has a bug that breaks my laptop's power button (causing
# it to turn off my laptop rather than go to sleep as I've configured it).
#
# https://discourse.nixos.org/t/tiny-power-button-kernel-module-causing-confusion/80683/8
{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_7_2;
}
