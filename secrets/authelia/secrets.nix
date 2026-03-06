let
  # Your workstation's public key (for editing)
  workstation = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/pGueja9l7ovfuotcmfgtrwnMCu5RL4i2JIewjzJhp";

  authelia = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1ztfwqfrMB4yRnwg0lglDxG24DSC9wA8J8+udQIolo";

  all = [
    workstation authelia
  ];
in
{
  "authelia-jwt-secret.age".publicKeys = all;
  "authelia-storage-key.age".publicKeys = all;
  "authelia-oidc-hmac.age".publicKeys = all;
  "authelia-oidc-private-key.age".publicKeys = all;

  # LLDAP
  "lldap-jwt-secret.age".publicKeys = all;
  "lldap-user-password.age".publicKeys = all;
}
