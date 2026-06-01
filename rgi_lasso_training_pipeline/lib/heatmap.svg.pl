#!/usr/bin/perl  -w
use strict;
use Getopt::Long;
use FindBin qw($Bin);
my $mech="$Bin/anti.mechnism.list";
my $colorlist="$Bin/color.list";
use lib "/data/Yixue/gaojianpeng/BTK/Scripts/SVGplot/5.8.8/";
use SVG;
my ($height,$width, $flank_x,$flank_y,$opacity,$fontsize,$xgridN,$taxname,$drug,$gene_family,$color1,$color2);
GetOptions(
           "height:i"   => \$height,        "width:i"    => \$width,
           "flank_x:i"  => \$flank_x,       "flank_y:i"  => \$flank_y,
           "opacity:f"  => \$opacity,       "drug:s" => \$drug,     
           "xgridN:i"    => \$xgridN,		"taxname:s"=>\$taxname,
		   "gene_family"=>\$gene_family,
			"color1:s"=>\$color1,
			"color2:s"=>\$color2,
);
my ($infile,$outfile) = @ARGV;

#$width   ||= 200;
$width   ||= 800;
#$height  ||= 250;
$height  ||= 800;
$flank_y ||= $height / 5;
$flank_x ||= $flank_y;
$opacity ||= 1;
$fontsize ||= 12;
$xgridN ||=10;
my $pwidth  = $width + $flank_x * 2;
my $pheight = $height + $flank_y * 2;
#############
my %hash;
if ($gene_family){
	#$mech="/data/GensKey/Work/gaojianpeng/work/Medical_Department_Projects/Naiyao/Pepline/DrugResistantPredict_V0.3/database/card.info_level6.new.xls";
	$mech="/data/Yixue/gaojianpeng/Projects/AST/Ruijin_Pseudomonas_aeruginosa/Softs/ARGdetectV1.0/lib/card_db/card.info.xls";
}
open IN,$mech;
<IN>;
while(<IN>){
	chomp;
	my @or=split /\t/;
	if($gene_family){ #L3_arg_subfamily        Resistance_Mechanism
		$hash{$or[8]}=$or[21];
	}else{
		$or[0] = "Omp36" if $or[0] eq "Klebsiella aerogenes Omp36";
		$hash{$or[0]}=$or[1];
	}
}
close IN;

my %color1;
if ($color1 && -s $color1 ){
	open IN,$color1;
	while(<IN>){
		chomp;
		my @or=split /\t/;
		$color1{$or[0]}=1;
	}
	close IN;
}

my %color2;
if ($color2 && -s $color2){
	open IN,$color2;
	while(<IN>){
		chomp;
		my @or=split /\t/;
		$color2{$or[0]}=1;
	}
	close IN;
}

open IN,$colorlist;
my %col;
while(<IN>){
	chomp;
	my @or=split /\t/;
	$col{$.}=$or[0];
}
close IN;
############ 输入文件处理
open IN,$infile;
my $one=<IN>;
chomp $one;
my @title=split /\t/,$one;
my @genes=@title;
shift @genes;pop @genes;pop @genes;
my %genecolor;
my $m=0;
foreach my $g (0..$#genes){
	#print $genes[$g],"\n" unless $hash{$genes[$g]};
	#print "$hash{$genes[$g]}\n";
	$hash{$genes[$g]}||="Unknown";
	if($genecolor{$hash{$genes[$g]}}){
		next;
	}else{
		$m++;
		$genecolor{$hash{$genes[$g]}}=$col{$m};
	}
}

my $gn=scalar @genes;
my %num;
my %value;
my @genomes;
my %rs;
while(<IN>){
	chomp;
	my @or=split /\t/;
	push @genomes,$or[0];
	for my $i(1..$#or-2){
		if ($or[$i] ne "NA"){
			$num{$or[$i]}=1;
		}
		$value{$or[0]}{$title[$i]}=$or[$i];
		$rs{$or[0]}{True}=$or[-2];
		$rs{$or[0]}{Predict}=$or[-1];
	}
}
close IN;

my $geno_height=$height/scalar(@genomes);#热图单个格子高度
my $gene_width=$width/((scalar(@title)-3)+2.5);#热图单个格子宽度

##############################################
my @nsort=sort {$a<=>$b} keys %num;
my %bili;
foreach my $i (0..$#nsort){
	$bili{$nsort[$i]}=($i+1)/scalar(@nsort); #权重越高，对应的系数越大
	#print $nsort[$i],"\t",($i+1)/scalar(@nsort),"\n";
}
#------------------------------- main --------------------------------
my $svg = SVG->new(width=> $pwidth,height=> $pheight);
#################### 左右热图文字标注 ##################

if($#nsort==1){
	my $text_gene_xloci=$flank_x+$gene_width*($#nsort+1)/2-$gene_width*0.8;
	my $text_gene_yloci=$flank_y+$height+5;
	$svg->text('x',$text_gene_xloci,'y',$text_gene_yloci,'-cdata',"Resistance gene content",'font-family','Arial', 'font-size',5.5,'font-weight','bold');		
	my $text_ast_xloci=$flank_x+$gene_width*($#nsort+1.8);
	my $text_ast_yloci=$flank_y+$height+5;
	$svg->text('x',$text_ast_xloci,'y',$text_ast_yloci,'-cdata',"Phenotypic AST",'font-family','Arial', 'font-size',5.5,'font-weight','bold');
}elsif($#nsort==0){
	my $text_gene_xloci=$flank_x+$gene_width*($#nsort+1)/2-$gene_width*0.5;
	my $text_gene_yloci=$flank_y+$height+5;
	$svg->text('x',$text_gene_xloci,'y',$text_gene_yloci,'-cdata',"Resistance gene content",'font-family','Arial', 'font-size',5.5,'font-weight','bold');		
	my $text_ast_xloci=$flank_x+$gene_width*($#nsort+2);
	my $text_ast_yloci=$flank_y+$height+5;
	$svg->text('x',$text_ast_xloci,'y',$text_ast_yloci,'-cdata',"Phenotypic AST",'font-family','Arial', 'font-size',5.5,'font-weight','bold');
}else{
	my $text_gene_xloci=$flank_x+$gene_width*($#nsort+1)/2-$gene_width*1.2;
	my $text_gene_yloci=$flank_y+$height+5;
	$svg->text('x',$text_gene_xloci,'y',$text_gene_yloci,'-cdata',"Resistance gene content",'font-family','Arial', 'font-size',5.5,'font-weight','bold');		
	my $text_ast_xloci=$flank_x+$gene_width*($#nsort+1.5);
	my $text_ast_yloci=$flank_y+$height+5;
	$svg->text('x',$text_ast_xloci,'y',$text_ast_yloci,'-cdata',"Phenotypic AST",'font-family','Arial', 'font-size',5.5,'font-weight','bold');
}

#################### 左侧热图图例 #######################
if($#nsort==1){
	foreach my $i (0..$#nsort){
		my $legend_xloci=$flank_x+$gene_width*($#nsort+1)/2-$gene_width*0.8;
		my $legend_yloci=$flank_y+$height+10+$i*1;
		$svg->rect('x',$legend_xloci,'y',$legend_yloci,'width',$gene_width*0.5,'height',1,'fill',"#FF0000",'fill-opacity',(scalar(@nsort)-$i)/scalar(@nsort));
	}
	my $legend_text_xloci=$flank_x+$gene_width*($#nsort+1)/2-$gene_width*0.8+$gene_width*0.5+1;
	my $legend_text_yloci=$flank_y+$height+10+(scalar(@nsort)/1.5);
	$svg->text('x',$legend_text_xloci,'y',$legend_text_yloci,'-cdata',"DeepAMR",'font-family','Arial', 'font-size',4.5,'font-weight','bold');	
}elsif($#nsort==0){
	foreach my $i (0..$#nsort){
		my $legend_xloci=$flank_x+$gene_width*($#nsort+1)/2-$gene_width*0.5;
		my $legend_yloci=$flank_y+$height+10+$i*1;
		$svg->rect('x',$legend_xloci,'y',$legend_yloci,'width',$gene_width*0.5,'height',1,'fill',"#FF0000",'fill-opacity',(scalar(@nsort)-$i)/scalar(@nsort));
	}
	my $legend_text_xloci=$flank_x+$gene_width*($#nsort+1)/2-$gene_width*0.5+$gene_width*0.5+1;
	my $legend_text_yloci=$flank_y+$height+10+(scalar(@nsort)/1.5);
	$svg->text('x',$legend_text_xloci,'y',$legend_text_yloci,'-cdata',"DeepAMR",'font-family','Arial', 'font-size',4.5,'font-weight','bold');	
}else{
	foreach my $i (0..$#nsort){
		my $legend_xloci=$flank_x+$gene_width*($#nsort+1)/2-$gene_width;
		my $legend_yloci=$flank_y+$height+10+$i*1;
		$svg->rect('x',$legend_xloci,'y',$legend_yloci,'width',$gene_width,'height',1,'fill',"#FF0000",'fill-opacity',(scalar(@nsort)-$i)/scalar(@nsort));
	}
	my $legend_text_xloci=$flank_x+$gene_width*($#nsort+1)/2+$gene_width/4;
	my $legend_text_yloci=$flank_y+$height+10+(scalar(@nsort)/1.5);
	$svg->text('x',$legend_text_xloci,'y',$legend_text_yloci,'-cdata',"DeepAMR",'font-family','Arial', 'font-size',4.5,'font-weight','bold');	
}

#################### 右侧热图图例 #######################
if($#nsort==1){
	my $legend_r_xloci=$flank_x+$gene_width*($gn+0.7);
	my $legend_r_yloci=$flank_y+$height+11;
	$svg->rect('x',$legend_r_xloci,'y',$legend_r_yloci,'width',$gene_width*0.5,'height',2.5,'fill',"#FF4500",'fill-opacity',1); #R
	my $legend_r_test_xloci=$flank_x+$gene_width*($gn+0.7)+$gene_width*0.5+1;
	my $legend_r_text_yloci=$flank_y+$height+14;
	$svg->text('x',$legend_r_test_xloci,'y',$legend_r_text_yloci,'-cdata',"Resistant",'font-family','Arial', 'font-size',4.5,'font-weight','bold');	

	my $legend_s_xloci=$flank_x+$gene_width*($gn+0.7);
	my $legend_s_yloci=$flank_y+$height+16;
	$svg->rect('x',$legend_s_xloci,'y',$legend_s_yloci,'width',$gene_width*0.5,'height',2.5,'fill',"#1E90FF",'fill-opacity',1); #S
	my $legend_s_test_xloci=$flank_x+$gene_width*($gn+0.7)+$gene_width*0.5+1;
	my $legend_s_text_yloci=$flank_y+$height+19;
	$svg->text('x',$legend_s_test_xloci,'y',$legend_s_text_yloci,'-cdata',"Sensitive",'font-family','Arial', 'font-size',4.5,'font-weight','bold');	
}elsif($#nsort==0){
	my $legend_r_xloci=$flank_x+$gene_width*($gn+1);
	my $legend_r_yloci=$flank_y+$height+11;
	$svg->rect('x',$legend_r_xloci,'y',$legend_r_yloci,'width',$gene_width*0.5,'height',2.5,'fill',"#FF4500",'fill-opacity',1); #R
	my $legend_r_test_xloci=$flank_x+$gene_width*($gn+1)+$gene_width*0.5+1;
	my $legend_r_text_yloci=$flank_y+$height+14;
	$svg->text('x',$legend_r_test_xloci,'y',$legend_r_text_yloci,'-cdata',"Resistant",'font-family','Arial', 'font-size',4.5,'font-weight','bold');	

	my $legend_s_xloci=$flank_x+$gene_width*($gn+1);
	my $legend_s_yloci=$flank_y+$height+16;
	$svg->rect('x',$legend_s_xloci,'y',$legend_s_yloci,'width',$gene_width*0.5,'height',2.5,'fill',"#1E90FF",'fill-opacity',1); #S
	my $legend_s_test_xloci=$flank_x+$gene_width*($gn+1)+$gene_width*0.5+1;
	my $legend_s_text_yloci=$flank_y+$height+19;
	$svg->text('x',$legend_s_test_xloci,'y',$legend_s_text_yloci,'-cdata',"Sensitive",'font-family','Arial', 'font-size',4.5,'font-weight','bold');	

}else{
	my $legend_r_xloci=$flank_x+$gene_width*($gn+0.5);
	my $legend_r_yloci=$flank_y+$height+11;
	$svg->rect('x',$legend_r_xloci,'y',$legend_r_yloci,'width',$gene_width,'height',2.5,'fill',"#FF4500",'fill-opacity',1); #R
	my $legend_r_test_xloci=$flank_x+$gene_width*($gn+0.5)+$gene_width+1;
	my $legend_r_text_yloci=$flank_y+$height+14;
	$svg->text('x',$legend_r_test_xloci,'y',$legend_r_text_yloci,'-cdata',"Resistant",'font-family','Arial', 'font-size',4.5,'font-weight','bold');	

	my $legend_s_xloci=$flank_x+$gene_width*($gn+0.5);
	my $legend_s_yloci=$flank_y+$height+16;
	$svg->rect('x',$legend_s_xloci,'y',$legend_s_yloci,'width',$gene_width,'height',2.5,'fill',"#1E90FF",'fill-opacity',1); #S
	my $legend_s_test_xloci=$flank_x+$gene_width*($gn+0.5)+$gene_width+1;
	my $legend_s_text_yloci=$flank_y+$height+19;
	$svg->text('x',$legend_s_test_xloci,'y',$legend_s_text_yloci,'-cdata',"Sensitive",'font-family','Arial', 'font-size',4.5,'font-weight','bold');	
}
################## 左侧热图 ######################
foreach my $geno (0..$#genomes){
	foreach my $gene (0..$#genes){
		if($value{$genomes[$geno]}{$title[$gene+1]} ne "NA"){
			my $fill= $color1{$title[$gene+1]} ? "#0000FF" : $color2{$title[$gene+1]} ? "#008000" :"#FF0000";
			$svg->rect('x',$flank_x+$gene*$gene_width,'y',$flank_y+$geno*$geno_height,'width',$gene_width,'height',$geno_height,'fill',$fill,'fill-opacity',1); # #FFDEAD 
		}else{
			#$svg->rect('x',$flank_x+$gene*$gene_width,'y',$flank_y+$geno*$geno_height,'width',$gene_width,'height',$geno_height,'fill',"#FF0000",'fill-opacity',$bili{$value{$genomes[$geno]}{$title[$gene+1]}});
			$svg->rect('x',$flank_x+$gene*$gene_width,'y',$flank_y+$geno*$geno_height,'width',$gene_width,'height',$geno_height,'fill',"#D3D3D3",'fill-opacity',1);
		}
	}
}
#################### 基因名称  ########################################
my %used_color;
foreach my $gene (0..$#genes){
	my $xloci=$flank_x+($gene_width/3)+$gene*$gene_width;
	my $yloci=$flank_y-5;
#	$svg->text('x',$xloci,'y',$yloci,'-cdata',$genes[$gene] ,'font-family','Arial', 'font-size',4.5,'font-weight','bold',"transform","rotate(-45,$xloci,$yloci)");	#基因不着色
	#$svg->text('x',$xloci,'y',$yloci,'-cdata',$genes[$gene] ,'font-family','Arial', 'font-size',9,'font-weight','bold',"transform","rotate(-45,$xloci,$yloci)",'fill',$genecolor{$hash{$genes[$gene]}});	 #color
	$svg->text('x',$xloci,'y',$yloci,'-cdata',$genes[$gene] ,'font-family','Arial', 'font-size',15,'font-weight','bold',"transform","rotate(-45,$xloci,$yloci)");	 #color
	$used_color{$hash{$genes[$gene]}}++;
}
################## 耐药机制图例 #######################################
my $mm=0;
my $mech_xloci=$flank_x*0.1;
my $mech_yloci=$flank_y-43;
#$svg->text('x',$mech_xloci,'y',$mech_yloci,'-cdata',"Resistance Mechanism" ,'font-family','Arial', 'font-size',10,'font-weight','bold');
foreach my $me (sort {$used_color{$b} <=> $used_color{$a}} keys %used_color){
	my $legend_mech_rect_xloci=$flank_x*0.1;
	my $legend_mech_rect_yloci=$flank_y-40+$mm*4;
#	$svg->rect('x',$legend_mech_rect_xloci,'y',$legend_mech_rect_yloci,'width',3,'height',3,'fill',$genecolor{$me},'fill-opacity',1);

	my $legend_mech_text_xloci=$flank_x*0.1+4;
	my $legend_mech_text_yloci=$flank_y-37.5+$mm*4;
	$me = "Omp36" if $me eq "Klebsiella aerogenes Omp36";
#	print "$me\n";
#	$svg->text('x',$legend_mech_text_xloci,'y',$legend_mech_text_yloci,'-cdata',$me ,'font-family','Arial', 'font-size',5,'font-weight','bold','fill',$genecolor{$me});
	$mm++;
}

#################  表型   ###################
my $text_true_xloci=$flank_x+$gene_width*($gn+0.5)+($gene_width/3);
my $text_true_yloci=$flank_y-5;
$svg->text('x',$text_true_xloci,'y',$text_true_yloci,'-cdata',$drug ,'font-family','Arial', 'font-size',11,'font-weight','bold',"transform","rotate(-45,$text_true_xloci,$text_true_yloci)");

my $text_predict_xloci=$flank_x+$gene_width*($gn+1.5)+($gene_width/3);
my $text_predict_yloci=$flank_y-5;
$svg->text('x',$text_predict_xloci,'y',$text_predict_yloci,'-cdata',"Predict" ,'font-family','Arial', 'font-size',11,'font-weight','bold',"transform","rotate(-45,$text_predict_xloci,$text_predict_yloci)");	

################## 物种名称 ################
my $taxname_xloci=$flank_x*0.9;
my $taxname_yloci=$flank_y+$height*0.6;
$svg->text('x',$taxname_xloci,'y',$taxname_yloci,'-cdata',$taxname,'font-family','Arial', 'font-size',10,'font-weight','bold',"transform","rotate(-90,$taxname_xloci,$taxname_yloci)",'font-style',"italic");	
#################### 右侧热图  ##########################################
foreach my $geno(0..$#genomes){

	if($rs{$genomes[$geno]}{True} eq "R"){
		$svg->rect('x',$flank_x+($gn+0.5)*$gene_width,'y',$flank_y+$geno*$geno_height,'width',$gene_width,'height',$geno_height,'fill',"#FF4500",'fill-opacity',1);
	}else{
		$svg->rect('x',$flank_x+($gn+0.5)*$gene_width,'y',$flank_y+$geno*$geno_height,'width',$gene_width,'height',$geno_height,'fill',"#1E90FF",'fill-opacity',1);
	}
	
	if($rs{$genomes[$geno]}{Predict} eq "R"){
		$svg->rect('x',$flank_x+($gn+1.5)*$gene_width,'y',$flank_y+$geno*$geno_height,'width',$gene_width,'height',$geno_height,'fill',"#FF4500",'fill-opacity',1);
	}else{
		$svg->rect('x',$flank_x+($gn+1.5)*$gene_width,'y',$flank_y+$geno*$geno_height,'width',$gene_width,'height',$geno_height,'fill',"#1E90FF",'fill-opacity',1);
	}
}

open OUT, ">$outfile" || die $!; 
print OUT $svg->xmlify;
close OUT;
###=======   Sub   =======##
sub avg{
    my ($avg,$total);
    foreach (@_){
        $total += $_;
    }
    $avg=$total/scalar(@_);
    return $avg;
}
sub max{
    my $max_present = $_[0];
    foreach (@_)    {
        $max_present = $_ if ($_ > $max_present);
    }
    $max_present;
}

