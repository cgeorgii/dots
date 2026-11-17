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

## Fetching without the key

Each use of the key asks for confirmation. That only means something if the
dialog is rare, but lazygit fetches in the background, and a fetch from a
`git@github.com:` remote needs a signature. So for each host listed in
`readonly-hosts` in `modules/dev/git/git.nix`, git reads over HTTPS and only
pushes over SSH. Hosts not in the list are left alone and use SSH for
everything.

- `url."https://HOST/".insteadOf` rewrites `git@HOST:` (and
  `ssh://git@HOST/`) remotes for fetch, pull, clone, ls-remote and LFS
  downloads. `pushInsteadOf` sends pushes back to `git@HOST:`, even for
  remotes cloned over HTTPS. git applies `pushInsteadOf` to the configured
  URL, not the rewritten one, which is why the SSH form also maps to itself.
  `git remote -v` shows both URLs after rewriting.
- HTTPS authenticates with a token that can only read repositories. Leaked, it
  exposes code but changes nothing.
- Each host's token is the sops secret `modules/dev/git/ro-tokens/HOST.sops`,
  decrypted to `/run/secrets/git-ro-token/HOST`, readable only by me. A
  helper, `git-ro-credential`, is the only credential helper for
  `https://HOST`. It hands the token to git and ignores git's requests to
  store or erase credentials. No helper hands out a token that can write.
- The helper also tells git not to ask for a password. Otherwise a fetch the
  token can't authenticate (expired, or a repository it doesn't reach) would
  open a username dialog through `SSH_ASKPASS`, from lazygit in the
  background.

Nothing else in this chapter changes: pushes still ask, and so does
everything else that uses the key.

### Creating a token

- **GitHub:** **Settings → Developer settings → Personal access tokens →
  Fine-grained tokens → Generate new token**. Resource owner: me. Repository
  access: **All repositories**. Permissions: **Contents: Read-only**
  (Metadata: Read-only is added by itself), nothing else. It starts with
  `github_pat_`, and its username is `x-access-token`. Private repositories
  of other owners need a token of their own, and fail to fetch without one.
- **GitLab:** **Preferences → Access tokens → Add new token**, with only the
  **read_repository** scope. It starts with `glpat-`. GitLab ignores the
  username next to a token, so `oauth2` will do. A group or project access
  token works too, for a repository my own user can't read.

Pick an expiry and note it in the token's KeePassXC entry.

### Adding a host or renewing its token

1. Encrypt the token from the terminal without it touching the disk or the
   shell history. `read -s` doesn't echo the paste:

   ```sh
   host=gitlab.example.com
   read -rs 'tok?Token: '; printf %s "$tok" \
     | sops encrypt --input-type binary --output-type binary \
         --filename-override "modules/dev/git/ro-tokens/$host.sops" /dev/stdin \
     > "modules/dev/git/ro-tokens/$host.sops"; unset tok
   git add -N "modules/dev/git/ro-tokens/$host.sops"
   ```

2. For a new host, add it to `readonly-hosts` in `modules/dev/git/git.nix`
   with the username from the previous section:

   ```nix
   "gitlab.example.com".username = "oauth2";
   ```

   This only works if the host serves SSH as `git@HOST:` and HTTPS at
   `https://HOST/`, as GitHub and GitLab do.

3. Rebuild, then check that git gets the token (this prints only the first
   characters):

   ```sh
   printf 'protocol=https\nhost=%s\n\n' "$host" | git credential fill | sed -n 's/^password=\(.\{12\}\).*/\1…/p'
   ```

When a token expires, fetches of private repositories on that host fail with
an authentication error, without a dialog. Public ones keep working.
