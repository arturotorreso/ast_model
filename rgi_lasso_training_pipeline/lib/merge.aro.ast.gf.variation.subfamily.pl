#!usr/bin/perl -w
use strict;
use Getopt::Long;

my $identity_cutoff;
GetOptions("identity_cutoff:s"=>\$identity_cutoff);
my ($rgi,$samplelist,$drugclass,$del_efflux)=@ARGV;

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

open IN,"/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/scripts/PDC.OXA.group.format";
my %sub;
while(<IN>){
	chomp;
	my @or=split /\t/;
	my $mark=$or[2]=~/PDC/ ? "PDC" : $or[2]=~/OXA/ ? "OXA" : "/";
	next if $mark eq "/";
	$sub{$or[1]}="$mark beta-lactamase $or[-1]";
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
		my $aro=$sub{$or[10]} ? $sub{$or[10]} : $or[16];
		my @tmp=split /;\s+/,$or[14];
		my %drugs;
		foreach my $t (@tmp){
			$drugs{$t}=1;
		}
		$drugclass=~s/_/ /g;
		
		if($or[9]<=$identity_cutoff){
			next;
		}
			
		if($del){
			if ($or[15]=~/efflux/){
				next;
			}
		}
		
		if(!$drugs{$drugclass}){
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
