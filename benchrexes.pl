#Regular Expression Benchmarker; both NFA (time) and DFA (memory) metrics
use warnings;
use strict;
use Try::Tiny;								#D #to capture runwaway garbage
use IO::CaptureOutput qw(capture qxx qxy);	#D #to catch error info that I actally use
use Getopt::Long;							#looooong arguments
use Time::HiRes;							#used for benchmarking NFA's
use Time::Out;								#D #but don't let it get too out of hand

#DFA related vars
my $filename = $ARGV[0];					#Filename is meant to be the first argument
my $regex;									#Expressions find themselves here
my $simple_string;							#non-evil string to match regex
my @rexes;									#A big group of them find themselves here
my $string = 'doesnt_matter';				#used for testing DFA expressions, string/expression pair NA
my $stdout;									#Used to harvest errors when starving DFA (RE2)...
my $stderr;									#engine of resources
my %hashed_rexes;			#Declare hash
my %hashed_rexes2;			#Declare hash
#NFA related vars
my $debug = 0;							#extra debugging info to stdout
my $csv;								#CSV argument
my $lexes = 0;							#debug info specific to 'bad' stringification process
my $strings = 0;
my $help;			
my $orig_exp;
my $ll;									#last lexeme
my $expression;
my $start;								#For timing
my $end;								#time of REDoS string
my $end2;								#time of normal efficient string
my $delta;								#difference between the above two
my $timeout_val = 25;					#Defualt timeout value in seconds
my $qlimit = 50;
#Some Metacharacter tokens...it's a weird hack, works great, I don't want to talk about it.
my $openparentoken = 'Ksc8pdCnhh';
my $closeparentoken = '2KzsuZTSrw';
my $opensquaretoken = 'pQwCCbYXqB';
my $closesquaretoken = 'UFa1N8tdjS';
my $openbracetoken = 'yVvs4ukduq';
my $closebracetoken = 'PvnD1hEwty';
my $alternativetoken = 'IAnelK5Zgr';

#Get arguments from user
GetOptions('debug' => \$debug,
		'csv=s' => \$csv,
		'lexes' => \$lexes,
		'timeout=s' => \$timeout_val,
		'qlimit=s' => \$qlimit,
		'strings' => \$strings,
		'help' => \$help);

if ($help) {
	help();
}

if ($strings eq 0) {
	#Lets get the expression file open and dump them into an array
	open FILE, "$filename" or die "$filename, $!\n";
	while (<FILE>) {
		my $regex = $_;
		$regex =~ s/\n$//;
		@rexes = (@rexes, $regex);
	}
	close FILE;

	#Now I want two hashes where the expression is the key, and memory use is the value
	#One is Memory level it failed at, and the other is reported memory use. I'm not sure
	#which is better or more accurate, so I grab both.
	$hashed_rexes{$_} = '' for @rexes;	#Populate hash
	$hashed_rexes2{$_} = '' for @rexes;	#Populate hash

	#This needs to be checked for all 26 memory allocations, below is the
	#long (readable version), the rest are visually compacted but logically
	#equivilant. I would use a loop here, but changing the pragma of the
	#module at runtime was giving me issues; so loop flattening.

	foreach (@rexes) {
		$regex = $_;
		$hashed_rexes{$regex} = 0;		#init all of these to 0
	}

	use re::engine::RE2 -max_mem => 8<<26, -strict => 1;
	foreach (@rexes) {
		$regex = $_;
		capture{
		try {
			if ($string =~ $regex) {}
			$hashed_rexes{$regex} = 8<<26;
		} catch {
			warn "$_";
		}};
	}

	use re::engine::RE2 -max_mem =>8<<25, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<25;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<24, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<24;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<23, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<23;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<22, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<22;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<21, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<21;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<20, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<20;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<19, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<19;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<18, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<18;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<17, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<17;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<16, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<16;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<15, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<15;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<14, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<14;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<13, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<13;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<12, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<12;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<11, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<11;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<10, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<10;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<9, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<9;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<8, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<8;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<7, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<7;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<6, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<6;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<5, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<5;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<4, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<4;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<3, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<3;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<2, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<2;} catch {warn "$_";}};
	}

	use re::engine::RE2 -max_mem =>8<<1, -strict => 1;	
	foreach (@rexes) { $regex = $_;
		capture { try { if ($string =~ $regex) {} $hashed_rexes{$regex} = 8<<1;} catch {warn "$_";}};
	}

	#Sort our hash descending
	my @sorted_rexes = sort { $hashed_rexes{$b} <=> $hashed_rexes{$a} } keys %hashed_rexes;

	if (!(defined $csv)) {
		print "\n\nMax_Mem Failure Level:\n===============================\nRegex\t\tMemory\n";
		foreach my $memory_req (@sorted_rexes) {	#For all elements in hash
		  	print "$memory_req \t\t $hashed_rexes{$memory_req}\n";
		}
	}


	foreach (@rexes) {
		$regex = $_;
		$hashed_rexes2{$regex} = 0;		#init all of these to 0
	}

	use re::engine::RE2 -max_mem =>8<<7, -strict => 1;		#Start with little memory
	foreach (@rexes) {										#try each expression
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		capture { if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;					#capture the error if it wasn't enough
		}}
	}

	use re::engine::RE2 -max_mem =>8<<8, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		capture { if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}}
	}

	use re::engine::RE2 -max_mem =>8<<9, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		capture { if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}}
	}

	use re::engine::RE2 -max_mem =>8<<10, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		capture { if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}}
	}

	use re::engine::RE2 -max_mem =>8<<11, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		capture { if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}}
	}

	use re::engine::RE2 -max_mem =>8<<12, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}
	}

	use re::engine::RE2 -max_mem =>8<<13, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}
	}

	use re::engine::RE2 -max_mem =>8<<14, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}
	}

	use re::engine::RE2 -max_mem =>8<<15, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}
	}

	use re::engine::RE2 -max_mem =>8<<16, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}
	}

	use re::engine::RE2 -max_mem =>8<<17, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}
	}

	use re::engine::RE2 -max_mem =>8<<18, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}
	}

	use re::engine::RE2 -max_mem =>8<<19, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}
	}

	use re::engine::RE2 -max_mem =>8<<20, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}
	}

	use re::engine::RE2 -max_mem =>8<<21, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}
	}

	use re::engine::RE2 -max_mem =>8<<22, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}
	}

	use re::engine::RE2 -max_mem =>8<<23, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}
	}

	use re::engine::RE2 -max_mem =>8<<24, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}
	}

	use re::engine::RE2 -max_mem =>8<<25, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}
	}

	use re::engine::RE2 -max_mem =>8<<26, -strict => 1;	
	foreach (@rexes) {
		$regex = $_;
		capture {
		try {
			if ($string =~ $regex) {}
		} catch {
			warn "$_";
		};} \$stdout, \$stderr;
		if ($stderr =~ /mem\s(.+)/) {
			$hashed_rexes2{$regex} = $1;
		}
	}

	#Sort our hash descending
	@sorted_rexes = sort { $hashed_rexes2{$b} <=> $hashed_rexes2{$a} } keys %hashed_rexes2;

	if (!(defined $csv)) {
		print "\n\nMemory Requirement for Each Regex:\n===============================\nRegex\t\tMemory\n";
		foreach my $memory_req (@sorted_rexes) {	#For all elements in hash
		  	print "$memory_req \t\t $hashed_rexes2{$memory_req}\n";
		}
	}

	no re::engine::RE2;			#No we go into default perl NFA RE land and exit RE2
}

sub lastlexeme ($) {
	$ll = '';
	$expression = shift;
	chomp($expression);
	$expression =~ s/\$$//;		#remove the anchor for hax reasons

	start:

	print "lastlexeme iteration: $expression\n" if $debug;

	if ($expression =~ /[?+*}]\?$/) { 		#If the expression ends in laziness
		$ll = 'x';							#just fucking give up and set it to 'x'
		next;
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

open IN, "$filename" or die "The file has to actually exist, try again $!\n";	#input filehandle is IN
my @expressions = <IN>;
close IN;

open OUT, ">$csv" if $csv;
print OUT "expression	DoS_time	time	Delta	Mem_fail	Mem_use\n" if $csv;
my $line = 0;
foreach (@expressions) {
	$line++;
	chomp($_);									#remove newlines trailing expression
	my $endanchor = 'no';
	if ($_ =~ /\$$/) {							#if this is an end anchored expression
		$endanchor = 'yes';						#make note
	}
	$orig_exp = $_;
	print "Original Expression: $_\n" if ($lexes or $strings);
	my $last_l = lastlexeme($_);				#get last lexeme
	print "Last Lexeme: $last_l\n" if $lexes;
	my $neg_l = negatelex(lastlexeme($_));		#get minimal negation of it
	print "Negated Last Lexeme: $neg_l\n" if $lexes;	
	$regex = $string = $_;						#get our expression

	if ($endanchor eq 'yes') {
		my $last_l_norm = pcre($last_l);
		print "Matching Bastard String: $last_l_norm\n" if $lexes;	
		$neg_l = $last_l_norm . $neg_l;
	}

	$regex =~ s/\Q$last_l\E.*$/$neg_l/;			#sub last lexeme with literal bad/negation part
	print "Unmatching Bastard Expression: $regex\n" if $lexes;

	$regex = pcre($regex);		#pass through again
	print "DoS String: $regex\n" if ($lexes or $strings);
	
	if ($strings eq 0) {
		#Validate timing for REDoS
		$start = Time::HiRes::time();
		Time::Out::timeout $timeout_val => sub {
		capture {
			try {
				if ($regex =~ $orig_exp) {
					#it shouldn't...lulz
				} else {
					$end = Time::HiRes::time() - $start;
					print "failed to match in $end time\n" if $lexes;
				}
			} catch {
				print "Something went wrong with this pattern, most likely timed out, which is the best wrong!\n" if $lexes;
				$end = Time::HiRes::time() - $start;
			};} \$stdout, \$stderr;
			$end = 'Engine Failure' if $stderr;
		};
	}

	$simple_string = pcre_nonviolent($orig_exp);
	print "Simple string: $simple_string\n" if ($lexes or $strings);
	print "\n" if $strings;

	if ($strings eq 0) {
		#Validate timing for efficient match
		$start = Time::HiRes::time();
		Time::Out::timeout $timeout_val => sub {
		capture {
			try {
				if ($simple_string =~ $orig_exp) {
					$end2 = Time::HiRes::time() - $start;
				} else {
					$end2 = Time::HiRes::time() - $start;
					print "failed to match in $end time\n" if $lexes;
				}
			} catch {
				print "Something went wrong with this pattern, most likely timed out, which is the best wrong!\n" if $lexes;
				$end2 = Time::HiRes::time() - $start;
			};} \$stdout, \$stderr;
			$end2 = 'Engine Failure' if $stderr;
		};	
		$end = sprintf("%.10f", $end);
		$end2 = sprintf("%.10f", $end2);

		$delta = $end - $end2;
		$delta = sprintf("%.10f", $delta);
	}

	print OUT "$orig_exp	$end	$end2	$delta	$hashed_rexes{$orig_exp}	$hashed_rexes2{$orig_exp}\n" if $csv;
	print "\n-----------------\n" if $lexes;
}
close OUT if $csv;

sub pcre {
	#Tokenize some metacharacters
	my $pcre = shift;
	$pcre =~ s/\\\(/$openparentoken/g; print "\nAfter ( tokenizing:\t\t$pcre\n" if $debug;
	$pcre =~ s/\\x28/$openparentoken/g; print "After ( tokenizing:\t\t$pcre\n" if $debug;	
	$pcre =~ s/\\\)/$closeparentoken/g; print "After ) tokenizing:\t\t$pcre\n" if $debug;
	$pcre =~ s/\\x29/$closeparentoken/g; print "After ) tokenizing:\t\t$pcre\n" if $debug;			
	$pcre =~ s/\\\[/$opensquaretoken/g; print "After [ tokenizing:\t\t$pcre\n" if $debug;
	$pcre =~ s/\\x5b/$opensquaretoken/gi; print "After [ tokenizing:\t\t$pcre\n" if $debug;	
	$pcre =~ s/\\\]/$closesquaretoken/g; print "After ] tokenizing:\t\t$pcre\n" if $debug;
	$pcre =~ s/\\x5d/$closesquaretoken/gi; print "After ] tokenizing:\t\t$pcre\n" if $debug;	
	$pcre =~ s/\\\{/$openbracetoken/g; print "After { tokenizing:\t\t$pcre\n" if $debug;
	$pcre =~ s/\\x7b/$openbracetoken/gi; print "After { tokenizing:\t\t$pcre\n" if $debug;	
	$pcre =~ s/\\\}/$closebracetoken/g; print "After } tokenizing:\t\t$pcre\n" if $debug;
	$pcre =~ s/\\x7d/$closebracetoken/gi; print "After } tokenizing:\t\t$pcre\n" if $debug;	
	$pcre =~ s/\\\|/$alternativetoken/g; print "After | tokenizing:\t\t$pcre\n" if $debug;
	$pcre =~ s/\\x7c/$alternativetoken/gi; print "After | tokenizing:\t\t$pcre\n" if $debug;	

	#Handle {\d,} situation
	$pcre =~ s/(\{\d+),(\})/$1,100$2/g;

	#We don't care about non-capturing groups
	$pcre =~ s/\(\?:/(/g; print "After removing non-capture groups:\t\t$pcre\n" if $debug;

	#Experimental Lookarounds:
	$pcre =~ s/\(\?=/(/g; print "After lookaheads:\t\t$pcre\n" if $debug;	
	$pcre =~ s/\(\?!.+?\)/(a)/g; print "After ~lookaheads:\t\t$pcre\n" if $debug;	
	$pcre =~ s/\(\?<=/(/g; print "After lookbehinds:\t\t$pcre\n" if $debug;	
	$pcre =~ s/\(\?<!.+?\)/(a)/g; print "After ~lookaheads:\t\t$pcre\n" if $debug;						

	#Handle Anchors (drop them, as they match anyway as a side effect)
	$pcre =~ s/^\^//; print "\nAfter ^:\t\t$pcre\n" if $debug;
	$pcre =~ s/\$$//; print "After \$:\t\t$pcre\n" if $debug;

	#Character Classes (Needs some Expansion)
	$pcre =~ s/\\s/ /g; print "After spaces:\t\t$pcre\n" if $debug;		#Handle regex whitespace (replace with 1 space
	$pcre =~ s/\\w/a/g; print "After \\w:\t\t$pcre\n" if $debug;		#handle regex alphanumeric (replace with an "a")
	$pcre =~ s/\\d/1/g; print "After \\d:\t\t$pcre\n" if $debug;		#handle regex digits (replace with a 1)
	$pcre =~ s/\\S/a/g; print "After nonspaces:\t\t$pcre\n" if $debug;		#Handle regex non-whitespace (replace with 1 "a"
	$pcre =~ s/\\W/ /g; print "After \\W:\t\t$pcre\n" if $debug;		#handle regex non-alphanumeric (replace with an space)
	$pcre =~ s/\\D/a/g; print "After \\D:\t\t$pcre\n" if $debug;		#handle regex non-digits (replace with 1 "a")

	$pcre =~ s/([^\}\\])\./$1a/g; print "After .:\t\t$pcre\n" if $debug;	#replace "." with "a" if not preceded by \ or }

	#Kill lazyness
	#If we get *? or +?, drop the ?
	$pcre =~ s/\*\?/*/g; print "After *?:\t\t$pcre\n" if $debug;
	$pcre =~ s/\+\?/+/g; print "After +?:\t\t$pcre\n" if $debug;
	$pcre =~ s/\?\?/+/g; print "After ??:\t\t$pcre\n" if $debug;	

	my $replacement = '';
	#Quantifiers (Done)
	#below is the non-evil version of the + modifier
	#$pcre =~ s/([^\\])\+/$1/g; print "After +:\t\t$pcre\n" if $debug;		#handle 1 or more (remove the +, thing preceding it stays, wich is equivilant to 1)
	while ($pcre =~ /([^\\+])\+(?<!\+)/) {		#Is there still an unescaped + quantifier with no surrounding +'s
		$replacement = "$1" x 50;				#If so, take what we are quantifying up to 50
		$pcre =~ s/([^\\])\+/$replacement/;		#replace that ONE instance with the 50x version (non global; becuase the replacement changes per iteration)
		print "After +:\t\t$pcre\n" if $debug;
	}
	#below is the non-evil version of the * modifier
	#$pcre =~ s/([^\\])\*/$1/g; print "After *:\t\t$pcre\n" if $debug;		#handle 0, 1, or more (remove the *, thing preceding it stays, wich is equivilant to 1)
	while ($pcre =~ /([^\\])\*/) {				#Is there still a + quantifier
		$replacement = "$1" x 50;				#If so, take what we are quantifying up to 50
		$pcre =~ s/([^\\])\*/$replacement/;		#replace that ONE instance with the 50x version (non global; becuase the replacement changes per iteration)
	}
	print "After *:\t\t$pcre\n" if $debug;
	$pcre =~ s/([^\\])\?/$1/g; print "After ?:\t\t$pcre\n" if $debug;		#handle 0 or 1 (remove the ?, thing preceding it stays, wich is equivilant to 1)

	#Literals (Needs some Expansion
	$pcre =~ s/\\\././g; print "After .:\t\t$pcre\n" if $debug;		#handle literal periods (replace with \. with .)
	$pcre =~ s/\\\//\//g; print "After /:\t\t$pcre\n" if $debug;		#handle literal forward slashes (replace with \/ with /)
	$pcre =~ s/\\\?/\?/g; print "After ?:\t\t$pcre\n" if $debug;		#handle literal ?'s (replace with \? with ?)
	$pcre =~ s/\\\-/\-/g; print "After -:\t\t$pcre\n" if $debug;		#handle literal -'s
	$pcre =~ s/\\\\/\\/g; print "After \\:\t\t$pcre\n" if $debug;		#handle literal \'s		
	$pcre =~ s/\\\]/\]/g; print "After ]:\t\t$pcre\n" if $debug;		#handle literal ]'s	
	$pcre =~ s/\\\[/\[/g; print "After ]:\t\t$pcre\n" if $debug;		#handle literal ['s		
	$pcre =~ s/\\\(/\(/g; print "After (:\t\t$pcre\n" if $debug;		#handle literal ('s
	$pcre =~ s/\\\)/\)/g; print "After ):\t\t$pcre\n" if $debug;		#handle literal )'s
	$pcre =~ s/\\\*/\*/g; print "After *:\t\t$pcre\n" if $debug;		#handle literal *'s
	$pcre =~ s/\\\|/\|/g; print "After |:\t\t$pcre\n" if $debug;		#handle literal |'s
	$pcre =~ s/\\\{/\{/g; print "After {:\t\t$pcre\n" if $debug;		#handle literal {'s
	$pcre =~ s/\\\}/\}/g; print "After {:\t\t$pcre\n" if $debug;		#handle literal }'s
	$pcre =~ s/\\\;/\;/g; print "After ;:\t\t$pcre\n" if $debug;		#handle literal ;'s
	$pcre =~ s/\\\%/\%/g; print "After %:\t\t$pcre\n" if $debug;		#handle literal %'s
	$pcre =~ s/\\\:/\:/g; print "After ::\t\t$pcre\n" if $debug;		#handle literal :'s
	$pcre =~ s/\\\&/\&/g; print "After &:\t\t$pcre\n" if $debug;		#handle literal &'s	
	$pcre =~ s/\\\=/\=/g; print "After =:\t\t$pcre\n" if $debug;		#handle literal ='s		
	$pcre =~ s/\\\ /\ /g; print "After sp:\t\t$pcre\n" if $debug;		#handle literal spaces's			
	$pcre =~ s/\\r/\x0d/g; print "After \\r:\t\t$pcre\n" if $debug;		#handle literal \r's
	$pcre =~ s/\\n/\x0a/g; print "After \\n:\t\t$pcre\n" if $debug;		#handle literal \n's
	$pcre =~ s/\\\$/\$/g; print "After \$:\t\t$pcre\n" if $debug;		#handle literal \$'s

	#handle hex encoding
	while ($pcre =~ /\\x([0-9a-f]{2})/i) {
	my $hex = pack("C*", map { $_ ? hex($_) :() } split(/\\x/, $1));
	$pcre =~ s/\\x([0-9a-f]{2})/$hex/i; print "After hex:\t\t$pcre\n" if $debug;
	}

	#handle character classes []'s, just take the first character for each []
	#In the case of a negated class [^abc], the "^" character gets picked as a 
	#side effect, which is still fine. [^^] is accounted for as well.
	while ($pcre =~ /\[(.)(.*?)\]/) {		#get [$1$2] where $1 is only one char and $2 is whats left
		my $class = $1;
		my $extra = $2;
		if (($class eq '^') && ($extra) && (($extra =~ /\^/) || ($extra =~ /^\\/))) {
			$pcre =~ s/\[(.).*?\]/a/; print "After []'s:\t\t$pcre\n" if $debug;	#handles a special negated class of [^^]
		} else {
			if ($class eq '\\') {									#if it starts with a \
				#if extra starts with [, then replace [$1$2] with [
					#So [\[] is converted to just a [ (and etc... for the rest of these)
				print "class is: $class - extra is $extra\n" if $debug;
				$pcre =~ s/\[(.).*?\[/\[/ if ($extra =~ /^\[/); print "After [[:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\]/ if ($extra =~ /^\]/); print "After []:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\x0d/ if ($extra =~ /^r/i); print "After [\\r:\t\t$pcre\n" if $debug;		
				$pcre =~ s/\[(.).*?\]/\x0a/ if ($extra =~ /^n/i); print "After [\\n:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/x/ if ($extra =~ /^s/i);	print "After [x:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\:/ if ($extra =~ /^:/); print "After [::\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\(/ if ($extra =~ /^\(/); print "After [(:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\)/ if ($extra =~ /^\)/); print "After [):\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\;/ if ($extra =~ /^\;/); print "After [;:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\*/ if ($extra =~ /^\*/); print "After [*:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\\/ if ($extra =~ /^\\/); print "After [\\:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\\/ if ($extra =~ /^\//); print "After [\\:\t\t$pcre\n" if $debug;				
				$pcre =~ s/\[(.).*?\]/\\/ if ($extra eq ''); print "After [null:\t\t$pcre\n" if $debug;				
				$pcre =~ s/\[(.).*?\]/\|/ if ($extra =~ /^\|/); print "After [|:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\{/ if ($extra =~ /^\{/); print "After [{:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\}/ if ($extra =~ /^\}/); print "After [}:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\%/ if ($extra =~ /^\%/); print "After [%:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\$/ if ($extra =~ /^\$/); print "After [\$:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\+/ if ($extra =~ '^\+'); print "After [+:\t\t$pcre\n" if $debug;	
				$pcre =~ s/\[(.).*?\]/\&/ if ($extra =~ '^\&'); print "After [&:\t\t$pcre\n" if $debug;		
				$pcre =~ s/\[(.).*?\]/\=/ if ($extra =~ '^\='); print "After [=:\t\t$pcre\n" if $debug;	
				$pcre =~ s/\[(.).*?\]/\!/ if ($extra =~ '^\!'); print "After [!:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\@/ if ($extra =~ '^\@'); print "After [\@:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\^/ if ($extra =~ '^^'); print "After [^:\t\t$pcre\n" if $debug;														
				$pcre =~ s/\[(.).*?\]/\ / if ($extra =~ '^\ '); print "After [sp:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\t/ if ($extra =~ '^t'); print "After [\\t:\t\t$pcre\n" if $debug;				
				#gracefully handle unicode, results are a failure, but prevents infinite loop
				$pcre =~ s/\[(.).*?\]/\u/ if ($extra =~ '^u'); print "After [\\u:\t\t$pcre\n" if $debug;														
			} else {
				$pcre =~ s/\[(.).*?\]/$class/; print "After [^:\t\t$pcre\n" if $debug;
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
				$pcre =~ s/\{(\d).*?\}//s; print "After {}'s:\t\t$pcre\n" if $debug;
			} else { 
				$pcre =~ s/.\{(\d).*?\}/$char/s; print "After {}'s:\t\t$pcre\n" if $debug;
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
			$pcre =~ s/(\(.+?\))\{(\d).*?\}/$char/s; print "After 2{}'s:\t\t$pcre\n" if $debug;
		}
	}

	#handle grouping ()'s, take the last alternation in ()'s
	while ($pcre =~ /\(([^)]+?)\|.+?\)/s){		#while we still have a group

		#Do something with it
		#$pcre =~ s/\((.+?)\|.+?\)/$1/; 		#this replaces with first option
		$pcre =~ s/\(.+?\|([^|]*?)\)/$1/s;			#this replaces with last option


		print "After R()'s:\t\t$pcre\n" if $debug;		#debugging line
	}

	#remove gratuitus parenthesis
	$pcre =~ s/\(|\)//g; print "After ()()()'s:\t\t$pcre\n" if $debug;

	#Reintroduce tokenized metacharacters as literal
	$pcre =~ s/$openparentoken/(/g; print "\nAfter ( add:\t\t$pcre\n" if $debug;
	$pcre =~ s/$closeparentoken/)/g; print "\nAfter ) add:\t\t$pcre\n" if $debug;
	$pcre =~ s/$opensquaretoken/[/g; print "\nAfter [ add:\t\t$pcre\n" if $debug;
	$pcre =~ s/$closesquaretoken/]/g; print "\nAfter ] add:\t\t$pcre\n" if $debug;
	$pcre =~ s/$openbracetoken/{/g; print "\nAfter { add:\t\t$pcre\n" if $debug;
	$pcre =~ s/$closebracetoken/}/g; print "\nAfter } add:\t\t$pcre\n" if $debug;	
	$pcre =~ s/$alternativetoken/|/g; print "\nAfter | add:\t\t$pcre\n" if $debug;	

	return $pcre;					
}

sub pcre_nonviolent {
	#Tokenize some metacharacters
	my $pcre = shift;
	$pcre =~ s/\\\(/$openparentoken/g; print "\nAfter ( tokenizing:\t\t$pcre\n" if $debug;
	$pcre =~ s/\\x28/$openparentoken/g; print "After ( tokenizing:\t\t$pcre\n" if $debug;	
	$pcre =~ s/\\\)/$closeparentoken/g; print "After ) tokenizing:\t\t$pcre\n" if $debug;
	$pcre =~ s/\\x29/$closeparentoken/g; print "After ) tokenizing:\t\t$pcre\n" if $debug;			
	$pcre =~ s/\\\[/$opensquaretoken/g; print "After [ tokenizing:\t\t$pcre\n" if $debug;
	$pcre =~ s/\\x5b/$opensquaretoken/gi; print "After [ tokenizing:\t\t$pcre\n" if $debug;	
	$pcre =~ s/\\\]/$closesquaretoken/g; print "After ] tokenizing:\t\t$pcre\n" if $debug;
	$pcre =~ s/\\x5d/$closesquaretoken/gi; print "After ] tokenizing:\t\t$pcre\n" if $debug;	
	$pcre =~ s/\\\{/$openbracetoken/g; print "After { tokenizing:\t\t$pcre\n" if $debug;
	$pcre =~ s/\\x7b/$openbracetoken/gi; print "After { tokenizing:\t\t$pcre\n" if $debug;	
	$pcre =~ s/\\\}/$closebracetoken/g; print "After } tokenizing:\t\t$pcre\n" if $debug;
	$pcre =~ s/\\x7d/$closebracetoken/gi; print "After } tokenizing:\t\t$pcre\n" if $debug;	
	$pcre =~ s/\\\|/$alternativetoken/g; print "After | tokenizing:\t\t$pcre\n" if $debug;
	$pcre =~ s/\\x7c/$alternativetoken/gi; print "After | tokenizing:\t\t$pcre\n" if $debug;	

	#Handle {\d,} situation
	$pcre =~ s/(\{\d+),(\})/$1,2$2/g;

	#We don't care about non-capturing groups
	$pcre =~ s/\(\?:/(/g; print "After removing non-capture groups:\t\t$pcre\n" if $debug;

	#Experimental Lookarounds:
	$pcre =~ s/\(\?=/(/g; print "After lookaheads:\t\t$pcre\n" if $debug;	
	$pcre =~ s/\(\?!.+?\)/(a)/g; print "After ~lookaheads:\t\t$pcre\n" if $debug;	
	$pcre =~ s/\(\?<=/(/g; print "After lookbehinds:\t\t$pcre\n" if $debug;	
	$pcre =~ s/\(\?<!.+?\)/(a)/g; print "After ~lookaheads:\t\t$pcre\n" if $debug;						

	#Handle Anchors (drop them, as they match anyway as a side effect)
	$pcre =~ s/^\^//; print "\nAfter ^:\t\t$pcre\n" if $debug;
	$pcre =~ s/\$$//; print "After \$:\t\t$pcre\n" if $debug;

	#Character Classes (Needs some Expansion)
	$pcre =~ s/\\s/ /g; print "After spaces:\t\t$pcre\n" if $debug;		#Handle regex whitespace (replace with 1 space
	$pcre =~ s/\\w/a/g; print "After \\w:\t\t$pcre\n" if $debug;		#handle regex alphanumeric (replace with an "a")
	$pcre =~ s/\\d/1/g; print "After \\d:\t\t$pcre\n" if $debug;		#handle regex digits (replace with a 1)
	$pcre =~ s/\\S/a/g; print "After nonspaces:\t\t$pcre\n" if $debug;		#Handle regex non-whitespace (replace with 1 "a"
	$pcre =~ s/\\W/ /g; print "After \\W:\t\t$pcre\n" if $debug;		#handle regex non-alphanumeric (replace with an space)
	$pcre =~ s/\\D/a/g; print "After \\D:\t\t$pcre\n" if $debug;		#handle regex non-digits (replace with 1 "a")

	$pcre =~ s/([^\}\\])\./$1a/g; print "After .:\t\t$pcre\n" if $debug;	#replace "." with "a" if not preceded by \ or }

	#Kill lazyness
	#If we get *? or +?, drop the ?
	$pcre =~ s/\*\?/*/g; print "After *?:\t\t$pcre\n" if $debug;
	$pcre =~ s/\+\?/+/g; print "After +?:\t\t$pcre\n" if $debug;
	$pcre =~ s/\?\?/+/g; print "After ??:\t\t$pcre\n" if $debug;	

	my $replacement = '';
	#Quantifiers (Done)
	$pcre =~ s/([^\\])\+/$1/g; print "After +:\t\t$pcre\n" if $debug;		#handle 1 or more (remove the +, thing preceding it stays, wich is equivilant to 1)
	$pcre =~ s/([^\\])\*/$1/g; print "After *:\t\t$pcre\n" if $debug;		#handle 0, 1, or more (remove the *, thing preceding it stays, wich is equivilant to 1)
	$pcre =~ s/([^\\])\?/$1/g; print "After ?:\t\t$pcre\n" if $debug;		#handle 0 or 1 (remove the ?, thing preceding it stays, wich is equivilant to 1)

	#Literals (Needs some Expansion
	$pcre =~ s/\\\././g; print "After .:\t\t$pcre\n" if $debug;		#handle literal periods (replace with \. with .)
	$pcre =~ s/\\\//\//g; print "After /:\t\t$pcre\n" if $debug;		#handle literal forward slashes (replace with \/ with /)
	$pcre =~ s/\\\?/\?/g; print "After ?:\t\t$pcre\n" if $debug;		#handle literal ?'s (replace with \? with ?)
	$pcre =~ s/\\\-/\-/g; print "After -:\t\t$pcre\n" if $debug;		#handle literal -'s
	$pcre =~ s/\\\\/\\/g; print "After \\:\t\t$pcre\n" if $debug;		#handle literal \'s		
	$pcre =~ s/\\\]/\]/g; print "After ]:\t\t$pcre\n" if $debug;		#handle literal ]'s	
	$pcre =~ s/\\\[/\[/g; print "After ]:\t\t$pcre\n" if $debug;		#handle literal ['s		
	$pcre =~ s/\\\(/\(/g; print "After (:\t\t$pcre\n" if $debug;		#handle literal ('s
	$pcre =~ s/\\\)/\)/g; print "After ):\t\t$pcre\n" if $debug;		#handle literal )'s
	$pcre =~ s/\\\*/\*/g; print "After *:\t\t$pcre\n" if $debug;		#handle literal *'s
	$pcre =~ s/\\\|/\|/g; print "After |:\t\t$pcre\n" if $debug;		#handle literal |'s
	$pcre =~ s/\\\{/\{/g; print "After {:\t\t$pcre\n" if $debug;		#handle literal {'s
	$pcre =~ s/\\\}/\}/g; print "After {:\t\t$pcre\n" if $debug;		#handle literal }'s
	$pcre =~ s/\\\;/\;/g; print "After ;:\t\t$pcre\n" if $debug;		#handle literal ;'s
	$pcre =~ s/\\\%/\%/g; print "After %:\t\t$pcre\n" if $debug;		#handle literal %'s
	$pcre =~ s/\\\:/\:/g; print "After ::\t\t$pcre\n" if $debug;		#handle literal :'s
	$pcre =~ s/\\\&/\&/g; print "After &:\t\t$pcre\n" if $debug;		#handle literal &'s	
	$pcre =~ s/\\\=/\=/g; print "After =:\t\t$pcre\n" if $debug;		#handle literal ='s		
	$pcre =~ s/\\\ /\ /g; print "After sp:\t\t$pcre\n" if $debug;		#handle literal spaces's			
	$pcre =~ s/\\r/\x0d/g; print "After \\r:\t\t$pcre\n" if $debug;		#handle literal \r's
	$pcre =~ s/\\n/\x0a/g; print "After \\n:\t\t$pcre\n" if $debug;		#handle literal \n's
	$pcre =~ s/\\\$/\$/g; print "After \$:\t\t$pcre\n" if $debug;		#handle literal \$'s

	#handle hex encoding
	while ($pcre =~ /\\x([0-9a-f]{2})/i) {
	my $hex = pack("C*", map { $_ ? hex($_) :() } split(/\\x/, $1));
	$pcre =~ s/\\x([0-9a-f]{2})/$hex/i; print "After hex:\t\t$pcre\n" if $debug;
	}

	#handle character classes []'s, just take the first character for each []
	#In the case of a negated class [^abc], the "^" character gets picked as a 
	#side effect, which is still fine. [^^] is accounted for as well.
	while ($pcre =~ /\[(.)(.*?)\]/) {		#get [$1$2] where $1 is only one char and $2 is whats left
		my $class = $1;
		my $extra = $2;
		if (($class eq '^') && ($extra) && (($extra =~ /\^/) || ($extra =~ /^\\/))) {
			$pcre =~ s/\[(.).*?\]/a/; print "After []'s:\t\t$pcre\n" if $debug;	#handles a special negated class of [^^]
		} else {
			if ($class eq '\\') {									#if it starts with a \
				#if extra starts with [, then replace [$1$2] with [
					#So [\[] is converted to just a [ (and etc... for the rest of these)
				print "class is: $class - extra is $extra\n" if $debug;
				$pcre =~ s/\[(.).*?\[/\[/ if ($extra =~ /^\[/); print "After [[:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\]/ if ($extra =~ /^\]/); print "After []:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\x0d/ if ($extra =~ /^r/i); print "After [\\r:\t\t$pcre\n" if $debug;		
				$pcre =~ s/\[(.).*?\]/\x0a/ if ($extra =~ /^n/i); print "After [\\n:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/x/ if ($extra =~ /^s/i);	print "After [x:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\:/ if ($extra =~ /^:/); print "After [::\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\(/ if ($extra =~ /^\(/); print "After [(:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\)/ if ($extra =~ /^\)/); print "After [):\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\;/ if ($extra =~ /^\;/); print "After [;:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\*/ if ($extra =~ /^\*/); print "After [*:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\\/ if ($extra =~ /^\\/); print "After [\\:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\\/ if ($extra =~ /^\//); print "After [\\:\t\t$pcre\n" if $debug;				
				$pcre =~ s/\[(.).*?\]/\\/ if ($extra eq ''); print "After [null:\t\t$pcre\n" if $debug;				
				$pcre =~ s/\[(.).*?\]/\|/ if ($extra =~ /^\|/); print "After [|:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\{/ if ($extra =~ /^\{/); print "After [{:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\}/ if ($extra =~ /^\}/); print "After [}:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\%/ if ($extra =~ /^\%/); print "After [%:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\$/ if ($extra =~ /^\$/); print "After [\$:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\+/ if ($extra =~ '^\+'); print "After [+:\t\t$pcre\n" if $debug;	
				$pcre =~ s/\[(.).*?\]/\&/ if ($extra =~ '^\&'); print "After [&:\t\t$pcre\n" if $debug;		
				$pcre =~ s/\[(.).*?\]/\=/ if ($extra =~ '^\='); print "After [=:\t\t$pcre\n" if $debug;	
				$pcre =~ s/\[(.).*?\]/\!/ if ($extra =~ '^\!'); print "After [!:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\@/ if ($extra =~ '^\@'); print "After [\@:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\^/ if ($extra =~ '^^'); print "After [^:\t\t$pcre\n" if $debug;														
				$pcre =~ s/\[(.).*?\]/\ / if ($extra =~ '^\ '); print "After [sp:\t\t$pcre\n" if $debug;
				$pcre =~ s/\[(.).*?\]/\t/ if ($extra =~ '^t'); print "After [\\t:\t\t$pcre\n" if $debug;				
				#gracefully handle unicode, results are a failure, but prevents infinite loop
				$pcre =~ s/\[(.).*?\]/\u/ if ($extra =~ '^u'); print "After [\\u:\t\t$pcre\n" if $debug;														
			} else {
				$pcre =~ s/\[(.).*?\]/$class/; print "After [^:\t\t$pcre\n" if $debug;
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
		print "After ()'s:\t\t$pcre\n" if $debug;		#debugging line
	}

	#remove gratuitus parenthesis
	$pcre =~ s/\(|\)//g; print "After ()()()'s:\t\t$pcre\n" if $debug;

	#Reintroduce tokenized metacharacters as literal
	$pcre =~ s/$openparentoken/(/g; print "\nAfter ( add:\t\t$pcre\n" if $debug;
	$pcre =~ s/$closeparentoken/)/g; print "\nAfter ) add:\t\t$pcre\n" if $debug;
	$pcre =~ s/$opensquaretoken/[/g; print "\nAfter [ add:\t\t$pcre\n" if $debug;
	$pcre =~ s/$closesquaretoken/]/g; print "\nAfter ] add:\t\t$pcre\n" if $debug;
	$pcre =~ s/$openbracetoken/{/g; print "\nAfter { add:\t\t$pcre\n" if $debug;
	$pcre =~ s/$closebracetoken/}/g; print "\nAfter } add:\t\t$pcre\n" if $debug;	
	$pcre =~ s/$alternativetoken/|/g; print "\nAfter | add:\t\t$pcre\n" if $debug;	

	return $pcre;					
}

sub help {
	print "NAME\n";
	print "\tBenchRexes - A Regular Expression Benchmarking tool\n\n";
	print "SYNOPSIS\n";
	print "\tbenchrexes.pl regex.txt [options]\n\n";
	print "DESCRIPTION\n";
	print "\tThis script will analyze a list of regular expressions for performance; metrics are measured on time taken and memory usage\n\n";
	print "OPTIONS\n";
	print "\t--help: Prints this dialog\n";
	print "\t--timeout: How long to try an expression before giving up. Default is 25.\n";
	print "\t--csv: csv output of results\n";
	print "\t--qlimit: upper limit cap on regex quantifiers. Default is 50. Larger number == more agressive\n";
	print "\t--lexes: prints some behind the scenes on NFA RE:DoS expression-to-string creation (to sdtout)\n";
	print "\t--debug: prints DETAILED debugging info for the string creation engine\n";
	print "EXAMPLES\n";
	print "\tbenchrexes.pl emerging_pcres.txt --timeout 4 --csv output.csv\n";
	print "\tbenchrexes.pl bad_expressions.txt --timeout 50 --csv output.csv\n";
	print "\tbenchrexes.pl malformed_expressions.txt --lexes --debug\n";
	exit;
}
