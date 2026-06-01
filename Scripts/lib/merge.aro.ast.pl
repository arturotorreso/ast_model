#!usr/bin/perl -w
use strict;
use Getopt::Long;

my $identity_cutoff;
GetOptions("identity_cutoff:s"=>\$identity_cutoff);
my ($rgi,$samplelist,$drugclass,$del_efflux)=@ARGV;
#Description：基于RGI机器学习（LASSO)进行耐药特征挖掘
#Date: 20220222
#Version: v0.1
#Email: gjpbioinfo\@163.com

$identity_cutoff ||=80;
my $del = $del_efflux ? 1 : 0 ;

my %ast;
open IN,$samplelist;
while(<IN>){
	chomp;
	my @or=split /\t/;
	next if $or[1] ne "R" and  $or[1] ne "S";
	$ast{$or[0]}=$or[1];
}
close IN;

open LIST,$rgi;
my %hash;
my %features;
while(<LIST>){
	chomp;
	my @arr=split /\//;
	next unless $ast{$arr[-2]}; #仅考虑有AST表型的样本
	open IN,$_;
	<IN>;
	while(my $l=<IN>){
		chomp $l;
		my @or=split /\t/,$l;
		my $aro=$or[8];
		my @tmp=split /;\s+/,$or[14];
		my %drugs;
		foreach my $t (@tmp){
			$drugs{$t}=1;
		}
		$drugclass=~s/_/ /g;
		
		if($or[9]<=$identity_cutoff){
#			print STDERR "Filter:$aro identity:$or[9],低于阈值 $identity_cutoff \n";
			next;
		}
			
		if($del){
			if ($or[15]=~/efflux/){
		#		print STDERR "Filter:$aro  identiy:$or[9] 外排泵机制:$or[15] \n";
				next;
			}
		}
		
		if(!$drugs{$drugclass}){
			#print STDERR "Filter:$aro  identiy:$or[9] DrugClass未包含 $drugclass  \n";
			next;
		}

		if($or[12] ne "n/a"){
			my @var=split /,\s+/,$or[12];
			foreach my $v (@var){
				$hash{$arr[-2]}{"$aro($v)"}=1;
				$features{"$aro($v)"}=1;
			}
		}else{
			$hash{$arr[-2]}{$aro}=1;
			$features{$aro}=1;
		}
	}
	close IN;
}
close LIST;

my @ff=sort keys %features;
print "AST\tARG\t",join("\t",@ff),"\n";
foreach my $sam (sort {$ast{$a} cmp $ast{$b}} keys %ast){
	print "$ast{$sam}\t$sam";
	foreach my $f (@ff){
		$hash{$sam}{$f}||="0";
		print "\t$hash{$sam}{$f}";
	}
	print "\n";
}
