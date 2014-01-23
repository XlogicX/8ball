#!/usr/bin/perl
use warnings;
use strict;
use IO::Socket;
use Time::HiRes qw(usleep nanosleep);

my $payload;
my $content;
my $ascii;

my $subexp;
my @payload_data;
my @payload_peices;
my $peice;
my $payloads;
my $peices;


open IN, 'rules.download' or die "The file has to actually exist, try again $!\n";	#input filehandle is IN


#This loop catalogues all content/pcre pecies for each rule into the @payload 2 diminsional array [rule][content/pcre part]
while (<IN>) {
	print "line $.\n";
	my $line = $_;
	print "$line\n";
	$peice = 0;	
	while (($line =~ /;\s*?((content|pcre|uricontent):\s?".+?";.+?)(content|pcre|uricontent).+\)$/) || ($line =~ /;\s*?((content|pcre|uricontent):\s?".+?".+)\)$/) ) {
		#$1 will capture first content:""; and all options after it (up to the next content or pcre)
		$subexp = $1;
		$payload_data[$.][$peice] = $subexp;
		$line =~ s/\Q$subexp\E//;
		$peice++;
	}
}

$payloads = @payload_data;	#get number of rules

#iterate through all pcre/content peices
my $i = 0;											#init the iterators
my $j = 0;											#init the iterators
while ($i < $payloads) {						#while we still have payloads
	$j = 0;
	while ($payload_data[$i][$j]) {				#while there are still content/pcre/uridata elements
		#if the element has an offset modifier, parse and capture it's value
		if (($payload_data[$i][$j]) && ($payload_data[$i][$j] =~ /;\s+offset:\s+(\d+)[^;]*?;/)) {
			$payload_peices[$i][$j][0] = $1;
		}
		#if the element has a distance modifier, parse and capture it's value
		if (($payload_data[$i][$j]) && ($payload_data[$i][$j] =~ /;\s+distance:\s+(\d+)[^;]*?;/)) {
			$payload_peices[$i][$j][1] = $1;
		}
		$j++;
	}
	$i++;
}

print "payload 115[1]: $payload_data[115][1]\n";
print "payload 115[1]'s distance: $payload_peices[115][1][1]\n";

=put

@payload_data datastructure:
$payload_data[rule][content or pcre part]

@payload_peices datastructure:
$peices[rule][content or pcre part][modifier]
	[0] = offset value
	[1] = distance value

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
		uri_len: Lenght of uri, padding may need to be used on these
		isdataat: another area that may need padding
		base64_data: only found one rule in ET that uses this, but may still try implementing

	Non-Content modifiers to use:
		http_encode

=cut
