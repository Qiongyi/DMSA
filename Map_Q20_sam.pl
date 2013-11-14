#!/usr/bin/perl -w
use warnings;
use strict;
if(@ARGV != 2) {
    print STDERR "Usage: Map_Q20_sam.pl input_sam output_sam\n";
  	exit(0);
}
my ($inf, $outf)=@ARGV;
my $qual_cutoff=20;

open(IN, $inf) or die "cannot open $inf\n";
open(OUT, ">$outf") or die "cannot open $outf\n";
while(<IN>){
	if($_=~/^\@/){
		print OUT $_;
	}else{
		my @info=split(/\t/,$_);
		my $read2=<IN>;
		my @info2=split(/\t/,$read2);
		if($info[0] eq $info2[0]){
			if($info[1] & 2){
				if($info[1] & 4 || ($info2[1] & 4)){
					next;
				}
				if($info[4]>=$qual_cutoff || $info2[4]>=$qual_cutoff){
					print OUT "$_$read2";
				}
			}
		}else{
			print STDERR "Wrong reads: not paired!\n$info[0]\t$info2[0]\n"; exit;
		}
	}
}
close IN;
close OUT;
