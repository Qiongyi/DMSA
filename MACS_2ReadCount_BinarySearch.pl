#!/usr/bin/perl -w
use strict;
use warnings;
use Statistics::R;

if(@ARGV < 7) {
    print STDERR "Usage: MACS_2ReadCount_BinarySearch.pl header_line(T/F, only \"T\" will print the header line) map_stat_file(for normalization) pos_file bed_dir outf1(count) outf2(count_norm) input_prefixs(eg. ISVA1PFC)\n";
    exit(0);
}
my ($header_TF, $stat, $inf, $bed_dir, $outf1, $outf2, @infs)=@ARGV;
my $norm_num=20000000; ### to normalise the total number of fragments to 20M
### read map stat file to get the total number of reads for normalization
my %total_reads;
open(IN, $stat) or die "cannot open $stat\n";
while(<IN>){
	if($_=~/^Sample/){
		next;
	}elsif($_=~/\w/){
		my @info=split(/\t/,$_);
		if($info[0]=~/s_\d_([^\s]+)/){
			$total_reads{$1}+=$info[1];
			$total_reads{$info[0]}+=$info[1];
		}else{
			$total_reads{$info[0]}+=$info[1];
		}
	}
}
close IN;

my %hash; # for recording the fragment positons from bed files
#my %start; # for recording all the start position of the fragment from bed files
my @all_beds;
my @samples;
foreach my $inf_list (@infs){
	my @bed=`ls $bed_dir/$inf_list*.bed`;
	foreach my $bed (@bed){
		chomp($bed);
		push(@all_beds, $bed);
		if($bed=~/([^\/]+)\.bed/){
			my $sample_name=$1;
			push(@samples, $sample_name);
			open(IN, $bed) or die "Cannot open $bed\n";
			while(<IN>){
				my @info=split(/\t/,$_);
				$hash{$sample_name}{$info[0]}.="$info[1]\t$info[2]";
			}
			close IN;
			print STDERR "Hash is finished for $sample_name\n";
		}else{
			print STDERR "Wrong bed name: $bed\n"; exit;
		}		
	}
}
print STDERR "All hash are finished\n";

if($header_TF eq "T"){
	my $outf_header="header_line.txt";
	open(OUT, ">$outf_header") or die "cannot open $outf_header\n";
	my $header_line="Chr\tPosition";
	my $line=join "\t", @samples;
	print OUT "$header_line\t$line\n";
	close OUT;
}

open(OUT, ">$outf1") or die "cannot open $outf1\n";
open(OUT2, ">$outf2") or die "cannot open $outf2\n";
open(IN, $inf) or die "cannot open $inf\n";
while(<IN>){
		chomp;
		my ($chr, $pos)=split(/\t/,$_);
		my $count_data;
		my $count_norm_data;
		foreach my $sample (@samples){
			my $count=&get_fragment_count($sample, $chr, $pos);
			my $count_norm;
			if($count==0){
				$count_norm=0;
			}else{
				$count_norm=sprintf("%.2f",$count/$total_reads{$sample}*$norm_num*2);
			}
			$count_data.="\t$count";
			$count_norm_data.="\t$count_norm";
		}
		print OUT "$chr\t$pos$count_data\n";
		print OUT2 "$chr\t$pos$count_norm_data\n";
}
close IN;
close OUT;
close OUT2;

sub get_fragment_count{
	my ($sample, $chr, $pos)=@_;
	my $pos_start=($pos-2000)>=0?($pos-2000):0;
	my $count=0;
	my @lines=split(/\n/, $hash{$sample}{$chr});
	my $num=scalar(@lines);
	my $mid_fix=int($num/2);
	my $mid=$mid_fix;
	my $times=1;
	while(1){
		$times*=2;
		my @info=split(/\t/,$lines[$mid]);
		if($pos_start>$info[0]){
			$mid=$mid+int($mid_fix/$times);
		}elsif($pos<$info[0]){
			$mid=($mid-int($mid_fix/$times+1))>0?($mid-int($mid_fix/$times+1)):0;
		}else{
			$mid=($mid-100)>=0?($mid-100):0;
			@info=split(/\t/,$lines[$mid]);
			if($pos_start>=$info[0]){
				last;
			}else{
				$mid=($mid-1000)>=0?($mid-1000):0;
				@info=split(/\t/,$lines[$mid]);
				if($pos_start>=$info[0]){
					last;
				}else{			
					$mid=($mid-10000)>=0?($mid-10000):0;
					last;
				}
			}
		}
		if($times==8192){  ### 2**13
			if($pos<$info[0] || $pos_start>$info[0]){
				$mid=($mid-int($mid_fix/$times+1))>0?($mid-int($mid_fix/$times+1)):0;
			}
			last;
		}
	}
	for(my $i=$mid; $i<$num; $i++){
		my @info=split(/\t/, $lines[$i]);
		if($pos>$info[0] && $pos<=$info[1]){
			$count++;
		}elsif($info[0]>$pos){
			last;
		}
	}
	return $count;
}

