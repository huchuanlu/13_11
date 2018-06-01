This is a preliminary version of the Structured Visual Dictionary tracking (SVDTrack) proposed in

Fan Yang, Huchuan Lu and Ming-Hsuan Yang, "Learning Structured Visual Dictionary for Object Tracking", Image and Vision Computing (IVC), vol. 31, no. 12, pp. 992-999, 2013.

This implementation has been tested with MATLAB2012a and 64-bit Windows 7/8. We are testing its compatibility with other systems.

==============================================
HOW TO RUN THE CODE
==============================================

This implementation uses VLFeat library to extract LBP and SIFT features, and perform k-means clustering. It also uses Distance Metric MATLAB library to compute pairwise distance.

You must have these two libraries installed and compiled, which can be downloaded from
   
VLFeat: http://www.vlfeat.org/
Distance Metric: http://www.mathworks.com/matlabcentral/fileexchange/15935-computing-pairwise-distances-and-metrics

Now you can run the code.
1. in "trackparam" file, specify the testing sequences with initial parameters and directory.

2. run "runtracker". Name of images should be 1, 2, 3, and so on.

3. all results are saved in the "results" folder, with a .mat file storing information of bounding boxes.

==============================================
UPDATE LOG
==============================================

V1.1 2014.6.22
Preliminary version released.

==============================================
NOTICE
==============================================

We are currently adding more comments to the code to improve the readability.

==============================================
CONTACT
==============================================

Any bugs or questions please contact fyang@umiacs.umd.edu