#!usr/bin/perl -w
use strict;
use Cwd qw(abs_path);
my ($in,$index,$outdir,$shdir)=@ARGV;
#输入二代模拟reads序列进行snap比对及coverage计算：fq.list index outdir shdir
-d $outdir || mkdir $outdir;
$outdir =abs_path($outdir);
-d $shdir || mkdir $shdir;
$shdir=abs_path($shdir);
-d "$outdir/01.SNAP" || system "mkdir -p $outdir/01.SNAP";
-d "$outdir/02.Coverage" ||system "mkdir -p $outdir/02.Coverage";
my $super_worker="perl /data/Yixue/hanpeng/01.Product_tech/AMRdetect/00.Pipeline/AMRdetect_v1.3_NGS/lib/super_worker.pl --cyqt 1 --maxjob 500 --sleept 30 --resource 2G --splits \"\\n\\n\" ";

my $num=`wc -l $in |awk '{print \$1}'`;
chomp $num;
my $each_n=100;
my $splitn=int($num/$each_n)+1;
#---------------------------
my $i=0;my $j=1;
open IN,$in;
open SH,">$shdir/step1.snap.$i.sh";
print SH "cd $outdir/01.SNAP\n/data/Yixue/hanpeng/Software/SNAP/snap-aligner ";
my @samples;
while(<IN>){
	chomp;
	my @or=split /\t/;
	push @samples,$or[0];
	#/data/GensKey/pipline/Genseq-PM/V3.2.1/software/snap-aligner single /data/GensKey/pipline/Genseq-PM/V3.2.1/database/DB_V0.20/snap_e /data/GensKey/Work/gaojianpeng/shengchan/illumina/projects/TJ495_BJ_20201129/02.HostRemove/20201128-DN-1-U25/20201128-DN-1-U25.pathogen.fq.gz -map -d 3 -F a -om 2 -mpc 1 -omax 10 -o /data/GensKey/Work/gaojianpeng/shengchan/illumina/projects/TJ495_BJ_20201129/03.Pathogen/20201128-DN-1-U25/20201128-DN-1-U25.snap_e.bam -xf 2.5 -t 16 , 
	if($j<=$each_n){
		print SH " single $index $or[1] -d 3 -F a -om 2 -mpc 1 -omax 10 -o $or[0].bam -xf 2.5 -t 16 , ";
		$j++;
	}else{
		print SH " > SNAP.$i.stat ";
		close SH;
		$i++;
		open SH,">$shdir/step1.snap.$i.sh";
 	    print SH "cd $outdir/01.SNAP\n/data/Yixue/hanpeng/Software/SNAP/snap-aligner ";
		print SH " single $index $or[1] -d 3 -F a -om 2 -mpc 1 -omax 10 -o $or[0].bam -xf 2.5 -t 16 , ";
		$j=1;
	}
}
print SH " > SNAP.stat ";
close SH;
#---------------------------------------------
open SH,">$shdir/step2.coverage.sh";
foreach my $s (@samples){
	-d "$outdir/02.Coverage/$s" || system "mkdir -p $outdir/02.Coverage/$s";
	print SH "cd $outdir/02.Coverage/$s
perl /data/GensKey/pipline/Genseq-PM/V3.2.1/lib/03.Pathogen/lib/bins.cov.depth.pl $outdir/01.SNAP/$s.bam --prefix $s
rm -rf $outdir/01.SNAP/$s.bam\n\n";
}
close SH;

open SH,">$shdir/main.run.sh";
print SH "cd $shdir\n";
foreach my $rr (0..$i){
	print SH "$super_worker --prefix snap$rr step1.snap.$rr.sh\n";
}
print SH "$super_worker --prefix coverage step2.coverage.sh\n";
close SH;

system "cd $shdir;sh main.run.sh";
