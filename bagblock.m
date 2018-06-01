function [lbpbag, rgbbag] = bagblock(I, r, b, g, patchnum)
%%
bin = 4;
[h w] = size(single(I));
r = floor(r/(256/bin));
g = floor(g/(256/bin));
b = floor(b/(256/bin));
color = r * bin * bin + g * bin + b + 1;

rgbbag = zeros(patchnum, 64); 
lbpbag = zeros(patchnum, 58);
minsize = 4;
maxsize = 8;
meansize = 6;
x = meansize + floor(rand(1,patchnum) * (w-2*meansize));
y = meansize + floor(rand(1,patchnum) * (h-2*meansize));
psize = minsize + floor(rand(1,patchnum) * (maxsize-minsize));
bound1 = min(y, min(psize, x));
bound2 = min(h-1-y, min(psize, w-1-x));
bound = max(minsize, min(bound1, bound2));
for i = 1: patchnum
    lbp_patch = I(y(i)-bound(i)+1 : y(i)+bound(i), x(i)-bound(i)+1 : x(i)+bound(i));
    color_patch = color(y(i)-bound(i)+1 : y(i)+bound(i), x(i)-bound(i)+1 : x(i)+bound(i));
    patchsize = size(lbp_patch);
    lbp = vl_lbp(single(lbp_patch), patchsize(1));
    lbpbag(i,:) = lbp(:)';
    rgbbag(i,:) = rgb_hist(color_patch, bin);
end
