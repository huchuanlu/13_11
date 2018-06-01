%% A preliminary implementation of the structured visual dictionary (SVD) tracking method proposed by 
%%     Fan Yang, Huchuan Lu and Ming-Hsuan Yang, "Learning Structured Visual Dictionary for Object Tracking",
%%     Image and Vision Computing (IVC), vol. 31, no. 12, pp. 992-999, 2013.
%% All rights reserved.

clc; clear; close all;
warning('off');
cmd = {'-outdir', './scripts/', '-O', './scripts/interp2.cpp'};
mex(cmd{:});
addpath('./scripts/');

%% load initial parameters
trackparam;
imgs = dir([dataPath, '*.' img_type]);
imgs_num = length(imgs);
iframe = imread([dataPath '1.' img_type]);
frame = double(rgb2gray(iframe))/256;

%% parameters for simple tracking
if ~exist('opt','var')        opt = [];  end
if ~isfield(opt,'tmplsize')   opt.tmplsize = [64 64];  end             
if ~isfield(opt,'condenssig') opt.condenssig = 0.01;  end
if ~isfield(opt,'errfunc')    opt.errfunc = 'L2';  end               
                                       
tmpl.mean = warpimg(frame, param0, opt.tmplsize);       
tmpl.basis = [];                                        
tmpl.eigval = [];                                       
tmpl.numsample = 0;                                     
tmpl.reseig = 0;                                        
sz = size(tmpl.mean);  
N = sz(1)*sz(2);                                       

param = [];
param.est = param0;                                    
param.wimg = tmpl.mean;                                


%% initialization
rst = [];
rgbtrain = []; lbptrain = [];
rgb_neg_bag = []; lbp_neg_bag = [];
lbp_histogram_all = []; rgb_histogram_all = [];
albp_centers = []; argb_centers = [];
lbp_neg_centers = []; rgb_neg_centers = [];
spatial_all = []; lbpspatial_all = [];
src = []; locs = []; im = [];

%% tracking begins
for f = 1:imgs_num
    %% read image
    img_index = sprintf('%d', f);
    iframe = imread([dataPath img_index '.' img_type]);
    frame = double(rgb2gray(iframe));
    cframe = double(iframe);
    
    %% do tracking
    [param, lbpbag, rgbbag, lbpbag_n, rgbbag_n, spatial_all, src, locs, im, lbp_histogram_all, rgb_histogram_all...
     lbp_hconf, rgb_hconf, spatial_conf] = dotrack(frame, cframe, tmpl, param, opt, patchnum, f,...
                                                     lbp_histogram_all, rgb_histogram_all, spatial_all,...
                                                     argb_centers, albp_centers, codebook_size, train_frames, src, locs, im);   
                      
    %% collect data                                             
    rgbtrain = [rgbtrain; rgbbag];
    rgb_neg_bag = [rgb_neg_bag; rgbbag_n];
    lbptrain = [lbptrain; lbpbag];
    lbp_neg_bag = [lbp_neg_bag; lbpbag_n];
    
    %% appearance keywords 
    if f == train_frames
        lbp_centers = vl_kmeans(lbptrain', codebook_size);
        rgb_centers = vl_kmeans(rgbtrain', codebook_size);
        lbp_neg_centers = vl_kmeans(lbp_neg_bag', codebook_size);
        rgb_neg_centers = vl_kmeans(rgb_neg_bag', codebook_size);
        albp_centers = [lbp_centers lbp_neg_centers];
        argb_centers = [rgb_centers rgb_neg_centers];
        lbp_histogram_all = do_vq(lbptrain, albp_centers, codebook_size, patchnum, f);
        rgb_histogram_all = do_vq(rgbtrain, argb_centers, codebook_size, patchnum, f);
        lbptrain = [];
        rgbtrain = [];
        lbp_neg_bag = [];
        rgb_neg_bag = [];    
    end
    
    %% clean up old data
    if f > train_frames && size(rgbtrain,1)/patchnum == 4
        lbptrain = [];
        rgbtrain = [];
        lbp_neg_bag = [];
        rgb_neg_bag = [];
    end

    %% save results
    rst = [rst; param.est'];

    %% draw tracking results
    if ~exist('drawopt', 'var')
        drawopt = drawtrackresult([], f, iframe, tmpl, param);
    else
        drawopt = drawtrackresult(drawopt, f, iframe, tmpl, param);
    end
    imwrite(frame2im(getframe(gcf)),sprintf('results/%s/%s_%04d.png', video, video, f));

end

%% save results
strFileName = sprintf('results/%s/%s.mat', video, video);
save(strFileName, 'rst');

