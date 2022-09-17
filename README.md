# rn-dependency-installer

### Auto set up development environments for React Native

</br>

<details>
  <summary>
  What does script do?
  </summary>

</br>

* Installs **Rosetta 2** if not installed
* Installs **Homebrew** if not installed or updates it
* Installs **node@16** if not installed
* Prompts to install **yarn** if not installed
* Installs required **node_modules**
* Installs **watchman** if not installed
* Installs **Xcode CLT** if not installed
* Installs **cocoapods** if not installed
* Installs **ffi** if not installed
* Installs required **pods**
* Installs **Java 11** and **Java 8** (only if needed and not installed)
* Prompts to add **JAVA_HOME** and other Android dependencies
* Installs **Android SDK tools**
* Prompts to install **Android image**
* Prompts to create **Android virtual device**

</details>

## Install Automatically

> Execute the command in your project's root directory

### Using curl

```zsh
curl -fsSL https://raw.githubusercontent.com/liis-dev-team/rn-dependency-installer/main/install.sh | zsh -s
```

### Using wget

```zsh
wget https://raw.githubusercontent.com/liis-dev-team/rn-dependency-installer/main/install.sh -O - | zsh -s
```

> If you're using **bash**, change `| zsh -s` to `| bash -s`

## Step by Step Install

1. Download:\
`curl -o rn-install https://raw.githubusercontent.com/liis-dev-team/rn-dependency-installer/main/install.sh`
2. Make it executable:\
`chmod +x rn-install`
3. Launch it:\
`./rn-install`
