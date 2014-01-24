#!/usr/bin/perl
use warnings;
use strict;
use IO::Socket;
use Time::HiRes qw(usleep nanosleep);

my $payload;
my $content;
my $ascii;
my @lines;			#each and every rule raw
my $count;			#general iterator

my $subexp;
my @payload_data;
my @payload_peices;
my @payload_metadata;
my $peice;
my $payloads;
my $peices;


open IN, 'rules.download' or die "The file has to actually exist, try again $!\n";	#input filehandle is IN
while (<IN>) {
	$lines[$.-1] = $_;
}
close IN;

#This loop catalogues all content/pcre pecies for each rule into the @payload 2 diminsional array [rule][content/pcre part]
$count = 0;
foreach (@lines) {
#	print "line $.\n";
	my $line = $_;
#	print "$line\n";
	$peice = 0;	
	while (($line =~ /;\s*?((content|pcre|uricontent):!?\s?".+?";.+?)(content|pcre|uricontent).+\)$/) || ($line =~ /;\s*?((content|pcre|uricontent):!?\s?".+?".+)\)$/) ) {
		#$1 will capture first content:""; and all options after it (up to the next content or pcre)
		$subexp = $1;
		$payload_data[$count][$peice] = $subexp;
		$line =~ s/\Q$subexp\E//;
		$peice++;
	}
	$count++;
}

#Get metadata/socket for each rule (which network/port to network/port), and other tidbits
$count = 0;
foreach (@lines) {
	my $line = $_;
	if ($line =~ /^#*?alert\s+([^\s]+?)\s+([^\s]+?)\s+([^\s]+?)\s+.+?>\s+([^\s]+?)\s+([^\s]+?)\s+/) {
		$payload_metadata[$count][0] = $1;
		$payload_metadata[$count][1] = $2;
		$payload_metadata[$count][2] = $3;
		$payload_metadata[$count][3] = $4;
		$payload_metadata[$count][4] = $5;		
	}
	$count++
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

print "payload 153[0]: $payload_data[153][0]\n";
print "payload 153[0]'s http_uri: $payload_peices[153][0][9]\n";
print "payload metadata\n";
print "\tprotocol: $payload_metadata[153][0]\n";
print "\tsource net: $payload_metadata[153][1]\n";
print "\tsource port: $payload_metadata[153][2]\n";
print "\tdest net: $payload_metadata[153][3]\n";
print "\tdest port: $payload_metadata[153][4]\n";

=put

@payload_data datastructure:
$payload_data[rule][content or pcre part]

@payload_peices datastructure:
$peices[rule][content or pcre part][modifier]
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
		uri_len: Probably easy, but wont implement for now due to lack of use in ET rules
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

	Non-Content modifiers to use:
		http_encode

=cut
