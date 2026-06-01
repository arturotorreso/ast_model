#!usr/bin/perl -w
use strict;
use Cwd qw(abs_path);
my ($tax,$cvgns,$cvgont,$ppv,$auc,$outdir)=@ARGV;
-d $outdir || mkdir $outdir;
$outdir =abs_path($outdir);
my %xx; #xx 覆盖深度梯度
my %pt;
open IN,$cvgns;
#/data/GensKey/Work/gaojianpeng/work/Medical_Department_Projects/Naiyao/01.Delete_Efflux_pump_Reanalyse/03.Paper.Figs.Reanalyse/06.AST-SimuReads-peprun/Escherichia_coli/04.Coverage/NS50/result/02.Coverage/NS50_0.3_GCA_000633675.2_repeat_1/NS50_0.3_GCA_000633675.2_repeat_1.cvg.bins.xls
my %cvg;
while(<IN>){
	chomp;
	my @or=split /\//;
	my @arr=split /_/,$or[-2];
	my $plat=$arr[0];
	my $dep=$arr[1];
	$xx{$dep}=1;
	$pt{$plat}=1;
	next unless -s $_;
	open FF,$_;
	while(my $f=<FF>){
		my @aa=split /\t/,$f;
		#/data/GensKey/Work/gaojianpeng/work/Medical_Department_Projects/AST/RuijinPA/AnalyseV0.2/SimuReads/NS50/Tr/02.ARG.anno/NS50/02.Blast/CARD/NS50_0.2_A245_repeat_1/NS50_0.2_A245_repeat_1.cvgstat
		#Pseudomonas aeruginosa  GCF_000006765.1 15777   1071783/6264404 17.109  1.1
		push @{$cvg{$plat}{$dep}},$aa[-2] if $aa[-2] > 0 and $tax eq $aa[0];
	}
	close FF;
}
close IN;

open IN,$cvgont;
while(<IN>){
	#/data/GensKey/Work/gaojianpeng/work/Medical_Department_Projects/Naiyao/01.Delete_Efflux_pump_Reanalyse/03.Paper.Figs.Reanalyse/06.AST-SimuReads-peprun/Escherichia_coli/04.Coverage/ONT/result/ONT_0.3_GCA_000633675.2_repeat_1/ONT_0.3_GCA_000633675.2_repeat_1.cvgstat
	chomp;
	my @or=split /\//;
	my @arr=split /_/,$or[-2];
	my $plat=$arr[0];
	my $dep=$arr[1];
	$pt{$plat}=1;
	next unless -s $_;
	open FF,$_;
	while(my $l=<FF>){
		chomp $l;
		my @arr=split /\t/,$l;
		if ($arr[0] eq $tax){
	#		print $l,"\n";
			push @{$cvg{$plat}{$dep}},sprintf("%.1f",$arr[-2]); #coverage
			last;
		}
	}
	close FF;
}
close IN;


my %drugs;
my %ppvnpv;
open IN,$ppv;
#/data/GensKey/Work/gaojianpeng/work/Medical_Department_Projects/Naiyao/01.Delete_Efflux_pump_Reanalyse/03.Paper.Figs.Reanalyse/06.AST-SimuReads-peprun/Escherichia_coli/03.RSPredict.ROC/02.ROC/NS50/0.3/aminoglycoside_antibiotic--gentamicin/aminoglycoside_antibiotic--gentamicin.ppv.npv
while(<IN>){
	chomp;
	my @or=split /\//;
	my $plat=$or[-4];
	my $dep=$or[-3];
	my $drug=$or[-2];
	$drugs{$drug}=1;
	open FF,$_;
	<FF>;
	my $l=<FF>;
	chomp $l;
	my @aa=split /\t/,$l;
	my @bb=split /:/,$aa[1]; #ppv
	my @cc=split /:/,$aa[2]; #npv
	#print STDERR "#ppvnpv\t$plat\t$dep\t$drug\t$bb[1]\t$cc[1]\n";
	$ppvnpv{$plat}{$dep}{$drug}{ppv}=$bb[1];
	$ppvnpv{$plat}{$dep}{$drug}{npv}=$cc[1];
	close FF;
}
close IN;

my %auc;
open IN,$auc;
#/data/GensKey/Work/gaojianpeng/work/Medical_Department_Projects/Naiyao/01.Delete_Efflux_pump_Reanalyse/03.Paper.Figs.Reanalyse/06.AST-SimuReads-peprun/Escherichia_coli/03.RSPredict.ROC/02.ROC/NS50/0.3/aminoglycoside_antibiotic--gentamicin/aminoglycoside_antibiotic--gentamicin.process.txt
while(<IN>){
	chomp;
	my @or=split /\//;
	my $plat=$or[-4];
	my $dep=$or[-3];
	my $drug=$or[-2];
	open FF,$_;
	my $l=<FF>;chomp $l;
	my @aa=split /\t/,$l;
	close FF;
	#print STDERR "#auc\t$plat\t$dep\t$drug\t$aa[-1]\n";
	$auc{$plat}{$dep}{$drug}=$aa[-1]; #auc
}
close IN;

my @platform=sort keys %pt;
my @drugs=sort keys %drugs;
my @xx=sort {$a <=> $b} keys %xx;

foreach my $p (@platform){
	foreach my $d(@drugs){
		-d "$outdir/$p/$d" ||system "mkdir -p $outdir/$p/$d";
		open OUT,">$outdir/$p/$d/ppv.npv.auc.xls";
		print OUT "#MockDepth\tCoverage\tPPV\tNPV\tAUC\n";
		foreach my $x (@xx){
			next unless $auc{$p}{$x}{$d};
		#	print STDERR $p,"\t",$d,"\t",$x,"\n" unless $cvg{$p}{$x};
			if($cvg{$p}{$x}){
				my @cvg=sort {$a <=> $b} @{$cvg{$p}{$x}};
		#		print "@cvg","\n";
				my $mean=avg_sd(\@cvg);
				my $min=$cvg[0];
				my $max=$cvg[-1];
				my $xxx="$mean($min:$max)";
				print OUT $x,"\t",$xxx,"\t",$ppvnpv{$p}{$x}{$d}{ppv},"\t",$ppvnpv{$p}{$x}{$d}{npv},"\t",$auc{$p}{$x}{$d},"\n";
			}else{
				print OUT $x,"\t-\t",$ppvnpv{$p}{$x}{$d}{ppv},"\t",$ppvnpv{$p}{$x}{$d}{npv},"\t",$auc{$p}{$x}{$d},"\n";
			}
		}
		close OUT;
	}
}
#-----------------------------------------
sub avg_sd{
    my ($avg);
	my $tmp=shift;
	my @sss=@{$tmp};
    my $num = scalar @sss; 
    for(@sss){
        $avg += $_; 
    }   
    $avg /= $num;
    $avg = sprintf("%.1f",$avg);
    return("$avg");
}
