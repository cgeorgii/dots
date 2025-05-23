Installation
------------
Symlink this folder into /etc/nixos using sudo:

    ❯ sudo ln -s /home/cgeorgii/projects/dots/nixos/* /etc/nixos

Run `sudo nixos-rebuild switch`.

Configuring git
---------------

### Using HTTPS with git-credential-manager

The dotfiles include configuration for secure credential storage using git-credential-manager and pass-secret-service:

1. Initialize the password store (only needed once):
   ```
   $ pass init YOUR_GPG_KEY_ID
   ```

2. Authentication workflow:
   - First-time authentication: You'll be prompted to enter a Personal Access Token (PAT)
   - PAT is securely stored in the pass password store via GPG encryption
   - Future authentications will use the stored PAT automatically
   - No browser-based auth - uses CLI-based token entry only

3. The configuration in home/cgeorgii.nix includes:
   ```nix
   credential = {
     helper = "manager";
     credentialStore = "gpg";
   };
   ```

Configuring fingerprint reader
------------------------------
  1. Run `fprintd-enroll`
  2. Profit