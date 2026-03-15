let
  # Your workstation's public key (for editing)
  workstation = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/pGueja9l7ovfuotcmfgtrwnMCu5RL4i2JIewjzJhp";

  wireguard = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMq8vrAxeoZ9S9x4k1JYlUnXqrGIcn8MesF/IRqR8Q2V";
in
{
  "wireguard-private-key.age".publicKeys = [
    workstation
    wireguard
  ];

  "firezone-oidc-client-secret.age".publicKeys = [
    workstation
    wireguard
  ];

  "firezone-admin-password.age".publicKeys = [
    workstation
    wireguard
  ];

  "firezone-db-encryption-key.age".publicKeys = [
    workstation
    wireguard
  ];
}
