function [BH, sifts, locs] = svd_compute(I)

%%
[locs, sifts] = vl_sift(single(256*I));
sifts = sifts';
locs = locs';
if size(sifts,1) == 0
    BH = zeros(1,20);
else
    cy = size(I,1)/2;
    cx = size(I,2)/2;
    spatial = [cx cy; [locs(:,1) locs(:,2)]];
    [BH, ~] = sc_compute(spatial);
    BH = BH / sum(BH);
end