#!/usr/bin/perl -w
use strict;
use warnings;

if(@ARGV < 3) {
    print STDERR "Usage: MACS_1GetPeakSummits.pl outf bed_dir(the folder that include \"*_summits.bed\" files) input_prefixs(eg. s_7 s_8)\n";
    exit(0);
}
my ($outf, $peak_dir, @infs)=@ARGV;

my %hash;
foreach my $inf (@infs){
	my @bed=`ls $peak_dir/$inf*_summits.bed`;
	foreach my $bed (@bed){
		chomp($bed);
		&read_summits_bed($bed);
		print STDERR "$bed finished!\n";
	}
}
print STDERR "All peak files are finished. Now I'm writing output file...\n";

open(OUT, ">$outf") or die "cannot open $outf\n";
foreach my $chr (sort keys %hash){
	foreach my $pos (sort {$a<=>$b} keys %{$hash{$chr}}){
		print OUT "$chr\t$pos\n";
	}
}
close OUT;

sub read_summits_bed{
	my $inf=shift;
	open(IN, $inf) or die "cannot open $inf\n";
	while(<IN>){
		my @info=split(/\t/,$_);
		$hash{$info[0]}{$info[1]}=undef;
	}
}
