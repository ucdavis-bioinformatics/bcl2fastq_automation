#!/usr/bin/perl

use File::Basename;

if (scalar(@ARGV) < 2) {
    print STDERR "Usage: $0 <run directory> <sample sheet>\n";
    exit(1);
}

$rundir = basename($ARGV[0]);
$ssfile = $ARGV[1];

my %sampfiles;

open($samp, "cat $ssfile | sed 's/\\r/\\n/g' |");
$dline=<$samp>;
$header=<$samp>;

while (<$samp>) {
	chomp;
	@data = split(/,/,$_,20);
	$project = $data[8];

	if (!exists $sampfiles{$project}) {
		open($sampfiles{$project}, ">$ARGV[0]/$project.SampleSheet.csv");
		print {$sampfiles{$project}} "$dline$header";
	}

#print STDERR "data: ".$#data."\n";

	print {$sampfiles{$project}} "$data[0],$data[1],$rundir"."_$data[1],".join(',',@data[3 .. $#data])."\n";
}

foreach $project (keys %sampfiles) {
	close($sampfiles{$project});
}
