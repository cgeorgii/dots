# SSH keys

SSH private keys live only in the KeePassXC database
(`~/Dropbox/Apps/Keepass2Android/passbook.kdbx`), as attachments on their
entries. Nothing in `~/.ssh` is secret: it holds the public keys and the
config.

The agent is the plain OpenSSH `ssh-agent`. KeePassXC adds the keys to it when
the database is unlocked and removes them when it locks, and every lock of the
session (F9, F10, lid, idle) also locks KeePassXC. If ssh runs while the agent
is empty, a hook in `~/.ssh/config` opens KeePassXC's unlock dialog and waits
up to a minute for the keys to show up. Each use of a key asks for
confirmation in a dialog whose default button is Deny, next to a notification
naming the command that wanted it.

## Adding a key

1. Generate the key somewhere that is not on disk. `$XDG_RUNTIME_DIR` is a
   tmpfs:

   ```sh
   ssh-keygen -t ed25519 -C "github" -N "" -f "$XDG_RUNTIME_DIR/id_github"
   ```

   An empty passphrase is fine, since the database encrypts the key. With a
   passphrase, put it in the entry's password field so KeePassXC can decrypt
   the key.

2. In KeePassXC, create an entry for it (or reuse the service's login entry).
   Under **Advanced → Attachments**, add `id_github` (the private key).

3. In the entry's **SSH Agent** page:
   - Under **Private key**, choose **Attachment** and pick `id_github`. The
     fingerprint and public key appear below it.
   - Tick **Add key to agent when database is opened/unlocked**.
   - Tick **Remove key from agent when database is closed/locked**.
   - Tick **Require user confirmation when this key is used**.

   Save the entry.

4. Keep the public key in `~/.ssh`, then remove both files from the tmpfs:

   ```sh
   mv "$XDG_RUNTIME_DIR/id_github.pub" ~/.ssh/github.pub
   rm "$XDG_RUNTIME_DIR/id_github"
   ```

5. Lock and unlock the database, then check that the agent holds the key:

   ```sh
   ssh-add -l
   ```

6. Give the public key to the service (`cat ~/.ssh/github.pub`).

The **SSH Agent** settings page (**Tools → Settings → SSH Agent**) must have
the integration enabled. It is on already; it is a per-machine setting stored
in `~/.config/keepassxc`, not in the database.

## Picking a key per host

With several keys loaded, ssh offers them in turn, and each offer pops a
confirmation dialog. To send a host only its own key, point `IdentityFile` at
the public key in `modules/system/security/ssh-config`. ssh uses the matching
key from the agent:

```ssh-config
Host github.com
    IdentityFile ~/.ssh/github.pub
    IdentitiesOnly yes
```

The file is linked into `~/.ssh/config`, so the change applies to the next ssh
run without a rebuild.

## Importing an existing key

Follow the same steps, skipping `ssh-keygen`: attach the existing private
key, then delete it from `~/.ssh` once `ssh-add -l` lists it.
