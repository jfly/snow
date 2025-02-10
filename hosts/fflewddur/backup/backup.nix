{ flake, ... }:

{
  imports = [ flake.nixosModules.backup ];

  snow.backup = {
    enable = true;

    resticPasswordEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBGZE8yOWYxbzBuUjV4RjV5
      TWM5c0dFeTVBeGtWQURFeGhzNXhpRnoyL213Clk4RHMwYTlSRXNVZFVzbGo2emd6
      RUMwU2cxbGU3RFFmblpkSFJWdEl3b1UKLS0tIGF0WVVWS0FzRTM0Qkl0ek5EeDB3
      a2dUQ1Q5d0gyRGt4Y3dxU01IYitKRlEKpVZveoKup6U1lzonGLrVUO5HWqOn5pEU
      aK5wQ1moF31hcxQzrIl8deVboCrVjI+Ov/yvDA==
      -----END AGE ENCRYPTED FILE-----
    '';

    paths = [ "/mnt/bay/archive" ];
  };
}
