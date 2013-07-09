#!/usr/bin/perl
require Encode;
use Unicode::Normalize;
use Tie::File;
use Getopt::Std;
#A Perl Home Companion
#Created 2006 by Ben Lamb
#All are free to distribute and reuse as long as proper attribution is made 

#This is for Mac OS X. Should work on other posix (BSD, linux, etc.) systems.
#requires:
#curl, though with a one-line change this could use wget
#realplayer or its codecs
#MPlayer with realplayer codec support
#lame
#the perl modules listed above. Use CPAN to get them if you receive an error.

#Mac OS X see http://www.macosxhints.com/article.php?story=2005013018405216 "Convert Real Audio Files to MP3s"
#additionally the author forgot to link the codecs both ways, you'll also need to enter
#ln -s /Applications/RealPlayer.app/Contents/Frameworks/HXClientKit.framework/HelixPlugins/Codecs /usr/local/lib/mplayer
#in terminal to get MPlayer to work.

#other platforms read http://www.mplayer.hu/DOCS/HTM/en/video-codecs.html#realvideo ; you'll have to (re)build mplayer with rm codecs, it seems

#Define the path where the rss & mp3 files should be put relative to server root directory. No trailing slash..
$outpath ="/Users/benlamb/Sites/phc";
#Define the "web" path. No trailing slash.
$webpath ="http://localhost/~benlamb/phc";

### ### ### ### ### ### ### ### ### ###
### COMMAND LINE OPTIONS:           ###
### -v verbose (for debugging)      ###
### -t runs on a test .ram file     ###
### -d <YYYY/MM/DD> run perl home   ###
### companion for date              ###
### -h print this information       ###
### ### ### ### ### ### ### ### ### ###

### ### ### ### ### ### ### ### ### ###
### MANUFACTURER'S WARNING          ###
### NO USER-SERVICABLE PARTS BELOW. ###
### MODIFICATIONS TO TO SUBSEQUENT  ###
### CODE WILL VOID YOUR NONEXISTENT ###
### WARRANTY.                       ###
### ### ### ### ### ### ### ### ### ###


#command-line arguements
getopts ("vthd:");
print "A Perl Home Companion Copyright 2006-2009 B.H. Lamb.\n";
print "Usage: phc.pl [options]\n  -v               write progress to STDOUT\n  -t               use short test audio file\n  -h               print this information\n  -d <YYYY/MM/DD>  run perl home companion for specified date\n\n" if $opt_h;
exit if $opt_h;

#Section 1.
#The math. This computes the most recent available date for a PHC.



($second, $minute, $hour, $dayofmonth, $month, $yearoffset, $dayofweek, $dayofyear, $daylightsavings) = localtime();
$yr = 1900 + $yearoffset;
#computers like to give the day of the week 0-6, with 0 as Sunday.
#In each calculation, however, we have to add 1, so that Monday is the
#second day of the week (2, instead of 1) for example.
#Ordinal numbers and fencepost errors.

#What's really stupid about Perl is that it gives the month as a range from
#0-11. I mean, I've seen in various things besides programming languages
#that list the days of the week from 0-6.
#But, months? What the heck.
$month = $month +1;
#There.

#Knowing how many days there were in the month LAST MONTH becomes useful later.
#It's placed here to avoid duplicated code. Of course, if this were BASIC, we 
#could just use a stinking goto. But that isn't best practices blah blah.

#31-day months (number for months after a 31-day month as conditions)
if (($month == 2) || ($month == 4) || ($month == 6) || ($month == 8) || ($month == 9) || ($month == 11))
	{$lastday = 31;}
#February
elsif ($month == 3)
	{ if (($yr % 4) == 0) {$lastday = 29;} else {$lastday = 28;}}
#30-day months
else
{$lastday = 30;}


# PHCs are datestamped as a Saturday but aren't available until Monday, 
#therefore, if the program is run on a Sunday the only PHC available is from 
#the Saturday 8 days before. This must be taken into consideration.

if ($dayofweek > 0) #if today isn't Sunday
{
	#This the major case, when the previous Saturday (PHC Day) is part of
	#the same month as today.
	if ( ($dayofmonth - ($dayofweek)) > 1) #The first day this can happen is Monday ($dayofweek >0) the third of the month
	{
		$mo = $month; #same month
		$dy = ($dayofmonth - ($dayofweek + 1 )); #The difference between today's date and Saturday's is one greater than the day of the week (0-6).
		print "Day of month > 2, operations to mo and dy \n" if $opt_v;
	}
	#However, if the non-Sunday day of the week is less than or equal to 1,
	#then the previous Saturday was last month.
	#Merely subtracting the 1-adjusted day-of-week from the day
	#won't work, we must use many days were in the past month, etc
	else
	{

		#Saturday computatation
		$dy = ($lastday - (($dayofweek + 1) - $dayofmonth));  # see Note1 below
		$mo = ($month - 1); #The show was recorded last month!
			#Note1: in order to determine the air date, we take the 
			#last possible day of the month, and subtract from that
			#the difference between the day of the week 
			#(1-adjusted) and the day of the month. If it's Monday
			#the Second, for example, Saturday was the last day of 
			#the last month, so the ordinal day of the week (2) 
			#minus the day of the month (2) equals zero,
		print "Day of month <= 2, operations to mo and dy \n" if $opt_v;
	}
}


#The Sunday problem confronted. Remember, if today's Sunday, yesterday's show 
#isn't yet available. So, let's fetch last weekend's show. Maybe when we're 
#done programming we'll put something here to doubleczech that last weekend's 
#show wasn't already downloaded.
else {  #Today must be Sunday
	if ($dayofmonth >= 9) #Sunday the 9th is the first day when the Saturday before is in the same month
	{ $dy = ($dayofmonth - 8); $mo = $month; } #last Saturday was 8 days ago.
	else 
	{$dy = $lastday - ( 8 - $dayofmonth); $mo = ($month - 1);} #see Note2 below
			#Note2: this is the same basic formula as the above
			#code block, "Satuday computation," but with a constant
			#8 instead of fiddling with the day of week variable.
			#We know this is Zero, since we're working exclusively
			#on Sunday in this point of the code, plus the ordinal
			#1 adjustement in the above block, plus a week (7), to
			#make 8.
	print "Today must be sunday \n" if $opt_v;
}
#One last thing, make a three-letter month name variable for later use (iTunes-style dating)
my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
$mo3= $abbr[$mo-1]; #remember when we added 1 to the month? Well, dang, I guess it's useful for THIS. WTF


#Section 2.
#Check the PHC server to see if such a show even exists!

#Let's make sure we have leading zeroes for the day and month, if they're
#needed. Otherwise we could be in trouble.
$paddedmo = sprintf("%0*d", 2, $mo); #Form months and 
$paddeddy = sprintf("%0*d", 2, $dy);	#days!

$datestring = $yr ."/" . $paddedmo . "/" . $paddeddy; # form the date string
$datestring = $opt_d if $opt_d;
print $datestring . "\n"  if $opt_v;

#And I'll form the URL!
#$url = "http://prairiehome.publicradio.org/programs/" . $datestring . "/show.smil"; 
$url = "http://www.publicradio.org/tools/media/player/noads/phc/" . $datestring . "_phc.smil"; #new url

#Here's the good stuff.
$flag = "-s"; $flag = "-v" if $opt_v; #silence curl unless verbose on
$quiet = " 2>/dev/null" unless $opt_v; #that first line isn't enough
$smil = `curl $flag $url $quiet`; #get the .smil file off of publicradio.org, -s supresses curl's progress output, so only the actual file is sent to STDOUT
if ($smil !~ /<smil>/) {die "phc.pl (Perl Home Companion) could not find a show for the date " . $datestring . "\n";} #die if curl is served something besides a smil (e.g., "file not found" page)
$smil =~ m/(rtsp.+phc.rm)/; #find the phc stream in the text file, which becomes designated $1 the .+ means "any number of alphanumeric characters"
$url = $1; # $1 is the URL for the stream, which is the one we want, so make $url equal to it
print $url . "\n"  if $opt_v;

#$url = "rtsp://a754.v5559f.c5559.g.vr.akamaistream.net/ondemand/7/754/5559/v001/mpr.download.akamai.com/5559/phc/admedia/sc1.rm"; # this a 10-second ad that comes from a recent PHC .smil file and is used for testing porpoises.

$url ="http://service.real.com/learnnav/testrams/28realaudio8.ram"  if $opt_t; # new dummy file. 39 seconds. From realplayer.

#This will get the program information.
$title = "A Prairie Home Companion for $datestring";
$prdate = $datestring;
$artist = "Garrison Keillor";
$desc = "No description available.";

#now let's get some data from the server
$html = `curl  $flag http://prairiehome.publicradio.org/programs/$datestring/ $quiet`; #get the index page for this show

##########OLD PAGE LAYOUT
#$html =~ m/pagehead">(.+)<br/;#get a pretty date without having to do the work
#$prdate = $1;
#$title = "A Prairie Home Companion for $prdate";
#$html =~ m/storytext">(\n|\s)*(.+)(\n|\s)*<br /; #get the description of the show
#$desc = $2; #assign it to $desc
#$desc =~ s/\s+$//; #strip trailing CRLF that gets caught in $2 for whatver reason
##########OLD PAGE LAYOUT

# new page layout
$html =~ m/topnewsblack">(.+)<br/;#get a pretty date without having to do the work
$prdate = $1;
$title = "A Prairie Home Companion for $prdate";
print $title . "\n" if $opt_v;
$html =~ m/DESCRIPTION\s-->(\n|\s)*(.+)<\/p>/; #get the description of the show
$desc = $2; #assign it to $desc
$desc =~ s/\s+$//; #strip trailing CRLF that gets caught in $2 for whatver reason
$desc =~ s{&amp;}{x-amp-x}gsx; #replace HTML-escaped ampersands with  "x-amp-x" to avoid black magic
#get rid of unicode stuff, from http://www.ahinea.com/en/tech/accented-translate.html
for ( $desc ) {  # the variable we work on

   ##  convert to Unicode first
   ##  if your data comes in Latin-1, then uncomment:
   $_ = Encode::decode( 'iso-8859-1', $_ );  

   s/\xe4/ae/g;  ##  a diaresis
   s/\xf1/ny/g;  ##  n tilde
   s/\xf6/oe/g;  ## o diaresis
   s/\xfc/ue/g;  ## u diaresis
   s/\xff/yu/g;   ##y diaresis

   $_ = NFD( $_ );   ##  decompose (Unicode Normalization Form D)
   s/\pM//g;         ##  strip combining characters

   # additional normalizations:

   s/\x{00df}/ss/g;  #ess-zet
   s/\x{00c6}/AE/g;  #AE
   s/\x{00e6}/ae/g;  #ae
   s/\x{0132}/IJ/g;    #IJ
   s/\x{0133}/ij/g;     #ij
   s/\x{0152}/Oe/g;  #Oe
   s/\x{0153}/oe/g;  #oe
   s/'|\x{0027}|\x{00b4}|\x{02c9}|\x{02bc}|\x{02ca}|\x{0301}|\x{0374}|\x{055b}|\x{2019}|\x{2032}|\x{2757}/x-apos-x/g; #apostrophe
   s/"|\x{0022}|\x{02ba}|\x{030b}|\x{030e}|\x{201c}|\x{201d}|\x{201f}|\x{275d}|\x{275e}|\x{301e}\x{3003}|\x{301d}/x-quot-x/g; #quote

   tr/\x{00d0}\x{0110}\x{00f0}\x{0111}\x{0126}\x{0127}/DDddHh/; #edth, crossed H
   tr/\x{0131}\x{0138}\x{013f}\x{0141}\x{0140}\x{0142}/ikLLll/; #Polish letters
   tr/\x{014a}\x{0149}\x{014b}\x{00d8}\x{00f8}\x{017f}/NnnOos/; #More Polish-looking stuff
   tr/\x{00de}\x{0166}\x{00fe}\x{0167}/TTtt/; #Thorn                   

   s/[^\0-\x80]//g;  ##  clear everything else; optional
 }
$desc =~ s{<([^>])+>|&([^;])+;}{}gsx; #black magic: remove any html markup / public-domain code from http://aspn.activestate.com/APSN/Cookbook/Rx/Recipe/66459
$desc =~ s{x-amp-x}{&amp;}gsx; #replace HTML-escaped ampersands with  "x-amp-x" to avoid black magic
$desc =~ s{x-apos-x}{&apos;}gsx; #see above (apostrophes)
$desc =~ s{x-quot-x}{&quot;}gsx; #see above (quotation marks)
print $desc . "\n" if $opt_v;

#this is the point at which the realplayer stream will be downloaded, decoded
print "Start download from site. This may take a few minutes. \n" if $opt_v;
$flag = "-really-quiet"; $flag = "-v" if $opt_v; #silence  unless verbose on
$quiet = "2>/dev/null" unless $opt_v; #that first line isn't enough
$dummy = `mplayer $url $flag -cache 30000 -cache-min 99 -bandwidth 10000000 -ao pcm:file=$outpath/phc.temp.wav -vc dummy -vo null $quiet`; #kludge to mplayer invoke mplayer and wait for it to do its business.
#Note: the previous command runs mplayer on $url, with an audio output driver 
#of pcm (wav dump), audio-out file phc.temp.wav, and a dummy video codec and 
#null video output driver, since these are not needed.
print "file's done! \n"  if $opt_v;	#AOL

#now stream will be mp3'd.
$filename = "/A-Prairie-Home-Companion-$mo-$dy-$yr.mp3"; #let's make a filename first

$quiet = ">> /dev/null 2>&1" unless $opt_v; #silence lame
$dummy = `lame $outpath/phc.temp.wav "$outpath/$filename" --tt "$title" --ta "$artist" --ty "$yr" $quiet`; #lame kludge
my $filesize = -s "$outpath/$filename";

#get rid of the temp wav
$dummy = `rm $outpath/phc.temp.wav`; #oh, I wish I could rm this silly workaround

#now, we need to write an RSS feed.
#Until RSS::XML actually works for RSS 2.0 files, we'll just have to do this mess by hand.

#this is the header for phc.rss
$header = "<?xml version=\"1.0\" encoding=\"UTF-8\"?> \n <rss xmlns:itunes=\"http://www.itunes.com/dtds/podcast-1.0.dtd\" version=\"2.0\"> \n <channel> \n \n <title>A Prairie Home Companion</title> \n <link>http://prairiehome.publicradio.org/</link> \n <language>en-us</language>\n <copyright>&#xA9; " . $yr . " American Public Media</copyright> \n <itunes:author>" . $artist . "</itunes:author> \n <itunes:image href=\"$webpath/aphc_logo.jpg\" />";

#this is the <item> block for today's podcast
$itemblock = "<item>  \n <title>" . $title . "</title> \n <itunes:author>" . $artist . "</itunes:author> \n <itunes:subtitle>All About the ". $prdate ." broadcast</itunes:subtitle> \n <itunes:summary>" . $desc . "</itunes:summary> \n <enclosure url=\"" . $webpath . $filename ."\" length=\"". $filesize . "\" type=\"audio/mpeg\" /> \n <guid>" . $webpath . $filename . "</guid> \n <pubDate>Sat, " . $dy . " " . $mo3 . " " . $yr . " 17:00:00 EST</pubDate> \n <itunes:duration>2:00:00</itunes:duration> \n </item> ";


if (-e "$outpath/phc.rss" && -s "$outpath/phc.rss") #if phc.rss exists and is of non-zero size, do
{
	$czech = `cat $outpath/phc.rss`;
	if ($czech !~ /<?xml version=/) {die "phc.pl (Perl Home Companion) believes phc.rss to be malformed, and cannot continue.\n";} #die if phc.rss is malformed (doesn't have a header).
	if ($czech =~ /$title/) {die "Entry for this show already exists, phc.pl (Perl Home Companion) quitting.\n";} #This check needs to be moved to the beginning of the script to prevent downloading a show we already have.
	tie my @rss, "Tie::File", "$outpath/phc.rss"; #open phc.rss with tie to strip header
	splice @rss, 0, 10; #remove first ten lines (length of header)
}
else
{
	open (RSS, ">$outpath/phc.rss") || die ("phc.pl (Perl Home Companion) encountered an error writing to nonexistent phc.rss\n"); #open the RSS (creating it). If this doesn't work, perl, ot at least open(), is FUBAR. Die.
	print RSS "</channel>\n</rss>"; # print the footer of the RSS, everything else will come later.
	close RSS;
}

tie my @rss, "Tie::File", "$outpath/phc.rss"; #open phc.rss with tie to append itemblock to the beginning
unshift @rss, $itemblock ; #append itemblock to the beginning


tie my @rss, "Tie::File", "$outpath/phc.rss"; #open phc.rss with tie to reattach header
unshift @rss, $header ; #append header to beginning






