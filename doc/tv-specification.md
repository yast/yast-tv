TV card configuration
=====================

Documentation
--------------

- [The Linux kernel documentation](https://github.com/torvalds/linux/tree/master/Documentation/video4linux)
- [BTTV homepage](http://bytesex.org/bttv)


Features of the Module
----------------------


A list of the features can be found [here](tv-features.md).


The Configuration
-----------------

A TV card is configured by writing the proper aliases and options to
the modules.conf file. The module options are the main problem because
the autodetection does not work for every card perfectly.

It is possible to have more cards in one computer at the same time.
The configuration module must reflect it.


### Database of Cards for Manual Configuration ###

It has to be maintained manually, there is no database to generate it from.

The sources of information are lists of the cards in `CARDLIST.*driver*` files
in [/usr/src/linux/Documentation/video4linux](https://github.com/torvalds/linux/tree/master/Documentation/video4linux)
Linux kernel directory.


### The volume of the Soundcard ###

The module has to ask the user if the TV card's audio output is
connected to a sound card. If yes, the module must unmute the sound card and
configure the (sound card's input) volume.

It is important to ask user, because there are also grabber boards without
any audio/tuner (they have just the bt848/878 chip, a video input and nothing
else), so the users could be confused.

If the sound card is not configured at all, it must be possible to run
the sound card configuration module.

### More Cards in One Computer ###

The `videodev.o` module gives out minor numbers to the drivers.
Aliases work like this:

    alias char-major-81          videodev
    alias char-major-81-<minor>  driver


Starting with 2.4.5 the video4linux modules have insmod options for
the minor numbers, i.e. you can give them fixed minor numbers this way:

    alias char-major-81-0        foo
    alias char-major-81-1        bar
    option foo                   video_nr=0
    option bar                   video_nr=1

### Scan for the Channels ###

`scantv` command-line tool is used, but it can write just
`xawtv` configuration files. It is not a big problem, because the
recommended application (`kwintv`) has a wizard for scanning the channels.
