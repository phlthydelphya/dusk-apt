# dusk-apt

The Dusk apt repository: signed packages for DuskOS, served from GitHub
Pages at https://phlthydelphya.github.io/dusk-apt/.

- `conf/` holds the reprepro configuration (`stonking`, component `main`, amd64; arch-all debs go into amd64).
- `publish.sh` adds the newest debs from `~/dusk-theme/packaging/dist` and the
  `dusk-archive-keyring` deb. It then exports a signed tree into `public/`.
- `public/` is a worktree of the `gh-pages` branch. Each publish replaces it with
  one parentless commit, so old debs never pile up in history.
- `db/` is reprepro's state. It is not in git, so back it up.
- `keyring/` builds `dusk-archive-keyring`. The package installs the public key in
  `/usr/share/keyrings/` and `/etc/apt/sources.list.d/dusk.sources` with
  `Signed-By:`, so the key is trusted for this repo only.

## Setup

1. `sudo scripts/install-deps.sh` installs reprepro.
2. Create the signing key. It asks for a passphrase:
   `gpg --quick-gen-key "Dusk Archive Signing Key" ed25519 sign 2y`
   Back up the secret key offline. Never commit it.
3. `scripts/set-key.sh FINGERPRINT`

## Publish

    ./publish.sh
    git -C public push -f origin gh-pages

Bump `keyring/VERSION` when the key or `dusk.sources` changes.

## Adding the repo by hand

    sudo curl -fsSLo /usr/share/keyrings/dusk-archive-keyring.gpg \
        https://phlthydelphya.github.io/dusk-apt/dusk-archive-keyring.gpg
    sudo curl -fsSLo /etc/apt/sources.list.d/dusk.sources \
        https://raw.githubusercontent.com/phlthydelphya/dusk-apt/main/keyring/dusk.sources

Then install `dusk-archive-keyring`. From then on apt keeps the key and the
source up to date.
