# Transmission Remote GUI

**This is a fork**. If you're looking for the original project, go [here](https://github.com/transmission-remote-gui/transgui/).

This place is meant to be a temporary home for Transmission Remote GUI as the original project appears to be dormant.

# Changes made

 * transgui is now compiled with Free Pascal 3.2.3 and Lazarus 2.2.6 due to two rather serious bugs in parsing JSON in older versions ([38618](https://gitlab.com/freepascal.org/fpc/source/-/issues/38618) and [38624](https://gitlab.com/freepascal.org/fpc/source/-/issues/38624)).
 * The program binary is now compiled in Release mode.
 * Old and makefiles were removed and all compilation is now handled via `lazbuild`.
 * Gzip compression is now used when talking to the daemon.
 * OpenSSL version was switched to version 3.0, making it possible to use TLS 1.3.

Whenever possible, those fixes are also submitted as pull requests against the original project.

# Disclaimer

 * I last touched Pascal around 20 years ago.
 * I've never seriously worked with Lazarus.
 * Neither Windows nor macOS are platforms that I use daily.

`tl;dr` Please don't expect swooping changes to the program's behaviour or UI here, just hacks upon hacks at best.
