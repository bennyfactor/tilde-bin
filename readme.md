# tilde-bin

(Really, that should be ~/bin, but you know, it's the slashdot problem when you start naming projects after directory names)

This is an assortment of scripts and other minor files I've written over the years to make things easier on myself. After noticing I lost a rather large scraper script I'd invested a lot of time on, I figured I should upload these to the world. Maybe you can use them too!

##eot.pl
Calculates annualized mean difference between solar noon and clock noon for a variety of midwestern cities. While this doesn't seem like of much use to anyone for anything, it was pretty critical to my undergraduate thesis on Daylight Saving Time and electricity use, so I don't want to lose it. Perl.

##opml-to-bookmarks
Converts opml export files favored by most RSS readers to the mozilla/safari bookmarks format used by Apple's mail.app RSS reader. Again very specialized but hey. PHP.

##phc-verbose.pl (Perl Home Companion)
Creates an itunes-compatible RSS feed, and MP3 file, of the latest episode of A Prairie Home Companion from the show's website. Needs a bit of updating to properly scrape from the newly-reformatted website. Perl.

##unrar-torrents
Traverses a folder filed with torrents that have a series of segmented rar files in second level directories, unrars them, cleans up the mess. You know, for linux ISOs. Bash.

##wma2mp3
Converts all .wma (or .WMA, or .wMa or whatever misery windows wishes to inflict) files in the present working directory to .mp3. Requires mplayer and lame.
