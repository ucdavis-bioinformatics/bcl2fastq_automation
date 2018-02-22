#!/usr/bin/perl

use File::Basename;

if (scalar(@ARGV) < 4) {
    print STDERR "Usage: $0 <run directory> <sample sheet> <outdir base> <project ID>\n";
    exit(1);
}

$rundir = basename($ARGV[0]);
$ssfile = $ARGV[1];
$out_base = $ARGV[2];
$project_id = $ARGV[3];

#print STDERR "Running split sample sheet with $rundir, $ssfile, $out_base, $project_id\n";

my %sampfiles;
if (! -e "$out_base/$rundir") {
    system ("mkdir $out_base/$rundir");
}

open($samp, "cat $ssfile | sed 's/\\r/\\n/g' | grep -v ^\$ |");
$dline=<$samp>;
$header=<$samp>;

open ($outfile,">$out_base/$rundir/$project_id.SampleSheet.csv");
print $outfile "$dline$header";
while (<$samp>) {
	chomp;
	@data = split(/,/,$_,20);
	$project = $data[8];

    if ($data[0] !~ /\d+/) {next;}

    if ($project eq $project_id) {
		print $outfile "$data[0],$data[1],$rundir-$data[1],".join(',',@data[3 .. $#data])."\n";
	}
}
close($samp);
close($outfile)
