#!usr/bin/perl -w
use strict;

my ($in,$outdir)=@ARGV;

my $refdir="/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/data/RefGenomes";

open IN,$in;
while(<IN>){
	chomp;
	my @or=split /\t/;
	-d "$outdir/$or[0]" || system "mkdir -p $outdir/$or[0]";
	print "cd $outdir/$or[0]
source /home/L1/gaojianpeng/software/miniconda3/bin/activate
#1 PAO1 
/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/bwa/bwa mem -Y -t 16 -R '\@RG\\tID:$or[0]\\tPL:$or[0]\\tSM:$or[0]' $refdir/PAO1/NC_002516.2.fa $or[1] | /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/samtools/samtools sort --threads 16 -o $or[0].PAO1.bam
/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/samtools/samtools index $or[0].PAO1.bam
/home/L1/gaojianpeng/software/dot_net_linux/dotnet /home/L1/gaojianpeng/software/Pisces/Pisces_5.2.5.20/Pisces.dll -bam $or[0].PAO1.bam -g $refdir/PAO1 -minbq 1 -minmq 10 -sbfilter 10 -minvq 0 -minvf 0.0005 -c 1 -OutFolder PAO1
perl /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/scripts/filter.vcf.pl PAO1/$or[0].PAO1.genome.vcf > PAO1/$or[0].PAO1.filter.vcf
snpEff ann PAO1 PAO1/$or[0].PAO1.filter.vcf > PAO1/$or[0].PAO1.filter.anno.vcf
#2 ATCC_27853
/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/bwa/bwa mem -Y -t 16 -R '\@RG\\tID:$or[0]\\tPL:$or[0]\\tSM:$or[0]' $refdir/ATCC_27853/NZ_CP101912.1.fa $or[1] | /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/samtools/samtools sort --threads 16 -o $or[0].ATCC_27853.bam
/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/samtools/samtools index $or[0].ATCC_27853.bam
/home/L1/gaojianpeng/software/dot_net_linux/dotnet /home/L1/gaojianpeng/software/Pisces/Pisces_5.2.5.20/Pisces.dll -bam $or[0].ATCC_27853.bam -g $refdir/ATCC_27853 -minbq 1 -minmq 10 -sbfilter 10 -minvq 0 -minvf 0.0005 -c 1 -OutFolder ATCC_27853
perl /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/scripts/filter.vcf.pl ATCC_27853/$or[0].ATCC_27853.genome.vcf > ATCC_27853/$or[0].ATCC_27853.filter.vcf
snpEff ann ATCC_27853 ATCC_27853/$or[0].ATCC_27853.filter.vcf > ATCC_27853/$or[0].ATCC_27853.filter.anno.vcf
#3 F23197
/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/bwa/bwa mem -Y -t 16 -R '\@RG\\tID:$or[0]\\tPL:$or[0]\\tSM:$or[0]' $refdir/F23197/NZ_CP008856.2.fa $or[1] | /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/samtools/samtools sort --threads 16 -o $or[0].F23197.bam
/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/samtools/samtools index $or[0].F23197.bam
/home/L1/gaojianpeng/software/dot_net_linux/dotnet /home/L1/gaojianpeng/software/Pisces/Pisces_5.2.5.20/Pisces.dll -bam $or[0].F23197.bam -g $refdir/F23197 -minbq 1 -minmq 10 -sbfilter 10 -minvq 0 -minvf 0.0005 -c 1 -OutFolder F23197
perl /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/scripts/filter.vcf.pl F23197/$or[0].F23197.genome.vcf > F23197/$or[0].F23197.filter.vcf
snpEff ann F23197 F23197/$or[0].F23197.filter.vcf > F23197/$or[0].F23197.filter.anno.vcf
#4 FRD1
/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/bwa/bwa mem -Y -t 16 -R '\@RG\\tID:$or[0]\\tPL:$or[0]\\tSM:$or[0]' $refdir/FRD1/NZ_CP010555.1.fa $or[1] | /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/samtools/samtools sort --threads 16 -o $or[0].FRD1.bam
/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/samtools/samtools index $or[0].FRD1.bam
/home/L1/gaojianpeng/software/dot_net_linux/dotnet /home/L1/gaojianpeng/software/Pisces/Pisces_5.2.5.20/Pisces.dll -bam $or[0].FRD1.bam -g $refdir/FRD1 -minbq 1 -minmq 10 -sbfilter 10 -minvq 0 -minvf 0.0005 -c 1 -OutFolder FRD1
perl /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/scripts/filter.vcf.pl FRD1/$or[0].FRD1.genome.vcf > FRD1/$or[0].FRD1.filter.vcf
snpEff ann FRD1 FRD1/$or[0].FRD1.filter.vcf > FRD1/$or[0].FRD1.filter.anno.vcf
#5 LESB58
/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/bwa/bwa mem -Y -t 16 -R '\@RG\\tID:$or[0]\\tPL:$or[0]\\tSM:$or[0]' $refdir/LESB58/FM209186.1.fa $or[1] | /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/samtools/samtools sort --threads 16 -o $or[0].LESB58.bam
/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/samtools/samtools index $or[0].LESB58.bam
/home/L1/gaojianpeng/software/dot_net_linux/dotnet /home/L1/gaojianpeng/software/Pisces/Pisces_5.2.5.20/Pisces.dll -bam $or[0].LESB58.bam -g $refdir/LESB58 -minbq 1 -minmq 10 -sbfilter 10 -minvq 0 -minvf 0.0005 -c 1 -OutFolder LESB58
perl /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/scripts/filter.vcf.pl LESB58/$or[0].LESB58.genome.vcf > LESB58/$or[0].LESB58.filter.vcf
snpEff ann LESB58 FRD1/$or[0].LESB58.filter.vcf > LESB58/$or[0].LESB58.filter.anno.vcf
#6 MTB-1
/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/bwa/bwa mem -Y -t 16 -R '\@RG\\tID:$or[0]\\tPL:$or[0]\\tSM:$or[0]' $refdir/MTB-1/CP006853.1.fa $or[1] | /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/samtools/samtools sort --threads 16 -o $or[0].MTB-1.bam
/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/samtools/samtools index $or[0].MTB-1.bam
/home/L1/gaojianpeng/software/dot_net_linux/dotnet /home/L1/gaojianpeng/software/Pisces/Pisces_5.2.5.20/Pisces.dll -bam $or[0].MTB-1.bam -g $refdir/MTB-1 -minbq 1 -minmq 10 -sbfilter 10 -minvq 0 -minvf 0.0005 -c 1 -OutFolder MTB-1
perl /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/scripts/filter.vcf.pl MTB-1/$or[0].MTB-1.genome.vcf > MTB-1/$or[0].MTB-1.filter.vcf
snpEff ann MTB-1 MTB-1/$or[0].MTB-1.filter.vcf > MTB-1/$or[0].MTB-1.filter.anno.vcf
#7 PA-VAP-4
/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/bwa/bwa mem -Y -t 16 -R '\@RG\\tID:$or[0]\\tPL:$or[0]\\tSM:$or[0]' $refdir/PA-VAP-4/CP028368.1.fa $or[1] | /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/samtools/samtools sort --threads 16 -o $or[0].PA-VAP-4.bam
/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/samtools/samtools index $or[0].PA-VAP-4.bam
/home/L1/gaojianpeng/software/dot_net_linux/dotnet /home/L1/gaojianpeng/software/Pisces/Pisces_5.2.5.20/Pisces.dll -bam $or[0].PA-VAP-4.bam -g $refdir/PA-VAP-4 -minbq 1 -minmq 10 -sbfilter 10 -minvq 0 -minvf 0.0005 -c 1 -OutFolder PA-VAP-4
perl /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/scripts/filter.vcf.pl PA-VAP-4/$or[0].PA-VAP-4.genome.vcf > PA-VAP-4/$or[0].PA-VAP-4.filter.vcf
snpEff ann PA-VAP-4 PA-VAP-4/$or[0].PA-VAP-4.filter.vcf > PA-VAP-4/$or[0].PA-VAP-4.filter.anno.vcf
#8 UCBPP-PA14
/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/bwa/bwa mem -Y -t 16 -R '\@RG\\tID:$or[0]\\tPL:$or[0]\\tSM:$or[0]' $refdir/UCBPP-PA14/CP000438.1.fa $or[1] | /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/samtools/samtools sort --threads 16 -o $or[0].UCBPP-PA14.bam
/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/samtools/samtools index $or[0].UCBPP-PA14.bam
/home/L1/gaojianpeng/software/dot_net_linux/dotnet /home/L1/gaojianpeng/software/Pisces/Pisces_5.2.5.20/Pisces.dll -bam $or[0].UCBPP-PA14.bam -g $refdir/UCBPP-PA14 -minbq 1 -minmq 10 -sbfilter 10 -minvq 0 -minvf 0.0005 -c 1 -OutFolder UCBPP-PA14
perl /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/scripts/filter.vcf.pl PA-VAP-4/$or[0].UCBPP-PA14.genome.vcf > UCBPP-PA14/$or[0].UCBPP-PA14.filter.vcf
snpEff ann UCBPP-PA14 UCBPP-PA14/$or[0].UCBPP-PA14.filter.vcf > UCBPP-PA14/$or[0].UCBPP-PA14.filter.anno.vcf\n\n";
}
close IN;
