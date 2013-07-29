pipeline
========

A modular, file-based analysis pipeline for NGS data

Notes:

 - This is the start of a basic processing pipeline
 - The pipeline starts from demultiplexed fastq files.
 - Modules will initially include

     -  fastqc
     -  cleaning with trimomatic
     -  aligning to a reference with tophat

Each module will have a log file containing

 - name of module
 - command line
 - input files
 - start time
 - execution node
 - end time
 - output files 

A separate trawler script will pick up the log files and parse them (could well fit in with our parallel filesystem walking code)

 
