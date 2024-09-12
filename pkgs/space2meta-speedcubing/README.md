space2meta-speedcubing
======================

A version of
[space2meta](https://gitlab.com/interception/linux/plugins/space2meta/)
designed to play nicely with speedcubing timers, which really want to know when
spacebar is pressed down and released, so they can stop and start the timer,
respectively.

This basically acts like vanilla space2meta except we emit a synthetic keydown
event (for some key that doesn't do much of anything except start/stop a
timer*) immediately when space is pressed, and then carefully release that
synthetic key when it won't trigger the timer to start or stop when it
shouldn't.

*It's pretty tricky to pick such a key. On my machine, `KEY_PAUSE` seems to be
a good choice for this, as it doesn't do anything interesting, but it can
start/stop my speedcubing timer. If this isn't a good choice for everyone, it
would be easy to make this configurable.
