function conf = spatial_match(I, spatial_all, src_sift)
%%
[locs, new_sift] = vl_sift(single(256*I));
new_sift = new_sift';
locs = locs';
des1 = src_sift;
des2 = new_sift;

match = zeros(1,size(des2,1));
distRatio = 0.6;   
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

% sifts = new_sift;
sifts = des2(match>0,:);
locs = locs(match>0,:);
if size(sifts,1) == 0
    BH = zeros(1,20);
else
    cy = size(I,1)/2;
    cx = size(I,2)/2;
    spatial = [cx cy; [locs(:,1) locs(:,2)]];
    [BH, ~] = sc_compute(spatial);
    BH = BH / sum(BH);
end

sigma = 10;
hist_conf = exp(-slmetric_pw(BH', spatial_all', 'chisq') / sigma);
conf = max(hist_conf);
