# HCP-v3.27-minimal-processing-pipeline  

What began as the chicken scratch in daily-work/bash has evolved since Ben Philip in Occupational Therapy at Washington University expressed interest in putting together a processing pipeline for his data.  He needed it to work on Mac and it needed to be compatible with the FSL GUI for modeling and analysis.  

This is a work in progress. In the HCP/scripts directory are a number of bash programs that are modified versions of the HCP originals. Pardon the funny names. In essence, one installs the stock HCP v3.27 minimal processing pipeline (https://github.com/Washington-University/HCPpipelines/tree/v3.27.0), inserts the "scripts" directory and uses the set up shells here as exemplified by batch.sh.  

One sets up a file such as IHC4.dat and that serves as the driving file to create the scripts to run the pipeline. The example IHC4.dat includes a mere two subjects (ie sessions), but one can stack up many more.

Besides the elimination of the hard coded paths and file names expected in by the stock scripts, the structural pipeline can run without a T2w image and the resolution can be specified to be either 0.7mm, 0.8mm or 1mm from the default of just 0.7mm Glasser space (Glasser 2013).  For the functional pipeline, besides the stock behavior of warping to the 2mm MNI atlas, scans can also remain in the native Glasser space.  The necessary additional outputs are provided for modeling and analysis with the FSL GUI.  
