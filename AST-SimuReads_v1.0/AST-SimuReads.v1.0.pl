#!usr/bin/perl -w
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;
my ($input,$outdir,$prefix,$notrun,$shdir,$depth,$repeat,$type,$step,$tax,$pheno,$nextseq_cov,$ont_cov);
GetOptions("genomes_list:s"=>\$input,"outdir:s"=>\$outdir,"notrun"=>\$notrun,"shdir:s"=>\$shdir,"repeat:i"=>\$repeat,"depth:s"=>\$depth,"mock_type:s"=>\$type,"step:i"=>\$step,"tax:s"=>\$tax,"pheno:s"=>\$pheno,"Nextseq_coverage_list:s"=>\$nextseq_cov,"ONT_coverage_list:s"=>\$ont_cov);

($input && -s $input) || die "
	perl $0 
	
		--Nextseq_coverage_list	二代模拟数据coverage结果文件，如果输入折线绘图横坐标用该文件的coverage结果
		--ONT_coverage_list	ONT模拟数据coverage文件，如果输入折线绘图横坐标用该文件的coverage结果
\n";
#################################### 变量声明及调用文件 ####################
$outdir||=".";
-d $outdir || mkdir $outdir;
$outdir=abs_path($outdir);
$input=abs_path($input);
$shdir ||="./Shell";
-d $shdir || `mkdir -p $shdir`;
$shdir=abs_path($shdir);
$pheno=abs_path($pheno);
$repeat||=1;
$depth||="0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,3,5,7,9,10";
#$type||="NS50,ONT"; #默认nextseq550，Nanopore
$type||="NS50";
my $svg2xxx="/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/svg2xxx_release/svg2xxx";
my $art="/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/art_bin_MountRainier/art_illumina";
my $readsim="/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/soft/readsim-1.6/src/readsim.py";

my $ns_argpip="/data/Yixue/hanpeng/01.Product_tech/AMRdetect/00.Pipeline/AMRdetect_v1.4_NGS/AMR_detect.pl";
#my $ont_argpip="$Bin/ONT_ARG.pl";
#my $ont_argpip="/data/GensKey/Work/hanpeng/01.Product_tech/naiyao2/00.Pipeline_AMRdetect/AMRdetect_v1.0_ONT_wenzhang/AMR_detect_ONT.pl";
my $ont_argpip="/data/GensKey/Work/gaojianpeng/work/Medical_Department_Projects/AST/RuijinPA/AnalyseV0.2/SimuReads/lib/AMRdetect_v1.3_ONT/AMR_detect_ONT.pl";

my $argfilter="$Bin/stat_ARGdetect_filter.pl";
my $statformat="$Bin/00.stat.format.pl";
my $nspredict="$Bin/ns.predict_AST.pl";
my $ontpredict="$Bin/ont.predict_AST.pl";
my $argroc="$Bin/arg.rs.roc.pl";
my $comb="$Bin/comb.pl";
my $line="$Bin/line.svg.pl";
my $nsdb="$Bin/db.index";
my $nscovpip="$Bin/NS.snap.coverage.pip.pl";
open IN,$nsdb;
my %nsdb;
while(<IN>){
	chomp;
	my @or=split /\t/;
	$nsdb{$or[0]}=$or[1];
}
close IN;
my $taxdb;
if ($nsdb{$tax}){
	$taxdb=$nsdb{$tax};
}else{
	print STDERR  "未找到$tax的索引文件!\n";
}
my $ontcovpip="$Bin/ont.coverage.pip.pl";
my $phenostat="$Bin/pheno.stat.pl";
my $super_worker="perl /home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/scripts/super_worker.pl --cyqt 1 --maxjob 500 --sleept 30 --resource 2G --splits \"\\n\\n\" ";
#################################### 主脚本  ###############################
#分析步骤
#1 模拟数据及模拟覆盖度计算
#2 耐药基因注释
#3 score计算及ROC分析
#4 AUC/PPV/NPV/Cutoff输出

my $main_shell = "run.MockReadsARG.sh";
open SH,">$shdir/$main_shell" || die $!;
print SH "cd $shdir\n";
if ($step=~/1/){
	my $step1_outdir="$outdir/01.SimuReads.Coverage";
	my $step1_1_outdir="$step1_outdir/01.SimuReads";
	my $step1_1_mock_shell;
	my $ont_reads_list;
	my $ns_reads_list;
	-d $step1_outdir || mkdir $step1_outdir;
	-d $step1_1_outdir || mkdir $step1_1_outdir;
	my @Simutype=split /,/,$type;
	my @depths=split /,/,$depth;
	open IN,$input ||die "基因组列表未找到!\n";
	my $n = 0;
	while (my  $line = <IN>){
    	    chomp $line;
	    my ($name,$genome)=split/\t/,$line;
		for my $ty (@Simutype){
    		    for my $xx (@depths){
	        	for( my $i=1;$i<=$repeat;$i++){
				my $dir=$step1_1_outdir."/$ty/$xx/$name/repeat_$i"; #模拟类型/几乘覆盖深度/基因组名称/重复次数
				-d $dir || system "mkdir -p $dir";
	    	        	if($ty eq "ONT"){
        	       			$step1_1_mock_shell.= "cd $dir\n$readsim sim fa --ref $genome --pre $ty\_$xx\_$name\_repeat_$i --rev_strd on --tech nanopore --read_mu 2000 --cov_mu $xx --read_dist normal\n\n";#可以再继续加入覆盖度计算的shell
					$ont_reads_list.="$ty\_$xx\_$name\_repeat_$i\t$dir/$ty\_$xx\_$name\_repeat_$i.fasta\n";
            			}elsif($ty eq "NS50"){
			        	$step1_1_mock_shell.= "cd $dir\n$art -ss $ty -i $genome -o ./$ty\_$xx\_$name\_repeat_$i -f $xx -l 50 -na \n";
					$ns_reads_list.="$ty\_$xx\_$name\_repeat_$i\t$dir/$ty\_$xx\_$name\_repeat_$i.fq\n";
				}else{
					die "未识别模拟数据测序平台,--type 参数!\n";
				}
			}
		    }
		}
	    $n++;
	    $n % 10 == 0 && ($step1_1_mock_shell .= "\n");
	}
	close IN;
	write_file("$step1_outdir/ONT.mock.reads.list",$ont_reads_list) if $ont_reads_list;
	write_file("$step1_outdir/NS50.mock.reads.list",$ns_reads_list) if $ns_reads_list;
	write_file("$shdir/step1.1.MockReads.sh",$step1_1_mock_shell);
	shell_box(*SH,"1.1) Mock Reads,type includes: $type","step1.1.MockReads.sh","Mock");
	
	my $step1_2_outdir="$step1_outdir/02.Coverage";
	my $step1_2_cov_shell;
	-d $step1_2_outdir || mkdir $step1_2_outdir;
	my $ns_cov_list;
	my $ont_cov_list;
	foreach my $ty (@Simutype){
		if ($ty=~/NS50/){
			die "未检测到  $step1_outdir/NS50.mock.reads.list 文件!\n" unless (-s "$step1_outdir/NS50.mock.reads.list");
			if($nextseq_cov){ #如果输入--Nextseq_coverage_list参数就不跑coverage计算
				$step1_2_cov_shell.="cd $step1_2_outdir\n#perl $nscovpip $step1_outdir/NS50.mock.reads.list $taxdb NS50 $shdir/step1.2.Coverage.NS50\n";
			}else{
				$step1_2_cov_shell.="cd $step1_2_outdir\nperl $nscovpip $step1_outdir/NS50.mock.reads.list $taxdb NS50 $shdir/step1.2.Coverage.NS50\n";
			}
			open LL,"$step1_outdir/NS50.mock.reads.list";
			while(my $l=<LL>){
				chomp $l;
				my @tmp=split /\t/,$l;
				#result/02.Coverage/NS50_0.3_GCA_000401195.1_repeat_1/NS50_0.3_GCA_000401195.1_repeat_1.cvg.bins.xls
				#$ns_cov_list.="$step1_2_outdir/NS50/02.Coverage/$tmp[0]/$tmp[0].cvg.bins.xls\n";
				$ns_cov_list.="$outdir/02.ARG.anno/NS50/02.Blast/CARD/$tmp[0]/$tmp[0].cvgstat\n";
			}
			close LL;
		}elsif($ty=~/ONT/){
			die "未检测到 $step1_outdir/ONT.mock.reads.list 文件!\n" unless (-s "$step1_outdir/ONT.mock.reads.list");
			if($ont_cov){
				$step1_2_cov_shell.="cd $step1_2_outdir\n#perl $ontcovpip $step1_outdir/ONT.mock.reads.list ONT $shdir/step1.2.Coverage.ONT\n";
			}else{
				$step1_2_cov_shell.="cd $step1_2_outdir\nperl $ontcovpip $step1_outdir/ONT.mock.reads.list ONT $shdir/step1.2.Coverage.ONT\n";
			}
			open LL,"$step1_outdir/ONT.mock.reads.list";
			while(my $l=<LL>){
				chomp $l;
				my @tmp=split /\t/,$l;
				#result/ONT_0.3_GCA_000406545.1_repeat_1/ONT_0.3_GCA_000406545.1_repeat_1.cvgstat
	#			$ont_cov_list.="$step1_2_outdir/ONT/$tmp[0]/$tmp[0].cvgstat\n";
				$ont_cov_list.="$outdir/02.ARG.anno/ONT/02.minimap2/CARD/$tmp[0]/$tmp[0].cvgstat\n";
			}
			close LL;
		}else{
			die "未识别模拟数据测序平台,--type 参数!\n";
		}
	}
	write_file("$shdir/step1.2.Coverage.sh",$step1_2_cov_shell);
	write_file("$step1_outdir/NS50.coverage.list",$ns_cov_list) if $ns_cov_list;
	write_file("$step1_outdir/ONT.coverage.list",$ont_cov_list) if $ont_cov_list;
#	shell_box(*SH,"1.2) Coverage ,type includes: $type","step1.2.Coverage.sh");
}
#--------------------------------------------------------------------------------------------------------------------------
-s "$outdir/01.SimuReads.Coverage/NS50.coverage.list" ? $nextseq_cov||="$outdir/01.SimuReads.Coverage/NS50.coverage.list" : die "未检测到$outdir/01.SimuReads.Coverage/NS50.coverage.list文件\n";
#-s "$outdir/01.SimuReads.Coverage/ONT.coverage.list"  ? $ont_cov||="$outdir/01.SimuReads.Coverage/ONT.coverage.list" : die "未检测到$outdir/01.SimuReads.Coverage/ONT.coverage.list文件\n";
$ont_cov||="$outdir/01.SimuReads.Coverage/ONT.coverage.list";
$nextseq_cov=abs_path($nextseq_cov);
$ont_cov=abs_path($ont_cov);
#--------------------------------------------------------------------------------------------------------------------------
if($step=~/2/){
	my $step2_outdir="$outdir/02.ARG.anno";
	my $step2_arg_shell;
	my $ns_stat_list; #02.ARG.anno/NS50/03.anno_stat/CARD/*.stat.xls
	my $ns_stat_list_filter;
	my $ont_stat_list; #02.ARG.anno/ONT/*/*.stat.xls
	my @listarr;
#	push @listarr,"$outdir/01.SimuReads.Coverage/ONT.mock.reads.list" if -s "$outdir/01.SimuReads.Coverage/ONT.mock.reads.list";
	push @listarr,"$outdir/01.SimuReads.Coverage/NS50.mock.reads.list" if -s "$outdir/01.SimuReads.Coverage/NS50.mock.reads.list";

	foreach my $f (@listarr){
		my $m=$1 if $f=~/.*\/(\S+)\.mock\.reads\.list$/;
		my $step2_outdir_sub="$step2_outdir/$m";
		-d $step2_outdir_sub || system "mkdir -p $step2_outdir_sub";
		if ($m eq "NS50"){
			open FF,$f;
			open OUT,">$step2_outdir_sub/total.QCstat.info.xls\n";
			print OUT join("\t",qw/Sample	RawReads	Adapter_ratio(%)	Duplication(%)	Clean_GC(%)	Clean_Q20	Clean_Q30	CleanReads	Effective(%)	AvgQuality	LowQuality(%)	Nfilter(%) TooShort(%)	BowtieAdapter(%)	LowComplexity(%)/),"\n";
			while(my $l=<FF>){
				my @or=split /\t/,$l;
				$ns_stat_list.="$or[0]\t$step2_outdir/$m/03.Arg2AST//CARD/$or[0]/$or[0].stat.xls\n";
				$ns_stat_list_filter.="$or[0]\t$step2_outdir/$m/03.Arg2AST//CARD/$or[0]/$or[0].stat.filter.xls\n";
				print OUT "$or[0]\t14704\t0.33\t0.0340855\t57.17\t95.45\t93.66\t14703\t99.99\t0.997569628437629\t0\t0\t0\t0.00\t0.01\n";
			}
			close OUT;
			#$step2_arg_shell.="cd $step2_outdir_sub\nperl $ns_argpip --qc_stat total.QCstat.info.xls  --data_list $f --outdir . --shdir $shdir/step2.ARG.anno/NS50\n";
			$step2_arg_shell.="cd $step2_outdir_sub\nperl $ns_argpip --data_list $f --outdir ./  --pathogen \"$tax\"  --shdir $shdir/step2.ARG.anno/NS50\n";
		}elsif($m eq "ONT"){
			#$step2_arg_shell.="cd $step2_outdir_sub\nperl $ont_argpip $f .  $shdir/step2.ARG.anno/ONT\n\n";
			$step2_arg_shell.="cd $step2_outdir_sub\nperl $ont_argpip --data_list $f --outdir ./   --pathogen \"$tax\"  --shdir $shdir/step2.ARG.anno/ONT\n\n";
			open FF,$f;
			while(my $l=<FF>){
				chomp $l;
				my @or=split /\t/,$l;
				$ont_stat_list.="$or[0]\t$step2_outdir/$m/$or[0]/$or[0].stat.xls\n";
			}
			close FF;
		}else{
			die "未识别模拟数据测序平台\n";
		}
	}
	write_file("$step2_outdir/ONT.stat.list",$ont_stat_list) if $ont_stat_list;
	write_file("$step2_outdir/NS50.stat.list",$ns_stat_list) if $ns_stat_list;
	write_file("$step2_outdir/NS50.stat.filter.list",$ns_stat_list) if $ns_stat_list_filter;
	write_file("$shdir/step2.ARG.anno.sh",$step2_arg_shell);
	shell_box(*SH,"2) ARG anno analyse,type include: $type","step2.ARG.anno.sh");
}

if($step=~/3/){
	my $step3_outdir="$outdir/03.RSPredict.ROC";
	my $step3_1_outdir="$step3_outdir/01.RSPredict";
	my $step3_2_outdir="$step3_outdir/02.ROC";
	foreach ($step3_outdir,$step3_1_outdir,$step3_2_outdir){
		-d $_ || system "mkdir -p $_";
	}
	my @listarr;
	push @listarr,"$outdir/02.ARG.anno/ONT.stat.list" if -s "$outdir/02.ARG.anno/ONT.stat.list";
	push @listarr,"$outdir/02.ARG.anno/NS50.stat.list" if -s "$outdir/02.ARG.anno/NS50.stat.list";
	
	my $step3_1_shell;
	my $predict_list;
	foreach my $list(@listarr){
		open LL,$list;
		while(my $l=<LL>){
			chomp $l;
			my @or=split /\t/,$l;
			-d "$step3_1_outdir/$or[0]" || system "mkdir -p $step3_1_outdir/$or[0]";
			if($or[0]=~/^NS50/){
				#01.SimuReads.Coverage/02.Coverage/NS50/02.Coverage/NS50_10_GCA_000406405.1_repeat_1/NS50_10_GCA_000406405.1_repeat_1.cvg.bins.xls
				my $coverage_file="$outdir/01.SimuReads.Coverage/02.Coverage/NS50/02.Coverage/$or[0]/$or[0].cvg.bins.xls";
				$step3_1_shell.="cd $step3_1_outdir/$or[0]\nperl $argfilter $or[1] > $or[0].filter.stat.xls\nperl $statformat $or[0].filter.stat.xls  $coverage_file NS50  \"$tax\" > $or[0].drug_class_detectARGs.xls\nperl $nspredict $or[0].drug_class_detectARGs.xls > $or[0].predict.xls\n\n";
				$predict_list.="$or[0]\t$outdir/02.ARG.anno/NS50/03.Arg2AST/CARD/$or[0]/$or[0].predict.xls\n";
			}elsif($or[0]=~/^ONT/){
				#01.SimuReads.Coverage/02.Coverage/ONT/ONT_0.1_GCA_000406485.1_repeat_1/ONT_0.1_GCA_000406485.1_repeat_1.cvgstat
				my $coverage_file="$outdir/01.SimuReads.Coverage/02.Coverage/ONT/$or[0]/$or[0].cvgstat";
				$step3_1_shell.="cd $step3_1_outdir/$or[0]\nperl $argfilter $or[1] > $or[0].filter.stat.xls\nperl $statformat $or[0].filter.stat.xls  $coverage_file  ONT \"$tax\" > $or[0].drug_class_detectARGs.xls\nperl $ontpredict $or[0].drug_class_detectARGs.xls > $or[0].predict.xls\n\n";
				$predict_list.="$or[0]\t$outdir/02.ARG.anno/ONT/03.Arg2AST/CARD/$or[0]/$or[0].predict.xls\n";
			}
		}
		close LL;
	}
	write_file("$step3_1_outdir/total.predict.list",$predict_list) if $predict_list;
#	write_file("$shdir/step3.1.RS.predict.sh",$step3_1_shell);
#	shell_box(*SH,"3.1) RS predict ","step3.1.RS.predict.sh","predict");
	
	my $step3_2_shell.="perl $argroc $step3_1_outdir/total.predict.list $pheno --tax \"$tax\" --outdir $step3_2_outdir --shdir $shdir/step3.2.roc\n";
	write_file("$shdir/step3.2.roc.sh",$step3_2_shell);
	shell_box(*SH,"3.2) ROC Analyse ","step3.2.roc.sh");
}

if($step=~/4/){
	my $step4_stat_shell;
	my $step4_outdir="$outdir/04.stat";
	-d $step4_outdir || mkdir $step4_outdir;
	
	$step4_stat_shell.="cd $step4_outdir\nls $outdir/03.RSPredict.ROC/02.ROC/*/*/*/*.process.txt > total.process.list\nls $outdir/03.RSPredict.ROC/02.ROC/*/*/*/*.auc.ppv.npv > total.auc.ppv.npv.list\nperl $comb \"$tax\" $nextseq_cov $ont_cov  total.auc.ppv.npv.list total.process.list result\nls $step4_outdir/result/*/*/*.xls | perl -ne '{chomp;my \@or=split /\\//;my\$dir=join(\"/\",\@or[0..\$#or-1]);\$or[-3] = \"Nextseq\" if \$or[-3] eq \"NS50\";print \"cd \$dir\\nperl $line \$_ --title \\\"$tax \$or[-3] \$or[-2]\\\" \$or[-3]-\$or[-2].line.svg\\n$svg2xxx -t png -dpi 300 \$or[-3]-\$or[-2].line.svg\\n\\n\";}' > $shdir/step4.1.plotline.sh\nperl $phenostat $pheno > AST_SampleNum.stat.xls\n";
	write_file("$shdir/step4.stat.sh",$step4_stat_shell);
	shell_box(*SH,"4) AUC PPV NPV stat ","step4.stat.sh");
	shell_box(*SH,"5) Plot Line ","step4.1.plotline.sh","lineplot");
}
close SH;

$notrun || system "cd $shdir;sh run.MockReadsARG.sh";
#################################### 子函数  ###############################

sub shell_box{
#=============
    my ($handel,$STEP,$shell,$qopt,$bgrun) = @_;
    my $middle= $qopt ? "nohup time -p $super_worker --prefix $qopt $shell" : "nohup sh $shell >& $shell.log";
    my $end = "date +\"\%D \%T -> Finish $STEP\"";
    if($bgrun){
        (-s $bgrun) && `rm $bgrun`;
        if($qopt && $qopt !~ /-splitn\s+1\b/){
            $middle .= " --endsh '$end > $bgrun'";
        }else{
        #`echo '$end > $bgrun' >> $shell`;
        }
        $STEP .= " background";
        $middle .= " &";
        $end = " ";
    }
    print $handel "##$STEP\ndate +\"\%D \%T -> Start  $STEP\"\n$middle\n$end\n\n";
}
#==============
sub write_file{
#==============
    my $file = shift;
    open SSH,">$file" || die$!;
    for(@_){
        print SSH;
    }
    close SSH;
}
