firefox-customizer
==================

I am very opinionated on how my browser of choice needs to look and behave. This
turned into a configuration orgy whereever and whenever I had to install a
Firefox browser ... and I did this a lot, because I somehow regularly try new
Linux distributions.

Finally I managed to have a script that automates the whole configuration by
running a single command and about three mouse-clicks.

It is written as a Bash script with minimal dependencies (`grep`, `sed`, `wget`
and `zip`) that should be installed in any normal Desktop distribution by
default.

Usage
-----

While Firefox is not running, start the script

    $ ./firefox-customizer.sh

and follow the very simple instructions (them being to click to install the
addons and closing the browser twice).

Configuration
-------------

All the configuration is done inside the script and has 5 sections:

### Addons

You can add [Firefox Addons](https://addons.mozilla.org) using their IDs as it
is seen behind the "+ Add to Firefox" link. These addons are being donwloaded,
bundeled and installed in one confirmation-click.

### Preferences (prefs.js)

Here you can update settings from `about:config`. Note that the bold lines are
the ones that differ from their default value. Most of them you want to set by
using this script. There are a few settings that hold session information and
timestamps, that need not to be set.

### Adblock Plus subscriptions

I like to not be bothered by ads and therefore one section configures the
subscriptions I like from Adblock Plus. See https://easylist.adblockplus.org for
official lists and details.

### Toolbar content customization ("browser.uiCustomization.state" in prefs.js)

Here you can customize what elements are in what toolbar and in what order. It
is a bit tricky to know all the elements. My approch was to move different
elements using the GUI configuration, close Firefox and then compare this
setting in `prefs.js` to a previous version I saved away. Note that you only
need to set stuff you are changing from the default.

### Toolbar visibility customization (xulstore.json)

Here you can update what toolbars are actually visible. A similar approch as
above was chosen, to get to know the names and elements.

Todo
----

I like the fact, that I can simply download one file from Github and then be
ready to run it. No extracting an archive, no separate configuration to handle.

However the script is rough and could need a few cleanups (e.g. create
functions, remove duplication) and also the fact that the configuration and the
code are in the same file is not best practice. If someone starts to use this
script, I would work on a cleaner version with better hadling of different
configurations (maybe pass the script a URL where it can download the config).

Comments / Help / Bugs
----------------------

I'm eager to hear your comments about this piece of software. If you find a bug
or thought of an enhancement, please fork or use the issue tracker.
