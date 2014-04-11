#!/usr/bin/perl
use warnings;
use strict;
use IO::Socket;
use Getopt::Std;
use Term::ANSIColor;
use Time::HiRes qw(usleep nanosleep);

my $payload;
my $content;
my $ascii;
my @lines;				#each and every rule raw
my $count;				#general iterator
my $peice;				#another indexer
my @packets;			#packet data for each rule
my $base_packet;		#A skeleton of what each packet will look like

my $subexp;				#for parsing contet/pcre/uricontent sub expressions
my @payload_data;		#This 2D array has all content/pcre/uricontent peices
my @payload_peices;		#This array has all modifiers to said peices
my @payload_metadata;	#This array has all socket metadata for each rule
my $payloads;			#This variable has the number of rules read in	

my %options=();						#For cli options
getopts("t:", \%options);			#Get the options passed

if ($options{t}) {
	$base_packet = "GET /? HTTP/1.1\nHost: $options{t}\n\n";
} else {
	help();
}

######################################---Parse Rules---####################################################
open IN, 'rules.download' or die "The file has to actually exist, try again $!\n";	#input filehandle is IN
while (<IN>) {				#Whilst we still have lines in our file
	$lines[$.-1] = $_;		#Get the current line and store it in that corresponding cell in our @lines array
}
close IN;					#Close our rules filehandle

#This loop catalogues all content/pcre pecies for each rule into the @payload 2 diminsional array [rule][content/pcre/uricontent part]
$count = 0;				#init the counter
foreach (@lines) {		#go through each rule
	my $line = $_;		#Get a copy of the rule to mangle through
	$peice = 0;			#Note that we are on our first content/pcre/uricontent peice
	while (($line =~ /;\s*?((content|pcre|uricontent):!?\s?".+?";.+?)(content|pcre|uricontent).+\)$/) || ($line =~ /;\s*?((content|pcre|uricontent):!?\s?".+?".+)\)$/) ) {
		#$1 will capture first content/pcre/uricontent:""; and all options after it (up to the next content or pcre)
		$subexp = $1;								#grab the peice
		$payload_data[$count][$peice] = $subexp;	#store it in $payload_data[rule number][peice in rule]
		$line =~ s/\Q$subexp\E//;					#remove what we found so we can easily iterate to the next peice
		$peice++;									#(next peice)
	}
	$count++;										#(incremnt index number for next rule)
}

#Get metadata/socket for each rule (which network/port to network/port), and other tidbits
$count = 0;				#init the counter
foreach (@lines) {		#go through each rule
	#This regex looks gnarly, but it's just getting first part of rule:
		#protocol, source_net, source_port, dest_net, dest_port
	if ($_ =~ /^#*?alert\s+([^\s]+?)\s+([^\s]+?)\s+([^\s]+?)\s+.+?>\s+([^\s]+?)\s+([^\s]+?)\s+.+sid:(\d+)/) {
		$payload_metadata[$count][0] = $1;
		$payload_metadata[$count][1] = $2;
		$payload_metadata[$count][2] = $3;
		$payload_metadata[$count][3] = $4;
		$payload_metadata[$count][4] = $5;	
		$payload_metadata[$count][5] = $6;	
	}
	$count++
}

$payloads = @payload_data;	#get number of rules

#iterate through all pcre/content peices and note modifiers
my $i = 0;											#init the iterators
my $j = 0;											#init the iterators
while ($i < $payloads) {						#while we still have payloads
	$j = 0;
	while ($payload_data[$i][$j]) {				#while there are still content/pcre/uridata elements
		#if the element has an offset modifier, parse and capture it's value
		if (($payload_data[$i][$j]) && ($payload_data[$i][$j] =~ /;\s+offset:\s+(\d+)[^;]*?;/)) {
			$payload_peices[$i][$j][0] = $1;}
		#if the element has a distance modifier, parse and capture it's value
		if (($payload_data[$i][$j]) && ($payload_data[$i][$j] =~ /;\s+distance:\s+(\d+)[^;]*?;/)) {
			$payload_peices[$i][$j][1] = $1;}
		#if the element has an http_client_body modifier, parse and capture it's value
		if (($payload_data[$i][$j]) && ($payload_data[$i][$j] =~ /;\s+http_client_body[^;]*?;/)) {
			$payload_peices[$i][$j][2] = 'yes';
		} else {$payload_peices[$i][$j][2] = 'no'}
		#if the element has an http_cookie modifier, parse and capture it's value
		if (($payload_data[$i][$j]) && ($payload_data[$i][$j] =~ /;\s+http_cookie[^;]*?;/)) {
			$payload_peices[$i][$j][3] = 'yes';
		} else {$payload_peices[$i][$j][3] = 'no'}		
		#if the element has an http_header modifier, parse and capture it's value
		if (($payload_data[$i][$j]) && ($payload_data[$i][$j] =~ /;\s+http_header[^;]*?;/)) {
			$payload_peices[$i][$j][4] = 'yes';
		} else {$payload_peices[$i][$j][4] = 'no'}		
		#if the element has an http_method modifier, parse and capture it's value
		if (($payload_data[$i][$j]) && ($payload_data[$i][$j] =~ /;\s+http_method[^;]*?;/)) {
			$payload_peices[$i][$j][5] = 'yes';
		} else {$payload_peices[$i][$j][5] = 'no'}		
		#if the element has an http_uri modifier, parse and capture it's value
		if (($payload_data[$i][$j]) && ($payload_data[$i][$j] =~ /;\s+http_uri[^;]*?;/)) {
			$payload_peices[$i][$j][6] = 'yes';
		} else {$payload_peices[$i][$j][6] = 'no'}	
		#if the element has an http_stat_code modifier, parse and capture it's value
		if (($payload_data[$i][$j]) && ($payload_data[$i][$j] =~ /;\s+http_stat_code[^;]*?;/)) {
			$payload_peices[$i][$j][7] = 'yes';
		} else {$payload_peices[$i][$j][7] = 'no'}		
		#if the element has an http_stat_msg modifier, parse and capture it's value
		if (($payload_data[$i][$j]) && ($payload_data[$i][$j] =~ /;\s+http_stat_msg[^;]*?;/)) {
			$payload_peices[$i][$j][8] = 'yes';
		} else {$payload_peices[$i][$j][8] = 'no'}		
		#if the element has an isdataat modifier, parse and capture it's value
		if (($payload_data[$i][$j]) && ($payload_data[$i][$j] =~ /;\s+isdataat:\s+(\d+)[^;]*?;/)) {
			$payload_peices[$i][$j][9] = $1;}
		$j++;
	}
	$i++;
}
###########################################################################################################

###################################---Build Packet Data---#################################################
my @packet_content;				#a peice of injected content
my $content_counter;			#which peice of content
my @packet_pcre;				#a peice of string that will match pcre
my $pcre_counter;				#which peice of that string
my $sub_packet;					#declare peice of packet

#Build out injections for content/pcre/uricontnet elements
$count = 0;													#init counter
while ($count < $payloads) {								#while we still have rules

	my $socket = IO::Socket::INET->new(
	PeerAddr => $options{t},
	PeerPort => '80',
	Proto        => 'tcp',
	) or next;

	$packets[$count] = $base_packet;
	#print "\nRule $count -------------------\n";
	my $j = 0;	
	$content_counter = 0;									#init content/pcre/uricontent counter
	$pcre_counter = 0;
	print color 'bold blue';
	print "sid:$payload_metadata[$count][5]\n";	
	print color 'reset';
	print "GET /?";
	while ($payload_data[$count][$j]) {						#while we still have content/pcre/uricontent elements
		$sub_packet = "$payload_data[$count][$j]\n";		#grab the element
 		#is the element "content"? if so, handle with content() sub
    	if ($sub_packet =~ /^content:"(.+?)";.+$/) { 		#parse the peice between ""'s in content
    		$sub_packet = $1;								#put it in global variable for sub
    		content();										#run sub
    		$packet_content[$count][$content_counter] = $sub_packet;
    		print color 'green';
    		print $packet_content[$count][$content_counter];
    		$packets[$count] =~ s/(GET \/\?.*)( HTTP\/1.1.+)/$1$packet_content[$count][$content_counter]$2/s;
    		$content_counter++;
    	}	
    	#do we have a negeated content element
    	if ($sub_packet =~ /^content:!"(.+?)";.+$/) { 		#parse the peice between ""'s in content
    		$sub_packet = 'lol';							#if so, doesn't really matter what we inject
    		$packet_content[$count][$content_counter] = $sub_packet; 
    		print color 'magenta';
    		print $packet_content[$count][$content_counter];    		
    		$packets[$count] =~ s/(GET \/\?.*)( HTTP\/1.1.+)/$1$packet_content[$count][$content_counter]$2/s;    		  		
    		$content_counter++;    		
    	}	    	
 		#is the element "pcre"? if so, handle with pcre() sub
    	if ($sub_packet =~ /^pcre:"\/(.+)\/.*";.+$/) { 		#parse the peice between ""'s in content
    		$sub_packet = $1;								#put it in global variable for sub
    		pcre();											#run sub
    		$packet_content[$count][$pcre_counter] = $sub_packet;  
    		#$packets[$count] =~ s/(GET \/\?.*)(HTTP\/1.1.+)/$1$2/s;	
    		print color 'red';
    		print $packet_content[$count][$pcre_counter];    				
    		$packets[$count] =~ s/(GET \/\?.*)( HTTP\/1.1.+)/$1$packet_content[$count][$pcre_counter]$2/s;			 		
    		$pcre_counter++;    		
    	}	    	
    	#print "$sub_packet\n";								#print interpreted peice (will do something else with this later)
		$j++												#inc
	}

	print($socket "$packets[$count]") if $packets[$count];
	close $socket;
	#usleep(100000);
	print color 'reset';
	print " HTTP/1.1\nHost: $options{t}\n\n";
	$count++;												#inc
}

#Deduplicate content items that regex generation would make redundant
#This is not required, but it's nicer to not have uneeded data in packet

###########################################################################################################

sub content {
	#Content rules are "mostly" plaintext, but there's the tricky |hex| stuff to deal with, this
	#is mostly why this subroutine exists
    while ($sub_packet =~ /\|(([0-9a-f]{2}\s*)+?)\|/i){     #while there is content with between |'s
        my $hex = $1;										#parse it out
        my $match = $hex;									#keep another copy of the match
        $ascii = '';										#init the plaintext
        $hex =~ s/\s//g;        							#remove spaces (it's in |AB CD EF 01| format)
        while ($hex) {										#So while we have remaining hex data to process
            if ($hex =~ /(..)/) {							#grab first two nibbles
            							#And format it into ASCII/Binary data
                $ascii .= pack("C*", map { $_ ? hex($_) :() } split(/\\x/, $1));
            }
            $hex =~ s/..//;									#Then remove the part we just processed so we can do another round
        }
        $sub_packet =~ s/\|$match\|/$ascii/;                #now replace the |41 42 43| stuff with ABC
    }
}

sub pcre {
	my $regex = $sub_packet;
	#Handle Anchors (drop them, as they match anyway as a side effect)
	$regex =~ s/^\^//;
	$regex =~ s/\$$//;

	#Character Classes (Needs some Expansion)
	$regex =~ s/\\s/ /g;		#Handle regex whitespace (replace with 1 space
	$regex =~ s/\\w/a/g;		#handle regex alphanumeric (replace with an "a")
	$regex =~ s/\\d/1/g;		#handle regex digits (replace with a 1)

	$regex =~ s/([^\}\\])\./$1a/g;	#replace "." with "a" if not preceded by \ or }

	#Kill lazyness
	#If we get *? or +?, drop the ?
	$regex =~ s/\*\?/*/g;
	$regex =~ s/\+\?/+/g;

	#Quantifiers (Done)
	$regex =~ s/([^\\])\+/$1/g;		#handle 1 or more (remove the +, thing preceding it stays, wich is equivilant to 1)
	$regex =~ s/([^\\])\*/$1/g;		#handle 0, 1, or more (remove the *, thing preceding it stays, wich is equivilant to 1)
	$regex =~ s/([^\\])\?/$1/g;		#handle 0 or 1 (remove the ?, thing preceding it stays, wich is equivilant to 1)

	#Literals (Needs some Expansion
	$regex =~ s/\\\././g;		#handle literal periods (replace with \. with .)
	$regex =~ s/\\\//\//g;		#handle literal forward slashes (replace with \/ with /)
	$regex =~ s/\\\?/\?/g;		#handle literal ?'s (replace with \? with ?)
	$regex =~ s/\\\-/\-/g;		#handle literal -'s
	$regex =~ s/\\\\/\\/g;		#handle literal \'s		
	$regex =~ s/\\\]/\]/g;		#handle literal ]'s	
	$regex =~ s/\\\(/\(/g;		#handle literal ('s
	$regex =~ s/\\\)/\)/g;		#handle literal )'s
	$regex =~ s/\\\*/\*/g;		#handle literal *'s
	$regex =~ s/\\\|/\|/g;		#handle literal |'s
	$regex =~ s/\\\{/\{/g;		#handle literal {'s
	$regex =~ s/\\\}/\}/g;		#handle literal }'s
	$regex =~ s/\\\;/\;/g;		#handle literal ;'s
	$regex =~ s/\\\%/\%/g;		#handle literal %'s
	$regex =~ s/\\\:/\:/g;		#handle literal :'s
	$regex =~ s/\\\r/\r/g;		#handle literal \r's
	$regex =~ s/\\\n/\n/g;		#handle literal \n's
	$regex =~ s/\\\$/\$/g;		#handle literal \$'s

	#handle hex encoding
	while ($regex =~ /\\x([0-9a-f]{2})/i) {
	my $hex = pack("C*", map { $_ ? hex($_) :() } split(/\\x/, $1));
	$regex =~ s/\\x([0-9a-f]{2})/$hex/i
	}

	#handle character classes []'s, just take the first character for each []
	#In the case of a negated class [^abc], the "^" character gets picked as a 
	#side effect, which is still fine. [^^] is accounted for as well.
	while ($regex =~ /\[(.)(.*?)\]/) {
		my $class = $1;
		my $extra = $2;
		if (($class eq '^') && ($extra) && (($extra =~ /\^/) || ($extra =~ /^\\/))) {
			$regex =~ s/\[(.).*?\]/a/;	#handles a special negated class of [^^]
		} else {
			if ($class eq '\\') {									#if it starts with a \
				$regex =~ s/\[(.).*?\[/\[/ if ($extra =~ /^\[/);		#if next char is \, then replace with c
				$regex =~ s/\[(.).*?\]/\]/ if ($extra =~ /^\]/);
				$regex =~ s/\[(.).*?\]/\r/ if ($extra =~ /^r/i);		
				$regex =~ s/\[(.).*?\]/\n/ if ($extra =~ /^n/i);
				$regex =~ s/\[(.).*?\]/x/ if ($extra =~ /^s/i);	
				$regex =~ s/\[(.).*?\]/\:/ if ($extra =~ /^:/);
				$regex =~ s/\[(.).*?\]/\(/ if ($extra =~ /^\(/);
				$regex =~ s/\[(.).*?\]/\)/ if ($extra =~ /^\)/);
				$regex =~ s/\[(.).*?\]/\;/ if ($extra =~ /^\;/);
				$regex =~ s/\[(.).*?\]/\*/ if ($extra =~ /^\*/);
				$regex =~ s/\[(.).*?\]/\\/ if ($extra =~ /^\\/);
				$regex =~ s/\[(.).*?\]/\|/ if ($extra =~ /^\|/);
				$regex =~ s/\[(.).*?\]/\{/ if ($extra =~ /^\{/);
				$regex =~ s/\[(.).*?\]/\}/ if ($extra =~ /^\}/);
				$regex =~ s/\[(.).*?\]/\%/ if ($extra =~ /^\%/);
				$regex =~ s/\[(.).*?\]/\$/ if ($extra =~ /^\$/);
				$regex =~ s/\[(.).*?\]/\\/ if ($extra eq '');		
			} else {
				$regex =~ s/\[(.).*?\]/$class/;
			}
		}
	}

	#{30,613} {34}
	#handle {}'s, take the only or first number and repeat that many times
	#This one is probably the most complicated, must be done before ()'s
	while ($regex =~ /(\))?\{(\d).*?\}/s){
		my $grouper = $1;
		my $digit = $+;
		my $char;
		if (!$grouper) {
			if ($regex =~ /(.)\{(\d+).*?\}/s) {
				$char = $1;
				$digit = $2;
				$char = $char x $digit;	
			}
			$regex =~ s/.\{(\d).*?\}/$char/s;
		} else {
			if ($regex =~ /(\(.+?\))\{(\d+).*?\}/s) {
				$char = $1;
				$digit = $2;
				$char = $char x $digit;
			}
			$regex =~ s/(\(.+?\))\{(\d).*?\}/$char/s;
		}
	}

	#handle grouping ()'s, take the first alternation in ()'s
	while ($regex =~ /\((.+?)\|.+?\)/){
		$regex =~ s/\((.+?)\|.+?\)/$1/;
	}

	#remove gratuitus parenthesis
	$regex =~ s/\(|\)//g;
	$sub_packet = $regex;
}

sub help {
	print "Dummy help file\n";
	exit;
}

#Testing:
#print "payload 1147[0] data: $payload_data[1147][0]\n";
#print "payload 1147[0] peice: $payload_peices[1147][0][6]\n";
#print "payload metadata\n";
#print "\tprotocol: $payload_metadata[12][0]\n";
#print "\tsource net: $payload_metadata[12][1]\n";
#print "\tsource port: $payload_metadata[12][2]\n";
#print "\tdest net: $payload_metadata[12][3]\n";
#print "\tdest port: $payload_metadata[12][4]\n";

=put

@payload_data datastructure:
$payload_data[rule][content or pcre part]

@payload_peices datastructure:
$payload_peices[rule][content or pcre part][modifier]
	[0] = offset (value)
	[1] = distance (value)
	[2] = http_client_body (yes/no)
	[3] = http_cookie (yes/no)
	[4] = http_header (yes/no)
	[5] = http_method (yes/no)
	[6] = http_uri (yes/no)
	[7] = http_stat_code (yes/no)
	[8] = http_stat_msg (yes/no)
	[9] = isdataat (value)

$payload_metadata[rule][item]
	[0] = protocol (tcp/udp)
	[1] = source network
	[2] = source port
	[3] = dest network
	[4] = dest port
	[5] = sid

modifiers to use / not use:
	Not Use:
		nocase: We don't need this because the packet wont differ from the case used in rule itself
		rawbytes: Don't yet see why this will need to be relevant
		depth: The rule can give whatever limit it wants, but 8ball will attempt to pack the sig as close to the beginning as possible, so this shouldn't be an issue
		within: This rule can be ignored for the same reason as depth
		http_raw_cookie: Not using for the same reason as rawbytes
		http_raw_header: Not using for the same reason as rawbytes
		http_raw_uri: Not using for the same reason as rawbytes
		pkt_data: Because I don't feel like it and harldy any rules seem to use it

		file_data: I'm pretty sure this can be ignored, but use used in a bit of rules, so should be tested
		base64_decode: while this would change packets, not implementing for now due to lack of use in rules from ET
		byte_test: Just seems like a pain in the ass
		byte_jump: Also a pain in the ass
		byte_extract: Also a pain in the ass
		base64_data: only found one rule in ET that uses this, but may still try implementing			

	Use:
		offset: We will need to use this, we will generally need to pad the first part of the packet with however many bytes the offset is
			;\s+offset:\s+\d+[^;]+?;
		distance: This will be needed for the same reason as offset
		http_client_body
		http_cookie
		http_header
		http_method
		http_uri
		http_stat_code
		http_stat_msg
		isdataat: another area that may need padding
		urilen:		

	Non-Content modifiers to use:
		http_encode: Probably wont use anyway, didn't find much ET rules using this

=cut
