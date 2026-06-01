#!/usr/bin/perl  -w
use strict;
use Getopt::Long;
use FindBin qw($Bin);
my $colorlist="$Bin/color.list";
use lib "/data/GensKey/Work/gaojianpeng/work/Tools/Software/svg/SVG-2.84/lib/";
use SVG;
my ($height,$width, $flank_x,$flank_y);
my ($title,$xgridN);
GetOptions(
	
           "height:i"   => \$height,        "width:i"    => \$width,
           "flank_x:i"  => \$flank_x,       "flank_y:i"  => \$flank_y,
           "xgridN:i" =>\$xgridN,

			"title:s" => \$title,    
);
my ($infile,$outfile) = @ARGV;

$width   ||= 650;
$height  ||= 1300;
$flank_y ||= $height /6.3;
$flank_x ||= $flank_y;
my $pwidth  = $width + $flank_x * 2;
my $pheight = $height + $flank_y * 2;

#-----------------------------  字体大小  ------------------------
my $title_size=15;
my $xfontsize;
my $yfontsize;
$xfontsize=$yfontsize;
$xfontsize=11;

#------------------------------ 颜色 --------------------------------
my $xcolor ||= 'black';
my $ycolor ||= 'black';

open IN,$colorlist;
my %col;
while(<IN>){
    chomp;
    my @or=split /\t/;
    $col{$.}=$or[0];
}
close IN;
my %miny;
open IN,$infile;
while(<IN>){
	chomp;
	my @or=split /\t/;
	push @{$miny{$or[1]}},$or[4];	
	push @{$miny{$or[1]}},$or[5];	
	push @{$miny{$or[1]}},$or[6];	
}
close IN;
my %miny2;
foreach my $drug(sort keys %miny){
	my @tmp=sort {$a <=> $b} @{$miny{$drug}};
#	$miny2{$drug}=int($tmp[0]*10)/10; #每个药物展示的下限AUC/PPV/NPV 值，可以不展示出大片空白 
	#$miny2{$drug}=0.3;  #统一下限都为0.5
	$miny2{$drug}=0;  #统一下限都为0.5
}
#------------------------------- main --------------------------------
my $svg = SVG->new(width=> $pwidth,height=> $pheight);
$xgridN||= `awk '{print \$3}' $infile | sort |uniq |wc -l`; #梯度的种类
my $drug_type_n=`awk '{print \$2}' $infile | sort |uniq |wc -l`;
chomp $drug_type_n;
my $drug_height=$height/$drug_type_n; #每种药物的纵轴长度
chomp $xgridN;
my $grid_len =$width/($xgridN+1);
open IN,$infile;
my $ii=1;
my $dd=0;
my (%xlabel,%ppv,%npv,%auc,%uniq,%ploted);
while(<IN>){
	chomp;
	my @or=split /\t/;
	#$xlabel{$ii}="$or[2]X:$or[3]";
	$xlabel{$ii}="$or[2]X";
	$ppv{$or[1]}{$ii}=$or[4]; #PPV
	$npv{$or[1]}{$ii}=$or[5]; #NPV
	$auc{$or[1]}{$ii}=$or[6]; #AUC
	unless($uniq{$or[1]}){
		$dd++;
		$uniq{$or[1]}=$dd;
		if($dd!=$drug_type_n){
			my $line_up_start_xloci=$flank_x;
			my $line_up_start_yloci=$flank_y+$dd*$drug_height;
			my $line_up_end_xloci=$flank_x+$width;
			my $line_up_end_yloci=$flank_y+$dd*$drug_height;
			$svg->line('x1',$line_up_start_xloci,'y1',$line_up_start_yloci, 'x2',$line_up_end_xloci,'y2',$line_up_end_yloci,'stroke', $xcolor, 'stroke-width', 1);#刻度线
		}
		my $suoxie_txt_xloci=$flank_x+$width*($xgridN-1)/$xgridN+20;
		my $suoxie_txt_yloci=$flank_y+($dd-1)*$drug_height+$drug_height*0.48;
		$svg->text('x',$suoxie_txt_xloci,'y',$suoxie_txt_yloci,'-cdata',$or[1],'font-family','Arial', 'font-size',$xfontsize+5,'font-weight','bold');# 药物缩写 
	
		## Y 轴刻度线
		#my $y_grid_len=$drug_height*0.8/7;
		my $y_grid_len=$drug_height*0.8/10;
#		foreach my $i (0..7){
		foreach my $i (0..10){
			my $line_ygrid_start_xloci=$flank_x;
			my $line_ygrid_start_yloci=$flank_y+$drug_height*(0.1)+$i*$y_grid_len+($dd-1)*$drug_height;
			my $line_ygrid_end_xloci=$flank_x-3;
			my $line_ygrid_end_yloci=$flank_y+$drug_height*(0.1)+$i*$y_grid_len+($dd-1)*$drug_height;
			$svg->line('x1',$line_ygrid_start_xloci,'y1',$line_ygrid_start_yloci, 'x2',$line_ygrid_end_xloci,'y2',$line_ygrid_end_yloci,'stroke', $xcolor, 'stroke-width', 1);#刻度线
		}
		foreach my $i (qw/0 2 4 6 8 10/){
			my $txt_ygrid_xloci=$flank_x-15;
			my $txt_ygrid_yloci=$flank_y+$drug_height*(0.1)+$i*$y_grid_len+($dd-1)*$drug_height+3;
#			my $x_txt=sprintf("%.1f",1-($i-1)*(1-$miny2{$or[1]})/5);
			my $x_txt=sprintf("%.1f",1-$i*0.1);
			#print $x_txt,"\n";
			$svg->text('x',$txt_ygrid_xloci,'y',$txt_ygrid_yloci,'-cdata',$x_txt,'font-family','Arial', 'font-size',$xfontsize,'text-anchor','middle','font-weight','bold');#刻度值
		}
	}
	#纵坐标组成：flank_y + 药物步长*$dd  + 数据转换后的长度
	#print $ii,"\n";
	my $point_xloci_ppv=$flank_x+$ii*$grid_len;
	my $point_yloci_ppv=$flank_y+$drug_height*(0.1)+(1-$or[4])/(1-$miny2{$or[1]})*$drug_height*0.8+($dd-1)*$drug_height; #PPV
	$svg->circle('cx',$point_xloci_ppv,'cy',$point_yloci_ppv,'r',2,'stroke',$col{1},'fill',$col{1});
	
	my $point_xloci_npv=$flank_x+$ii*$grid_len;
	my $point_yloci_npv=$flank_y+$drug_height*(0.1)+(1-$or[5])/(1-$miny2{$or[1]})*$drug_height*0.8+($dd-1)*$drug_height;  #NPV
	$svg->circle('cx',$point_xloci_npv,'cy',$point_yloci_npv,'r',2,'stroke',$col{2},'fill',$col{2});
	
	my $point_xloci_auc=$flank_x+$ii*$grid_len;
	my $point_yloci_auc=$flank_y+$drug_height*(0.1)+(1-$or[6])/(1-$miny2{$or[1]})*$drug_height*0.8+($dd-1)*$drug_height; #AUC 
	$svg->circle('cx',$point_xloci_auc,'cy',$point_yloci_auc,'r',2,'stroke',$col{3},'fill',$col{3});

	if($ii<$xgridN){
		$ii++;
	}else{
		$ii=1;
	}
}
close IN;
###折线
foreach my $drug (sort {$uniq{$a} <=> $uniq{$b}} keys %uniq){ #药物  编号1-9
	foreach my $i (1..$xgridN-1){
		my $line_start_xloci_ppv=$flank_x+$i*$grid_len;
		my $line_start_yloci_ppv=$flank_y+$drug_height*(0.1)+(1-$ppv{$drug}{$i})/(1-$miny2{$drug})*$drug_height*0.8+($uniq{$drug}-1)*$drug_height;
		my $line_end_xloci_ppv=$flank_x+($i+1)*$grid_len;
		my $line_end_yloci_ppv=$flank_y+$drug_height*(0.1)+(1-$ppv{$drug}{$i+1})/(1-$miny2{$drug})*$drug_height*0.8+($uniq{$drug}-1)*$drug_height;
		$svg->line('x1',$line_start_xloci_ppv,'y1',$line_start_yloci_ppv, 'x2',$line_end_xloci_ppv,'y2',$line_end_yloci_ppv,'stroke',$col{1}, 'stroke-width', 2);
	
		my $line_start_xloci_npv=$flank_x+$i*$grid_len;
		my $line_start_yloci_npv=$flank_y+$drug_height*(0.1)+(1-$npv{$drug}{$i})/(1-$miny2{$drug})*$drug_height*0.8+($uniq{$drug}-1)*$drug_height;
		my $line_end_xloci_npv=$flank_x+($i+1)*$grid_len;
		my $line_end_yloci_npv=$flank_y+$drug_height*(0.1)+(1-$npv{$drug}{$i+1})/(1-$miny2{$drug})*$drug_height*0.8+($uniq{$drug}-1)*$drug_height;
		$svg->line('x1',$line_start_xloci_npv,'y1',$line_start_yloci_npv, 'x2',$line_end_xloci_npv,'y2',$line_end_yloci_npv,'stroke',$col{2}, 'stroke-width', 2);

		my $line_start_xloci_auc=$flank_x+$i*$grid_len;
		my $line_start_yloci_auc=$flank_y+$drug_height*(0.1)+(1-$auc{$drug}{$i})/(1-$miny2{$drug})*$drug_height*0.8+($uniq{$drug}-1)*$drug_height;
		my $line_end_xloci_auc=$flank_x+($i+1)*$grid_len;
		my $line_end_yloci_auc=$flank_y+$drug_height*(0.1)+(1-$auc{$drug}{$i+1})/(1-$miny2{$drug})*$drug_height*0.8+($uniq{$drug}-1)*$drug_height;
		$svg->line('x1',$line_start_xloci_auc,'y1',$line_start_yloci_auc, 'x2',$line_end_xloci_auc,'y2',$line_end_yloci_auc,'stroke',$col{3}, 'stroke-width', 2);
	}
}
#折线图例
my $leg_line_start_xloci_ppv=$flank_x+$width+5;
my $leg_line_start_yloci_ppv=$flank_y+$height*0.47;
my $leg_line_end_xloci_ppv=$flank_x+$width+25;
my $leg_line_end_yloci_ppv=$flank_y+$height*0.47;
$svg->line('x1',$leg_line_start_xloci_ppv,'y1',$leg_line_start_yloci_ppv, 'x2',$leg_line_end_xloci_ppv,'y2',$leg_line_end_yloci_ppv,'stroke',$col{1}, 'stroke-width', 5);
my $legtxt_line_start_xloci_ppv=$flank_x+$width+30;
my $legtxt_line_start_yloci_ppv=$flank_y+$height*0.47+3;
$svg->text('x',$legtxt_line_start_xloci_ppv,'y',$legtxt_line_start_yloci_ppv,'-cdata',"PPV",'font-family','Arial', 'font-size',$xfontsize+3,'font-weight','bold');#刻度值

my $leg_line_start_xloci_npv=$flank_x+$width+5;
my $leg_line_start_yloci_npv=$flank_y+$height*0.5;
my $leg_line_end_xloci_npv=$flank_x+$width+25;
my $leg_line_end_yloci_npv=$flank_y+$height*0.5;
$svg->line('x1',$leg_line_start_xloci_npv,'y1',$leg_line_start_yloci_npv, 'x2',$leg_line_end_xloci_npv,'y2',$leg_line_end_yloci_npv,'stroke',$col{2}, 'stroke-width', 5);
my $legtxt_line_start_xloci_npv=$flank_x+$width+30;
my $legtxt_line_start_yloci_npv=$flank_y+$height*0.5+3;
$svg->text('x',$legtxt_line_start_xloci_npv,'y',$legtxt_line_start_yloci_npv,'-cdata',"NPV",'font-family','Arial', 'font-size',$xfontsize+3,'font-weight','bold');#刻度值

my $leg_line_start_xloci_auc=$flank_x+$width+5;
my $leg_line_start_yloci_auc=$flank_y+$height*0.53;
my $leg_line_end_xloci_auc=$flank_x+$width+25;
my $leg_line_end_yloci_auc=$flank_y+$height*0.53;
$svg->line('x1',$leg_line_start_xloci_auc,'y1',$leg_line_start_yloci_auc, 'x2',$leg_line_end_xloci_auc,'y2',$leg_line_end_yloci_auc,'stroke',$col{3}, 'stroke-width', 5);
my $legtxt_line_start_xloci_auc=$flank_x+$width+30;
my $legtxt_line_start_yloci_auc=$flank_y+$height*0.53+3;
$svg->text('x',$legtxt_line_start_xloci_auc,'y',$legtxt_line_start_yloci_auc,'-cdata',"AUC",'font-family','Arial', 'font-size',$xfontsize+3,'font-weight','bold');#刻度值
## X 轴 
my $line_x_start_xloci=$flank_x;
my $line_x_start_yloci=$flank_y+$height;
my $line_x_end_xloci=$flank_x+$width;
my $line_x_end_yloci=$flank_y+$height;
$svg->line('x1',$line_x_start_xloci,'y1',$line_x_start_yloci, 'x2',$line_x_end_xloci,'y2',$line_x_end_yloci,'stroke', $xcolor, 'stroke-width', 1);#刻度线

## X 轴刻度线
foreach my $i (1..$xgridN+1){
	my $line_xgrid_start_xloci=$flank_x+$i*$grid_len;
	my $line_xgrid_start_yloci=$flank_y+$height;
	my $line_xgrid_end_xloci=$flank_x+$i*$grid_len;
	my $line_xgrid_end_yloci=$flank_y+$height+3;
	$svg->line('x1',$line_xgrid_start_xloci,'y1',$line_xgrid_start_yloci, 'x2',$line_xgrid_end_xloci,'y2',$line_xgrid_end_yloci,'stroke', $xcolor, 'stroke-width', 1);#刻度线
	
	my $txt_xgrid_xloci=$flank_x+$i*$grid_len-$grid_len*0.1;
	my $txt_xgrid_yloci=$flank_y*1.2+$height;
	my $x_txt;
	if($i<=$xgridN){
		$x_txt=$xlabel{$i};
		#$svg->text('x',$txt_xgrid_xloci,'y',$txt_xgrid_yloci,'-cdata',$x_txt,'font-family','Arial', 'font-size',$xfontsize,'text-anchor','middle',"transform","rotate(-45,$txt_xgrid_xloci,$txt_xgrid_yloci)");#刻度值
		$svg->text('x',$txt_xgrid_xloci,'y',$txt_xgrid_yloci,'-cdata',$x_txt,'font-family','Arial', 'font-size',$xfontsize+3,"transform","rotate(-55,$txt_xgrid_xloci,$txt_xgrid_yloci)",'text-anchor','middle','font-weight','bold');#刻度值 
	}
}
#上边
my $line_up_start_xloci=$flank_x;
my $line_up_start_yloci=$flank_y;
my $line_up_end_xloci=$flank_x+$width;
my $line_up_end_yloci=$flank_y;
$svg->line('x1',$line_up_start_xloci,'y1',$line_up_start_yloci, 'x2',$line_up_end_xloci,'y2',$line_up_end_yloci,'stroke', $xcolor, 'stroke-width', 1);#刻度线
#右边
my $line_right_start_xloci=$flank_x+$width;
my $line_right_start_yloci=$flank_y;
my $line_right_end_xloci=$flank_x+$width;
my $line_right_end_yloci=$flank_y+$height;
$svg->line('x1',$line_right_start_xloci,'y1',$line_right_start_yloci, 'x2',$line_right_end_xloci,'y2',$line_right_end_yloci,'stroke', $xcolor, 'stroke-width', 1);#刻度线

## Y 轴
my $line_y_start_xloci=$flank_x;
my $line_y_start_yloci=$flank_y;
my $line_y_end_xloci=$flank_x;
my $line_y_end_yloci=$flank_y+$height;
$svg->line('x1',$line_y_start_xloci,'y1',$line_y_start_yloci, 'x2',$line_y_end_xloci,'y2',$line_y_end_yloci,'stroke', $xcolor, 'stroke-width', 1);#刻度线

###对角线
#$svg->line('x1',$flank_x,'y1',$flank_y+$height, 'x2',$flank_x+$width,'y2',$flank_y,'stroke', 'sandybrown', 'stroke-width', 1,'stroke-dasharray','3 2');
## 0
#$svg->text('x',$flank_x-10,'y',$flank_y+$height+8,'-cdata',0,'font-family','Arial', 'font-size',$xfontsize,'text-anchor','middle');

## 标题
my $title_xloci=$flank_x+$width*0.5;
my $title_yloci=$flank_y-10;
$svg->text('x',$title_xloci,'y',$title_yloci,'-cdata',$title,'font-family','Arial', 'font-size',$title_size+7,'text-anchor','middle','font-weight','bold');
#X轴标题
my $x_lengend_xloci=$flank_x+$width*0.5;
my $x_lengend_tloci=$flank_y*1.97+$height;
$svg->text('x',$x_lengend_xloci,'y',$x_lengend_tloci,'-cdata',"Coverage",'font-family','Arial', 'font-size',$title_size+5,'text-anchor','middle','font-weight','bold');
#Y轴标题
my $y_lengend_xloci=$flank_x*0.5;
my $y_lengend_yloci=$flank_y+$height*0.5;
$svg->text('x',$y_lengend_xloci,'y',$y_lengend_yloci,'-cdata',"Value",'font-family','Arial', 'font-size',$title_size+5,'text-anchor','middle','font-weight','bold',"transform","rotate(-90,$y_lengend_xloci,$y_lengend_yloci)");


open OUT, ">$outfile" || die $!;
print OUT $svg->xmlify;
close OUT;
###=======   Sub   =======##


