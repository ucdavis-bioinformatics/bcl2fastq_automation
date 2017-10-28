#!/usr/bin/perl

$out_base = "/share/dnatech/hiseq-fastq";

$datadir = $ARGV[0];
opendir ($dh,$datadir);
@dirs = grep {-d "$datadir/$_" && ! /^\.{1,2}$/} readdir($dh);
closedir($dh);

foreach $dir (@dirs) {
#    print "$dir\n";
    if (-e "$datadir/$dir/done_flag" || -e "$datadir/$dir/running_flag") {next;}

    $numcycles=0;
    open($ri, "<$datadir/$dir/RunInfo.xml");
    while (<$ri>) {
        chomp;
        if ($_ =~ /\<Read Number.+NumCycles=\"(\d+)\"/) {
            $numcycles += $1;
        }

        if ($_ =~ /\<FlowcellLayout\s+LaneCount=\"(\d+)\"\s+SurfaceCount=\"(\d+)\"\s+SwathCount=\"(\d+)\"\s+TileCount=\"(\d+)\"/) {
            $lanecount = $1;
            $surfacecount = $2;
            $swathcount = $3;
            $tilecount = $4;
        }
    }
    close($ri);


    if (-e "$datadir/$dir/Data/Intensities/BaseCalls/L00$lanecount/C$numcycles.1/s_${lanecount}_$surfacecount$swathcount$tilecount.bcl.gz") {
        #run is ready for bcl2fastq
        ($run_num)=$dir=~/_run(\d+)/;
        $samplesheet = $run_num . "_SampleSheet.csv";
        $outputfolder = "$out_base/$dir";
        system ("touch $datadir/$dir/running_flag");
        system ("split_sample_sheet.pl $datadir/$dir $datadir/$dir/$samplesheet");
        system ("run_bcl2fastq.pl $datadir/$dir/RunInfo.xml $datadir/$dir/$samplesheet $datadir/$dir $outputfolder");
    }
}


