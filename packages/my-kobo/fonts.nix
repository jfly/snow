{ pkgs, fetchFromGitHub }:

let
  mkPenguinFont = (
    {
      name,
      url,
      hash,
    }:
    # TODO: actually shuffle the files around so they end up in /share/fonts/truetype
    pkgs.fetchzip {
      inherit name url hash;
      stripRoot = false;
    }
  );
  fonts = [
    # From https://thepenguin.eu/2020-01-02-some-nice-fonts-for-your-ebook-reader/
    (mkPenguinFont {
      name = "Bookerly";
      url = "https://web.archive.org/web/20201230040224/https://thepenguin.eu/download/fonts/Bookerly.zip";
      hash = "sha256-8CkLPh5m4yMVizDHNucRKu4R4Jvv+OUqA9IGURh396c=";
    })
    (mkPenguinFont {
      name = "Linux Libertine";
      url = "https://web.archive.org/web/20201230040222/https://thepenguin.eu/download/fonts/Libertine.zip";
      hash = "sha256-cgR1sOcFzQoQ+Yj5i24FjZSFiUqsMABzNc6gCMLfXqU=";
    })
    (mkPenguinFont {
      name = "Google Literata";
      url = "https://web.archive.org/web/20201230040223/https://thepenguin.eu/download/fonts/Literata.zip";
      hash = "sha256-Z7uiGVZCdnbX75X93mwuA79vKJN3xQGhqFCVeNUWbxE=";
    })
    (mkPenguinFont {
      name = "Noto Serif";
      url = "https://web.archive.org/web/20201230040223/https://thepenguin.eu/download/fonts/NotoSerifEink.zip";
      hash = "sha256-8Mv2jMrPecGUacpQaEdBcSyELYLtaQDNfYPGst7Q0Kc=";
    })
    (mkPenguinFont {
      name = "Charis SIL";
      url = "https://web.archive.org/web/20201230040223/https://thepenguin.eu/download/fonts/ChareInk%20NoWeight%20v1.1.zip";
      hash = "sha256-GzmY7576BcleHVExNfkUnJkMVmFeHSupf1E1dtHox3w=";
    })
    (mkPenguinFont {
      name = "Bitter ht";
      url = "https://web.archive.org/web/20201230040224/https://thepenguin.eu/download/fonts/Bitter-Ht.zip";
      hash = "sha256-jACsTw66wC5D/NFSoiBK4VRiui8ZDohUJtsyb/fD09c=";
    })
    # From https://thepenguin.eu/2020-10-28-some-nice-fonts-for-your-ebook-reader-pt2/
    (mkPenguinFont {
      name = "Baskerville";
      url = "https://web.archive.org/web/20201230040220/https://thepenguin.eu/download/fonts/Baskerville.zip";
      hash = "sha256-AO7ICK75YT/71WMkZL923Ddr2sZlfG+hjd+oi1H+Nr0=";
    })
    (mkPenguinFont {
      name = "Lexend Deca";
      url = "https://web.archive.org/web/20201230040220/https://thepenguin.eu/download/fonts/Lexend-Deca.zip";
      hash = "sha256-IgCKN04z1NGGWwdI6UdHFS7RYw3arOQZgYjv8YpC078=";
    })
    (mkPenguinFont {
      name = "Didact Gothic";
      url = "https://web.archive.org/web/20201230040220/https://thepenguin.eu/download/fonts/Didact-Gothic.zip";
      hash = "sha256-SGwJYQESaRH68+YYtXCSkeCQTLtiHU3GRphIWJwngqc=";
    })
    (mkPenguinFont {
      name = "Verdana Pro Condensed";
      url = "https://web.archive.org/web/20201230040220/https://thepenguin.eu/download/fonts/Verdana-Pro-Condensed.zip";
      hash = "sha256-YPOVh4qIMh0yt8WGj2dSwo0f9IyD7i1AA37HY44jK2o=";
    })

    # From https://github.com/googlefonts/atkinson-hyperlegible/tree/main/fonts/ttf
    (fetchFromGitHub {
      name = "Atkinson Hyperlegible";
      owner = "googlefonts";
      repo = "atkinson-hyperlegible";
      rev = "1cb311624b2ddf88e9e37873999d165a8cd28b46";
      hash = "sha256-uCQ+4vH58B2TVjv1CkHo96IVzxcZt21Mo9WwYYfk7Os=";
      postFetch = ''
        mv $out $out-bak
        mv $out-bak/fonts/ttf $out
      '';
    })
    pkgs.rubik # yes, this is a font
  ];

  cmds = [
    "mkdir $out"
  ]
  ++ (map (font: ''ln -s ${font} "$out/${font.name}"'') fonts);
in
pkgs.runCommand "kobo-fonts" { } (builtins.concatStringsSep "\n" cmds)
