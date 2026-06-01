#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use lib "$Bin/lib/";
#################db####
my $db_CARD = "/data/GensKey/Work/chenfy/project/test_data/script/predict_ONT/bin/../database/card.nucl.mmi";
my $ref = "/data/GensKey/Work/hanpeng/01.Product_tech/naiyao/02.predict_AST/ONT_vs_NGS/ONT/script/target_ref/ref.fa";
################sodtware######
my $minimap = "/data/GensKey/Work/chenfy/project/test_data/script/predict_ONT/bin//../software/minimap2";
###############lib##########
my $paf_filter2anno = "/data/GensKey/Work/hanpeng/01.Product_tech/naiyao/02.predict_AST/ONT_vs_NGS/ONT/script/paf_filter2anno.pl";
my $stat_ARGdetect = "/data/GensKey/Work/hanpeng/01.Product_tech/naiyao/02.predict_AST/ONT_vs_NGS/ONT/script/stat_ARGdetect.pl";
my $stat_ARGdetect_filter = "/data/GensKey/Work/hanpeng/01.Product_tech/naiyao/02.predict_AST/ONT_vs_NGS/ONT/script/stat_ARGdetect_filter.pl";
my $predict_arg2spe = "/data/GensKey/Work/hanpeng/01.Product_tech/naiyao/02.predict_AST/ONT_vs_NGS/ONT/script/predict_arg2spe.pl";
my $extract_pathoseq = "/data/GensKey/Work/hanpeng/01.Product_tech/naiyao/02.predict_AST/ONT_vs_NGS/ONT/script/extract_pathoseq.pl";
my $cover_depth = "/data/GensKey/Work/hanpeng/01.Product_tech/naiyao/02.predict_AST/ONT_vs_NGS/ONT/script/cover_depth.pl";
my $patho_ARGdetect = "/data/GensKey/Work/hanpeng/01.Product_tech/naiyao/02.predict_AST/ONT_vs_NGS/ONT/script/patho_ARGdetect.pl";
my $predict_AST = "/data/GensKey/Work/hanpeng/01.Product_tech/naiyao/02.predict_AST/ONT_vs_NGS/ONT/script/predict_AST.pl";
my $super_worker="perl /data/GensKey/pipline/Genseq-PM/V3.1.b/lib/00.Commbin/super_worker.pl --cyqt 1 --maxjob 500 --sleept 30 --resource 2G --splits \"\\n\\n\" ";
########################
my $list = $ARGV[0];
my $outdir = $ARGV[1];
my $shdir=$ARGV[2];
-d $shdir || system "mkdir -p $shdir";
-d $outdir || system "mkdir -p $outdir";
$shdir=abs_path($shdir);
$outdir=abs_path($outdir);
open IN,$list || die $!;
my ($shell,$shell2);
while (<IN>){
	chomp;
	my ($name,$file) = split /\t/;
#	$shell .= "mkdir -p $outdir/$name\n";
	-d "$outdir/$name" || system "mkdir -p $outdir/$name";
	$shell .= "cd $outdir/$name\n";
	$shell .= "$minimap -c -x map-ont -L  --secondary=no $db_CARD $file >$name.paf\n";
	$shell .= "perl $paf_filter2anno $name.paf $name.paf.filter.anno \n";
	$shell .= "perl $stat_ARGdetect $name.paf.filter.anno >$name.stat.xls 2>$name.reads.anno.lca\n\n";

#	$shell2 .= "cd $outdir/$name\n";
#	$shell2 .= "$minimap -x map-ont -a  -t 8 --secondary=no -L $ref  $file  > $name.sam\n";
#	$shell2 .= "perl $cover_depth $name.sam --prefix $name\n\n";
}
open OUT,">$shdir/ARG.ont.sh" || die $!;
print OUT "$shell";
close OUT;
system "cd $shdir\n$super_worker --prefix ONT ARG.ont.sh ";
#open OUT2,">Shell2.sh" || die $!;
#print OUT2 "$shell2";
