#!/usr/bin/perl

use strict;
use warnings;

my $max_gram = 4;

my %greek_ng;
my %all_ng;

read_ngram('ngram.el', \%greek_ng);
read_ngram('ngram.all', \%all_ng);

while(<>) {
	chop;
	my $word = "^$_\$";
	print "$_ ", "\n" if(classify($word, \%greek_ng, \%all_ng) > 2);
}

# Given two references to arrays of n-gram probabilities
# return the ratio between their two classifications
# the second
sub
classify
{
	my ($word, $ngp0, $ngp1) = @_;

	return grade($word, $ngp0) / grade($word, $ngp1);
}

# Given a reference to an array of n-gram probabilities
# return how well the word matches those probabilities
sub
grade
{
	my ($word, $ngp) = @_;

	my $count = 0;
	my $sum = 0;
	for (my $n = 2; $n <= $max_gram; $n++) {
		for (my $s = 0; $s < length($word) - $n + 1; $s++) {
			$sum += $ngp->{substr($_, $s, $n)} * $n
				if (exists($ngp->{substr($_, $s, $n)}));
			$count++;
		}
	}
	return $sum / $count;
}

# Read a tab-separated file of n-gram probabilities into the specified
# hash reference
sub
read_ngram
{
	my($fname, $ngp) = @_;

	open(my $in, '<', $fname) || die "Unable to open $fname: $_\n";
	while (<$in>) {
		chop;
		my ($ngram, $prob) = split(/\t/);
		$ngp->{$ngram} = $prob;
	}
}

