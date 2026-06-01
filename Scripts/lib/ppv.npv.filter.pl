#!usr/bin/perl -w
use strict;
use Getopt::Long;
my ($pcut,$ncut,$tpgc,$clist,$drug);
GetOptions(
	"cutoff_list:s"=>\$clist,
	"drug:s"=>\$drug,
	"ppv_cutoff:s"=>\$pcut,
	"npv_cutoff:s"=>\$ncut,
	"tp_genome_cutoff:s"=>\$tpgc,
);
$pcut||="0.9";
$ncut||="0";
$tpgc||="2";
my ($in)=@ARGV;

my %gf;
open IN,"/data/Yixue/gaojianpeng/Projects/AST/Ruijin_Pseudomonas_aeruginosa/Softs/ARGdetectV1.0/lib/card_db/card.info.xls";
<IN>;
while(<IN>){
	chomp;
	my @or=split /\t/;
	$gf{$or[8]}=1;
}
close IN;


if($clist and $drug){
	open IN,$clist;
	#<IN>;
	while(<IN>){
		chomp;
		next if $_=~/^#/;
		my @jj=split /\t/;
		if ($jj[0] eq "$drug"){
			$pcut=$jj[2];
			$tpgc=$jj[1];
			last;
		}
	}
	close IN;
}
print STDERR "#ppv_cutoff:$pcut\n";
print STDERR "#npv_cutoff:$ncut\n";
print STDERR "#tp_genome_cutoff:$tpgc\n";
#---------------------------
open IN,$in;
my $one=<IN>;
chomp $one;
my @tt=split /\t/,$one;
my $astn;
my @genes;
foreach my $i (0..$#tt){
	$astn=$i and next  if $tt[$i] eq "AST";
	push @genes,$tt[$i] if $i > 1;
}

my %truep;
my %truen;
while(<IN>){
	chomp;
	my @or=split /\t/;
	next if $or[$astn] eq "NA";
	if ($or[$astn] eq "R"){
		$truep{$or[0]}=1;
	}elsif($or[$astn] eq "S"){
		$truen{$or[0]}=1;
	}else{
		next;
	}
}
close IN;

my $tp=scalar keys %truep;
my $tn=scalar keys %truen;

open IN,$in;
<IN>;
my %predp;
my %predn;
while(<IN>){
	chomp;
	my @or=split /\t/;
	next if $or[$astn] eq "NA";
	foreach my $i(2..$#or){
		if ($i == $astn){
			next;
		}else{
			if($or[$i] > 0 ){
				push @{$predp{$tt[$i]}},$or[0];
			}else{
#				print STDERR "#",$or[0],"\t",$or[$i],"\t",$tt[$i],"\n";
				push @{$predn{$tt[$i]}},$or[0];
			}
		}
	}
}
close IN;

my %fp;
foreach my $g (sort keys %predp){
	foreach my $k (@{$predp{$g}}){
		$fp{$g}||=0;
		$fp{$g}++ unless $truep{$k};
	}
}

my %fn;
foreach my $g (sort keys %predn){
	foreach my $k (@{$predn{$g}}){
		$fn{$g}||=0;
		$fn{$g}++ unless $truen{$k};
	}
}

print "#Genes\tPPV\tNPV\n";
foreach my $g (@genes){
	$fp{$g}||=0;
	$fn{$g}||=0;
	my $predp;
	if($predp{$g}){
		$predp=scalar(@{$predp{$g}});
	}else{
		$predp=0;
	}
	my $predn;
	if($predn{$g}){
		$predn=scalar(@{$predn{$g}});
	}else{
		$predn=0;
	}
	my $ppv;
	if($predp>0){
		$ppv=($predp-$fp{$g})/$predp;
	}else{
		$ppv="0";
	}
	my $npv;
	if ($predn>0){
		$npv=($predn-$fn{$g})/$predn;
	}else{
		$npv="0";
	}
#$pcut||="0.5";
#$ncut||="0";
#$tpgc||="3";
#	print STDERR $g,"\t","($predp-$fp{$g})/$predp","\t","($predn-$fn{$g})/$predn","\n";
	if($predp-$fp{$g}>=$tpgc and $ppv >=$pcut and $npv >= $ncut){
		print $g,"\t",$predp-$fp{$g},"/(",$predp-$fp{$g},"+$fp{$g}):",$ppv,"\t",$predn-$fn{$g},"/(",$predn-$fn{$g},"+$fn{$g}):",$npv,"\n";
	}else{
		#if($gf{$g} and $ppv >= $pcut){
		if($g=~/beta-lactamase/ and $ppv >= $pcut and $predp-$fp{$g}>=$tpgc-1 ){
			print $g,"\t",$predp-$fp{$g},"/(",$predp-$fp{$g},"+$fp{$g}):",$ppv,"\t",$predn-$fn{$g},"/(",$predn-$fn{$g},"+$fn{$g}):",$npv,"\n";
		}
		print STDERR "Filter Log:",$g,"\t",$predp-$fp{$g},"/(",$predp-$fp{$g},"+$fp{$g}):",$ppv,"\t",$predn-$fn{$g},"/(",$predn-$fn{$g},"+$fn{$g}):",$npv,"\n";
	}
}
