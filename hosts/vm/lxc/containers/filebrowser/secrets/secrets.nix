let
  # Your workstation's public key (for editing)
  workstation = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/pGueja9l7ovfuotcmfgtrwnMCu5RL4i2JIewjzJhp";
  
  # Your server's host SSH key (for decryption)
  server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdkmeR53wnrKjOZsDK1Uj51LPceVWXqLv0bW9WpH89O";
in
{
  "filebrowser-secret.age".publicKeys = [ workstation server ];
}
