#!/usr/bin/env bash
# Release Sotto to App Store Connect from the CLI.
#
# Usage:
#   ./scripts/release.sh patch        # 1.0.0 -> 1.0.1, build +1
#   ./scripts/release.sh minor        # 1.0.0 -> 1.1.0, build +1
#   ./scripts/release.sh major        # 1.0.0 -> 2.0.0, build +1
#   ./scripts/release.sh build        # marketing unchanged, build +1 (retry mode)
#
# Flags:
#   --ios-only       Skip macOS archive/upload
#   --macos-only     Skip iOS archive/upload
#   --dry-run        Stop after export; don't upload, don't commit
#   --no-commit      Upload but skip auto-commit + tag

set -euo pipefail

# ---------- Args ----------
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <patch|minor|major|build> [--ios-only|--macos-only|--dry-run|--no-commit]"
    exit 1
fi

bump="$1"
shift

ios_enabled=true
macos_enabled=true
dry_run=false
auto_commit=true

for arg in "$@"; do
    case "$arg" in
        --ios-only) macos_enabled=false ;;
        --macos-only) ios_enabled=false ;;
        --dry-run) dry_run=true; auto_commit=false ;;
        --no-commit) auto_commit=false ;;
        *) echo "Unknown flag: $arg"; exit 1 ;;
    esac
done

case "$bump" in
    patch|minor|major|build) ;;
    *) echo "bump must be patch|minor|major|build (got: $bump)"; exit 1 ;;
esac

# ---------- Repo root ----------
cd "$(git rev-parse --show-toplevel)"

# ---------- Load env ----------
if [[ ! -f .env.release ]]; then
    echo "Missing .env.release at repo root."
    echo "  Copy .env.release.example to .env.release and fill in your values."
    exit 1
fi
set -a
# shellcheck disable=SC1091
source .env.release
set +a

: "${ASC_KEY_ID:?ASC_KEY_ID not set in .env.release}"
: "${ASC_ISSUER_ID:?ASC_ISSUER_ID not set in .env.release}"

# Verify the .p8 lives where altool can find it.
key_paths=(
    "$PWD/private_keys/AuthKey_${ASC_KEY_ID}.p8"
    "$HOME/private_keys/AuthKey_${ASC_KEY_ID}.p8"
    "$HOME/.private_keys/AuthKey_${ASC_KEY_ID}.p8"
    "$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
)
key_found=false
for path in "${key_paths[@]}"; do
    if [[ -f "$path" ]]; then
        key_found=true
        echo "Found ASC key at $path"
        break
    fi
done
if [[ "$key_found" != true ]]; then
    echo "AuthKey_${ASC_KEY_ID}.p8 not found. altool searches:"
    for path in "${key_paths[@]}"; do echo "    $path"; done
    exit 1
fi

# ---------- Read current versions from Project.swift ----------
current_marketing=$(grep -E '"MARKETING_VERSION":' Project.swift | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')
current_build=$(grep -E '"CURRENT_PROJECT_VERSION":' Project.swift | sed -E 's/.*"([0-9]+)".*/\1/')

if [[ -z "$current_marketing" || -z "$current_build" ]]; then
    echo "Could not read MARKETING_VERSION / CURRENT_PROJECT_VERSION from Project.swift"
    exit 1
fi

# ---------- Compute new versions ----------
IFS=. read -r maj min pat <<< "$current_marketing"
case "$bump" in
    patch) pat=$((pat + 1)) ;;
    minor) min=$((min + 1)); pat=0 ;;
    major) maj=$((maj + 1)); min=0; pat=0 ;;
    build) ;;  # marketing unchanged
esac
new_marketing="$maj.$min.$pat"
new_build=$((current_build + 1))

echo ""
echo "Releasing: $current_marketing (build $current_build) -> $new_marketing (build $new_build)"
$ios_enabled && echo "  - iOS / iPadOS .ipa -> App Store Connect"
$macos_enabled && echo "  - macOS .pkg -> App Store Connect"
$dry_run && echo "  (dry run -- no upload, no commit)"
echo ""

# ---------- Rewrite Project.swift ----------
sed -i '' "s/\"MARKETING_VERSION\": \"$current_marketing\"/\"MARKETING_VERSION\": \"$new_marketing\"/" Project.swift
sed -i '' "s/\"CURRENT_PROJECT_VERSION\": \"$current_build\"/\"CURRENT_PROJECT_VERSION\": \"$new_build\"/" Project.swift

# ---------- Regenerate project ----------
echo "==> tuist generate"
tuist generate -n

# ---------- Helper: archive + export + upload ----------
archive_and_upload() {
    local platform=$1
    local dest_arg export_plist type_arg artifact

    case "$platform" in
        iOS)
            dest_arg='generic/platform=iOS'
            export_plist=scripts/ExportOptions-iOS.plist
            type_arg=ios
            artifact=Sotto.ipa
            ;;
        macOS)
            dest_arg='generic/platform=macOS'
            export_plist=scripts/ExportOptions-macOS.plist
            type_arg=macos
            artifact=Sotto.pkg
            ;;
        *)
            echo "Unknown platform: $platform"; return 1 ;;
    esac

    local archive_path="build/Sotto-$platform.xcarchive"
    local export_dir="build/$platform"

    rm -rf "$archive_path" "$export_dir"
    mkdir -p build

    echo ""
    echo "==> Archiving $platform"
    xcodebuild \
        -workspace Sotto.xcworkspace \
        -scheme Sotto \
        -configuration Release \
        -destination "$dest_arg" \
        -archivePath "$archive_path" \
        archive

    echo ""
    echo "==> Exporting $platform"
    xcodebuild \
        -exportArchive \
        -archivePath "$archive_path" \
        -exportOptionsPlist "$export_plist" \
        -exportPath "$export_dir"

    if $dry_run; then
        echo "  (dry run) artifact ready at $export_dir/$artifact"
        return 0
    fi

    echo ""
    echo "==> Uploading $platform to App Store Connect"
    xcrun altool --upload-app \
        -f "$export_dir/$artifact" \
        -t "$type_arg" \
        --api-key "$ASC_KEY_ID" \
        --api-issuer "$ASC_ISSUER_ID"
}

# ---------- Run ----------
if $ios_enabled; then
    archive_and_upload iOS
fi
if $macos_enabled; then
    archive_and_upload macOS
fi

# ---------- Commit + tag ----------
if $auto_commit; then
    echo ""
    echo "==> Committing version bump"
    git add Project.swift
    git commit -m "chore(release): v$new_marketing (build $new_build)"
    git tag "v$new_marketing"
    echo ""
    echo "Released v$new_marketing build $new_build."
    echo "Push when ready:  git push && git push --tags"
else
    echo ""
    echo "Released v$new_marketing build $new_build (no commit made)."
fi
