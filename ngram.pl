#!/usr/bin/perl
#
# Calculate n-gram frequencies for the specified input file

use strict;
use warnings;

my @gram;
my @count;

my $max_gram = 4;

while (<>) {
	chop;
	# Beginning and end have additional significance
	s/^/^/;
	s/$/\$/;
	for (my $n = 2; $n <= $max_gram; $n++) {
		for (my $s = 0; $s < length($_) - $n + 1; $s++) {
			$gram[$n]{substr($_, $s, $n)}++;
			$count[$n]++;
		}
	}
}

# Print results
for (my $n = 2; $n <= $max_gram; $n++) {
	for my $g (keys %{$gram[$n]}) {
		print "$g\t", $gram[$n]{$g} / $count[$n], "\n";
	}
}
