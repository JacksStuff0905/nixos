let
  # Your workstation's public key (for editing)
  workstation = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/pGueja9l7ovfuotcmfgtrwnMCu5RL4i2JIewjzJhp";

  filebrowser = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdkmeR53wnrKjOZsDK1Uj51LPceVWXqLv0bW9WpH89O";

  authelia = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1ztfwqfrMB4yRnwg0lglDxG24DSC9wA8J8+udQIolo";
in
{
  "filebrowser-secret.age".publicKeys = [
    workstation
    filebrowser
  ];

  "immich-oidc-client-secret.age".publicKeys = [
    workstation
    filebrowser
  ];

  "samba-ldap-password.age".publicKeys = [
    workstation
    filebrowser
    authelia
  ];
}
