# SocialCog

**Design**
* 2 runs
  * 10 Blocks per run
    * 1 Block = 4 trials
      * 1 trial = 2 seconds context -> 1 second of face -> 4 seconds of face + rate bar
      * Context images are all same cetegory (Pleasant or Unpleasant)
        * These are randomly selected using sample
      * There are 18 unique female faces
      * There are 22 unqiue male faces (27 and 28 currently excluded)
      * Blocks were created to try to always have equal number of genders (Blocks.csv)
      * Each face has 2 expressions: NeutFear and NeutHappy (80 total face images)
      * There are 3 different block types:
        * 1: 1 = NeutFear, 3 = NeutHappy (3 total per run)
        * 2: 2 = NeutFear, 2 = NeutHappy (4 total per run)
        * 3: 3 = NeutFear, 1 = NeutHappy (3 total per run)
      * Face images are randomly selected per block using sample
  * Block type order is randomized, using sample (maybe look into counterbalancing)
  
**Design Options**
* InScan
  * 1 = Yes, this will make the presentations opaque
  * 2 = No, this will make the presentations translucent which is usefull for debugging. If an error occurs in this mode, enter "sca" without quotes in the Matlab terminal to close the experiemehnt.
* Participant ID: self explanatory; a directory Responses/[ID] will be created to store participant output
* StartRun: run to start
* EndRun: run to end
* Testing
  * 1 = Yes, this will use TestOrder.csv as the design which is signficiantly shorter for testing purposes
  * 2 = No, this will use Design.csv as the design which is what you want to use in the scanner
* Suppress
  * 1 = Yes, suprress all psychtoolbox output
  * 2 = No, do not suppress psychtoolobx output
  
**File/Directory Descriptions**
* SocialCognitionTask.m - matlab script to run the social cognition task
* Design.csv - csv file listing the trials used in the experiment. Manually edit this file if you want to use a specific trial order, but make sure you keep the same format; otherwise, the task will not run.
* GetDevice.m - matlab file to list connected devices to computer. Use this to identify the DeviceIndex value for SocialCognitionTask. This is useless for Windows machines (confirm this statement).
* Contextual - directory containing contextual images (separated by category and subcategory)
* Faces - directory containing face images (separated by gender; category is listed in file name)
* ImageCsvs/Blocks.csv - **(imporant file used for creating Design.csv)**; lists the following:
  * available block types for run
  * context type displayed for block
  * number of male and female faces per block
* ImageCsvs/CreateDesign.R - creates Design.csv

