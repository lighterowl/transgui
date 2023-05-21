# Transmission Remote GUI

**This is a fork of a fork**. If you're looking for the community-maintained version, go [here](https://github.com/transmission-remote-gui/transgui/). If you're looking for the original project, go [here](https://sourceforge.net/projects/transgui/).

This place is meant to be a temporary home for Transmission Remote GUI as both the community-maintained version and the original project appear to be dormant.

# Compiling

You need to clone the repository with submodules, and then use `lazbuild` to build :

```
git clone --recurse-submodules https://github.com/xavery/transgui.git
cd transgui
lazbuild transgui.lpi
```

If you hit trouble, have a look at `build_` scripts in the `.github` folder. They are used to build the project for each of the supported platforms in GitHub Actions.

Due to issues with fpc 3.2.2 mentioned below, it is recommended to build transgui with a development version of the Free Pascal compiler. The `build_` scripts include necessary code that downloads and compiles the development version from source.

Also, due to the fix for [one issue](https://github.com/xavery/transgui/issues/25), there was a need to introduce a change to Lazarus code. This version of transgui thus now uses [my own fork of Lazarus](https://gitlab.com/dkk089/lazarus). If you don't want to use it, just remove the offending line when compiling with upstream Lazarus - stuff will still work.

You're encouraged to read the [wiki](https://github.com/xavery/transgui/wiki) if you're looking into making changes yourself.

# Changes made

This list applies to the first release of this fork : please look into release notes for individual releases in order to see what else changed since then.

 * transgui is now compiled with Free Pascal 3.2.3 and Lazarus 2.2.6 due to two rather serious bugs in parsing JSON in older versions ([38618](https://gitlab.com/freepascal.org/fpc/source/-/issues/38618) and [38624](https://gitlab.com/freepascal.org/fpc/source/-/issues/38624)).
 * The program binary is now compiled in Release mode.
 * Old makefiles were removed and all compilation is now handled via `lazbuild`.
 * Gzip compression is now used when talking to the daemon.
 * OpenSSL version was switched to version 3.0, making it possible to use TLS 1.3.

# Disclaimer

 * I last touched Pascal between 2001 and 2003.
 * I've never seriously worked with Lazarus.
 * Neither Windows nor macOS are platforms that I use daily.

`tl;dr` Please don't expect swooping changes to the program's behaviour or UI here, just hacks upon hacks at best.
