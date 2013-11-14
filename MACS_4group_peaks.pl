#!/usr/bin/perl -w
use warnings;
use strict;
if(@ARGV != 3) {
    print STDERR "Usage: MACS_4group_peaks.pl cutoff(the distance between peaks, eg.600) inf outf\n";
  	exit(0);
}
my ($cutoff, $inf, $outf)=@ARGV;

my $count=0;
my $chr_old="chr";
my $pos_old;
my $line;
open(IN, $inf) or die "Cannot open $inf\n";
open(OUT, ">$outf") or die "Cannot open $outf\n";
while(<IN>){
	if($_=~/^Chr\s/){
		print OUT $_;
	}elsif($_=~/^\w/){
		my @info=split(/\t/,$_);
		if($chr_old ne $info[0]){
			if(defined($line)){
				$count++;
				print OUT "\#Peak $count\n$line";
			}
			$line=$_;
			$chr_old=$info[0];
			$pos_old=$info[1];
		}else{
			if($info[1]-$pos_old<$cutoff){
				$line.=$_;
				$pos_old=$info[1];
			}else{
				$count++;
				print OUT "\#Peak $count\n$line";
				$line=$_;
				$pos_old=$info[1];
			}
		}
	}
}
close IN;
$count++;
print OUT "\#Peak $count\n$line";
close OUT;
