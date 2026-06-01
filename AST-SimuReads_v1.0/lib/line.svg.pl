#!/usr/bin/perl  -w
use strict;
use Getopt::Long;
use FindBin qw($Bin);
my $colorlist="$Bin/color.list";
use lib "/data/Yixue/chenfangyuan/bin/software/svg_lib";
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

$width   ||= 500;
$height  ||= 350;
$flank_y ||= $height /2.4;
$flank_x ||= $flank_y;
my $pwidth  = $width + $flank_x * 2;
my $pheight = $height + $flank_y * 2;

#-----------------------------  字体大小  ------------------------
my $title_size=13;
my $xfontsize;
my $yfontsize;
$xfontsize=$yfontsize;
$xfontsize=10;

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
#------------------------------- main --------------------------------
my $svg = SVG->new(width=> $pwidth,height=> $pheight);
$xgridN||=`wc -l $infile | awk '{print \$1}' `;
chomp $xgridN;
my $grid_len =$width/$xgridN;
open IN,$infile;
<IN>;
my $ii=1;
my (%xlabel,%ppv,%npv,%auc);
while(<IN>){
	chomp;
	my @or=split /\t/;
	#$xlabel{$ii}="$or[0]X:$or[1]";
	my @mm=split /\(/,$or[1];
	$xlabel{$ii}=" $or[0]X ($mm[0]%)";
	$ppv{$ii}=$or[2];
	$npv{$ii}=$or[3];
	$auc{$ii}=$or[4];
	
	my $point_xloci_ppv=$flank_x+$ii*$grid_len;
	my $point_yloci_ppv=$flank_y+(1-$or[2])*$height;
	$svg->circle('cx',$point_xloci_ppv,'cy',$point_yloci_ppv,'r',2,'stroke',$col{1},'fill',$col{1});
	
	my $point_xloci_npv=$flank_x+$ii*$grid_len;
	my $point_yloci_npv=$flank_y+(1-$or[3])*$height;
	$svg->circle('cx',$point_xloci_npv,'cy',$point_yloci_npv,'r',2,'stroke',$col{2},'fill',$col{2});
	
	my $point_xloci_auc=$flank_x+$ii*$grid_len;
	my $point_yloci_auc=$flank_y+(1-$or[4])*$height;
	$svg->circle('cx',$point_xloci_auc,'cy',$point_yloci_auc,'r',2,'stroke',$col{3},'fill',$col{3});
	
	$ii++;
}
close IN;
###折线
foreach my $i (1..$ii-2){
	my $line_start_xloci_ppv=$flank_x+$i*$grid_len;
	my $line_start_yloci_ppv=$flank_y+(1-$ppv{$i})*$height;
	my $line_end_xloci_ppv=$flank_x+($i+1)*$grid_len;
	my $line_end_yloci_ppv=$flank_y+(1-$ppv{($i+1)})*$height;
	$svg->line('x1',$line_start_xloci_ppv,'y1',$line_start_yloci_ppv, 'x2',$line_end_xloci_ppv,'y2',$line_end_yloci_ppv,'stroke',$col{1}, 'stroke-width', 2);
	
	my $line_start_xloci_npv=$flank_x+$i*$grid_len;
	my $line_start_yloci_npv=$flank_y+(1-$npv{$i})*$height;
	my $line_end_xloci_npv=$flank_x+($i+1)*$grid_len;
	my $line_end_yloci_npv=$flank_y+(1-$npv{($i+1)})*$height;
	$svg->line('x1',$line_start_xloci_npv,'y1',$line_start_yloci_npv, 'x2',$line_end_xloci_npv,'y2',$line_end_yloci_npv,'stroke',$col{2}, 'stroke-width', 2);

	my $line_start_xloci_auc=$flank_x+$i*$grid_len;
	my $line_start_yloci_auc=$flank_y+(1-$auc{$i})*$height;
	my $line_end_xloci_auc=$flank_x+($i+1)*$grid_len;
	my $line_end_yloci_auc=$flank_y+(1-$auc{($i+1)})*$height;
	$svg->line('x1',$line_start_xloci_auc,'y1',$line_start_yloci_auc, 'x2',$line_end_xloci_auc,'y2',$line_end_yloci_auc,'stroke',$col{3}, 'stroke-width', 2);
}
#折线图例
my $leg_line_start_xloci_ppv=$flank_x+$width+5;
my $leg_line_start_yloci_ppv=$flank_y+$height*0.47;
my $leg_line_end_xloci_ppv=$flank_x+$width+25;
my $leg_line_end_yloci_ppv=$flank_y+$height*0.47;
$svg->line('x1',$leg_line_start_xloci_ppv,'y1',$leg_line_start_yloci_ppv, 'x2',$leg_line_end_xloci_ppv,'y2',$leg_line_end_yloci_ppv,'stroke',$col{1}, 'stroke-width', 3);
my $legtxt_line_start_xloci_ppv=$flank_x+$width+30;
my $legtxt_line_start_yloci_ppv=$flank_y+$height*0.47+1;
$svg->text('x',$legtxt_line_start_xloci_ppv,'y',$legtxt_line_start_yloci_ppv,'-cdata',"PPV",'font-family','Arial', 'font-size',$xfontsize);#刻度值

my $leg_line_start_xloci_npv=$flank_x+$width+5;
my $leg_line_start_yloci_npv=$flank_y+$height*0.5;
my $leg_line_end_xloci_npv=$flank_x+$width+25;
my $leg_line_end_yloci_npv=$flank_y+$height*0.5;
$svg->line('x1',$leg_line_start_xloci_npv,'y1',$leg_line_start_yloci_npv, 'x2',$leg_line_end_xloci_npv,'y2',$leg_line_end_yloci_npv,'stroke',$col{2}, 'stroke-width', 3);
my $legtxt_line_start_xloci_npv=$flank_x+$width+30;
my $legtxt_line_start_yloci_npv=$flank_y+$height*0.5+1;
$svg->text('x',$legtxt_line_start_xloci_npv,'y',$legtxt_line_start_yloci_npv,'-cdata',"NPV",'font-family','Arial', 'font-size',$xfontsize);#刻度值

my $leg_line_start_xloci_auc=$flank_x+$width+5;
my $leg_line_start_yloci_auc=$flank_y+$height*0.53;
my $leg_line_end_xloci_auc=$flank_x+$width+25;
my $leg_line_end_yloci_auc=$flank_y+$height*0.53;
$svg->line('x1',$leg_line_start_xloci_auc,'y1',$leg_line_start_yloci_auc, 'x2',$leg_line_end_xloci_auc,'y2',$leg_line_end_yloci_auc,'stroke',$col{3}, 'stroke-width', 3);
my $legtxt_line_start_xloci_auc=$flank_x+$width+30;
my $legtxt_line_start_yloci_auc=$flank_y+$height*0.53+1;
$svg->text('x',$legtxt_line_start_xloci_auc,'y',$legtxt_line_start_yloci_auc,'-cdata',"AUC",'font-family','Arial', 'font-size',$xfontsize);#刻度值
## X 轴 
my $line_x_start_xloci=$flank_x;
my $line_x_start_yloci=$flank_y+$height;
my $line_x_end_xloci=$flank_x+$width;
my $line_x_end_yloci=$flank_y+$height;
$svg->line('x1',$line_x_start_xloci,'y1',$line_x_start_yloci, 'x2',$line_x_end_xloci,'y2',$line_x_end_yloci,'stroke', $xcolor, 'stroke-width', 1);#刻度线

## X 轴刻度线
foreach my $i (1..$ii){
	my $line_xgrid_start_xloci=$flank_x+$i*$grid_len;
	my $line_xgrid_start_yloci=$flank_y+$height;
	my $line_xgrid_end_xloci=$flank_x+$i*$grid_len;
	my $line_xgrid_end_yloci=$flank_y+$height+3;
	$svg->line('x1',$line_xgrid_start_xloci,'y1',$line_xgrid_start_yloci, 'x2',$line_xgrid_end_xloci,'y2',$line_xgrid_end_yloci,'stroke', $xcolor, 'stroke-width', 1);#刻度线
	
	my $txt_xgrid_xloci=$flank_x+$i*$grid_len-$grid_len*0.2;  ## 控制横坐标刻度label位置x
	my $txt_xgrid_yloci=$flank_y*1.33+$height; ##控制横坐标刻度label位置y
	my $x_txt;
	if($i==0){
		$x_txt=$i;
		$svg->text('x',$txt_xgrid_xloci,'y',$txt_xgrid_yloci,'-cdata',$x_txt,'font-family','Arial', 'font-size',$xfontsize,"transform","rotate(-45,$txt_xgrid_xloci,$txt_xgrid_yloci)");#刻度值
#	}elsif($i==$xgridN){
#		$x_txt=100;
#		$svg->text('x',$txt_xgrid_xloci,'y',$txt_xgrid_yloci,'-cdata',$x_txt,'font-family','Arial', 'font-size',$xfontsize,"transform","rotate(-45,$txt_xgrid_xloci,$txt_xgrid_yloci)");#刻度值
	}else{
		$x_txt=$xlabel{$i};
		#$svg->text('x',$txt_xgrid_xloci,'y',$txt_xgrid_yloci,'-cdata',$x_txt,'font-family','Arial', 'font-size',$xfontsize,'text-anchor','middle',"transform","rotate(-45,$txt_xgrid_xloci,$txt_xgrid_yloci)");#刻度值
		$svg->text('x',$txt_xgrid_xloci,'y',$txt_xgrid_yloci,'-cdata',$x_txt,'font-family','Arial', 'font-size',$xfontsize,"transform","rotate(-60,$txt_xgrid_xloci,$txt_xgrid_yloci)",'text-anchor','middle');#刻度值
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

## Y 轴刻度线
my $y_grid_len=$height/10;
foreach my $i (1..10){
	my $line_ygrid_start_xloci=$flank_x;
	my $line_ygrid_start_yloci=$flank_y+$height-$i*$y_grid_len;
	my $line_ygrid_end_xloci=$flank_x-3;
	my $line_ygrid_end_yloci=$flank_y+$height-$i*$y_grid_len;
	$svg->line('x1',$line_ygrid_start_xloci,'y1',$line_ygrid_start_yloci, 'x2',$line_ygrid_end_xloci,'y2',$line_ygrid_end_yloci,'stroke', $xcolor, 'stroke-width', 1);#刻度线
	
	my $txt_ygrid_xloci=$flank_x-12;
	my $txt_ygrid_yloci=$flank_y+$height-$i*$y_grid_len+3;
	my $x_txt=sprintf("%.1f",$i*0.1);
	$svg->text('x',$txt_ygrid_xloci,'y',$txt_ygrid_yloci,'-cdata',$x_txt,'font-family','Arial', 'font-size',$xfontsize,'text-anchor','middle');#刻度值
}

###对角线
#$svg->line('x1',$flank_x,'y1',$flank_y+$height, 'x2',$flank_x+$width,'y2',$flank_y,'stroke', 'sandybrown', 'stroke-width', 1,'stroke-dasharray','3 2');
## 0
#$svg->text('x',$flank_x-10,'y',$flank_y+$height+8,'-cdata',0,'font-family','Arial', 'font-size',$xfontsize,'text-anchor','middle');

## 标题
my $title_xloci=$flank_x+$width*0.5;
my $title_yloci=$flank_y-10;
$svg->text('x',$title_xloci,'y',$title_yloci,'-cdata',$title,'font-family','Arial', 'font-size',$title_size,'text-anchor','middle','font-weight','bold');
#X轴标题
my $x_lengend_xloci=$flank_x+$width*0.5;
my $x_lengend_tloci=$flank_y*1.8+$height;
$svg->text('x',$x_lengend_xloci,'y',$x_lengend_tloci,'-cdata',"Coverage",'font-family','Arial', 'font-size',$title_size-1,'text-anchor','middle','font-weight','bold');
#Y轴标题
my $y_lengend_xloci=$flank_x*0.8;
my $y_lengend_yloci=$flank_y+$height*0.5;
$svg->text('x',$y_lengend_xloci,'y',$y_lengend_yloci,'-cdata',"Value",'font-family','Arial', 'font-size',$title_size-1,'text-anchor','middle','font-weight','bold',"transform","rotate(-90,$y_lengend_xloci,$y_lengend_yloci)");


open OUT, ">$outfile" || die $!;
print OUT $svg->xmlify;
close OUT;
###=======   Sub   =======##


