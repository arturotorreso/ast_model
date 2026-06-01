#!usr/bin/perl -w
use strict;
use Cwd qw(abs_path);
use FindBin qw($Bin);
my ($in,$drug,$outdir,$shdir)=@ARGV;
-d $outdir || mkdir $outdir;
$outdir=abs_path($outdir);
-d $shdir || system "mkdir -p $shdir";
$shdir=abs_path($shdir);
my $predict="/data/GensKey/Work/gaojianpeng/work/Tools/Software/miniconda3/install/bin/python $Bin/roc.py ";
my $bar="perl $Bin/bar.pl ";
my $paper="$Bin/drug.show.list.english";
my $ppvnpv="$Bin/ppv.npv.pl";
my $super_worker="perl /data/GensKey/pipline/Genseq-PM/V3.1.b/lib/00.Commbin/super_worker.pl --cyqt 1 --maxjob 900 --sleept 30 --resource 2G --splits \"\\n\\n\" ";


my %filter;
open IN,$paper;
while(<IN>){
	chomp;
	$_=~s/\s+/_/g;
	$filter{$_}=1;
}
close IN;
#-----------------------------------------------------
open IN,$drug;
my $one=<IN>;
chomp $one;
my @tt=split /\t/,$one;
my %rs;
while(<IN>){
	chomp;
	my @or=split /\t/;
	$or[0]=~s/\s+/_/g;
	$or[0]=~s/:/--/g;
	foreach my $j (1..$#or){
		if ($or[$j] eq "R" or $or[$j] eq "S"){
			$rs{$or[0]}{$tt[$j]}=$or[$j];
		}
	}
}
close IN;
#----------------------------------------------------
my %hash;
open IN,$in;
while(<IN>){
	chomp; # NS50_0.3_GCA_000401195.1_repeat_1
	my @arr=split /\t/;
	my @or=split /_/,$arr[0];
	my $gid=join("_",@or[2..3]);
	my $platform=$or[0];
	my $depth=$or[1];
	open FF,$arr[1];
	<FF>;
	while(my $l=<FF>){
		chomp $l;
		my @arr=split /\t/,$l;
		my $drug=$arr[1];
		$drug=~s/:/--/g;
		$drug=~s/\s+/_/g;
		push @{$hash{$platform}{$depth}{$drug}},$gid."\t".$drug."\t".$arr[3]."\t$rs{$drug}{$gid}" if $rs{$drug}{$gid};
	}
	close FF;	
}
close IN;

open SH,">$shdir/roc.sh";
foreach my $plat(sort keys %hash){
	foreach my $depth (sort keys %{$hash{$plat}}){
		foreach my $d (sort keys %{$hash{$plat}{$depth}}){
			next unless $filter{$d};
			$d=~s/\s+/_/g;
			my $dir="$outdir/$plat/$depth/$d";
			-d "$dir" || system "mkdir -p $dir";
			open OUT,">$dir/$d.input.xls";
			print OUT "sample\tdrug\tscore\tast\n";
			print OUT join("\n",@{$hash{$plat}{$depth}{$d}});
			close OUT;
			print SH "cd $dir
$predict -i $d.input.xls -p $d
$bar $d.input.xls $d
perl $ppvnpv $d.input.xls cutoff.value > $d.ppv.npv\n\n";
		}
	}
}
close SH;

system "cd $shdir;$super_worker --prefix roc roc.sh";
