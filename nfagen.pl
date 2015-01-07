#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
use Try::Tiny;
use Pod::Usage;

my $regex;
my $string;
my $debug = 0;
my $csv = 0;
my $expressionfile;
my $cliinput;
my @expressions;
my $help = 0;
my $man = 0;
#Some Metacharacter tokens
my $openparentoken = 'Ksc8pdCnhh';
my $closeparentoken = '2KzsuZTSrw';
my $opensquaretoken = 'pQwCCbYXqB';
my $closesquaretoken = 'UFa1N8tdjS';
my $openbracetoken = 'yVvs4ukduq';
my $closebracetoken = 'PvnD1hEwty';
my $alternativetoken = 'IAnelK5Zgr';

GetOptions('debug' => \$debug,
		'csv' => \$csv,
		'file=s' => \$expressionfile,
		'in=s' => \$cliinput,
		'help|h' => \$help,
		'man|m' => \$man);

pod2usage(1) if ($help);
pod2usage(-verbose => 2) if ($man);

if ($expressionfile) {
	open IN, "$expressionfile" or die "The file has to actually exist, try again $!\n";	#input filehandle is IN
	@expressions = <IN>;
	close IN;
}
if ($cliinput) {
	@expressions = ("$cliinput");
}

print "expression	string	match?\n" if $csv;
foreach (@expressions) {
	chomp($_);
	print "$_	";
	$regex = $string = $_;
	pcre();
	print "$regex";
	if ($csv) {
		try {
			if ($regex =~ $string) {
				print "	match";
			} else {
				print "	no match";
		} catch {
			print "	not possible"
		}};
	}
	print "\n";
}

sub pcre {
	#Tokenize some metacharacters
	$regex =~ s/\\\(/$openparentoken/g; print "\nAfter ( tokenizing:\t\t$regex\n" if $debug;
	$regex =~ s/\\x28/$openparentoken/g; print "After ( tokenizing:\t\t$regex\n" if $debug;	
	$regex =~ s/\\\)/$closeparentoken/g; print "After ) tokenizing:\t\t$regex\n" if $debug;
	$regex =~ s/\\x29/$closeparentoken/g; print "After ) tokenizing:\t\t$regex\n" if $debug;			
	$regex =~ s/\\\[/$opensquaretoken/g; print "After [ tokenizing:\t\t$regex\n" if $debug;
	$regex =~ s/\\x5b/$opensquaretoken/gi; print "After [ tokenizing:\t\t$regex\n" if $debug;	
	$regex =~ s/\\\]/$closesquaretoken/g; print "After ] tokenizing:\t\t$regex\n" if $debug;
	$regex =~ s/\\x5d/$closesquaretoken/gi; print "After ] tokenizing:\t\t$regex\n" if $debug;	
	$regex =~ s/\\\{/$openbracetoken/g; print "After { tokenizing:\t\t$regex\n" if $debug;
	$regex =~ s/\\x7b/$openbracetoken/gi; print "After { tokenizing:\t\t$regex\n" if $debug;	
	$regex =~ s/\\\}/$closebracetoken/g; print "After } tokenizing:\t\t$regex\n" if $debug;
	$regex =~ s/\\x7d/$closebracetoken/gi; print "After } tokenizing:\t\t$regex\n" if $debug;	
	$regex =~ s/\\\|/$alternativetoken/g; print "After | tokenizing:\t\t$regex\n" if $debug;
	$regex =~ s/\\x7c/$alternativetoken/gi; print "After | tokenizing:\t\t$regex\n" if $debug;	

	#We don't care about non-capturing groups
	$regex =~ s/\(\?:/(/g; print "After removing non-capture groups:\t\t$regex\n" if $debug;

	#Experimental Lookarounds:
	$regex =~ s/\(\?=/(/g; print "After lookaheads:\t\t$regex\n" if $debug;	
	$regex =~ s/\(\?!.+?\)/(a)/g; print "After ~lookaheads:\t\t$regex\n" if $debug;	
	$regex =~ s/\(\?<=/(/g; print "After lookbehinds:\t\t$regex\n" if $debug;	
	$regex =~ s/\(\?<!.+?\)/(a)/g; print "After ~lookaheads:\t\t$regex\n" if $debug;						

	#Handle Anchors (drop them, as they match anyway as a side effect)
	$regex =~ s/^\^//; print "\nAfter ^:\t\t$regex\n" if $debug;
	$regex =~ s/\$$//; print "After \$:\t\t$regex\n" if $debug;

	#Character Classes (Needs some Expansion)
	$regex =~ s/\\s/ /g; print "After spaces:\t\t$regex\n" if $debug;		#Handle regex whitespace (replace with 1 space
	$regex =~ s/\\w/a/g; print "After \\w:\t\t$regex\n" if $debug;		#handle regex alphanumeric (replace with an "a")
	$regex =~ s/\\d/1/g; print "After \\d:\t\t$regex\n" if $debug;		#handle regex digits (replace with a 1)
	$regex =~ s/\\S/a/g; print "After nonspaces:\t\t$regex\n" if $debug;		#Handle regex non-whitespace (replace with 1 "a"
	$regex =~ s/\\W/ /g; print "After \\W:\t\t$regex\n" if $debug;		#handle regex non-alphanumeric (replace with an space)
	$regex =~ s/\\D/a/g; print "After \\D:\t\t$regex\n" if $debug;		#handle regex non-digits (replace with 1 "a")

	$regex =~ s/([^\}\\])\./$1a/g; print "After .:\t\t$regex\n" if $debug;	#replace "." with "a" if not preceded by \ or }

	#Kill lazyness
	#If we get *? or +?, drop the ?
	$regex =~ s/\*\?/*/g; print "After *?:\t\t$regex\n" if $debug;
	$regex =~ s/\+\?/+/g; print "After +?:\t\t$regex\n" if $debug;
	$regex =~ s/\?\?/+/g; print "After ??:\t\t$regex\n" if $debug;	

	#Quantifiers (Done)
	$regex =~ s/([^\\])\+/$1/g; print "After +:\t\t$regex\n" if $debug;		#handle 1 or more (remove the +, thing preceding it stays, wich is equivilant to 1)
	$regex =~ s/([^\\])\*/$1/g; print "After *:\t\t$regex\n" if $debug;		#handle 0, 1, or more (remove the *, thing preceding it stays, wich is equivilant to 1)
	$regex =~ s/([^\\])\?/$1/g; print "After ?:\t\t$regex\n" if $debug;		#handle 0 or 1 (remove the ?, thing preceding it stays, wich is equivilant to 1)

	#Literals (Needs some Expansion
	$regex =~ s/\\\././g; print "After .:\t\t$regex\n" if $debug;		#handle literal periods (replace with \. with .)
	$regex =~ s/\\\//\//g; print "After /:\t\t$regex\n" if $debug;		#handle literal forward slashes (replace with \/ with /)
	$regex =~ s/\\\?/\?/g; print "After ?:\t\t$regex\n" if $debug;		#handle literal ?'s (replace with \? with ?)
	$regex =~ s/\\\-/\-/g; print "After -:\t\t$regex\n" if $debug;		#handle literal -'s
	$regex =~ s/\\\\/\\/g; print "After \\:\t\t$regex\n" if $debug;		#handle literal \'s		
	$regex =~ s/\\\]/\]/g; print "After ]:\t\t$regex\n" if $debug;		#handle literal ]'s	
	$regex =~ s/\\\[/\[/g; print "After ]:\t\t$regex\n" if $debug;		#handle literal ['s		
	$regex =~ s/\\\(/\(/g; print "After (:\t\t$regex\n" if $debug;		#handle literal ('s
	$regex =~ s/\\\)/\)/g; print "After ):\t\t$regex\n" if $debug;		#handle literal )'s
	$regex =~ s/\\\*/\*/g; print "After *:\t\t$regex\n" if $debug;		#handle literal *'s
	$regex =~ s/\\\|/\|/g; print "After |:\t\t$regex\n" if $debug;		#handle literal |'s
	$regex =~ s/\\\{/\{/g; print "After {:\t\t$regex\n" if $debug;		#handle literal {'s
	$regex =~ s/\\\}/\}/g; print "After {:\t\t$regex\n" if $debug;		#handle literal }'s
	$regex =~ s/\\\;/\;/g; print "After ;:\t\t$regex\n" if $debug;		#handle literal ;'s
	$regex =~ s/\\\%/\%/g; print "After %:\t\t$regex\n" if $debug;		#handle literal %'s
	$regex =~ s/\\\:/\:/g; print "After ::\t\t$regex\n" if $debug;		#handle literal :'s
	$regex =~ s/\\\&/\&/g; print "After &:\t\t$regex\n" if $debug;		#handle literal &'s	
	$regex =~ s/\\\=/\=/g; print "After =:\t\t$regex\n" if $debug;		#handle literal ='s		
	$regex =~ s/\\\ /\ /g; print "After sp:\t\t$regex\n" if $debug;		#handle literal spaces's			
	$regex =~ s/\\r/\x0d/g; print "After \\r:\t\t$regex\n" if $debug;		#handle literal \r's
	$regex =~ s/\\n/\x0a/g; print "After \\n:\t\t$regex\n" if $debug;		#handle literal \n's
	$regex =~ s/\\\$/\$/g; print "After \$:\t\t$regex\n" if $debug;		#handle literal \$'s

	#handle hex encoding
	while ($regex =~ /\\x([0-9a-f]{2})/i) {
	my $hex = pack("C*", map { $_ ? hex($_) :() } split(/\\x/, $1));
	$regex =~ s/\\x([0-9a-f]{2})/$hex/i; print "After hex:\t\t$regex\n" if $debug;
	}

	#handle character classes []'s, just take the first character for each []
	#In the case of a negated class [^abc], the "^" character gets picked as a 
	#side effect, which is still fine. [^^] is accounted for as well.
	while ($regex =~ /\[(.)(.*?)\]/) {		#get [$1$2] where $1 is only one char and $2 is whats left
		my $class = $1;
		my $extra = $2;
		if (($class eq '^') && ($extra) && (($extra =~ /\^/) || ($extra =~ /^\\/))) {
			$regex =~ s/\[(.).*?\]/a/; print "After []'s:\t\t$regex\n" if $debug;	#handles a special negated class of [^^]
		} else {
			if ($class eq '\\') {									#if it starts with a \
				#if extra starts with [, then replace [$1$2] with [
					#So [\[] is converted to just a [ (and etc... for the rest of these)
				print "class is: $class - extra is $extra\n" if $debug;
				$regex =~ s/\[(.).*?\[/\[/ if ($extra =~ /^\[/); print "After [[:\t\t$regex\n" if $debug;
				$regex =~ s/\[(.).*?\]/\]/ if ($extra =~ /^\]/); print "After []:\t\t$regex\n" if $debug;
				$regex =~ s/\[(.).*?\]/\x0d/ if ($extra =~ /^r/i); print "After [\\r:\t\t$regex\n" if $debug;		
				$regex =~ s/\[(.).*?\]/\x0a/ if ($extra =~ /^n/i); print "After [\\n:\t\t$regex\n" if $debug;
				$regex =~ s/\[(.).*?\]/x/ if ($extra =~ /^s/i);	print "After [x:\t\t$regex\n" if $debug;
				$regex =~ s/\[(.).*?\]/\:/ if ($extra =~ /^:/); print "After [::\t\t$regex\n" if $debug;
				$regex =~ s/\[(.).*?\]/\(/ if ($extra =~ /^\(/); print "After [(:\t\t$regex\n" if $debug;
				$regex =~ s/\[(.).*?\]/\)/ if ($extra =~ /^\)/); print "After [):\t\t$regex\n" if $debug;
				$regex =~ s/\[(.).*?\]/\;/ if ($extra =~ /^\;/); print "After [;:\t\t$regex\n" if $debug;
				$regex =~ s/\[(.).*?\]/\*/ if ($extra =~ /^\*/); print "After [*:\t\t$regex\n" if $debug;
				$regex =~ s/\[(.).*?\]/\\/ if ($extra =~ /^\\/); print "After [\\:\t\t$regex\n" if $debug;
				$regex =~ s/\[(.).*?\]/\\/ if ($extra eq ''); print "After [null:\t\t$regex\n" if $debug;				
				$regex =~ s/\[(.).*?\]/\|/ if ($extra =~ /^\|/); print "After [|:\t\t$regex\n" if $debug;
				$regex =~ s/\[(.).*?\]/\{/ if ($extra =~ /^\{/); print "After [{:\t\t$regex\n" if $debug;
				$regex =~ s/\[(.).*?\]/\}/ if ($extra =~ /^\}/); print "After [}:\t\t$regex\n" if $debug;
				$regex =~ s/\[(.).*?\]/\%/ if ($extra =~ /^\%/); print "After [%:\t\t$regex\n" if $debug;
				$regex =~ s/\[(.).*?\]/\$/ if ($extra =~ /^\$/); print "After [\$:\t\t$regex\n" if $debug;
				$regex =~ s/\[(.).*?\]/\+/ if ($extra =~ '^\+'); print "After [+:\t\t$regex\n" if $debug;	
				$regex =~ s/\[(.).*?\]/\&/ if ($extra =~ '^\&'); print "After [&:\t\t$regex\n" if $debug;		
				$regex =~ s/\[(.).*?\]/\=/ if ($extra =~ '^\='); print "After [=:\t\t$regex\n" if $debug;		
				$regex =~ s/\[(.).*?\]/\ / if ($extra =~ '^\ '); print "After [sp:\t\t$regex\n" if $debug;														
			} else {
				$regex =~ s/\[(.).*?\]/$class/; print "After [^:\t\t$regex\n" if $debug;
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
			$regex =~ s/.\{(\d).*?\}/$char/s; print "After {}'s:\t\t$regex\n" if $debug;
		} else {
			if ($regex =~ /(\(.+?\))\{(\d+).*?\}/s) {
				$char = $1;
				$digit = $2;
				$char = $char x $digit;
			}
			$regex =~ s/(\(.+?\))\{(\d).*?\}/$char/s; print "After 2{}'s:\t\t$regex\n" if $debug;
		}
	}

	#handle grouping ()'s, take the first alternation in ()'s
	while ($regex =~ /\((.+?)\|.+?\)/){
		$regex =~ s/\((.+?)\|.+?\)/$1/; print "After ()'s:\t\t$regex\n" if $debug;
	}

	#remove gratuitus parenthesis
	$regex =~ s/\(|\)//g; print "After ()()()'s:\t\t$regex\n" if $debug;

	#Reintroduce tokenized metacharacters as literal
	$regex =~ s/$openparentoken/(/g; print "\nAfter ( add:\t\t$regex\n" if $debug;
	$regex =~ s/$closeparentoken/)/g; print "\nAfter ) add:\t\t$regex\n" if $debug;
	$regex =~ s/$opensquaretoken/[/g; print "\nAfter [ add:\t\t$regex\n" if $debug;
	$regex =~ s/$closesquaretoken/]/g; print "\nAfter ] add:\t\t$regex\n" if $debug;
	$regex =~ s/$openbracetoken/{/g; print "\nAfter { add:\t\t$regex\n" if $debug;
	$regex =~ s/$closebracetoken/}/g; print "\nAfter } add:\t\t$regex\n" if $debug;	
	$regex =~ s/$alternativetoken/|/g; print "\nAfter | add:\t\t$regex\n" if $debug;						
}

__END__

=head1 NAME

NFA Regex String Generator

=head1 SYNOPSIS

nfagen [options]

	Options:
	-h, --help	help
	-m, --man 	manpage
	--csv	output tab dillimited values
	--in 	input regex
	--file 	input text file

=head1 OPTIONS

=over 8

=item B<-h, --help>

Print a brief help message and exits

=item B<-m, --man>

Full documentation

=item B<--csv>

Outputs in tab dilimited values, along with a column showing validation of if the string actually matches

=item B<--in>

Input regex (surrounded with single quotes, becuase shell)

=item B<--file>

A text file with a different regular expression perl line

=back

=head1 DESCRIPTION

B<nfagen> Takes a user supplied regular expression and attempts to generate a 
string that would be matched by supplied regular expression. Currently, this
script generates a string that would match pretty much as quickly as possible.
Eventually terminating long circuit non-matches will be expirimented with,
for RE:DoS purposes.

A version of this engine is subroutined in the 8ball script.

=cut
