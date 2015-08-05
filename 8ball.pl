#!/usr/bin/perl
use warnings;
use strict;
use IO::Socket;
use Getopt::Std;
use Term::ANSIColor;
use Time::HiRes qw(usleep nanosleep);
use Try::Tiny;			#There are still bugs, this lets us not fail hard

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

my $expression;
my $ll;
my $regex;
my $string;
my $qlimit = 50;
#Some Metacharacter tokens...it's a weird hack, works great, I don't want to talk about it.
my $openparentoken = 'Ksc8pdCnhh';
my $closeparentoken = '2KzsuZTSrw';
my $opensquaretoken = 'pQwCCbYXqB';
my $closesquaretoken = 'UFa1N8tdjS';
my $openbracetoken = 'yVvs4ukduq';
my $closebracetoken = 'PvnD1hEwty';
my $alternativetoken = 'IAnelK5Zgr';

my %options=();						#For cli options
getopts("t:r:d:hels", \%options);		#Get the options passed

if (($options{t}) && ($options{r})) {
	$base_packet = "GET /? HTTP/1.1\nHost: $options{t}\n\n";
} else {
	help();
}

sub lastlexeme ($) {
	$ll = '';
	$expression = shift;
	chomp($expression);
	$expression =~ s/\$$//;		#remove the anchor for hax reasons

	start:

	if ($expression =~ /[?+*}]\?$/) { 		#If the expression ends in laziness
		$ll = 'x';							#just fucking give up and set it to 'x'
		return;
	}
	if ($expression =~ /(\\?[^}?+*)\]\$])$/){		#is last character an atom
		$ll = $1;									#if so, this is our last lexeme
	}
	if ($expression =~ /\]$/){					#is last character is a ]
		if ($expression =~ /(\[[^\[]+)$/) {		#parse the character class
			$ll = $1;		
		}						
	}
	if ($expression =~ /\)$/){					#is last character is a )
		if ($expression =~ /(\([^\(]+)$/) {		#parse the grouping
			$ll = $1;		
		}						
	}	

	#Quantifiers
	#+
	if ($expression =~ /\+$/) {							#If last character is +
		if ($expression =~ /(\\?[^}?+*)\]\$]\+)$/){		#is last character an atom
			$ll = $1;									#if so, this is our last lexeme
		}
		if ($expression =~ /\]\+$/){					#is last character is a ]
			if ($expression =~ /(\[[^\[]+\+)$/) {		#parse the character class
				$ll = $1;		
			}						
		}
		if ($expression =~ /\)\+$/){					#is last character is a )
			if ($expression =~ /(\([^\(]+\+)$/) {		#parse the grouping
				$ll = $1;		
			}						
		}	
	}
	#{..}
	if ($expression =~ /\{.+?\}$/) {						#If last character is }
		if ($expression =~ /(\\?[^}?+*)\]\$]\{.+?\})$/){	#is last character an atom
			$ll = $1;										#if so, this is our last lexeme
		}
		if ($expression =~ /\]\{.+?\}$/){					#is last character is a ]
			if ($expression =~ /(\\?\[[^\[]+\{.+?\})$/) {	#parse the character class
				$ll = $1;		
			}						
		}
		if ($expression =~ /\)\{.+?\}$/){					#is last character is a )
			if ($expression =~ /(\([^\(]+\{.+?\})$/) {		#parse the grouping
				$ll = $1;		
			}						
		}	
	}	

	#?	
	if ($expression =~ /\?$/) {							#If last character is ?
		if ($expression =~ /(\\?[^}?+*)\]\$]\?)$/){		#is last character an atom
			$expression =~ s/\Q$1\E$//;
		}
		if ($expression =~ /\]\?$/){					#is last character is a ]
			if ($expression =~ /(\[[^\[]+\?)$/) {		#parse the character class
				$expression =~ s/\Q$1\E$//;		
			}						
		}
		if ($expression =~ /\)\?$/){					#is last character is a )
			if ($expression =~ /(\([^\(]+\?)$/) {		#parse the grouping
				$expression =~ s/\Q$1\E$//;		
			}						
		}
		goto start;										#OMFG I used a goto
	}

	#*
	if ($expression =~ /\*$/) {							#If last character is ?
		if ($expression =~ /(\\?[^}?+*)\]\$]\*)$/){		#is last character an atom
			$expression =~ s/\Q$1\E$//;
		}
		if ($expression =~ /\]\*$/){					#is last character is a ]
			if ($expression =~ /(\[[^\[]+\*)$/) {		#parse the character class
				$expression =~ s/\Q$1\E$//;		
			}						
		}
		if ($expression =~ /\)\*$/){					#is last character is a )
			if ($expression =~ /(\([^\(]+\*)$/) {		#parse the grouping
				$expression =~ s/\Q$1\E$//;		
			}						
		}
		if ($expression =~ /(\\\?\*|\\\*\*|\\\$\*|\\\$\*)$/) {		#do we end with a \?*, \** \$?, or \$*
			$expression =~ s/\Q$1\E$//;					#remove that
		}
		goto start;										#OMFG I used a goto
	}	

	#{0,}  \{0.+
	if ($expression =~ /{0.+$/) {						#If last characters are {0,#}
		if ($expression =~ /(\\?[^}?+*)\]\$]{0.+)$/){	#is last character an atom
			$expression =~ s/\Q$1\E$//;
		}
		if ($expression =~ /\]{0.+$/){					#is last character is a ]
			if ($expression =~ /(\[[^\[]+{0.+)$/) {		#parse the character class
				$expression =~ s/\Q$1\E$//;		
			}						
		}
		if ($expression =~ /\){0.+$/){					#is last character is a )
			if ($expression =~ /(\([^\(]+{0.+)$/) {		#parse the grouping
				$expression =~ s/\Q$1\E$//;		
			}						
		}
		goto start;										#OMFG I used a goto
	}		

	return $ll;
}

sub negatelex ($) {
	my $negate = shift;
	#This charlist is in a specific order; within the first few chars, one of them should negate the expression, otherwise, try all the rest
	my @chars = ('a','1','@',' ','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','2','3','4','5','6','7','8','9','0','~','!','#','$','%','^','&','*','(',')','_','+','-','=','[',']','{','}','\\','|',';',':',',','<','.','>','/','?','`');
	try {
		foreach (@chars) {
			if ($_ !~ $negate) {
				return $_;
			}
		}
		return "@";		#Didn't find a negation (this can happen if the last lexeme is a '.')

	} catch {
		return '@';		#There was an error with the lexeme, don't worry about it though, just make it an @ as well
	};
}

sub filters($) {
	#-h -e filters, add them
	my $filter = shift;
	my $result;
	#If we have a tcp rule with a specific source port, don't use it. I don't want to attempt to spoof a TCP socket
	if ($filter !~ /^alert\s+tcp\s+[^\s]+?\s+any/) {return "false";}
	#If we want to stick exclusive to $HOME_NET, keep $HOME_NET and 'any'
	if (($options{h}) && ($filter !~ /^alert\s+\w+\s+(\$HOME_NET|any)/)) {return "false";}
	#If we want to stick exclusive to $EXTERNAL_NET, keep $EXTERNAL_NET and 'any'	
	if (($options{e}) && ($filter !~ /^alert\s+\w+\s+(\$EXTERNAL_NET|any)/)) {return "false";}	
	return "true";
}

######################################---Parse Rules---####################################################
open IN, "$options{r}" or die "The file has to actually exist, try again $!\n";	#input filehandle is IN
my $i = 0;
while (<IN>) {				#Whilst we still have lines in our file
	if ((filters($_) ne "false")) {
		$lines[$i] = $_;		#Get the current line and store it in that corresponding cell in our @lines array
		$i++;
	}
}
close IN;					#Close our rules filehandle

#REMOVE WHEN FINISHED, this file is for troubleshooting which rules made it after filtering
open OUT, ">troubleshooting.txt";
	print OUT @lines;

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
$i = 0;											#init the iterators
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
	);
	next unless $socket;

	$packets[$count] = $base_packet;
	#print "\nRule $count -------------------\n";
	my $j = 0;	
	$content_counter = 0;									#init content/pcre/uricontent counter
	$pcre_counter = 0;
	print color 'bold blue' if !$options{s};
	print "sid:$payload_metadata[$count][5]\n" if !$options{s};
	print color 'reset' if !$options{s};
	print "GET /?" if !$options{s};
	while ($payload_data[$count][$j]) {						#while we still have content/pcre/uricontent elements
		$sub_packet = "$payload_data[$count][$j]\n";		#grab the element
 		#is the element "content"? if so, handle with content() sub
    	if ($sub_packet =~ /^content:"(.+?)";.+$/) { 		#parse the peice between ""'s in content
    		$sub_packet = $1;								#put it in global variable for sub
    		content();										#run sub
    		$packet_content[$count][$content_counter] = $sub_packet;
    		print color 'green' if !$options{s};
    		print $packet_content[$count][$content_counter] if !$options{s};
    		$packets[$count] =~ s/(GET \/\?.*)( HTTP\/1.1.+)/$1$packet_content[$count][$content_counter]$2/s;
    		$content_counter++;
    	}	
    	#do we have a negeated content element
    	if ($sub_packet =~ /^content:!"(.+?)";.+$/) { 		#parse the peice between ""'s in content
    		$sub_packet = 'lol';							#if so, doesn't really matter what we inject
    		$packet_content[$count][$content_counter] = $sub_packet; 
    		print color 'magenta' if !$options{s};
    		print $packet_content[$count][$content_counter] if !$options{s};  		
    		$packets[$count] =~ s/(GET \/\?.*)( HTTP\/1.1.+)/$1$packet_content[$count][$content_counter]$2/s;    		  		
    		$content_counter++;    		
    	}	    	
 		#is the element "pcre"? if so, handle with pcre() sub
    	if ($sub_packet =~ /^pcre:"\/(.+)\/.*";.+$/) { 		#parse the peice between ""'s in content
    		$sub_packet = $1;								#put it in global variable for sub


    		if ($options{l}){
    			#Create Denial of Service string
				try {
					my $endanchor = 'no';
					my $orig_exp = $sub_packet;
					if ($orig_exp =~ /\$$/) {							#if this is an end anchored expression
						$endanchor = 'yes';						#make note
					}
					my $last_l = lastlexeme($orig_exp);				#get last lexeme
					my $neg_l = negatelex(lastlexeme($orig_exp));		#get minimal negation of it
					$regex = $string = $orig_exp;						#get our expression
					if ($endanchor eq 'yes') {
						my $last_l_norm = pcre_dos($last_l);
						$neg_l = $last_l_norm . $neg_l;
					}
					#sub last lexeme with literal bad/negation part
					$regex =~ s/\Q$last_l\E\$?$//;
					$regex .= $neg_l;
					$regex = pcre_dos($regex);		#pass through again
				} catch {
					$regex = "I'm a stupid payload, becuase 8ball couldn't DoS\n";
				};
    		} else {
    			pcre();			#do simple (efficient) string
    		}
    		$sub_packet = $regex;


    		$packet_content[$count][$pcre_counter] = $sub_packet;  
    		#$packets[$count] =~ s/(GET \/\?.*)(HTTP\/1.1.+)/$1$2/s;	
    		print color 'red' if !$options{s};
    		print $packet_content[$count][$pcre_counter] if !$options{s};   				
    		$packets[$count] =~ s/(GET \/\?.*)( HTTP\/1.1.+)/$1$packet_content[$count][$pcre_counter]$2/s;			 		
    		$pcre_counter++;    		
    	}	    	
    	#print "$sub_packet\n";								#print interpreted peice (will do something else with this later)
		$j++												#inc
	}

	#print($socket "$packets[$count]") if $packets[$count];
	close $socket;
	#usleep(100000);	
	#usleep(10000);
	usleep($options{d}) if $options{d};
	print color 'reset' if !$options{s};
	print " HTTP/1.1\nHost: $options{t}\n\n" if !$options{s};
	$count++;												#inc
}
#96747
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
	#Tokenize some metacharacters
	my $pcre = $sub_packet;
	$pcre =~ s/\\\(/$openparentoken/g;
	$pcre =~ s/\\x28/$openparentoken/g;	
	$pcre =~ s/\\\)/$closeparentoken/g;
	$pcre =~ s/\\x29/$closeparentoken/g;			
	$pcre =~ s/\\\[/$opensquaretoken/g;
	$pcre =~ s/\\x5b/$opensquaretoken/gi;	
	$pcre =~ s/\\\]/$closesquaretoken/g;
	$pcre =~ s/\\x5d/$closesquaretoken/gi;	
	$pcre =~ s/\\\{/$openbracetoken/g;
	$pcre =~ s/\\x7b/$openbracetoken/gi;	
	$pcre =~ s/\\\}/$closebracetoken/g;
	$pcre =~ s/\\x7d/$closebracetoken/gi;	
	$pcre =~ s/\\\|/$alternativetoken/g;
	$pcre =~ s/\\x7c/$alternativetoken/gi;	

	#Handle {\d,} situation
	$pcre =~ s/(\{\d+),(\})/$1,2$2/g;

	#We don't care about non-capturing groups
	$pcre =~ s/\(\?:/(/g;

	#Experimental Lookarounds:
	$pcre =~ s/\(\?=/(/g;	
	$pcre =~ s/\(\?!.+?\)/(a)/g;	
	$pcre =~ s/\(\?<=/(/g;	
	$pcre =~ s/\(\?<!.+?\)/(a)/g;						

	#Handle Anchors (drop them, as they match anyway as a side effect)
	$pcre =~ s/^\^//;
	$pcre =~ s/\$$//;

	#Character Classes (Needs some Expansion)
	$pcre =~ s/\\s/ /g;		#Handle regex whitespace (replace with 1 space
	$pcre =~ s/\\w/a/g;		#handle regex alphanumeric (replace with an "a")
	$pcre =~ s/\\d/1/g;		#handle regex digits (replace with a 1)
	$pcre =~ s/\\S/a/g;		#Handle regex non-whitespace (replace with 1 "a"
	$pcre =~ s/\\W/ /g;		#handle regex non-alphanumeric (replace with an space)
	$pcre =~ s/\\D/a/g;		#handle regex non-digits (replace with 1 "a")

	$pcre =~ s/([^\}\\])\./$1a/g;	#replace "." with "a" if not preceded by \ or }

	#Kill lazyness
	#If we get *? or +?, drop the ?
	$pcre =~ s/\*\?/*/g;
	$pcre =~ s/\+\?/+/g;
	$pcre =~ s/\?\?/+/g;	

	my $replacement = '';
	#Quantifiers (Done)
	$pcre =~ s/([^\\])\+/$1/g;		#handle 1 or more (remove the +, thing preceding it stays, wich is equivilant to 1)
	$pcre =~ s/([^\\])\*/$1/g;		#handle 0, 1, or more (remove the *, thing preceding it stays, wich is equivilant to 1)
	$pcre =~ s/([^\\])\?/$1/g;		#handle 0 or 1 (remove the ?, thing preceding it stays, wich is equivilant to 1)

	#Literals (Needs some Expansion
	$pcre =~ s/\\\././g;		#handle literal periods (replace with \. with .)
	$pcre =~ s/\\\//\//g;		#handle literal forward slashes (replace with \/ with /)
	$pcre =~ s/\\\?/\?/g;		#handle literal ?'s (replace with \? with ?)
	$pcre =~ s/\\\-/\-/g;		#handle literal -'s
	$pcre =~ s/\\\\/\\/g;		#handle literal \'s		
	$pcre =~ s/\\\]/\]/g;		#handle literal ]'s	
	$pcre =~ s/\\\[/\[/g;		#handle literal ['s		
	$pcre =~ s/\\\(/\(/g;		#handle literal ('s
	$pcre =~ s/\\\)/\)/g;		#handle literal )'s
	$pcre =~ s/\\\*/\*/g;		#handle literal *'s
	$pcre =~ s/\\\|/\|/g;		#handle literal |'s
	$pcre =~ s/\\\{/\{/g;		#handle literal {'s
	$pcre =~ s/\\\}/\}/g;		#handle literal }'s
	$pcre =~ s/\\\;/\;/g;
	$pcre =~ s/\\\%/\%/g;		#handle literal %'s
	$pcre =~ s/\\\:/\:/g;		#handle literal :'s
	$pcre =~ s/\\\&/\&/g;		#handle literal &'s	
	$pcre =~ s/\\\=/\=/g;		#handle literal ='s		
	$pcre =~ s/\\\ /\ /g;		#handle literal spaces's			
	$pcre =~ s/\\r/\x0d/g;		#handle literal \r's
	$pcre =~ s/\\n/\x0a/g;		#handle literal \n's
	$pcre =~ s/\\\$/\$/g;		#handle literal \$'s

	#handle hex encoding
	while ($pcre =~ /\\x([0-9a-f]{2})/i) {
	my $hex = pack("C*", map { $_ ? hex($_) :() } split(/\\x/, $1));
	$pcre =~ s/\\x([0-9a-f]{2})/$hex/i;
	}

	#handle character classes []'s, just take the first character for each []
	#In the case of a negated class [^abc], the "^" character gets picked as a 
	#side effect, which is still fine. [^^] is accounted for as well.
	while ($pcre =~ /\[(.)(.*?)\]/) {		#get [$1$2] where $1 is only one char and $2 is whats left
		my $class = $1;
		my $extra = $2;
		if (($class eq '^') && ($extra) && (($extra =~ /\^/) || ($extra =~ /^\\/))) {
			$pcre =~ s/\[(.).*?\]/a/;	#handles a special negated class of [^^]
		} else {
			if ($class eq '\\') {									#if it starts with a \
				#if extra starts with [, then replace [$1$2] with [
					#So [\[] is converted to just a [ (and etc... for the rest of these)
				$pcre =~ s/\[(.).*?\[/\[/ if ($extra =~ /^\[/);
				$pcre =~ s/\[(.).*?\]/\]/ if ($extra =~ /^\]/);
				$pcre =~ s/\[(.).*?\]/\x0d/ if ($extra =~ /^r/i);		
				$pcre =~ s/\[(.).*?\]/\x0a/ if ($extra =~ /^n/i);
				$pcre =~ s/\[(.).*?\]/x/ if ($extra =~ /^s/i);
				$pcre =~ s/\[(.).*?\]/\:/ if ($extra =~ /^:/);
				$pcre =~ s/\[(.).*?\]/\(/ if ($extra =~ /^\(/);
				$pcre =~ s/\[(.).*?\]/\)/ if ($extra =~ /^\)/);
				$pcre =~ s/\[(.).*?\]/\;/ if ($extra =~ /^\;/);
				$pcre =~ s/\[(.).*?\]/\*/ if ($extra =~ /^\*/);
				$pcre =~ s/\[(.).*?\]/\\/ if ($extra =~ /^\\/);
				$pcre =~ s/\[(.).*?\]/\\/ if ($extra =~ /^\//);				
				$pcre =~ s/\[(.).*?\]/\\/ if ($extra eq '');				
				$pcre =~ s/\[(.).*?\]/\|/ if ($extra =~ /^\|/);
				$pcre =~ s/\[(.).*?\]/\{/ if ($extra =~ /^\{/);
				$pcre =~ s/\[(.).*?\]/\}/ if ($extra =~ /^\}/);
				$pcre =~ s/\[(.).*?\]/\%/ if ($extra =~ /^\%/);
				$pcre =~ s/\[(.).*?\]/\$/ if ($extra =~ /^\$/);
				$pcre =~ s/\[(.).*?\]/\+/ if ($extra =~ '^\+');	
				$pcre =~ s/\[(.).*?\]/\&/ if ($extra =~ '^\&');		
				$pcre =~ s/\[(.).*?\]/\=/ if ($extra =~ '^\=');	
				$pcre =~ s/\[(.).*?\]/\!/ if ($extra =~ '^\!');
				$pcre =~ s/\[(.).*?\]/\@/ if ($extra =~ '^\@');
				$pcre =~ s/\[(.).*?\]/\^/ if ($extra =~ '^^');														
				$pcre =~ s/\[(.).*?\]/\ / if ($extra =~ '^\ ');
				$pcre =~ s/\[(.).*?\]/\t/ if ($extra =~ '^t');				
				#gracefully handle unicode, results are a failure, but prevents infinite loop
				$pcre =~ s/\[(.).*?\]/\u/ if ($extra =~ '^u');														
			} else {
				$pcre =~ s/\[(.).*?\]/$class/;
			}
		}
	}

	#handle {}'s, take the only or first number and repeat that many times
	#This one is probably the most complicated, must be done before ()'s
	while ($pcre =~ /(\))?\{(\d).*?\}/s){
		my $grouper = $1;
		my $digit = $+;
		my $char;
		if (!$grouper) {
			if ($pcre =~ /(.)\{(\d+).*?\}/s) {
				$char = $1;
				$digit = $2;
				$char = $char x $digit;	
			}
			$pcre =~ s/.\{(\d).*?\}/$char/s;
		} else {
			if ($pcre =~ /(\(.+?\))\{(\d+).*?\}/s) {
				$char = $1;
				$digit = $2;
				$char = $char x $digit;
			}
			$pcre =~ s/(\(.+?\))\{(\d).*?\}/$char/s;
		}
	}

	#handle grouping ()'s, take the last alternation in ()'s
	while ($pcre =~ /\(([^)]+?)\|.?\)/s){		#while we still have a group

		#Do something with it
		$pcre =~ s/\((.+?)\|.*?\)/$1/s; 		#this replaces with first option
	}

	#remove gratuitus parenthesis
	$pcre =~ s/\(|\)//g;

	#Reintroduce tokenized metacharacters as literal
	$pcre =~ s/$openparentoken/(/g;
	$pcre =~ s/$closeparentoken/)/g;
	$pcre =~ s/$opensquaretoken/[/g;
	$pcre =~ s/$closesquaretoken/]/g;
	$pcre =~ s/$openbracetoken/{/g;
	$pcre =~ s/$closebracetoken/}/g;	
	$pcre =~ s/$alternativetoken/|/g;	

	$regex = $pcre;					
}

sub pcre_dos {
	#Tokenize some metacharacters
	my $pcre = shift;
	$pcre =~ s/\\\(/$openparentoken/g;
	$pcre =~ s/\\x28/$openparentoken/g;	
	$pcre =~ s/\\\)/$closeparentoken/g;
	$pcre =~ s/\\x29/$closeparentoken/g;			
	$pcre =~ s/\\\[/$opensquaretoken/g;
	$pcre =~ s/\\x5b/$opensquaretoken/gi;	
	$pcre =~ s/\\\]/$closesquaretoken/g;
	$pcre =~ s/\\x5d/$closesquaretoken/gi;	
	$pcre =~ s/\\\{/$openbracetoken/g;
	$pcre =~ s/\\x7b/$openbracetoken/gi;	
	$pcre =~ s/\\\}/$closebracetoken/g;
	$pcre =~ s/\\x7d/$closebracetoken/gi;	
	$pcre =~ s/\\\|/$alternativetoken/g;
	$pcre =~ s/\\x7c/$alternativetoken/gi;	

	#Handle {\d,} situation
	$pcre =~ s/(\{\d+),(\})/$1,100$2/g;

	#We don't care about non-capturing groups
	$pcre =~ s/\(\?:/(/g;

	#Experimental Lookarounds:
	$pcre =~ s/\(\?=/(/g;	
	$pcre =~ s/\(\?!.+?\)/(a)/g;	
	$pcre =~ s/\(\?<=/(/g;	
	$pcre =~ s/\(\?<!.+?\)/(a)/g;						

	#Handle Anchors (drop them, as they match anyway as a side effect)
	$pcre =~ s/^\^//;
	$pcre =~ s/\$$//;

	#Character Classes (Needs some Expansion)
	$pcre =~ s/\\s/ /g;		#Handle regex whitespace (replace with 1 space
	$pcre =~ s/\\w/a/g;		#handle regex alphanumeric (replace with an "a")
	$pcre =~ s/\\d/1/g;		#handle regex digits (replace with a 1)
	$pcre =~ s/\\S/a/g;		#Handle regex non-whitespace (replace with 1 "a"
	$pcre =~ s/\\W/ /g;		#handle regex non-alphanumeric (replace with an space)
	$pcre =~ s/\\D/a/g;		#handle regex non-digits (replace with 1 "a")

	$pcre =~ s/([^\}\\])\./$1a/g;	#replace "." with "a" if not preceded by \ or }

	#Kill lazyness
	#If we get *? or +?, drop the ?
	$pcre =~ s/\*\?/*/g;
	$pcre =~ s/\+\?/+/g;
	$pcre =~ s/\?\?/+/g;	

	my $replacement = '';
	#Quantifiers (Done)
	#below is the non-evil version of the + modifier
	#$pcre =~ s/([^\\])\+/$1/g;		#handle 1 or more (remove the +, thing preceding it stays, wich is equivilant to 1)
	while ($pcre =~ /([^\\+])\+(?!\+)/) {		#Is there still an unescaped + quantifier with no surrounding +'s
		my $classchar = $1;
		#handle character class (pick the last character)
		if ($classchar eq ']') {
			if ($pcre =~ /(.)[^\\+]\+(?!\+)/) {
				$classchar = $1;
				$replacement = "$classchar" x 50;
				$pcre =~ s/\[[^\]]+?\]\+/$replacement/;
			}
		} else {
			$replacement = "$classchar" x 50;				#If so, take what we are quantifying up to 50
			$pcre =~ s/([^\\])\+/$replacement/;		#replace that ONE instance with the 50x version (non global; becuase the replacement changes per iteration)
		}
		print "After +:\t\t$pcre\n" if $debug;
	}
	#below is the non-evil version of the * modifier
	#$pcre =~ s/([^\\])\*/$1/g;		#handle 0, 1, or more (remove the *, thing preceding it stays, wich is equivilant to 1)
	while ($pcre =~ /([^\\])\*/) {				#Is there still a + quantifier
		$replacement = "$1" x 50;				#If so, take what we are quantifying up to 50
		$pcre =~ s/([^\\])\*/$replacement/;		#replace that ONE instance with the 50x version (non global; becuase the replacement changes per iteration)
	}
	$pcre =~ s/([^\\])\?/$1/g;		#handle 0 or 1 (remove the ?, thing preceding it stays, wich is equivilant to 1)

	#Literals (Needs some Expansion
	$pcre =~ s/\\\././g;		#handle literal periods (replace with \. with .)
	$pcre =~ s/\\\//\//g;		#handle literal forward slashes (replace with \/ with /)
	$pcre =~ s/\\\?/\?/g;		#handle literal ?'s (replace with \? with ?)
	$pcre =~ s/\\\-/\-/g;		#handle literal -'s
	$pcre =~ s/\\\\/\\/g;		#handle literal \'s		
	$pcre =~ s/\\\]/\]/g;		#handle literal ]'s	
	$pcre =~ s/\\\[/\[/g;		#handle literal ['s		
	$pcre =~ s/\\\(/\(/g;		#handle literal ('s
	$pcre =~ s/\\\)/\)/g;		#handle literal )'s
	$pcre =~ s/\\\*/\*/g;		#handle literal *'s
	$pcre =~ s/\\\|/\|/g;		#handle literal |'s
	$pcre =~ s/\\\{/\{/g;		#handle literal {'s
	$pcre =~ s/\\\}/\}/g;		#handle literal }'s
	$pcre =~ s/\\\;/\;/g;
	$pcre =~ s/\\\%/\%/g;		#handle literal %'s
	$pcre =~ s/\\\:/\:/g;		#handle literal :'s
	$pcre =~ s/\\\&/\&/g;		#handle literal &'s	
	$pcre =~ s/\\\=/\=/g;		#handle literal ='s		
	$pcre =~ s/\\\ /\ /g;		#handle literal spaces's			
	$pcre =~ s/\\r/\x0d/g;		#handle literal \r's
	$pcre =~ s/\\n/\x0a/g;		#handle literal \n's
	$pcre =~ s/\\\$/\$/g;		#handle literal \$'s

	#handle hex encoding
	while ($pcre =~ /\\x([0-9a-f]{2})/i) {
	my $hex = pack("C*", map { $_ ? hex($_) :() } split(/\\x/, $1));
	$pcre =~ s/\\x([0-9a-f]{2})/$hex/i;
	}

	#handle character classes []'s, just take the first character for each []
	#In the case of a negated class [^abc], the "^" character gets picked as a 
	#side effect, which is still fine. [^^] is accounted for as well.
	while ($pcre =~ /\[(.)(.*?)\]/) {		#get [$1$2] where $1 is only one char and $2 is whats left
		my $class = $1;
		my $extra = $2;
		if (($class eq '^') && ($extra) && (($extra =~ /\^/) || ($extra =~ /^\\/))) {
			$pcre =~ s/\[(.).*?\]/a/;	#handles a special negated class of [^^]
		} else {
			if ($class eq '\\') {									#if it starts with a \
				#if extra starts with [, then replace [$1$2] with [
					#So [\[] is converted to just a [ (and etc... for the rest of these)
				$pcre =~ s/\[(.).*?\[/\[/ if ($extra =~ /^\[/);
				$pcre =~ s/\[(.).*?\]/\]/ if ($extra =~ /^\]/);
				$pcre =~ s/\[(.).*?\]/\x0d/ if ($extra =~ /^r/i);		
				$pcre =~ s/\[(.).*?\]/\x0a/ if ($extra =~ /^n/i);
				$pcre =~ s/\[(.).*?\]/x/ if ($extra =~ /^s/i);
				$pcre =~ s/\[(.).*?\]/\:/ if ($extra =~ /^:/);
				$pcre =~ s/\[(.).*?\]/\(/ if ($extra =~ /^\(/);
				$pcre =~ s/\[(.).*?\]/\)/ if ($extra =~ /^\)/);
				$pcre =~ s/\[(.).*?\]/\;/ if ($extra =~ /^\;/);
				$pcre =~ s/\[(.).*?\]/\*/ if ($extra =~ /^\*/);
				$pcre =~ s/\[(.).*?\]/\\/ if ($extra =~ /^\\/);
				$pcre =~ s/\[(.).*?\]/\\/ if ($extra =~ /^\//);				
				$pcre =~ s/\[(.).*?\]/\\/ if ($extra eq '');				
				$pcre =~ s/\[(.).*?\]/\|/ if ($extra =~ /^\|/);
				$pcre =~ s/\[(.).*?\]/\{/ if ($extra =~ /^\{/);
				$pcre =~ s/\[(.).*?\]/\}/ if ($extra =~ /^\}/);
				$pcre =~ s/\[(.).*?\]/\%/ if ($extra =~ /^\%/);
				$pcre =~ s/\[(.).*?\]/\$/ if ($extra =~ /^\$/);
				$pcre =~ s/\[(.).*?\]/\+/ if ($extra =~ '^\+');	
				$pcre =~ s/\[(.).*?\]/\&/ if ($extra =~ '^\&');		
				$pcre =~ s/\[(.).*?\]/\=/ if ($extra =~ '^\=');	
				$pcre =~ s/\[(.).*?\]/\!/ if ($extra =~ '^\!');
				$pcre =~ s/\[(.).*?\]/\@/ if ($extra =~ '^\@');
				$pcre =~ s/\[(.).*?\]/\^/ if ($extra =~ '^^');														
				$pcre =~ s/\[(.).*?\]/\ / if ($extra =~ '^\ ');
				$pcre =~ s/\[(.).*?\]/\t/ if ($extra =~ '^t');				
				#gracefully handle unicode, results are a failure, but prevents infinite loop
				$pcre =~ s/\[(.).*?\]/\u/ if ($extra =~ '^u');														
			} else {
				$pcre =~ s/\[(.).*?\]/$class/;
			}
		}
	}

	#handle {}'s, take the only or last number and repeat that many times munus 1, unless it's greater than 50, then just do 50
	#This one is probably the most complicated, must be done before ()'s
	while ($pcre =~ /(\))?\{(\d).*?\}/s){			#while maybe preceded by ) - a { - followed by digit - then anything to last }
		my $grouper = $1;	#may be )
		my $digit = $+;		#the first digit
		my $char;
		my $digit2 = '';
		if (!$grouper) {	#If it's atomic: a{1,4}
			if ($pcre =~ /(.)\{(\d+)(.*?)\}/s) {	#get the atom and first digit and possibly 2nd digit
				$char = $1;						#atom
				$digit = $2;					#first digit
				if ($3) {
					$digit2 = $3;
					if ($digit2 =~ /(\d+)/) {
						$digit2 = $1;
						if ($digit2 > ($qlimit - 1)) {
							$digit2 = $qlimit;
						}
						$digit2--;						
						$char = $char x $digit2;
					} else {
						$char = $char x $digit;
					}
				} else {
					$char = $char x $digit;
				}
			}
			if ($char eq '') {
				$pcre =~ s/\{(\d).*?\}//s;
			} else { 
				$pcre =~ s/.\{(\d).*?\}/$char/s;
			}
		} else {
			if ($pcre =~ /(\(.+?\))\{(\d+)(.*?)\}/s) {
				$char = $1;
				$digit = $2;
				if ($3) {
					$digit2 = $3;
					if ($digit2 =~ /(\d+)/) {
						$digit2 = $1;
						if ($digit2 > ($qlimit - 1)) {
							$digit2 = $qlimit;
						}
						$digit2--;
						$char = $char x $digit2;
					} else {
						$char = $char x $digit;
					}
				} else {
					$char = $char x $digit;
				}	
			}
			$pcre =~ s/(\(.+?\))\{(\d).*?\}/$char/s;
		}
	}

	#handle grouping ()'s, take the last alternation in ()'s
	while ($pcre =~ /\(([^)]+?)\|.+?\)/s){		#while we still have a group

		#Do something with it
		#$pcre =~ s/\((.+?)\|.+?\)/$1/; 		#this replaces with first option
		$pcre =~ s/\(.+?\|([^|]*?)\)/$1/s;			#this replaces with last option
	}

	#remove gratuitus parenthesis
	$pcre =~ s/\(|\)//g;

	#Reintroduce tokenized metacharacters as literal
	$pcre =~ s/$openparentoken/(/g;
	$pcre =~ s/$closeparentoken/)/g;
	$pcre =~ s/$opensquaretoken/[/g;
	$pcre =~ s/$closesquaretoken/]/g;
	$pcre =~ s/$openbracetoken/{/g;
	$pcre =~ s/$closebracetoken/}/g;	
	$pcre =~ s/$alternativetoken/|/g;	

	return $pcre;					
}


sub help {
	print "NAME\n";
	print "\t8ball - An IDS validation tool\n\n";
	print "SYNOPSIS\n";
	print "\t8ball.pl -t ip -r rules [ -d delay]\n\n";
	print "DESCRIPTION\n";
	print "\tThis tool will 'kick the tires' on your Suricata/Snort based IDS by attempting to send a packet for every rule that you supply it from a rules file input\n\n";
	print "OPTIONS\n";
	print "\t-t: The target IP address is required to follow this option\n";
	print "\t-r: The IDS rule file to feed into 8ball engine";
	print "\t-d: You can set a delay between each packet, depending on the network performance of the target, packets will drop if you run this too quickly. This is measured in microseconds.\n";
	print "\t-h: Limiting rules to only coming from \$HOME_NET; when using 8ball to target external source to trigger internal IDS";
	print "\t-e: Limiting rules to only coming from \$EXTERNAL_NET; when using 8ball to target IDS from the outside";
	print "\t-l: Long/DoS strings, less alerts / more resource usage for IDS\n";
	print "\t-s: Silent Mode; don't print all that colorful stuff onscreen\n";
	print "EXAMPLES\n";
	print "\t8ball.pl -t 192.168.0.42 -r rules.download -d 10000\n";
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
