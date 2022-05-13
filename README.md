Installation
------------
Symlink this folder into /etc/nixos using sudo:

    ❯ sudo ln -s /home/cgeorgii/projects/dots/nixos/* /etc/nixos

Run `sudo nixos-rebuild switch`.

Configuring git
---------------

  1. Login with `gh`:

  ```
  $ gh auth login
  ```

  2. Create personal access token for machine by going to `https://github.com/settings/tokens` and paste it in `~/.config/hub`

  ```
  github.com:
   - user: cgeorgii
     oauth_token: PASTE_TOKEN_HERE
     protocol: https
  ```

Configuring fingerprint reader
------------------------------
  1. Run `fprintd-enroll`
  2. Profit
