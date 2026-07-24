# NagaReader

NagaReader is a local macOS EPUB reader focused on comfortable centered reading on widescreen displays.

## Build And Install

Generate a local macOS app bundle and install it into your user Applications folder:

```sh
./scripts/build-app.sh
```

The script compiles the Swift package, builds `.build/NagaReader.app`, and installs a copy at:

```text
~/Applications/NagaReader.app
```

After running it, open Finder, go to your home folder's `Applications` directory, and launch `NagaReader.app`.

This local packaging flow is for personal use. It does not sign, notarize, upload to the App Store, or create a `.dmg`/`.pkg` installer.
