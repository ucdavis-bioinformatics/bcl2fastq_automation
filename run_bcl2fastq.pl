#!/usr/bin/perl

# This is only meant to be used with a split sample sheet file

$bp{"PE150"} = 150;
$bp{"PE100"} = 100;
$bp{"SR100"} = 100;
$bp{"SR90"} = 90;
$bp{"SR50"} = 50;

if (scalar(@ARGV) < 4) {
    print STDERR "Usage: $0 <runinfo file> <sample sheet> <run folder> <output folder>\n";
    exit(1);
}

$runinfo_file = $ARGV[0];
$samplesheet = $ARGV[1];
$runfolder = $ARGV[2];
$outfolder = $ARGV[3];

$mismatch = 1;
$create_index_option="";

%reads = ();
%indexes = ();

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

open($ss,"<$samplesheet") or die "Cannot open sample sheet: $samplesheet\n";
<$ss>;
<$ss>;
$base_mask = "";
$firstline=0;
while (<$ss>) {
    chomp;
    @data = split(/,/,$_,20);

    $lane = $data[0];
    $index1 = $data[5];
    $index2 = $data[7];

    $i1len = length($data[5]);
    $i2len = length($data[7]);

    # check if lengths are defined for no demultiplexing
    if ($index1 eq "" && $data[12] ne "") {
        $i1len = $data[12];
        $create_index_option = "--create-fastq-for-index-reads";
    }

    if ($index2 eq "" && $data[13] ne "") {
        $i2len = $data[13];
        $create_index_option = "--create-fastq-for-index-reads";
    }


    if ($index1 ne "" && $i1len > $indexes{"I1"} && exists $indexes{"I1"}) {
        print STDERR "Error: Index $index1 is too long. Should be ".$indexes{"I1"}."bp or less.\n";
        exit(1);
    }

    if ($index2 ne "" && $i2len > $indexes{"I2"} && exists $indexes{"I2"}) {
        print STDERR "Error: Index $index2 is too long. Should be ".$indexes{"I2"}."bp or less.\n";
        exit(1);
    }

    if ($firstline == 0) {
        $project = $data[8];
        $runtype = scalar(@data) < 11 ? "" : uc($data[10]);
        $projectfolder = "$outfolder/$project";

        $mismatch = scalar(@data) < 12 || $data[11] eq "" ? 1 : $data[11];

        if (exists $bp{$runtype}) {

            $type_length = exists $bp{$runtype} ? $bp{$runtype} : $reads{"R1"};

            if (exists $reads{"R1"}) {
                if ($reads{"R1"} < $type_length) {
                    print STDERR "ERROR: $runtype is longer than the read length.\n"
                }

                $n_num = $reads{"R1"} - $type_length;
                $base_mask .= "y$bp{$runtype}".($n_num <= 0 ? "" : "n$n_num");
            }

            if (exists $indexes{"I1"}) {
                if ($i1len != 0) {
                    $n_num = $indexes{"I1"} - $i1len;
                    if ($n_num > 0) {
                        $base_mask .= ",i".$i1len."n$n_num";
                    } else {
                        $base_mask .= ",i".$i1len;
                    }
                } else {
                    $base_mask .= ",n".$indexes{"I1"};
                }
            }

            if (exists $indexes{"I2"}) {
                if ($i2len != 0) {
                    $n_num = $indexes{"I2"} - $i2len;
                    if ($n_num > 0) {
                        $base_mask .= ",i".$i2len."n$n_num";
                    } else {
                        $base_mask .= ",i".$i2len;
                    }
                } else {
                    $base_mask .= ",n".$indexes{"I2"};
                }
            }

            if (exists $reads{"R2"}) {
                if ($reads{"R2"} < $type_length) {
                    print STDERR "ERROR: $runtype is longer than the read length.\n"
                }

                $n_num = $reads{"R2"} - $type_length;
                $base_mask .= ",y$bp{$runtype}".($n_num <= 0 ? "" : "n$n_num");
            }

        } elsif ($runtype eq "10X") {
              $base_mask = "y26,i8,y98";
        } else {
            print STDERR "ERROR: Unrecognized Runtype '$runtype'.\n";
        }
          
        $firstline = 1;
    }


    if ($indices{$lane}{$index1}{$index2} == 1) {
        print STDERR "Error: $index1".($index2 ne "" ? ",$index2" : "")." is seen more than once in lane $lane.\n";
        exit(1);
    } elsif ($index1 ne "") {
        $indices{$lane}{$index1}{$index2} = 1;
    }
}

#print "$base_mask\n";

#print <<EOF;
#bcl2fastq \\
#--sample-sheet $samplesheet \\
#--runfolder-dir $runfolder \\
#--output-dir $outfolder \\
#--stats-dir $outfolder/Stats \\
#--reports-dir $outfolder/Reports \\
#--create-fastq-for-index-reads \\
#--ignore-missing-positions \\
#--ignore-missing-controls \\
#--ignore-missing-filter \\
#--ignore-missing-bcls \\
#--barcode-mismatches $mismatch \\
#--loading-threads 2 \\
#--processing-threads 14 \\
#--writing-threads 2 \\
#--use-bases-mask $base_mask
#EOF

$command = "bcl2fastq --sample-sheet $samplesheet --runfolder-dir $runfolder --output-dir $outfolder --stats-dir $projectfolder/Stats --reports-dir $projectfolder/Reports --ignore-missing-positions --ignore-missing-controls --ignore-missing-filter --ignore-missing-bcls --barcode-mismatches $mismatch --loading-threads 2 --processing-threads 14 --writing-threads 2 --minimum-trimmed-read-length 0 --mask-short-adapter-reads 0 $create_index_option --use-bases-mask $base_mask";

print "$command\n";

$ret = system($command);
exit($ret/256);

#system("sbatch run_bcl2fastq.slurm $samplesheet $runfolder $outfolder $projectfolder $mismatch $base_mask");
#print("sbatch run_bcl2fastq.slurm $samplesheet $runfolder $outfolder $projectfolder $mismatch $base_mask\n");
