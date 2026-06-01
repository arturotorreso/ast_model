#!usr/bin/perl -w
use strict;

my ($seq,$prefix)=@ARGV;
my $block_length||=100;

my %hash;
open IN,$seq;
$/=">";
<IN>;
while(<IN>){
	chomp;
	my $m=1;
	my @or=split /\n/;
	my @aa=split /\s+/,$or[0];
	my $fa=join("",@or[1..$#or]);
	if (length($fa)>$block_length){
		my $n=int(length($fa)/$block_length);
		foreach (my $i=0;$i<$n;$i++){
			my $cutfa=substr($fa,$i*$block_length,$block_length);
			my $len=length($cutfa);
			print ">$prefix\_$aa[0]_$m\_$len\n$cutfa\n";
			$m++;
		}
		if ($n < length($fa)/$block_length){
			my $cutfa=substr($fa,$n*$block_length,length($fa)-$n*$block_length);
			my $len=length($cutfa);
			next if $len<50;
			print ">$prefix\_$aa[0]_$m\_$len\n$cutfa\n";;
		}
	}elsif(length($fa)>50){
		my $len=length($fa);
		print ">$prefix\_$aa[0]_$m\_$len\n$fa\n";
	}else{
		next;
	}
}
close IN;
$/="\n";
