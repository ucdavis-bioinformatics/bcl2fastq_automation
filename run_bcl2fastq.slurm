#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=180
#SBATCH --ntasks=18 # Number of cores
#SBATCH --mem=8000 # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH --partition=dev,gpu,intel,assembly

start=`date +%s`
hostname
echo "My SLURM_JOB_ID"
echo $SLURM_JOB_ID

module load bcl2fastq

runfolder=$1
outfolder=$2
scriptfolder=$3
samplesheet=$4
project=$5

echo run_bcl2fastq.pl $runfolder/RunInfo.xml $samplesheet $runfolder $outfolder
${scriptfolder}/run_bcl2fastq.pl $runfolder/RunInfo.xml $samplesheet $runfolder $outfolder

if [ $? -ne 0 ]
then
    touch ${outfolder}/flags/error__$project
else
	touch ${outfolder}/flags/done__$project
fi

rm ${outfolder}/flags/running__$project

end=`date +%s`
runtime=$((end-start))
echo $runtime
