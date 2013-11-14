#!/usr/bin/perl -w
use strict;
use warnings;
use Statistics::R;

if(@ARGV != 4) {
    print STDERR "Usage: MACS_22TTest.pl suffix_for_inf(eg. .count.norm.xls) group1(eg. NaivePFC1:NaivePFC2:NaivePFC3:NaivePFC4:NaivePFC5) group2 outf\n";
    exit(0);
}
my ($suffix, $group1, $group2, $outf)=@ARGV;

# Create a communication bridge with R and start R
my $R = Statistics::R->new();


my @sample1=split(/:/, $group1);
my @sample2=split(/:/, $group2);
my @all_sample=(@sample1, @sample2);
open(OUT, ">$outf") or die "cannot open $outf\n";
print OUT "Chr\tPosition\t".(join"\t", @all_sample)."\tMean1\tMean2\tP-value\n";
my %hash;
for(my $i=0; $i<=$#all_sample; $i++){
	if($i==$#all_sample){
		my $count=0;
		my $inf=$all_sample[$i]."$suffix";
		open(IN, $inf) or die "cannot open $inf\n";
		while(<IN>){
			chomp;
			my @info=split(/\t/,$_);
			my @list1;
			my @list2;
			my $total1=0;
			my $total2=0;
			foreach my $sample (@sample1){
				my @count=@{$hash{$sample}};
				push(@list1, $count[$count]);
				$total1+=$count[$count];
			}
			if(scalar(@sample2)>1){
				my @tmp=@sample2[0..$#sample2-1];
				foreach my $sample (@tmp){
					my @count=@{$hash{$sample}};
					push(@list2, $count[$count]);
					$total2+=$count[$count];
				}
			}
			push(@list2, $info[2]);
			$total2+=$info[2];
  			my $list1=join",", @list1;
  			my $list2=join",", @list2;
  			my @list=(@list1, @list2);
  			my $tag=0;
  			for(my $i=1; $i<=$#list; $i++){
  				if($list[0]!=$list[$i]){
  					$tag=1;
  					last;
  				}
  			}
  			
  			my $p_value;
  			if($tag==1){
  				### Run R commands
  				$R->run(qq`x <- t.test(c($list1), c($list2))`);
  				$p_value= $R -> get('x$p.value');
  			}elsif($tag==0){
  				$p_value=1;
  			}
  			$list1=join"\t", @list1;
  			$list2=join"\t", @list2;
  			my $mean1= sprintf("%.2f", $total1/scalar(@sample1));
  			my $mean2= sprintf("%.2f", $total2/scalar(@sample2));
			print OUT "$info[0]\t$info[1]\t$list1\t$list2\t$mean1\t$mean2\t$p_value\n";
			$count++;
		}
		close IN;
	}else{
		my @count;
		my $inf=$all_sample[$i]."$suffix";
		open(IN, $inf) or die "cannot open $inf\n";
		while(<IN>){
			chomp;
			my @info=split(/\t/,$_);
			push(@count, $info[2]);
		}
		close IN;
		$hash{$all_sample[$i]}=\@count;
	}
}
close OUT;
