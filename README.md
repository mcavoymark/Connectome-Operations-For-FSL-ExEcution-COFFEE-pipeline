# Connectome Operations For FSL ExEcution (COFFEE) Pipeline  

Ben Philip in Occupational Therapy at Washington University expressed interest in putting together a processing pipeline for his data.  He needed it to work on Mac and it needed to be compatible with the FSL GUI for modeling and analysis.  

In the HCP/scripts directory are a number of bash programs that are modified versions of the HCP originals. Install the stock HCP v3.27 minimal processing pipeline (https://github.com/Washington-University/HCPpipelines/tree/v3.27.0) and insert the "scripts" directory.  The set-up script for the functional pipeline (ie COFFEEfMRIpipeSETUP.sh) checks the phase encoding direction of the SBref's and field maps to ensure compatibility with the BOLD file.  

One sets up a file such as IHC4.dat and that serves as the driving file to create the scripts to run the pipeline. The example IHC4.dat includes a mere two subjects (ie sessions), but one can stack up many more.  Of course, using hard coded paths in the set-up-bash-scripts would increase the readibility of the driving file.

Besides the elimination of the hard coded paths and file names expected in by the stock scripts, the structural pipeline can run without a T2w image and the resolution can be specified to be either 0.7mm, 0.8mm or 1mm from the original of just 0.7mm Glasser space (Glasser 2013).  The pipeline can be run with Freesurfer versions 7.2.0, 7.3.2 and 7.4.0 as well as the default 5.3.0-HCP.  A welcome addition is that the Freesurfer can be edited, and an option reruns just the necessary parts of the structural pipeline.  For the functional pipeline, besides the stock behavior of warping to the 2mm MNI atlas, scans can also remain in the native Glasser space. The phase encoding direction is read from the nifti's json file rather than assumed from the file name. Intensity normalization to a global mean of 10000 is not performed (Glasser 2013). The necessary additional outputs are provided for modeling and analysis with the FSL FEAT GUI.  
