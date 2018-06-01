function [param, lbpbag, rgbbag, lbpbag_n, rgbbag_n, spatial_all, src_sift, src_locs, src_im, lbp_histogram_all, rgb_histogram_all...
          lbp_h, rgb_h, spatial_c] = dotrack(frm, cfrm, tmpl, param, opt, ...
                                                     patchnum, f, lbp_histogram_all, rgb_histogram_all, spatial_all,...
                                                     rgb_centers, lbp_centers, codebook_size, train_f, src_sift, src_locs, src_im)

n = opt.numsample;
sz = size(tmpl.mean);
N = sz(1) * sz(2);
lbpbag = []; rgbbag = [];
lbpbag_n = []; rgbbag_n = [];
frm = frm/256;
theta = 0.02;
rate = opt.update;
lbp_h = 0; rgb_h = 0; spatial_c = 0;

if ~isfield(param,'lbp_histogram')
    param.lbp_histogram = [];
end
if ~isfield(param,'rgb_histogram')
    param.rgb_histogram = [];
end

param.param = repmat(affparam2geom(param.est(:)), [1,n]);
param.param = param.param + randn(6,n).*repmat(opt.affsig(:),[1,n]);  

wimgs = warpimg(frm, affparam2mat(param.param), sz);                 
diff = repmat(tmpl.mean(:),[1,n]) - reshape(wimgs,[N,n]);
rwimgs = warpimg(double(cfrm(:,:,1)), affparam2mat(param.param), sz);  
bwimgs = warpimg(double(cfrm(:,:,2)), affparam2mat(param.param), sz);  
gwimgs = warpimg(double(cfrm(:,:,3)), affparam2mat(param.param), sz);  

%% check the frame index 
if f <= train_f  
    %% simple tracking 
    coefdiff = 0;
    if (size(tmpl.basis,2) > 0)
        coef = tmpl.basis'*diff;
        diff = diff - tmpl.basis*coef;
        if (isfield(param,'coef'))
            coefdiff = (abs(coef)-abs(param.coef))*tmpl.reseig./repmat(tmpl.eigval,[1,n]);
        else
            coefdiff = coef .* tmpl.reseig ./ repmat(tmpl.eigval,[1,n]);
        end
        param.coef = coef;
    end
    if ~isfield(opt,'errfunc')
        opt.errfunc = [];  
    end
    switch (opt.errfunc)
        case 'robust';
            param.conf = exp(-sum(diff.^2./(diff.^2+opt.rsig.^2))./opt.condenssig)';
        case 'ppca';
            param.conf = exp(-(sum(diff.^2) + sum(coefdiff.^2))./opt.condenssig)';
        otherwise;
            param.conf = exp(-sum(diff.^2)./opt.condenssig)';
    end
    param.conf = param.conf ./ sum(param.conf);
    [~, maxidx] = max(param.conf);
    
    param.est = affparam2mat(param.param(:,maxidx));
    param.wimg = wimgs(:,:,maxidx);
    param.err = reshape(diff(:,maxidx), sz);
    param.recon = param.wimg + param.err;

    [lbpbag_n, rgbbag_n] = sampleNegblock(param.est, 256*frm, cfrm, sz, patchnum);
    [lbpbag, rgbbag] = samplePosblock(param.est, 256*frm, cfrm, sz, patchnum);
    [spatial, src_sift, src_locs] = svd_compute(param.wimg);
    src_im = param.wimg;
    spatial_all = [spatial_all; spatial];
    lbp_histogram_all = []; rgb_histogram_all = [];
else
    %% do svd tracking
    nsample = size(wimgs, 3);
    lbp_hconf = zeros(1,nsample);
    lbp_hist = zeros(nsample, codebook_size*2);
    rgb_hconf = zeros(1,nsample);
    rgb_hist = zeros(nsample, codebook_size*2);
    lbp_feature = [];
    rgb_feature = [];
    spatial_conf = zeros(1,nsample);
    
    %% go through every sample
    for i = 1:nsample
        r = rwimgs(:,:,i);
        b = gwimgs(:,:,i);
        g = bwimgs(:,:,i);
        [lbp_test, rgb_test] = bagblock(256*wimgs(:,:,i), r, b, g, patchnum);
        [~, lbp_hsim, lbp_h] = patch_match( lbp_test, lbp_centers, patchnum, codebook_size, lbp_histogram_all );
        [~, rgb_hsim, rgb_h] = patch_match( rgb_test, rgb_centers, patchnum, codebook_size, rgb_histogram_all );
        lbp_feature = [lbp_feature; lbp_test];
        rgb_feature = [rgb_feature; rgb_test];
        
        lbp_hconf(i) = lbp_hsim;
        lbp_hist(i,:) = lbp_h;
        rgb_hconf(i) = rgb_hsim;
        rgb_hist(i,:) = rgb_h;
        
        spatial_conf(i) = spatial_match(wimgs(:,:,i), spatial_all, src_sift);        
    end
    
    lbp_hconf = lbp_hconf ./ sum(lbp_hconf);
    rgb_hconf = rgb_hconf ./ sum(rgb_hconf);
    spatial_conf = spatial_conf ./ sum(spatial_conf);
    bow_conf = exp(lbp_hconf/(theta^2)) .* exp(rgb_hconf/(theta^2)) .* exp(spatial_conf/(theta^2));
    
    ma_ = max(bow_conf);
    mi_ = min(bow_conf);
    bow_conf = (bow_conf-mi_) / (ma_-mi_);
    bow_conf = bow_conf ./ sum(bow_conf);
    param.conf = bow_conf;
    
    param.param = affparam2mat(param.param);
    [~, idxsort]=sort(param.conf, 'descend');
    portion = 0.05 * nsample;
    cc = param.conf(idxsort(1:portion));
    maxprob = sum(cc);
    cc = cc / sum(cc);
    result = repmat(cc, 6, 1) .* param.param(:,idxsort(1:portion));  %% weighted sum
    param.est = sum(result,2);
    param.wimg = warpimg(frm, param.est, sz);  
    param.conf = param.conf';
    
    lbp_h = sum(lbp_hconf(idxsort(1:portion)));
    rgb_h = sum(rgb_hconf(idxsort(1:portion)));
    spatial_c = sum(spatial_conf(idxsort(1:portion)));
      
    if ~isfield(param, 'max')
        param.max = maxprob;
        r = warpimg(double(cfrm(:,:,1)), param.est, sz);  
        b = warpimg(double(cfrm(:,:,2)), param.est, sz);  
        g = warpimg(double(cfrm(:,:,3)), param.est, sz); 
        [lbpbag, rgbbag] = bagblock( param.wimg, r, b, g, patchnum);
%         [lbpbag_n, rgbbag_n] = sampleNegblock(param.est, frm, cfrm, sz, patchnum, 1);
        param.lbp_histogram = do_vq(lbpbag, lbp_centers, codebook_size, patchnum, 1);
        param.rgb_histogram = do_vq(rgbbag, rgb_centers, codebook_size, patchnum, 1);
    elseif param.max < maxprob
        param.max = maxprob;
        r = warpimg(double(cfrm(:,:,1)), param.est, sz);  
        b = warpimg(double(cfrm(:,:,2)), param.est, sz);  
        g = warpimg(double(cfrm(:,:,3)), param.est, sz); 
        [lbpbag, rgbbag] = bagblock( param.wimg, r, b, g, patchnum);
%         [lbpbag_n, rgbbag_n] = sampleNegblock(param.est, frm, cfrm, sz, patchnum, 1);
        param.lbp_histogram = do_vq(lbpbag, lbp_centers, codebook_size, patchnum, 1);
        param.rgb_histogram = do_vq(rgbbag, rgb_centers, codebook_size, patchnum, 1);
    end
    
    %% extract shape context    
    [BH, t_sift, ~] = svd_compute(param.wimg);
    BH = BH / sum(BH);
    if size(t_sift,1) < 2 
        return;
    else
        des2 = src_sift; 
        des1 = t_sift;
        match = zeros(1,size(des2,1));
        distRatio = 0.7;   
        % For each descriptor in the first image, select its match to second image.
        des1t = des1';                          % Precompute matrix transpose
        for i = 1 : size(des2,1)
           dotprods = single(des2(i,:)) * single(des1t);        % Computes vector of dot products
           [vals,indx] = sort(acos(dotprods));  % Take inverse cosine and sort results

           % Check if nearest neighbor has angle less than distRatio times 2nd.
           if (vals(1) < distRatio * vals(2))
              match(i) = indx(1);
           end
        end
        
        if sum(match~=0) >= 0.4*i
            src_im = param.wimg;
            src_sift = t_sift;
            spatial_all = [spatial_all; BH];
            spatial_all = spatial_all(2:train_f+1,:);
        end
    end

    if mod(f-5, rate) == 0
        lbp_histogram_all = [lbp_histogram_all; param.lbp_histogram];
        rgb_histogram_all = [rgb_histogram_all; param.rgb_histogram];
        lbp_histogram_all = lbp_histogram_all(2:train_f+1,:);
        rgb_histogram_all = rgb_histogram_all(2:train_f+1,:);
        param.max = -Inf;
    end
    
end
