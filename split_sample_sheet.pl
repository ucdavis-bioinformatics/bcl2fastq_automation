#!/usr/bin/perl

use File::Basename;

if (scalar(@ARGV) < 3) {
    print STDERR "Usage: $0 <run directory> <sample sheet> <outdir base>\n";
    exit(1);
}

$rundir = basename($ARGV[0]);
$ssfile = $ARGV[1];
$out_base = $ARGV[2];

my %sampfiles;
if (! -e "$out_base/$rundir") {
    system ("mkdir $out_base/$rundir");
}
open($task_array,">$out_base/$rundir/all_sample_sheets.txt");

open($samp, "cat $ssfile | sed 's/\\r/\\n/g' | grep -v ^\$ |");
$dline=<$samp>;
$header=<$samp>;

while (<$samp>) {
	chomp;
	@data = split(/,/,$_,20);
	$project = $data[8];

    if ($data[0] !~ /\d+/) {next;}

	if (!exists $sampfiles{$project}) {
		open($sampfiles{$project}, ">$out_base/$rundir/$project.SampleSheet.csv");
        print $task_array "$out_base/$rundir/$project.SampleSheet.csv\n";
		print {$sampfiles{$project}} "$dline$header";
	}

#print STDERR "data: ".$#data."\n";

	print {$sampfiles{$project}} "$data[0],$data[1],$rundir-$data[1],".join(',',@data[3 .. $#data])."\n";
}
close($task_array);

foreach $project (keys %sampfiles) {
	close($sampfiles{$project});
}
