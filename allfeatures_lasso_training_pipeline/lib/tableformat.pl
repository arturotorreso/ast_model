#!usr/bin/perl -w
use strict;

my ($in,$score,$drug)=@ARGV;

my %score;
open IN,$score;
while(<IN>){
	chomp;
	my @or=split /\t/;
	$score{$or[0]}=$or[1];
}
close IN;

my %hash;
my %hash2;
my %ast;
open IN,$in;
my $title=<IN>;
chomp $title;
my @tt=split /\t/,$title;
my @samples;
while(<IN>){
	chomp;
	my @or=split /\t/;	
	$ast{$or[0]}=$or[-1];
	push @samples,$or[0];
	foreach my $i (1..$#or-1){
		$hash{$or[0]}+=$or[$i]*$score{$tt[$i]};
		$hash2{$or[0]}.="$tt[$i]:$score{$tt[$i]}," if $or[$i]>0;
	}
}
close IN;

print "sample\tdrug\tscore\tast\tdetail\n";
foreach my $sam (@samples){
	$hash2{$sam}||="/";
	print $sam,"\t",$drug,"\t",$hash{$sam},"\t",$ast{$sam},"\t",$hash2{$sam},"\n";
}
