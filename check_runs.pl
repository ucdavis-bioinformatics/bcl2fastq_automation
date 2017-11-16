#!/usr/bin/perl

$out_base = "/share/biocore/hiseq-fastq";
$run_base = "/share/dnatech/hiseq";
$script_base = "/share/biocore/joshi/projects/bcl2fastq_automation";

opendir ($dh,$run_base);
@dirs = grep {! /^\.{1,2}$/ && /_run\d+$/} readdir($dh);
closedir($dh);

foreach $rundir (@dirs) {
#    print "$dir\n";
    if (-e "$out_base/$rundir/flags/done_flag1" || -e "$out_base/$rundir/flags/done_flag2" || -e "$out_base/$rundir/flags/done_flag3" || -e "$out_base/$rundir/flags/done_flag4" || -e "$out_base/$rundir/flags/done_flag5" || -e "$out_base/$rundir/flags/done_flag6" || -e "$out_base/$rundir/flags/done_flag7" || -e "$out_base/$rundir/flags/done_flag8" || -e "$out_base/$rundir/flags/running_flag") {next;}

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
    print STDERR "Checking for $run_base/$rundir/Data/Intensities/BaseCalls/L00$lanecount/C$numcycles.1/s_${lanecount}_$surfacecount$swathcount$tilecount.bcl.gz creation...\n";
    if (-e "$run_base/$rundir/Data/Intensities/BaseCalls/L00$lanecount/C$numcycles.1/s_${lanecount}_$surfacecount$swathcount$tilecount.bcl.gz") {
        #run is ready for bcl2fastq
        ($run_num)=$rundir=~/_run(\d+)/;
        $samplesheet = $run_num . "_SampleSheet.csv";
        $outputfolder = "$out_base/$rundir";
        print STDERR "Running bcl2fastq for $out_base/$rundir...\n";
        system ("mkdir -p $outputfolder/flags");
        system ("touch $outputfolder/flags/running_flag");
        system ("$script_base/split_sample_sheet.pl $run_base/$rundir $run_base/$rundir/$samplesheet $out_base");
        system ("sbatch $script_base/run_bcl2fastq.slurm $run_base/$rundir $outputfolder");
        #system ("run_bcl2fastq.pl $datadir/$dir/RunInfo.xml $datadir/$dir/$samplesheet $datadir/$dir $outputfolder");
    }
}
