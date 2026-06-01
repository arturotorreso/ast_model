#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Getopt::Long;
#my %opt=();
#GetOptions(\%opt,"arg2taxon:s","focus_species:s");
@ARGV || die "Usage: perl $0 <patho_ARG.detect> > predict.xls
Version: 1.0,20210316
Contact: p.han\@genskey.com\n\n";

#============ 文件配置 ===========
my $feature_weight = "/data/GensKey/Work/hanpeng/01.Product_tech/naiyao/02.predict_AST/01.key_feature/feature_weight.xls";  #20210503
my $drug_class_db = "/data/GensKey/Work/hanpeng/01.Product_tech/naiyao/02.predict_AST/ONT_vs_NGS/ONT/script//report_db/drug_class.xls";
my $report = "/data/GensKey/Work/hanpeng/01.Product_tech/naiyao/02.predict_AST/01.key_feature/focus_patho_drug.report"; #20210503

#===== 关键基因及其权重系数 ======
open IN,$feature_weight || die $!;
my (%arg_weight,%argfamily_weight);
while(<IN>){
    chomp;
    /^#/ && next;
    my @ll = split /\t/;
    $arg_weight{$ll[0]}{$ll[1]}{$ll[6]} = $ll[7];
    $argfamily_weight{$ll[0]}{$ll[1]}{$ll[4]} = $ll[5];
}
close IN;

#===== 药物分类 =====
my (%drug_class,%drug_name,%class_name);
open DC,$drug_class_db;
while(<DC>){
    chomp;
    /^#/ && next;
    my @ll = split /\t/;
    $ll[8] = lc($ll[8]);
    $drug_class{$ll[8]} = $ll[7];
}
close DC;

#============ main function ==============
open IN,$ARGV[0] || die $!;
my (%patho_ARGdetect,%patho_cov,%patho_rn);
while(<IN>){
    chomp;
    /^#/ && next;
    my @ll = split /\t/;
    $patho_ARGdetect{$ll[0]}{$ll[1]} = $ll[2];
    $patho_cov{$ll[0]} = $ll[3];  #以检出的基因组覆盖度，作为评价数据量的指标
    $patho_rn{$ll[0]} = $ll[5];
}
close IN;

###针对关注的病原菌-药物，预测表型
open IN,$report || die $!;
my %uniq_ARG_family;
print "#Patho\tdrug\tdetect_ARGs\tscores\tcutoff\tpredict\taccuracy\tpatho_rn\tpatho_coverage\n";
while(<IN>){
    chomp;
    my @ll = split /\t/;
    $ll[2] eq "-" && next;  #比较关注的药物，但目前未进行训练
#    $ll[0] eq "Klebsiella pneumoniae" || next;
    if($patho_cov{$ll[0]}){
        my ($drug_class,$drug) = split /:/,$ll[1];
	$patho_ARGdetect{$ll[0]}{$drug_class} ||= ""; #所关注的病原菌及其药物分类相关基因，无检出
        my @args = split /;/,$patho_ARGdetect{$ll[0]}{$drug_class}; #当前病原菌对应药物的相关基因检出
        my ($report_args,$scores) = ("",0); #
#$drug_class eq "aminoglycoside antibiotic" || next;
#$drug eq "gentamicin" || next;
        for my $arg(@args){
	    my @aa = split /--/,$arg;
	    my $L4_arg_family = $1 if($aa[0]=~/^(.+?)\([\d]+\)$/);
	    my $arg_family = $1 if($aa[1]=~/^(.+?)\([\d]+\)$/);
	    $argfamily_weight{$ll[0]}{$ll[1]}{$arg_family} ||= 0; #基因家族权重系数,训练模型结果中没有的，设置为0
	    my ($arg0,$arg0_rn) = ($1,$2) if($aa[2]=~/(.+?)\(([\d]+)\|[\.\d]+\)$/);
	    $arg_weight{$ll[0]}{$ll[1]}{$arg0} ||= 0; #基因权重系数,训练模型结果中没有的，设置为0 
	    $argfamily_weight{$ll[0]}{$ll[1]}{$arg_family} <= 0 && next;
	    if($arg0_rn > 0){
		if($arg_weight{$ll[0]}{$ll[1]}{$arg0} > 0){
		    $report_args .= "$arg0;";
	            $scores += $arg_weight{$ll[0]}{$ll[1]}{$arg0};
	        }else{
		    if($argfamily_weight{$ll[0]}{$ll[1]}{$arg_family} > 0 && $L4_arg_family !~ /efflux pump/){
			$uniq_ARG_family{$ll[0]}{$ll[1]}{$arg_family}++;
			if($uniq_ARG_family{$ll[0]}{$ll[1]}{$arg_family} == 1){
			    $report_args .= "$arg_family;";
			    $scores += $argfamily_weight{$ll[0]}{$ll[1]}{$arg_family};
			}
		    }
	    	}
	    }else{
		if($argfamily_weight{$ll[0]}{$ll[1]}{$arg_family} > 0 && $L4_arg_family !~ /efflux pump/){
		    $uniq_ARG_family{$ll[0]}{$ll[1]}{$arg_family}++;
		    if($uniq_ARG_family{$ll[0]}{$ll[1]}{$arg_family} == 1){
		        $report_args .= "$arg_family;";
		        $scores += $argfamily_weight{$ll[0]}{$ll[1]}{$arg_family};
		    }
		}
	    }
        }
	$report_args ||= "not_detect";
        $report_args =~ s/;$//;
	$patho_cov{$ll[0]} eq "-" && ($patho_cov{$ll[0]} = 1);
        my $predict_ast = $scores >= $ll[2] ? "R" : ($patho_cov{$ll[0]} > 38 && $ll[3] > 0.75) ? "S" : "/";
        my $accuracy = $predict_ast ne "/" ? $ll[3] : "/";
	$patho_rn{$ll[0]} > 10 && (print "$ll[0]\t$ll[1]\t$report_args\t$scores\t$ll[2]\t$predict_ast\t$accuracy\t$patho_rn{$ll[0]}\t$patho_cov{$ll[0]}\n");
    }
}
close IN;

