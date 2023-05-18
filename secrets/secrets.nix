let
  chebuya = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9blPuLoJkCfTl88JKpqnSUmybCm7ci5EgWAUvfEmwb chebuya@laptop";
in {
  "sssweden.age".publicKeys = [ chebuya ];
  "ssfinland.age".publicKeys = [ chebuya ];
  "ssturkey.age".publicKeys = [ chebuya ];
  "ssmoldova.age".publicKeys = [ chebuya ];
  "cloudflaredinternal.age".publicKeys = [ chebuya ];
  "cloudflarednginx.age".publicKeys = [ chebuya ];
  "cloudflaredssh.age".publicKeys = [ chebuya ];
  "precise.age".publicKeys = [ chebuya ];
  "blogrs.age".publicKeys = [ chebuya ];
}
