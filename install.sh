#!/bin/bash

# Get architecture
unameArch="$(uname -m)"

# Installing Rosetta 2 (if arm64)
if [ -z "$(command -v arch)" ]; then
  echo "Install Rosetta? [enter]"
  read -r -s -n 1 rosetta_status
  if [[ $rosetta_status = "" ]]; then
    echo "AGREE with EVERYTHING in pop up window in 5 seconds..."
    sleep 5
    softwareupdate --install-rosetta
  else
    echo "Install Rosetta and rerun the script..."
    echo "https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment"
    exit 0
  fi

# Get OS
unameOut="$(uname -s)"
case "${unameOut}" in
    Darwin*)
      machine=Mac
      ;;
    Linux*)
      machine=Linux
      ;;
    *)
      machine="UNKNOWN:${unameOut}"
esac

# Exit if not Mac OS
if [ ! "$machine" = "Mac" ]; then
  echo "$unameOut not supported"
  echo "Open an issue if you want us to add support for this machine"
  exit 0
fi

# Get user's shell
case "${SHELL}" in
  */bash*)
    if [ -d "$HOME/.bash_profile" ]; then
      profile_dir="$HOME/.bash_profile"
    else
      profile_dir="$HOME/.bashrc"
    fi
    ;;
  */zsh*)
    if [ -d "$HOME/.zprofile" ]; then
      profile_dir="$HOME/.zprofile"
    else
      profile_dir="$HOME/.zshrc"
    fi
    ;;
  *)
    echo "Unknown shell, the script only supports zsh and bash"
    echo "Change the shell and rerun the script"
    exit 0
    ;;
esac

# Install brew (if not installed)
if [ -z "$(command -v brew)" ]; then
  if [ -d "/opt/homebrew/" ]; then
    # Update brew and cleanup if brew was installed but not in current PATH
    brew update && brew upgrade && brew cleanup
    brew tap homebrew/cask-versions
  else
    echo "Install brew? [enter]"
    read -r -s -n 1 brew_status
    if [[ $brew_status = "" ]]; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

      # Adding Homebrew to PATH
      echo "Adding Homebrew to PATH..."
      eval "$(/opt/homebrew/bin/brew shellenv)"
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$profile_dir"

      # Taping homebrew/cask-versions
      echo "Taping homebrew/cask-versions..."
      brew tap homebrew/cask-versions
    else
      echo "Install brew and rerun the script..."
      exit 0
    fi
  fi
else
  # Update brew and cleanup if brew was installed
  brew update && brew upgrade && brew cleanup
  brew tap homebrew/cask-versions
fi

# Install node@16 (if not installed)
if [ -z "$(command -v node)" ] && ! node --version | grep -q 'v16.'; then
  echo "Install node@16 (LTS)? [enter]"
  read -r -s -n 1 node_status
  if [[ $node_status = "" ]]; then
    brew install node@16
  else
    echo "Install node and rerun the script..."
    exit 0
  fi
fi

# Install yarn (if not installed) & node_modules
if [ -z "$(command -v yarn)" ]; then
  echo "Are you using yarn? [enter]"
  read -r -s -n 1 yarn_status
  if [[ $yarn_status = "" ]]; then
    echo "Installing yarn and node_modules"
    npm i -g yarn && yarn
  else
    echo "Installing node_modules via npm"
    npm i
  fi
else
  echo "Installing node_modules via yarn"
  yarn
fi

# Install dependencies for Xcode

# Install watchman (if not installed)
if [ -z "$(command -v watchman)" ]; then
  echo "Install watchman? [enter]"
  read -r -s -n 1 watchman_status
  if [[ $watchman_status = "" ]]; then
    brew install watchman
  else
    echo "Install watchman and rerun the script..."
    exit 0
  fi
fi

# Install Xcode CLT (if not installed)
if brew config | grep 'CLT' | grep -q 'N/A' ; then
  echo "Install Xcode CLT? [enter]"
  read -r -s -n 1 clt_status
  if [[ $clt_status = "" ]]; then
    echo "AGREE with EVERYTHING in pop up window in 5 seconds..."
    sleep 5
    xcode-select --install
  else
    echo "Install Xcode CLT and rerun the script..."
    echo "https://reactnative.dev/docs/environment-setup#command-line-tools"
    exit 0
  fi
fi

# Install cocoapods & ffi (if not installed)
if ! gem list | grep -Eq '^cocoapods'; then
  echo "Install cocoapods? [enter]"
  read -r -s -n 1 cocoapods_status
  if [[ $cocoapods_status = "" ]]; then
    sudo gem install cocoapods
  else
    echo "Install cocoapods and rerun the script..."
    exit 0
  fi
fi

if [ "$unameArch" = "arm64" ] && ! gem list | grep -Eq '^ffi'; then
  echo "Installing ffi"
  echo "https://github.com/ffi/ffi"
  sudo arch -x86_64 gem install ffi
fi

# Install Pods
echo "Installing Pods"
if [ "$unameArch" = "arm64" ]; then
  cd ios && arch -x86_64 pod install && cd ..
else
  cd ios && pod install && cd ..
fi

# Install Android dependencies

# Function to get Java location
function java_location ()
{
  java_version="$(/usr/libexec/java_home -V 2>&1 | awk '{ print $1 }' | grep -E "$1.")"
  if [ -z "$java_version" ]; then
    brew install "temurin$1"
    java_version="$(/usr/libexec/java_home -V 2>&1 | awk '{ print $1 }' | grep -E "$1.")"
  fi
  /usr/libexec/java_home -v "$java_version"
}

# Install Java 11
echo "Set JAVA_HOME environment? [enter]"
read -r -s -n 1 java_home_status
if [[ $java_home_status = "" ]]; then
  echo "export JAVA_HOME=$(java_location 11)" >> "$profile_dir"
else
  echo "Skipped exporting JAVA_HOME..."
fi

# Create ANDROID_SDK_ROOT folder if there was none
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"

if [ ! -d "$ANDROID_SDK_ROOT" ]; then
  mkdir "$ANDROID_SDK_ROOT"
fi

# Install Android Studio (if not installed)
if [ ! -d "$ANDROID_SDK_ROOT/emulator/" ] || [ ! -d "$ANDROID_SDK_ROOT/platform-tools/" ]; then
  if ! brew list | grep -Eq '^android-studio$'; then
    echo "Install android-studio? [enter]"
    read -r -s -n 1 android_studio_status
    if [[ $android_studio_status = "" ]]; then
      brew install android-studio
    else
      echo "Install android-studio and rerun script..."
      exit 0
    fi
  fi
fi

# Install Android SDK tools
if [ ! -f "$ANDROID_SDK_ROOT/tools/bin/sdkmanager" ]; then
  echo "Installing Android SDK tools..."
  brew install android-sdk
  # shellcheck disable=SC2016
  which sdkmanager | xargs sh -c 'cp $0 $ANDROID_SDK_ROOT/tools/bin'
  # shellcheck disable=SC2016
  which avdmanager | xargs sh -c 'cp $0 $ANDROID_SDK_ROOT/tools/bin'
fi

# Change to Java 8 (for sdkmanager & avdmanager)
java8_location="$(java_location 1.8)"
export JAVA_HOME=$java8_location

# Install Android Studio dependencies
# Dependencies: "emulator" "platform-tools" "sources;android-31" "platforms;android-31" "build-tools;30.0.2"
# If Intel "system-images;android-31;default;x86_64"
# Else "system-images;android-31;google_apis_playstore;arm64-v8a"
cd "$ANDROID_SDK_ROOT/tools/bin" || { echo "Failure: dir not found (sdkmanager) "; exit 1; }

echo "Install Android image (for emulators)? [enter]"
read -r -s -n 1 android_image_status
if [[ $android_image_status = "" ]]; then
  if [ "$unameArch" = "arm64" ]; then
  ./sdkmanager --sdk_root="$ANDROID_SDK_ROOT" "system-images;android-31;google_apis_playstore;arm64-v8a"
  else
  ./sdkmanager --sdk_root="$ANDROID_SDK_ROOT" "system-images;android-31;default;x86_64"
  fi
else
  echo "Skipped Android image"
fi

echo "Install Android dependencies? [enter]"
read -r -s -n 1 android_dependencies_status
if [[ $android_dependencies_status = "" ]]; then
  ./sdkmanager --sdk_root="$ANDROID_SDK_ROOT" "emulator" "platform-tools" "sources;android-31" "platforms;android-31" "build-tools;30.0.2"
else
  echo "Skipped Android dependencies"
fi


# Set up ENV in profile_dir
if [ -n "$profile_dir" ]; then
  echo "Export Android ENVs? [enter]"
  echo "ANDROID_SDK_ROOT and emulator & platform-tools to PATH"
  read -r -s -n 1 export_env_status
  if [[ $export_env_status = "" ]]; then
    # Warning if user skipped Android dependencies
    if [[ $android_dependencies_status = "" ]]; then
      echo "Make sure you've installed Android dependencies"
    fi

    {
      # shellcheck disable=SC2016
      echo 'export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk'
      # shellcheck disable=SC2016
      echo 'export PATH=$PATH:$ANDROID_SDK_ROOT/emulator'
      # shellcheck disable=SC2016
      echo 'export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools'
    } >> "$profile_dir"
  else
    echo "Skipped exporting Android ENVs"
  fi
fi


# Get device id func (pixel_xl)
function get_device () {
  cd "$ANDROID_SDK_ROOT/tools/bin" || { echo "Failure: dir not found (get_device) "; exit 1; }
  ./avdmanager list device 2>&1 | grep "$1" | awk '{ print $2 }'
}

# Add emulator if non was found(avd name: RN-AVD)
# System image: "system-images;android-31;default;x86_64"

echo "Create Android virtual device (simulator)? [enter]"
read -r -s -n 1 avd_status
if [[ $avd_status = "" ]]; then
  cd "$ANDROID_SDK_ROOT/tools/bin" || { echo "Failure: dir not found (avdmanager) "; exit 1; }

  if ! ./avdmanager list avd 2>&1 | grep -q 'Name:'; then
    if [ "$unameArch" = "arm64" ]; then
      ./avdmanager create avd --name "RN-AVD" --package "system-images;android-31;google_apis_playstore;arm64-v8a" --device "$(get_device pixel_xl)" -c 2000M
    else
      ./avdmanager create avd --name "RN-AVD" --package "system-images;android-31;default;x86_64" --device "$(get_device pixel_xl)" -c 2000M
    fi
  fi
else
  echo "Skipped creation of avd"
fi

# Open AVD
if [[ $avd_status = "" ]]; then
  echo "Opening AVD in 5 seconds..."
  sleep 5
  cd "$HOME/Library/Android/sdk/emulator/" || { echo "Failure: dir not found (avdmanager) "; exit 1; }
  ./emulator @RN-AVD
fi

# Exit
echo "All done! Reboot your machine"
echo "(to be sure everything is set and ready)"
exit 1
