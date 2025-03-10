# xord/all

![License](https://img.shields.io/github/license/xord/all)
![Build Status](https://github.com/xord/all/actions/workflows/test.yml/badge.svg)

## 🚀 About

**xord/all** is a monorepo that contains all the main libraries developed by xord.

This repository serves as a central location for the development and maintenance of various projects, ensuring consistency and ease of management.

The monorepo includes libraries for creative coding, graphical user interfaces, game engines, and more, all designed to work seamlessly with Ruby.

## 🔄 Mirroring

This repository uses the `git subtree` command to mirror changes to individual repositories.

Each library within this monorepo is mirrored to its respective standalone repository.

## 📦 Installation

For installation instructions, please refer to the README.md file in each subdirectory.

## 🛠️  How to Develop

### Build C/C++ Libraries
```bash
$ rake lib
```

### Build Ruby C-Extensions
```bash
$ rake ext
```

### Run Tests
```bash
$ rake test
```

### Run Examples
```bash
$ ruby reflex/samples/hello.rb
```

## 📜 License

**xord/all** is licensed under the MIT License.
See the [LICENSE](./LICENSE) file for details.
