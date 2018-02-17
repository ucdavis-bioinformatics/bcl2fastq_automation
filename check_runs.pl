#!/usr/bin/perl

$out_base = "/share/biocore/hiseq_fastq_runs";
#$out_base = "/share/biocore/hiseq-fastq";
$run_base = "/share/dnatech/hiseq";
#$run_base = "/share/illumina/hiseq";
$script_base = "/share/biocore/joshi/projects/bcl2fastq_automation";

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$now = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
print STDERR "Checking for new data ($now)...\n";

opendir ($dh,$run_base);
@dirs = grep {! /^\.{1,2}$/ && /_run\d+$/} readdir($dh);
closedir($dh);

foreach $rundir (@dirs) {

    ($run_num)=$rundir=~/_run(\d+)/;
    $samplesheet = $run_num . "_SampleSheet.csv";

    # check if sample sheet exists
    if (! -e "$run_base/$rundir/$samplesheet") {
        print STDERR "Sample sheet not found for $rundir... skipping.\n";
        next;
    }

    # check if final bcl file has been generated
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

    print STDERR "Checking for $run_base/$rundir/Data/Intensities/BaseCalls/L00$lanecount/C$numcycles.1/s_${lanecount}_$surfacecount$swathcount$tilecount.bcl.gz creation...\n";
    if (! -e "$run_base/$rundir/Data/Intensities/BaseCalls/L00$lanecount/C$numcycles.1/s_${lanecount}_$surfacecount$swathcount$tilecount.bcl.gz") {next;}

    %found = ();
    open($ss,"<$run_base/$rundir/$samplesheet");
    <$ss>;
    <$ss>;
    while (<$ss>) {
        chomp;
        @data = split(/,/);
        $project = $data[8];

        if (exists $found{$project}) {next;}
        $found{$project}=1;

        if (-e "$out_base/$rundir/flags/done__$project" || -e "$out_base/$rundir/flags/running__$project") {next;}

        #project is ready for bcl2fastq
        $outputfolder = "$out_base/$rundir";
        print STDERR "Running bcl2fastq for $out_base/$rundir/$project...\n";
        if (! -e "$outputfolder/flags") {system ("mkdir -p $outputfolder/flags");}
        system ("touch $outputfolder/flags/running__$project");
        system ("$script_base/get_project_sample_sheet.pl $run_base/$rundir $run_base/$rundir/$samplesheet $out_base $project");
        system ("sbatch --job-name=bcl2fastq_${rundir}_$project --output=$outputfolder/slurm.$project.out $script_base/run_bcl2fastq.slurm $run_base/$rundir $outputfolder $script_base $outputfolder/$project.SampleSheet.csv $project");
    }
    close($ss);
}
