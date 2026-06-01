#!usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
my ($in,$outdir,$shdir)=@ARGV;
#输入二代模拟reads序列进行snap比对及coverage计算：fq.list index outdir shdir
-d $outdir || mkdir $outdir;
$outdir =abs_path($outdir);
-d $shdir || mkdir $shdir;
$shdir=abs_path($shdir);
my $super_worker="perl /data/GensKey/pipline/Genseq-PM/V3.1.b/lib/00.Commbin/super_worker.pl --cyqt 1 --maxjob 500 --sleept 30 --resource 2G --splits \"\\n\\n\" ";
my $ref="$Bin/ref/ref.fa";
open IN,$in;
open SH,">$shdir/ont.coverage.sh";
my @samples;;
while(<IN>){
	chomp;
	my @or=split /\t/;
	push @samples,$or[0];
	-d "$outdir/$or[0]" || system "mkdir -p $outdir/$or[0]";
	#/data/GensKey/Work/hanpeng/Software/minimap2/minimap2-2.17_x64-linux/minimap2 -x map-ont -a  -t 8 --secondary=no -L /data/GensKey/Work/hanpeng/01.Product_tech/naiyao/02.predict_AST/ONT_vs_NGS/ONT/script/target_ref/ref.fa 20JS050993-04.pathogen.fa > 20JS050993-04.sam
	print SH "cd $outdir/$or[0]
/data/GensKey/Work/hanpeng/Software/minimap2/minimap2-2.17_x64-linux/minimap2 -x map-ont -a  -t 8 --secondary=no -L  $ref $or[1] > $or[0].sam
perl /data/GensKey/Work/hanpeng/01.Product_tech/naiyao/02.predict_AST/ONT_vs_NGS/ONT/script/cover_depth.pl $or[0].sam --prefix $or[0]
rm -rf $or[0].sam \n\n";
}
close SH;

system "cd $shdir;$super_worker --prefix ont.cov ont.coverage.sh";	
