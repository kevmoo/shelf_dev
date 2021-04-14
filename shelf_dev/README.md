[![Dart CI](https://github.com/kevmoo/shelf_dev/actions/workflows/dart.yml/badge.svg?branch=main)](https://github.com/kevmoo/shelf_dev/actions/workflows/dart.yml)

A Dart tool for development of a client and server application.

See https://github.com/kevmoo/shelf_dev/blob/main/example/shelf_dev.yaml for
an example of the configuration file.

# Installation

```console
[flutter] pub global activate sheld_dev
```

# Usage

```console
shelf_dev must be run in a directory with a shelf_dev.yaml configuration file.

See https://github.com/kevmoo/shelf_dev for information on the configuration format.

While running, these keys – "r", "R" – will be passed to the "web-app" target.
When used with `flutter run` this cause a hot restart.

When these keys – "s", "S" – are pressed, shelf_dev will
attempt to restart the "web-server" target.

Other options:
-?, --help       Print out usage information.
    --version    Print out the version of the executable.
```
