#!/usr/bin/perl
use warnings;
use strict;
use IO::Socket;
use Time::HiRes qw(usleep nanosleep);

my $payload;
my $content;
my $ascii;

open IN, 'rules.download' or die "The file has to actually exist, try again $!\n";	#input filehandle is IN

while (<IN>) {
	print "line $.";
	my $line = $_;
	my $socket = IO::Socket::INET->new(
	PeerAddr => "172.22.111.207",
	PeerPort => '80',
	Proto        => 'tcp',
	) or next;
	#Handle Content Tags:
		#Gets quoted content and also converts |hex encoding|
	if ($line =~ /;.*?content:"(.+?)";/) {					#Find content:"something" preceded by ; and anything followed by ;, capture between ""'s
		print " - has content";
		$content = $1;
		while ($content =~ /\|(([0-9a-f]{2}\s*)+?)\|/i){		#while there is content with between |'s
			my $hex = $1;
			print "\nmatched hex = $hex";
			my $match = $hex;
			$ascii = '';
			$hex =~ s/\s//g;	#remove spaces
			while ($hex) {
				if ($hex =~ /(..)/) {
					$ascii .= pack("C*", map { $_ ? hex($_) :() } split(/\\x/, $1));
				}
				$hex =~ s/..//;
			}
			print "\ncontent before s/: $content";
			$content =~ s/\|$match\|/$ascii/;
			print "\ncontent after s/: $content";			
		}
	}
	print($socket "$content\n") if $content;
	print "\n$content \n\n";
	close $socket;
	usleep(100000);
	print "\n";
}


#5690
#1188
#6751
