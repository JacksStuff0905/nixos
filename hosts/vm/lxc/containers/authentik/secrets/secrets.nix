let
  # Your workstation's public key (for editing)
  workstation = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/pGueja9l7ovfuotcmfgtrwnMCu5RL4i2JIewjzJhp";

  authentik = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1ztfwqfrMB4yRnwg0lglDxG24DSC9wA8J8+udQIolo";
in
{
  "authentik-secret.age".publicKeys = [
    workstation
    authentik
  ];
}
