#!/usr/bin/perl -w
use strict;

open IN,$ARGV[0];
my (%score,%uniq);
while(<IN>){
    /^sample/ && next;
    chomp;
    my @ll = split /\t/;
    $score{"$ll[0]\t$ll[3]"}=$ll[2];
    $uniq{$ll[2]} = 1;
    
}
close IN;
 
my @uniq_s = sort {$b <=> $a} keys %uniq;
my @sams = sort {$score{$b} <=> $score{$b}} keys %score;
open OUT,">performance0.stat";
print OUT "cutoff\tsensitivity\tspecifity\tPPV\tNPV\tpredictR_n\tpredictS_n\tastR_n\tastS_n\ttotal_sample_n\n";
my (@series,%report_R_n,%report_S_n,$total_astR_n,$total_astS_n,$total_sample_n);
for my $s0(@uniq_s){
    my ($predictR_astR,$predictR_astS,$predictS_astR,$predictS_astS)=(0,0,0,0);
    for my $sam(@sams){
	my $ast = (split /\t/,$sam)[1];
	my $predict = $score{$sam} >= $s0 ? "R" : "S";
	if($ast eq "R"){
	    $predict eq $ast ? ($predictR_astR++) : ($predictS_astR++);
	}else{
	    $predict eq $ast ? ($predictS_astS++) : ($predictR_astS++);
	}
    }
    my $predictR_n = $predictR_astR+$predictR_astS;
    my $predictS_n = $predictS_astR+$predictS_astS;
    my $astR_n = $predictR_astR+$predictS_astR;
    my $astS_n = $predictR_astS+$predictS_astS;
    my $total_n = $predictR_n+$predictS_n;
    my $sensitivity = sprintf "%.2f",($predictR_astR/($predictR_astR+$predictS_astR));
    my $specifity = sprintf "%.2f",($predictS_astS/($predictR_astS+$predictS_astS));
    my $ppv = $predictR_n == 0 ? 0 : (sprintf "%.2f",$predictR_astR/$predictR_n); 
    my $npv =  $predictS_n == 0 ? 0 : (sprintf "%.2f",$predictS_astS/$predictS_n);
    push @series,"$s0\t$ppv\t$npv";
    $report_R_n{$s0} = $predictR_n;
    $report_S_n{$s0} = $predictS_n;
    $total_astR_n ||= $astR_n;
    $total_astS_n ||= $astS_n;
    $total_sample_n ||= $total_n;
    print OUT "$s0\t$sensitivity\t$specifity\t$ppv\t$npv\t$predictR_n\t$predictS_n\t$astR_n\t$astS_n\t$total_n\n";
}
close OUT;

my (%combine,%discard);
my ($cutoff_R0,$cutoff_S0);
for my $i(0..$#series){
    my @aa = split /\t/,$series[$i];
    $aa[1] < 0.9 && next; #PPV > 0.9
    $cutoff_R0 = $aa[0];  #
    for my $j(0..$#series){
	$i>$j && next;
	my @bb = split /\t/,$series[$j];
	$bb[2] < 0.985 && next; #NPV >0.9
	my ($cutoff_R,$cutoff_S) = ($aa[0],$bb[0]);
	my ($predictR_astR,$predictR_astS,$predictS_astR,$predictS_astS)=(0,0,0,0);
	my ($discard_n,$discard_R_n,$discard_S_n) = (0,0,0);
	for my $sam(sort {$score{$b} <=> $score{$a}} keys %score){
	    my $ast = (split /\t/,$sam)[1];
	    if($score{$sam} < $cutoff_R && $score{$sam} >=$cutoff_S){
	        $discard_n++;
		$ast eq "R" ? ($discard_R_n++) : ($discard_S_n++);
		next;
	    }
	    my $predict = $score{$sam} >= $cutoff_R ? "R" : "S";
            if($ast eq "R"){
                $predict eq $ast ? ($predictR_astR++) : ($predictS_astR++);
            }else{
                $predict eq $ast ? ($predictS_astS++) : ($predictR_astS++);
            }
	}
	my $predictR_n = $predictR_astR+$predictR_astS;
        my $predictS_n = $predictS_astR+$predictS_astS;
        my $astR_n = $predictR_astR+$predictS_astR;
        my $astS_n = $predictR_astS+$predictS_astS;
        my $total_n = $predictR_n+$predictS_n;
        my $sensitivity = $astR_n == 0 ? 0 : (sprintf "%.2f",($predictR_astR/($predictR_astR+$predictS_astR)));
        my $specifity = $astS_n == 0 ? 0 : sprintf "%.2f",($predictS_astS/($predictR_astS+$predictS_astS));
        my $ppv = $predictR_n == 0 ? 0 : (sprintf "%.2f",$predictR_astR/$predictR_n);
        my $npv =  $predictS_n == 0 ? 0 : (sprintf "%.2f",$predictS_astS/$predictS_n);
	my $discard_rate = sprintf "%.2f",$discard_n/($total_n+$discard_n);
#	$discard_rate > 0.5 && next;
	$sensitivity < 0.8 && next;
	$specifity < 0.8 && next;
	$combine{"$cutoff_R\t$cutoff_S"} = "$cutoff_R\t$cutoff_S\t$sensitivity\t$specifity\t$ppv\t$npv\t$predictR_n:$predictS_n\t$total_n($astR_n:$astS_n)\t$discard_n($discard_R_n:$discard_S_n)\t$discard_rate";
	$discard{"$cutoff_R\t$cutoff_S"} = $discard_rate;
    }
}

my $ID=0;
my $ID0;
print "ID\tcutoff_R\tcutoff_S\tsensitivity\tspecifity\tPPV\tNPV\tpredictR_n:predictS_n\ttotal_report_n(astR_n:astS_n)\tdiscard_n(R:S)\tdiscard_rate\n";
my @combs = sort {$discard{$a}<=>$discard{$b}} keys %discard;
if(@combs){
    my $mark = 0;
    for my $k(@combs){
        $ID++;
        print "$ID\t$combine{$k}\n";
	my ($cutoff_R,$cutoff_S,$sensivity,$specifity)= (split /\t/,$combine{$k})[0,1,2,3];
	if($sensivity>=0.985 && $specifity>=0.90){
	    $mark++;
	    if ($mark == 1){$cutoff_R0 = $cutoff_R;$cutoff_S0 = $cutoff_S;$ID0 = $ID;}
	}
    }
}
$cutoff_R0 ||= "NA";
$cutoff_S0 ||= "NA";

$cutoff_R0 eq "NA" && ($report_R_n{$cutoff_R0} = 0);
$cutoff_S0 eq "NA" && ($report_S_n{$cutoff_S0} = 0);
print STDERR "$ID0\t$cutoff_R0\t$cutoff_S0\t$report_R_n{$cutoff_R0}\t$report_S_n{$cutoff_S0}\t$total_sample_n($total_astR_n:$total_astS_n)\n";

