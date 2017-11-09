#!/usr/bin/perl

$out_base = "/share/dnatech/hiseq-fastq";
$run_base = "/share/dnatech/hiseq";

opendir ($dh,$run_base);
@dirs = grep {-d "$run_base/$_" && ! /^\.{1,2}$/ && /_run\d+$/} readdir($dh);
closedir($dh);

foreach $rundir (@dirs) {
#    print "$dir\n";
    if (-e "$run_base/$rundir/flags/done_flag1" || -e "$run_base/$rundir/flags/done_flag2" || -e "$run_base/$rundir/flags/done_flag3" || -e "$run_base/$rundir/flags/done_flag4" || -e "$run_base/$rundir/flags/done_flag5" || -e "$run_base/$rundir/flags/done_flag6" || -e "$run_base/$rundir/flags/done_flag7" || -e "$run_base/$rundir/flags/done_flag8" || -e "$run_base/$rundir/flags/running_flag") {next;}

    $numcycles=0;
    open($ri, "<$run_base/$rundir/RunInfo.xml");
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


    # check if final bcl file has been generated
    if (-e "$run_base/$rundir/Data/Intensities/BaseCalls/L00$lanecount/C$numcycles.1/s_${lanecount}_$surfacecount$swathcount$tilecount.bcl.gz") {
        #run is ready for bcl2fastq
        ($run_num)=$run_dir=~/_run(\d+)/;
        $samplesheet = $run_num . "_SampleSheet.csv";
        $outputfolder = "$out_base/$rundir";
        system ("mkdir $run_base/$rundir/flags");
        system ("touch $run_base/$rundir/flags/running_flag");
        system ("split_sample_sheet.pl $run_base/$rundir $run_base/$rundir/$samplesheet");
        system ("sbatch run_bcl2fastq.slurm $run_base/$rundir $outputfolder");
        #system ("run_bcl2fastq.pl $datadir/$dir/RunInfo.xml $datadir/$dir/$samplesheet $datadir/$dir $outputfolder");
    }
}
