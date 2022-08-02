### Git
AddPackage git-delta # Syntax-highlighting pager for git and diff output

### Docker
AddPackage docker                                    # Pack, ship and run any application as a lightweight container
AddPackage docker-compose                            # Fast, isolated development environments using Docker
AddPackage --foreign docker-credential-secretservice # program to use secretservice to keep Docker credentials safe
IgnorePath '/var/lib/docker/*'
IgnorePath '/etc/docker/key.json' # https://stackoverflow.com/questions/47573820/what-is-etc-docker-key-json
# Part of running docker with a users remap. See
# https://github.com/jfly/dotfiles/blob/master/notes/setting-up-docker-user-remap
# for details.
echo "jeremy:1000:65536" >"$(CreateFile /etc/subgid)"
echo "jeremy:1000:65536" >"$(CreateFile /etc/subuid)"
# Enable the service.
cat >"$(CreateFile /etc/systemd/system/docker.service.d/override.conf)" <<EOF
[Service]
ExecStart=
# ExecStart=/usr/bin/dockerd -H fd:// -s overlay2 --userns-remap=jeremy
ExecStart=/usr/bin/dockerd -H fd:// -s overlay2
EOF
IgnorePath '/opt/containerd/*' # containerd likes to create this folder on startup. See https://github.com/containerd/containerd/blob/main/docs/managed-opt.md for more details.
IgnorePath '/var/lib/containerd/*'

### Virtualization
AddPackage vagrant # Build and distribute virtualized development environments
# https://wiki.archlinux.org/title/VirtualBox#Install_the_core_packages says:
# for the linux kernel, choose virtualbox-host-modules-arch
AddPackage virtualbox-host-modules-arch
AddPackage virtualbox # Powerful x86 virtualization for enterprise as well as home use

### nix
AddPackage nix # A purely functional package manager
CopyFile /etc/nix/nix.conf
CreateLink /etc/systemd/system/multi-user.target.wants/nix-daemon.service /usr/lib/systemd/system/nix-daemon.service
IgnorePath '/nix/*'
# QEMU emulation is used for compiling for other architectures.
AddPackage --foreign binfmt-qemu-static   # Register qemu-static interpreters for various binary formats
AddPackage --foreign glib2-static         # Low level core library: Static library
AddPackage --foreign qemu-user-static-bin # A generic and open source machine emulator, statically linked

### Network
AddPackage nginx # Lightweight HTTP server and IMAP/POP3 proxy server
CreateDir /var/lib/nginx/fastcgi
CreateDir /var/lib/nginx/scgi
CreateDir /var/lib/nginx/uwsgi
AddPackage curl           # An URL retrieval utility and library
AddPackage wget           # Network utility to retrieve files from the Web
AddPackage openbsd-netcat # TCP/IP swiss army knife. OpenBSD variant.
AddPackage traceroute     # Tracks the route taken by packets over an IP network
AddPackage whois          # Intelligent WHOIS client
AddPackage wireshark-qt   # Network traffic and protocol analyzer/sniffer - Qt GUI
AddPackage bind           # Provides nslookup
AddPackage sipcalc        # an advanced console based ip subnet calculator.

### Python
AddPackage socat   # Multipurpose relay (useful with remote-pdb!)
IgnorePath '*.pyc' # There's a surprising number of these files scattered around. I guess a lot of tools like to use Python somewhere internally.

### Misc
AddPackage tcpdump             # Powerful command-line packet analyzer
AddPackage gdb                 # The GNU Debugger
AddPackage nasm                # 80x86 assembler designed for portability and modularity
AddPackage m4                  # The GNU macro processor
AddPackage mercurial           # A scalable distributed SCM tool
AddPackage imake               # X.Org imake program and related utilities
AddPackage autoconf2.13        # A GNU tool for automatically configuring source code (Legacy 2.1x version)
AddPackage binutils            # A set of programs to assemble and manipulate binary and object files
AddPackage bison               # The GNU general-purpose parser generator
AddPackage boost               # Free peer-reviewed portable C++ source libraries (development headers)
AddPackage llvm                # Collection of modular and reusable compiler and toolchain technologies
AddPackage extra-cmake-modules # Extra modules and scripts for CMake
AddPackage ctags               # Generates an index file of language objects found in source files
AddPackage coreutils           # The basic file, shell and text manipulation utilities of the GNU operating system
AddPackage doxygen             # Documentation system for C++, C, Java, IDL and PHP
AddPackage expect              # A tool for automating interactive applications
AddPackage diffstat            # Display a histogram of diff changes
AddPackage diffutils           # Utility programs used for creating patch files
AddPackage patchutils          # A small collection of programs that operate on patch files
AddPackage wkhtmltopdf         # Command line tools to render HTML into PDF and various image formats

### Dependencies to install stuff from the AUR
AddPackage gcc
AddPackage fakeroot
AddPackage patch # A utility to apply patch files to original sources
AddPackage autoconf
AddPackage automake
AddPackage make # GNU make utility to maintain groups of programs

### cubing/icons
AddPackage potrace # Utility for tracing a bitmap (input: PBM,PGM,PPM,BMP; output: EPS,PS,PDF,SVG,DXF,PGM,Gimppath,XFig)

### Graphviz
AddPackage graphviz                    # Graph visualization software
IgnorePath '/usr/lib/graphviz/config6' # Autogenerated by `dot -c`: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=755065

### Dictionary
AddPackage words # A collection of International 'words' files for /usr/share/dict.
CreateLink /usr/share/dict/words ./usa

### asdf
AddPackage direnv # Even though I use asdf-direnv, it's nice to test out if it works with a system installed direnv as well.

### Misc Honor stuff
# Needed by dev setup script.
AddPackage pyenv # Easily switch between multiple versions of Python
# Needed by asdf installed MySQL. Hopefully we can remove this someday.
AddPackage --foreign ncurses5-compat-libs # System V Release 4.0 curses emulation library, ABI 5
# Needed to compile thrift
AddPackage flex    # A tool for generating text-scanning programs
AddPackage pkgconf # Package compiler and linker metadata toolkit
