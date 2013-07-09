#!/usr/bin/perl

#yearly mean equation of time calculator.
$LTZ =0; #longitude of time zone meridian
$LLOC = 0; #longitude of city
$IN = 0; #if one, then it's standard time year-round
$sum = 0; #sum of day-to-day EOT calculations
$DST = 0; #if DST is in effect
$BN = 0; #b-sub-n calculation
sub eot {
	my($LTZ, $LLOC, $IN) = @_;
	$sum = 0; #reset sum to zero
	for ($day = 1; $day <= 365; $day++) {
		if ($day >= 94 && $day <= 302 && $IN != 1) { 
			$DST= (-60);
		} 
		else {$DST=0;}
		$BN = (360*($day-81))/364; 
		$sum += $DST+(4*($LTZ - $LLOC))-((9.87*(sin(2*$BN)))-(7.54*(cos($BN)))-(1.5*(sin($BN))));
	}
	return $sum/365;
}
print &eot(90, 89.6094, 0) . " Peoria, IL" . "\n"; #peoria
print &eot(90, 89.6504, 0) . " Springfield, IL" . "\n"; #springfield
print &eot(90, 87.6500, 0) . " Chicago, IL" . "\n"; #chicago
print &eot(90, 88.9442, 0) . " Decatur, IL" . "\n"; #decatur
print &eot(90, 87.7686, 0) . " Mt. Carmel, IL" . "\n"; #mount carmel
print &eot(90, 89.0386, 0) . " South Beloit, IL" . "\n"; #south beloit
print &eot(75, 86.1582, 1) . " INDPLS" . "\n"; #indianapolis
print &eot(75, 85.1267, 1) . " Ft Wayne, IN" . "\n"; #fort wayne
print &eot(75, 87.3353, 1) . " Merrillville, IN" . "\n"; #NIPSCO
print &eot(75, 86.0567, 1) . " Franklin, IN" . "\n"; #PSI
print &eot(75, 87.5506, 1) . " Evansville, IN" . "\n"; #evansville
print &eot(75, 84.5031, 0) . " Cincinnati, OH" . "\n"; #cincinnati
print &eot(75, 82.9834, 0) . " Columbus, OH" . "\n"; #cincinnati
print &eot(75, 84.1917, 0) . " Dayton, OH" . "\n"; #dayton
print "----------------" . "\n"; #second appearence of Columbus in dataset
print &eot(75, 83.5753, 0) . " Toledo, OH" . "\n"; #toledo


#2001 	91	301
#2002 	97	301
#2003 	95	299
#2004 	95	305
#2005 	93	303