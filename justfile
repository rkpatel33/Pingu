# Pingu build recipes

app_name := "Pingu"
scheme := "Pingu"
project := "Pingu.xcodeproj"
build_dir := "./build"
app_path := build_dir / "Build/Products/Debug" / app_name + ".app"

# Build the app (auto-increments build number)
build:
    #!/usr/bin/env bash
    set -euo pipefail
    build=$(($(cat BUILD_NUMBER) + 1))
    echo "$build" > BUILD_NUMBER
    version=$(cat VERSION | tr -d '[:space:]')
    echo "Building {{app_name}} v${version} (build ${build})"
    xcodebuild -project {{project}} -scheme {{scheme}} -configuration Debug \
        -derivedDataPath {{build_dir}} \
        CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" \
        MARKETING_VERSION="${version}" \
        CURRENT_PROJECT_VERSION="${build}"

# Build, install to ~/Applications, and restart
deploy: build
    -killall {{app_name}}
    cp -R {{app_path}} ~/Applications/
    open ~/Applications/{{app_name}}.app

# Clean build artifacts
clean:
    rm -rf {{build_dir}}

# Open project in Xcode
xcode:
    open {{project}}
