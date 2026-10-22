# NumberGenPrototype — GitHub Actions starter

This is a native SwiftUI prototype with a GitHub Actions workflow that attempts an iOS device build on GitHub's macOS runner.

## Start from iPhone
1. Download and unzip this folder.
2. Open github.com in Safari and create a **new empty repository** named `NumberGenPrototype` (do not add README/license/gitignore there).
3. In the repository, use **Add file → Upload files** and upload the contents of this folder, including `.github/workflows/build-ios.yml`. If the hidden `.github` folder is hard to upload from iPhone, use GitHub's web editor to create `.github/workflows/build-ios.yml` and paste the workflow content from this ZIP.
4. Commit to `main`.
5. Open **Actions → Build NumberGen iOS → Run workflow**. On first push it should also run automatically.
6. Open the completed run and download the artifact `NumberGenPrototype-unsigned-ipa`.

## Important signing limitation
The workflow deliberately builds **without Apple signing credentials**. The `.ipa` artifact is therefore an unsigned package for build/testing purposes and normally will **not install directly** on an iPhone. Installing on a real device requires valid signing/provisioning or another supported signing workflow. Do not put Apple certificates or passwords into source files.

## Current scope
This is a prototype, not a faithful port of the original Unity game. It currently includes generated number plates, rarity, coins, collection persistence and one upgrade. Original Unity assets/game logic have not yet been extracted.
