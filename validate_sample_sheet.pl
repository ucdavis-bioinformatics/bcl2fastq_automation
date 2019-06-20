#!/usr/bin/perl

$MISMATCH_THRESHOLD_DEFAULT = 1;
$prevproj="";
$rts{"PE150"} = 150;
$rts{"PE100"} = 100;
$rts{"SR100"} = 100;
$rts{"SR90"} = 90;
$rts{"SR50"} = 50;

if (scalar(@ARGV) < 2) {
    print STDERR "Usage: $0 <runinfo file> <sample sheet>\n";
    exit(1);
}

$runinfo_file = $ARGV[0];
$samplesheet = $ARGV[1];

%reads=();
%indexes=();
open($ri,"<$runinfo_file");
while (<$ri>) {
    if ($_ =~ /\<Read Number=\"(\d)\" NumCycles=\"(\d+)\" IsIndexedRead=\"(\w)\"/) {
        if ($3 eq "N") {
            if (!exists $reads{"R1"}) {
                $reads{"R1"} = $2;
            } else {
                $reads{"R2"} = $2;
            }
        } else {
            if (!exists $indexes{"I1"}) {
                $indexes{"I1"} = $2;
            } else {
                $indexes{"I2"} = $2;
            }
        }
    }
}
close($ri);

open($ss,"cat $samplesheet | sed 's/\\r/\\n/g' | grep -v ^\$");
<$ss>;
<$ss>;
while (<$ss>) {
    chomp;
    @data = split(/,/,$_,20);

    $index1 = $data[5];
    $index2 = $data[7];
    $project = $data[8];

    if ($prevproj eq "" || $prevproj ne $project) {
        if (scalar(@data) != 12) {
            print STDERR "Error: The first line of a project has to have 12 comma-separated columns. The first line of project $project does not.\n";
        }
        $runtype = $data[10];
        $mismatch_values{$project} = $data[11] eq "" ? $MISMATCH_THRESHOLD_DEFAULT : $data[11];

        if ($reads{"R1"} < $rts{$runtype} || $reads{"R2"} < $rts{$runtype}) {
            print STDERR "Error: The runtype ($runtype) length exceeds the read length (".$reads{"R1"}.")\n";
        }

        $prevproj = $project;
    }

    if ($index1 ne "" && length($index1) > $indexes{"I1"} && exists $indexes{"I1"}) {
        print STDERR "Error: Index $index1 is too long. Should be ".$indexes{"I1"}."bp or less.\n";
    }

    if ($index2 ne "" && length($index2) > $indexes{"I2"} && exists $indexes{"I2"}) {
        print STDERR "Error: Index $index2 is too long. Should be ".$indexes{"I2"}."bp or less.\n";
    }

    if ($indices{$project}{$index1}{$index2} == 1) {
        print STDERR "Error: $index1".($index2 ne "" ? ",$index2" : "")." is seen more than once for project $project\n";
    } elsif ($index1 ne "") {
        $indices{$project}{$index1}{$index2} = 1;
    }

    $all_ind1{$project}{$index1}=1;
    $all_ind2{$project}{$index2}=1;
#print STDERR "Adding index $index1 with lane $lane...\n";

    if (!exists $rts{$runtype}) {
        print STDERR "Error: Unrecognized runtype $runtype for project $project.\n";
    }

    if (exists $reads{"R1"} && !exists $reads{"R2"} && ($runtype eq "PE100" || $runtype eq "PE150")) {
        print STDERR "Error: runtype is $runtype, but run is a Single-End run.\n";
    }
}
close($ss);


foreach $proj (keys %all_ind1 ) {
  $ambiguity_threshold = (2 * $mismatch_values{$proj}) + 1;

  foreach $i1 (keys %{ $all_ind1{$proj} }) {
    foreach $i2 (keys %{ $all_ind1{$proj} }) {

#print STDERR "Checking $i1, $i2 with lane $lane...\n";
        if ($i1 ne $i2) {
            $mismatch = ( $i1 ^ $i2 ) =~ tr/\0//c;
            if ($mismatch < $ambiguity_threshold) {
                print STDERR "Error: index $i1 is too similar to index $i2 for project $proj. bcl2fastq will call this ambiguous and not run, since the number of mismatches in these two barcodes ($mismatch) is less than the ambiguity threshold ($ambiguity_threshold). Ambiguity is defined as less than 2 times the mismatch threshold plus one.\n";
            }
        }
    }
  }
}

foreach $proj (keys %all_ind2 ) {
  $ambiguity_threshold = (2 * $mismatch_values{$proj}) + 1;

  foreach $i1 (keys %{ $all_ind2{$proj} }) {
    foreach $i2 (keys %{ $all_ind2{$proj} }) {

#print STDERR "Checking $i1, $i2 with lane $lane...\n";
        if ($i1 ne $i2) {
            $mismatch = ( $i1 ^ $i2 ) =~ tr/\0//c;
            if ($mismatch < $ambiguity_threshold) {
                print STDERR "Error: index $i1 is too similar to index $i2 for project $proj. bcl2fastq will call this ambiguous and not run, since the number of mismatches in these two barcodes ($mismatch) is less than the ambiguity threshold ($ambiguity_threshold). Ambiguity is defined as less than 2 times the mismatch threshold plus one.\n";
            }
        }
    }
  }
}
