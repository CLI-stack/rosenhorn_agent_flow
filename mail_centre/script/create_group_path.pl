#!/tool/aticad/1.0/bin/perl

use Getopt::Long;
use warnings;
use strict;
use Data::Dumper;


my $help;
my $slack = 17;
my $group ;
my $file;
my $weight;
my $n=0;
my $critical_range;
my $is_end;
GetOptions("group:i"=>\$group, "slack:f"=>\$slack, "help"=>\$help, "file:s"=>\$file, "weight:s"=>\$weight, "start:i"=>\$n,"critical_range:f"=>\$critical_range,"end"=>\$is_end);

die "\n$0: -file file_name [-group group_name] [-slack -0.1 ] ...

Description:

-file:   input file(SCLK_max.rpt.gz clock_gating_default_max.rpt.gz ... )
-group:  define the group name;
-end:    use end point create group path;
-slack:  create the group less than slack, default is 0;
-critical_range: critical_range, default is 0.4;
-help:   show the help
" if(defined $help or !defined $file );
my $start_or_end = "Start";

if (defined $is_end) {
   $start_or_end = "End"; 
}
if (!defined $critical_range) {
	$critical_range = 300;
}

if (!defined $group ) {
$group =  `zegrep "group:|Group:" $file | head -n 1 | awk '{print \$NF}' | sed 's/*//g'`;
chomp $group;
}

system "rm create_group_path.tmp -f";
system "zegrep \"$start_or_end| slack \" $file | grep -v Warning > create_group_path.tmp";
#open FILE ,"<","zegrep \"Start\|slack\" $file  | " or die "Can't open file:$file\n";
open FILE ,"<","create_group_path.tmp" or die "Can't open file:$file\n";

my %path_all;
my $current_path;
foreach my $line (<FILE>) {
	if ($line=~m/$start_or_end.*:\s*(\S+)/) {
		$current_path = $1;
		$path_all{$current_path}{name} = $current_path;
		$path_all{$current_path}{name} =~ s/\d+/\*/g;
		++$path_all{$current_path}{num};
	}
	if($line=~m/slack\s*\(\S+\)\s*(\S+)/) {
		#	print $line;
		my $slack = $1;
        if(exists$path_all{$current_path}{slack} ) {
            #print "$current_path $path_all{$current_path}{slack}  $slack\n";
        }
		if(!exists$path_all{$current_path}{slack} or $path_all{$current_path}{slack} > $slack) {
			$path_all{$current_path}{slack} = $slack;
		}

	}
}
close FILE;
#system "rm create_group_path.tmp -f";
#print Dumper \%path_all;
my %sort_path;

foreach my $path (keys %path_all) {
	my $name = $path_all{$path}{name};
	my $slack = $path_all{$path}{slack};
	$sort_path{$name}{num} += $path_all{$path}{num};
	if(!exists $sort_path{$name}{slack} or $sort_path{$name}{slack} > $slack) {
	$sort_path{$name}{slack} = $slack;
}
	if(!exists $sort_path{$name}{slack_min} or $sort_path{$name}{slack_min} < $slack) {
	$sort_path{$name}{slack_min} = $slack;
}

}
#print Dumper \%sort_path;

my @list = grep { $sort_path{$_}{slack} < $slack } keys %sort_path;
foreach my $pa (@list) {
    print $pa;
}
print "\n";
##if (defined $weight) {
##
##map {printf "group_path -cr 0.4 -name ${group}_%02d -weight $weight -from [get_pins $_/CLK ]  \n",$n++} @list; 
##} else {
##map {printf "group_path -cr 0.4 -name ${group}_%02d -from [get_pins $_/CLK ] \n",$n++} @list; 
##}
open NEW, ">$group.info" or die;
print NEW " max_slack   min_slack   No.      $start_or_end point\n";
#print NEW "----------------------------------------------------------------------------------------------------------------------\n";
#map {printf NEW "%9.4f   %9.3f    %3d     %s\n", $sort_path{$_}{slack},$sort_path{$_}{slack_min},$sort_path{$_}{num},$_ } @list;
#print NEW "----------------------------------------------------------------------------------------------------------------------\n";
#map {printf NEW "%9.4f   %9.3f    %3d     %s\n", $sort_path{$_}{slack},$sort_path{$_}{slack_min},$sort_path{$_}{num},$_ } keys %sort_path;

my $num = 0;
my $weight_now = 20;
open GRP, "> group.tcl" or die $!;
#my $pin = "CK" ;
my $pin = "" ;
my $direction = "from";
if (defined $is_end ) {
   #$pin = "D";
    $pin = "";
   $direction = "to";
}

foreach my $patha ( reverse sort sort_bya keys %sort_path ) {
	#printf GRP "group_path -priority 5 -critical_range 150 -weight %4.1f -name ucpg_${group}_%02d -$direction [get_pins $patha/$pin ] \n",$weight_now, $num;
    printf GRP "group_path -priority 5 -critical_range 150 -weight %4.1f -name ucpg_${group}_%02d -$direction [get_pins $patha ] \n",$weight_now, $num;
	printf NEW "%9.4f   %9.3f    %3d     %s\n", $sort_path{$patha}{slack},$sort_path{$patha}{slack_min},$sort_path{$patha}{num},$patha;
	$num++;
	if ($weight_now > 10) {
	$weight_now -= 0.5;
}
}
close NEW;
close GRP;
sub sort_bya {
	$sort_path{$b}{slack} <=> $sort_path{$a}{slack}
}
print "\n## You can see the path info in file: $group.info
Group path file: group.tcl\n\n";
