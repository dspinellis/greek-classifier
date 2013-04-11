#!/usr/bin/perl

use strict;
use warnings;

# Default distance
my $opt_d = 9;

my $max_gram = 4;

my %greek_ng;
my %all_ng;

read_ngram('ngram.el', \%greek_ng);
read_ngram('ngram.all', \%all_ng);

while(<>) {
	chop;
	my $word = "^$_\$";
	print "$_ ", "\n" if(delta($word, \%greek_ng, \%all_ng) > $opt_d);
	#print "$_ GD:", distance($word, \%greek_ng), "\n";
	#print "$_ AD:", distance($word, \%all_ng), "\n";
}

# Given two references to arrays of n-gram probabilities
# return the difference in their distance
sub
delta
{
	my ($word, $ngp0, $ngp1) = @_;

	return distance($word, $ngp1) - distance($word, $ngp0);
}

sub
sqr
{
	my ($n) = @_;
	return $n * $n;
}

# Given a reference to an array of n-gram probabilities
# return the distance measure of the word from the array
sub
distance
{
	my ($word, $ngp) = @_;

	my $sum = 0;
	for (my $n = 2; $n <= $max_gram; $n++) {
		# Relative frequency of each ngram in word
		my $fA = 1 / (length($word) - $n + 1);
		for (my $s = 0; $s < length($word) - $n + 1; $s++) {
			my $ngram = substr($_, $s, $n);
			# Relative frequency of ngram in training set
			my $fa = (exists($ngp->{$ngram})) ?
				$ngp->{$ngram} * 5 : 0;
			$sum += sqr(($max_gram + 1 - $n) * ($fa - $fA) / ($fA + $fa));
			#print "fa=$fa fA=$fA sum=$sum\n";
		}
	}
	return $sum;
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
