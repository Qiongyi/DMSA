#!/usr/bin/perl -w
use warnings;
use strict;
if(@ARGV != 5) {
    print STDERR "Usage: Summary_stats.pl length_of_chr IN_DIR outf(xls) outf2(chr,xls) outf3(chr,nomalisation)\n";
  	exit(0);
}
my ($chr_len, $in_dir, $outf, $outf2, $outf3)=@ARGV;

# normalised the length of each chromosome to 100Mbp
my $len_norm=100000000; # 100 Mbp

# normalised the total DNA fragments (one DNA frament equals to one paired-end reads) to 1 Million (i.e. 2 million reads)
my $num_norm=1000000;  # 1 M paired-end reads
my %total;
my %chr_len;

open(IN, $chr_len) or die "Cannot open $chr_len\n";
while(<IN>){
	my @info=split(/\t/,$_);
	$chr_len{$info[0]}=$info[1];
}
close IN;

my $output;
my $chr;
my $chr_head;
my %hash;
opendir(INDIR, $in_dir) or die "Cannot open dir $in_dir\n";
my @files=readdir INDIR;
closedir INDIR;
foreach my $file (sort @files){
#	next if $file!~/_stat\.xls$/;
	if($file=~/^(.+)_bwa_mapping_stats.xls/){
		my $sample_name=$1;
		$output.=$1;
		$chr.=$1;
		$chr_head="Sample name";
		open(IN, "$in_dir/$file") or die "Cannot open $in_dir/$file\n";
		while(<IN>){
			chomp;
			my @info=split(/\t/,$_);
			if($_=~/^Total/ || $_=~/^Properly/){			
				$output.="\t".$info[1];
				if($info[0]=~/^Total reads/i){
					$total{$sample_name}=$info[1];
				}
			}elsif($_=~/^chr/){
				$hash{$sample_name}{$info[0]}=$info[1];
				$chr.="\t".$info[1];
				$chr_head.="\t".$info[0];
			}
		}
		close IN;
		$output.="\n";
		$chr.="\n";
	}
}

open(OUT, ">$outf") or die "Cannot open $outf\n";
print OUT "Sample name\tTotal reads\tProperly paired-end mapped reads\t%\tProperly paired-end mapped reads with mapping quality >=20\t%\n";
print OUT $output;
close OUT;

open(OUT, ">$outf2") or die "Cannot open $outf2\n";
print OUT "$chr_head\n$chr";
close OUT;

my %count;
my %norm;

open(OUT, ">$outf3") or die "Cannot open $outf3\n";
my @chr=sort keys %chr_len;
my $line_title="Sample name\t".(join"\t",@chr)."\n";
print OUT $line_title;

foreach my $sample (sort keys %total){
	print OUT $sample;
	foreach my $chr (@chr){
		my $norm=$hash{$sample}{$chr} * ($num_norm/$total{$sample}) * ($len_norm/$chr_len{$chr});
		printf OUT ("\t%.2f",$norm);
	}
	print OUT "\n";
}
close OUT;



