#!/usr/bin/perl -w
use warnings;
use strict;
if(@ARGV != 3) {
    print STDERR "Usage: Get_properly_mapping_stats.pl chr_name.txt sam mapping_stats\n";
  	exit(0);
}
my ($chr_name, $inf, $outf)=@ARGV;

# default mapping quality cutoff is 20
my $qual_cutoff=20;

my %total; ## Total reads
my %pp; ## Only for properly paired mapped reads
my %hash; ## Only for properly paired mapped reads with the mapping quality >=$qual_cutoff, sperate by each chromosome
my %chr_num; ## record each chromosome name;

# read sam file and select properly paired-end mapped reads with good mapping quality
open(IN, $inf) or die "cannot open $inf\n";
while(<IN>){
	if($_=~/^\@/){
		next;
	}else{
		my @read=split(/\t/,$_);
		my $read2=<IN>;
		my @read2=split(/\t/,$read2);
		$total{$read[0]}=undef;
		if($read[1] & 2){
			if($read[1] & 4 || ($read2[1] & 4)){
				next;
			}
			$pp{$read[0]}=undef;
			if($read[4]>=$qual_cutoff || $read2[4]>=$qual_cutoff){
				$hash{$read[2]}{$read[0]}=undef;
			}		
		}
	}
}
close IN;

my $total=scalar(keys %total)*2;
my $pp=scalar(keys %pp)*2;
my $ppq=0;
foreach my $chr (sort keys %hash){
	$ppq+=scalar(keys %{$hash{$chr}});
	$chr_num{$chr}=scalar(keys %{$hash{$chr}});
}
$ppq=$ppq*2;
open(OUT, ">$outf") or die "cannot open $outf\n";
print OUT "Total reads\t$total\nProperly mapped reads\t$pp\nProperly mapped reads(%)\t";
printf OUT ("%.2f%%\n", $pp/$total*100);
print OUT "Properly paired-end mapped reads with mapping quality >= $qual_cutoff\t$ppq\nProperly mapped reads with mapping quality >= $qual_cutoff(%)\t";
printf OUT ("%.2f%%\n", $ppq/$total*100);
print OUT "######## Reads on each chromosome (only considering properly paired-end mapped reads with mapping quality >= $qual_cutoff) ########\n";

open(IN, $chr_name) or die "cannot open $chr_name\n";
while(<IN>){
	if($_=~/(\w+)/){
#		chomp;
#		$_=~s/>//g;
		if(defined($chr_num{$1})){
			my $num=$chr_num{$1}*2;
			print OUT "$1\t$num\n";
		}else{
			print OUT "$1\t0\n";
		}
	}
}
close IN;
close OUT;
