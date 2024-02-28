{ pkgs }:
{
  wifi = {
    home = {
      password = pkgs.deage.string ''
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBiMjFGNTFPYTVXcWIyeW4x
        M0VuOURsQmZJbXE0QWY1RjNmVnp5VjBKTlRZCllsYitvWWlVY0N0U3hXN1lVTmJO
        Z3ljMHRrYkJVWHd3cU8vSU5MSUwxV00KLS0tIEVuU1p4eFRKTkxNZkk3NzZQdmds
        WmhzT2NoUEJiNCtTTUNmRGU4Qjh6eU0K4xTdrdazTIOpP9vmdaigLMmHfSfEEnSu
        uq0FTh+oKCJ00kRgWVAYWwlCP+A=
        -----END AGE ENCRYPTED FILE-----
      '';
    };
    iot = {
      password = pkgs.deage.string ''
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBObmJ5Q1NoOFkxSnFPdlYz
        bjAxVzZWd1VvbXBsOWtkRklzVUtPVnNIdkNzCmJSdlBXSmNGc3JRbm93VXBWaHlF
        V1pPZEMvVmgwUXdoaVNDM2hENmVBQUEKLS0tIDNEdENXOE1SQUhpaWdMR0htVlc4
        QUNmd2ZGWVVLQnZ5bFBEQUgvOXZlSDAK8byIeNYA/+PhYh/a9Y3kZsRpSx42wFFY
        W59sGFTSHLPDqALbQLqu2ywq
        -----END AGE ENCRYPTED FILE-----
      '';
    };
  };
  users = {
    homeAssistant = {
      password = pkgs.deage.string ''
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBOc0RGcGZXZFBCTmdvMnov
        LzBXN0NXUlJ0eVVOcDc2Rnl3OE55U0g2d1ZVCklpVmxMV0FnRXIrajVydTBSajM2
        S3A0UWVtSEdqN3QyOTAwS2FiOTZYNVEKLS0tIGxHMWgyd1ZNRXZpeTJiTVBlTlds
        WmF2NlJJYjEzbmV4bHMrTmhqOWNPd1kKdDnx8IHTFXeo8OTece+fFXZJNfX3yYGA
        INTexKyXiEePCyLOvL+K+YUfBFTxqjtAxXTQQg==
        -----END AGE ENCRYPTED FILE-----
      '';
    };
  };
}
