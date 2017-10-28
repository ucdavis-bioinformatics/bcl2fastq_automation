#!/usr/bin/perl

$MISMATCH_THRESHOLD_DEFAULT = 1;
$prevlane="";
$rts{"Illumina"}=1;
$rts{"10X"}=1;

if (scalar(@ARGV) < 2) {
    print STDERR "Usage: $0 <runinfo file> <sample sheet>\n";
    exit(1);
}

$runinfo_file = $ARGV[0];
$samplesheet = $ARGV[1];

open($ri,"<$runinfo_file");
while (<$ri>) {
    if ($_ =~ /\<Read Number=\"(\d)\" NumCycles=\"(\d+)\"/) {
        $runinfo{$1} = $2;
    }
}
close($ri);

open($ss,"cat $samplesheet | sed 's/\\r/\\n/g' |");
<$ss>;
<$ss>;
while (<$ss>) {
    chomp;
    @data = split(/,/,$_,20);

    $lane = $data[0];
    $index1 = $data[5];
    $index2 = $data[7];
    $runtype = $data[10];

    if ($prevlane eq "" || $prevlane ne $lane) {
        if (scalar(data) != 12) {
            print STDERR "The first line of a lane has to have 12 comma-separated columns. The first line of lane $lane does not.\n";
        }
        $mismatch_values{$lane} = $data[11] eq "" ? $MISMATCH_THRESHOLD_DEFAULT : $data[11];
        $prevlane = $lane;
    }

    if ($index1 ne "" && length($index1) > $runinfo{2}) {
        print STDERR "Error: Index $index1 is too long. Should be $runinfo{2}bp or less.\n";
    }

    if ($index2 ne "" && length($index2) > $runinfo{3}) {
        print STDERR "Error: Index $index2 is too long. Should be $runinfo{3}bp or less.\n";
    }

    if ($indices{$lane}{$index1}{$index2} == 1) {
        print STDERR "Error: $index1".($index2 ne "" ? ",$index2" : "")." is seen more than once in lane $lane.\n";
    } elsif ($index1 ne "") {
        $indices{$lane}{$index1}{$index2} = 1;
    }

    $all_ind1{$lane}{$index1}=1;
    $all_ind2{$lane}{$index2}=1;
#print STDERR "Adding index $index1 with lane $lane...\n";

    if (!exists $rts{$runtype}) {
        print STDERR "Error: Runtype $runtype for lane $lane is invalid.\n";
    }
}
close($ss);


foreach $lane (keys %all_ind1 ) {
  $ambiguity_threshold = (2 * $mismatch_values{$lane}) + 1;

  foreach $i1 (keys %{ $all_ind1{$lane} }) {
    foreach $i2 (keys %{ $all_ind1{$lane} }) {

#print STDERR "Checking $i1, $i2 with lane $lane...\n";
        if ($i1 ne $i2) {
            $mismatch = ( $i1 ^ $i2 ) =~ tr/\0//c;
            if ($mismatch < $ambiguity_threshold) {
                print STDERR "Error: index $i1 is too similar to index $i2 in lane $lane. bcl2fastq will call this ambiguous and not run, since the number of mismatches in these two barcodes ($mismatch) is less than the ambiguity threshold ($ambiguity_threshold). Ambiguity is defined as less than 2 times the mismatch threshold plus one.\n";
            }
        }
    }
  }
}

foreach $lane (keys %all_ind2 ) {
  $ambiguity_threshold = (2 * $mismatch_values{$lane}) + 1;

  foreach $i1 (keys %{ $all_ind2{$lane} }) {
    foreach $i2 (keys %{ $all_ind2{$lane} }) {

#print STDERR "Checking $i1, $i2 with lane $lane...\n";
        if ($i1 ne $i2) {
            $mismatch = ( $i1 ^ $i2 ) =~ tr/\0//c;
            if ($mismatch < $ambiguity_threshold) {
                print STDERR "Error: index $i1 is too similar to index $i2 in lane $lane. bcl2fastq will call this ambiguous and not run, since the number of mismatches in these two barcodes ($mismatch) is less than the ambiguity threshold ($ambiguity_threshold). Ambiguity is defined as less than 2 times the mismatch threshold plus one.\n";
            }
        }
    }
  }
}
