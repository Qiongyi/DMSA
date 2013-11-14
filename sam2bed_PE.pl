#!/usr/bin/perl -w
use strict;
use warnings;

# bam/sam: 1 based
# bed: 0 based and [start, end)

if(@ARGV !=2) {
    print STDERR "Usage: sam2bed_PE.pl sam_file bed_file\n";
    exit(0);
}
my ($inf, $outf)=@ARGV;
open(IN, $inf) or die "Cannot open $inf\n";
open(OUT, ">$outf") or die "Cannot open $outf\n";
while(<IN>){
	next if $_=~/^\@/;
	my @info=split(/\t/,$_);
	if(defined($info[8]) && $info[8]>0){
		print OUT "$info[2]\t".($info[3]-1)."\t".($info[3]+$info[8]-1)."\n";
	}
}
close IN;
close OUT;
