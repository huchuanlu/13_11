function [lbpbag_n, rgbbag_n] = samplePosblock(param, frm, cfrm, sz, patchnum)
%%
train_num = 20;
theta = [1,1,0,0,0,0];
lbpbag_n = []; rgbbag_n = [];
par = repmat(affparam2geom(param(:)), [1,train_num]);
pos_param = par + randn(6,train_num) .* repmat(theta(:),[1,train_num]);
wimgs = warpimg(frm, affparam2mat(pos_param), sz);                 
rwimgs = warpimg(double(cfrm(:,:,1)), affparam2mat(pos_param), sz);  
bwimgs = warpimg(double(cfrm(:,:,2)), affparam2mat(pos_param), sz);  
gwimgs = warpimg(double(cfrm(:,:,3)), affparam2mat(pos_param), sz);  
for i = 1:size(pos_param,2)
    [lbpbag, rgbbag] = bagblock(wimgs(:,:,i), rwimgs(:,:,i), bwimgs(:,:,i), gwimgs(:,:,i), patchnum);
    lbpbag_n = [lbpbag_n; lbpbag];
    rgbbag_n = [rgbbag_n; rgbbag];
end

      