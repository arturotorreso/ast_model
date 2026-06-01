#!usr/bin/perl -w
use strict;

my ($in)=@ARGV;

open IN,$in;
my $one=<IN>;
chomp $one;
my @title=split /\t/,$one;
my @genes=@title;
shift @genes;pop @genes;pop @genes;
my %value;
my %info;
my %r;
my %s;
while(<IN>){
	chomp;
	my @or=split /\t/;
	foreach my $i (1..$#or-2){
		$value{$title[$i]}{$or[0]}=$or[$i];
	}
	if ($or[-2] eq "R"){
		$r{$or[0]}=1;
	}else{
		$s{$or[0]}=1;
	}
	$info{$or[0]}=$_;
}
close IN;

my @rr=sort keys %r;
my @ss=sort keys %s;

my %sortedgeno;
my $m=0;
foreach my $gene(@genes){
	my %hash=%{$value{$gene}};
	foreach my $g ( @rr){
		if($hash{$g} ne "NA" && !$sortedgeno{$g}){
			$m++;
			$sortedgeno{$g}=$m;
		}
	}
}
print $one,"\n";
foreach my $g (sort {$sortedgeno{$a} <=> $sortedgeno{$b}} keys %sortedgeno){
	print $info{$g},"\n";
}
foreach my $left (@rr){
	if($sortedgeno{$left}){
		next;
	}else{
		print $info{$left},"\n";
	}
}

my %sortedgeno2;
my $m2=0;
foreach my $gene(@genes){
	my %hash=%{$value{$gene}};
	foreach my $g (@ss){
		if($hash{$g} ne "NA" && !$sortedgeno2{$g}){
			$m2++;
			$sortedgeno2{$g}=$m2;
		}
	}
}

foreach my $g (sort {$sortedgeno2{$a} <=> $sortedgeno2{$b}} keys %sortedgeno2){
	print $info{$g},"\n";
}

foreach my $left (@ss){
	if($sortedgeno2{$left}){
		next;
	}else{
		print $info{$left},"\n";
	}
}
############################################################
sub sortgenome{
	my ($input,$vv)=@_;
	my @input=@{$input};
	my %vv=%{$vv};
	my @sel;
	my @left;
	foreach my $g (sort @input){
		if ($vv{$g} eq "NA"){
			push @left,$g;
		}else{
			push @sel,$g;
		}
	}
	my $tmp=join("#",@sel);
	return ($tmp,\@left);
}
