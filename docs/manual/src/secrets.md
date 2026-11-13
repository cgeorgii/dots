# Secrets

Secrets that the system needs at boot, such as the VPN's private key, are
committed encrypted with [sops](https://github.com/getsops/sops) and decrypted
by sops-nix into `/run/secrets/` when the configuration activates. They never
reach `/nix/store`.

Each encrypted file is readable by two age keys, listed in `.sops.yaml`:

- **Mine**, for creating and editing secrets. It lives only in KeePassXC, in
  the password field of the `sops age key` entry. `SOPS_AGE_KEY_CMD` points
  sops at `sops-age-key`, which asks for the database password in a dialog
  and reads the entry with `keepassxc-cli`, so each sops command asks once.
  Without this key, and with the machine gone, nothing can be decrypted.
- **The machine's**, in `/var/lib/sops-nix/key.txt`, for decrypting at
  activation. It is made by hand once per install, and stays in plain text
  since nobody is there to unlock anything at boot.

`sops` and `age` are in the dev shell.

## Creating or replacing my key

1. Generate it on the tmpfs, not the disk:

   ```sh
   age-keygen -o "$XDG_RUNTIME_DIR/sops-age.txt"
   ```

   It prints the public key (`age1…`).

2. In KeePassXC, put the `AGE-SECRET-KEY-1…` line in the password field of
   the `sops age key` entry (create it at the top level of the database).

3. Replace the `&cgeorgii` recipient in `.sops.yaml` with the new public key.

4. Re-encrypt every secret, decrypting with the old key, then give each file
   a new data key with the new one:

   ```sh
   find modules -name '*.sops' -exec env SOPS_AGE_KEY_FILE=/path/to/old-key.txt sops updatekeys -y {} \;
   find modules -name '*.sops' -exec env SOPS_AGE_KEY_FILE="$XDG_RUNTIME_DIR/sops-age.txt" sops rotate -i {} \;
   ```

   When the old key is the KeePassXC one, drop the `env …` prefix from the
   first command and let `SOPS_AGE_KEY_CMD` fetch it.

5. Check the KeePassXC path, then remove the tmpfs copy:

   ```sh
   sops decrypt modules/work/work.key.sops | head -1
   rm "$XDG_RUNTIME_DIR/sops-age.txt"
   ```

## Setting up a new machine

1. Create the machine's key:

   ```sh
   sudo install -d -m 700 /var/lib/sops-nix
   sudo nix shell nixpkgs#age -c age-keygen -o /var/lib/sops-nix/key.txt
   ```

   It prints the public key (`age1…`).

2. Add the public key to `.sops.yaml` as a second recipient:

   ```yaml
   keys:
     - &cgeorgii age1…
     - &coco age1…
   creation_rules:
     - path_regex: \.sops$
       key_groups:
         - age:
             - *cgeorgii
             - *coco
   ```

3. Re-encrypt every secret for the new recipient list:

   ```sh
   find modules -name '*.sops' -exec sops updatekeys -y {} \;
   ```

4. Rebuild. A secret the machine cannot decrypt fails activation of that
   secret, with sops-nix naming the file.

## Adding a secret

Files ending in `.sops` are encrypted for the keys in `.sops.yaml`. Put the
file beside the feature that uses it, and encrypt it from stdin so the
plaintext never touches the disk:

```sh
some-command-printing-the-secret \
  | sops encrypt --input-type binary --output-type binary \
      --filename-override modules/feature/thing.sops /dev/stdin \
  > modules/feature/thing.sops
```

Then declare it in the feature's NixOS module and use its path:

```nix
sops.secrets.thing = {
  sopsFile = ./thing.sops;
  format = "binary";
};
# config.sops.secrets.thing.path is /run/secrets/thing
```

## Reading or replacing a secret

```sh
sops decrypt modules/work/work.key.sops
```

To replace one, encrypt the new value over the old file as in
[Adding a secret](#adding-a-secret).
