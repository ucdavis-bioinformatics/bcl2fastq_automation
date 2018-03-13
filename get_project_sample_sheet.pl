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

$firstline=0;
#print STDERR "Running split sample sheet with $rundir, $ssfile, $out_base, $project_id\n";

my %sampfiles;
if (! -e "$out_base/$rundir") {
    system ("mkdir $out_base/$rundir");
}

($machine_id) = $rundir =~ /^.+_(.+?)_run\d+/;

open($samp, "cat $ssfile | sed 's/\\r/\\n/g' | grep -v ^\$ |");
$dline=<$samp>;
chomp $dline;
$header=<$samp>;
chomp $header;

open ($outfile,">$out_base/$rundir/$project_id.SampleSheet.csv");
print $outfile "$dline,,\n$header,i1_length,i2_length\n";
while (<$samp>) {
	chomp;
	@data = split(/,/,$_,20);
	$project = $data[8];

    if ($data[0] !~ /\d+/) {next;}

    if ($project eq $project_id) {

    	$i1_length = "";
    	$i2_length = "";
    	# check if barcodes are Ns for no demultiplexing
    	if ($data[5] =~ /^N+/i) {
    		$i1_length = length($data[5]);
    		$data[5] = "";
    	}

    	if ($data[7] =~ /^N+/i) {
    		$i2_length = length($data[7]);
    		$data[7] = "";
    	}

		print $outfile "$data[0],$data[1],$machine_id-$data[1],".join(',',@data[3 .. $#data]);
		if ($firstline == 0) {
			print $outfile ",$i1_length,$i2_length";
			$firstline=1;
		}
		print $outfile "\n";
	}
}
close($samp);
close($outfile)
