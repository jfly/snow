{
  flake',
  config,
  lib,
  pkgs,
  ...
}:

{
  # I find it pretty useful to do ad-hoc edits of `/etc/hosts`. I know this
  # isn't exactly reproducible, but I'll live with it.
  # Trick copied from
  # https://discourse.nixos.org/t/a-fast-way-for-modifying-etc-hosts-using-networking-extrahosts/4190
  environment.etc.hosts.mode = "0644";

  # Enable docker for the main user.
  # TODO: move closer to docker configuration in `home.nix`
  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings = {
    # clark hosts its own docker registry, which is plain HTTP because currently all HTTPS
    # goes through k8s, and that would create an annoying circular
    # dependency.
    # TODO: get rid of k8s, and get rid of this
    insecure-registries = [ "clark.ec:5000" ];
  };
  users.users.${config.snow.user.name}.extraGroups = [ "docker" ];
  clan.core.vars.generators.snow-containers-auth = {
    files.password = {
      secret = true;
      owner = config.snow.user.name;
    };
    prompts.password = {
      type = "hidden";
    };
    files.username = {
      owner = config.snow.user.name;
    };
    prompts.username = {
      type = "line";
    };
    script = ''
      cp $prompts/username $out/username
      cp $prompts/password $out/password
    '';
  };

  # `systemd-resolved` is nice for VPNs because it understands how to query
  # different DNS servers for different TLDs.
  services.resolved.enable = true;

  # Set up ssh agent
  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
    askPassword = lib.getExe pkgs.lxqt.lxqt-openssh-askpass;
    extraConfig = ''
      AddKeysToAgent yes
    '';
  };
  environment.variables.SSH_ASKPASS_REQUIRE = "prefer";

  # QEMU emulation used for compiling for other architectures.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Needed by `~/bin/allprocs`
  programs.sysdig.enable = true;

  programs.git.enable = true;
  programs.git.lfs.enable = true;

  # Use our fancy configured neovim rather than stock.
  snow.neovim.package = flake'.packages.neovim;

  # Get debug symbols in gdb.
  services.nixseparatedebuginfod.enable = true;

  environment.systemPackages = with pkgs; [
    ### Version control
    git-filter-repo
    # `gh` manages credentials internally, but it also honors the
    # `GITHUB_TOKEN` env var if one is present. However, this interferes with
    # development in repos where I *do* have a `GITHUB_TOKEN` env var set.
    # Since I seem to rely upon `gh`s internal authentication anyways, we can
    # just completely ignore external `GITHUB_TOKEN` environment variables.
    (pkgs.symlinkJoin {
      name = pkgs.gh.name;
      paths = [ pkgs.gh ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/gh --unset GITHUB_TOKEN
      '';
    })
    mob

    ### Network
    curl
    wget
    whois
    netcat
    traceroute
    dnsutils # provides nslookup
    sipcalc # an advanced console based ip subnet calculator
    lsof
    wireshark
    tcpdump

    ### Python
    socat # Multipurpose relay (useful with remote-pdb!)

    ### Misc
    gdb
    binutils
    strace
    xxd
    rsync
    flake'.packages.mycli
    miller
    jq
    inotify-info
    nix-output-monitor

    ### Docs
    linux-manual
    man-pages
    man-pages-posix

    ### Virtualization
    quickemu
  ];
}
