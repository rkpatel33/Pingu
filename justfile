# Pingu build recipes

app_name := "Pingu"
scheme := "Pingu"
project := "Pingu.xcodeproj"
build_dir := "./build"
app_path := build_dir / "Build/Products/Debug" / app_name + ".app"

# Build the app
build:
    xcodebuild -project {{project}} -scheme {{scheme}} -configuration Debug \
        -derivedDataPath {{build_dir}} \
        CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""

# Build, install to ~/Applications, and run
deploy: build
    cp -R {{app_path}} ~/Applications/
    open ~/Applications/{{app_name}}.app

# Clean build artifacts
clean:
    rm -rf {{build_dir}}

# Open project in Xcode
xcode:
    open {{project}}
