function [patch_sim, hist_sim, histogram] = patch_match(testbag, centers, patchnum, codesize, hist_all)

theta = 0.2;
bag_feature = testbag';
codesize = 2 * codesize;
distance = Inf * ones(patchnum, codesize);
hist_conf = -Inf * ones(1,size(hist_all,1));
histogram = zeros(1,codesize);

% for p = 1:patchnum
%     for c = 1:codesize
%         distance(p,c) = norm(centers(:,c) - double(bag_feature(:,p)));
%     end  
% end

distance = slmetric_pw(centers, bag_feature, 'eucdist')';

[tmph,descriptor_vq] = min(distance,[],2);
label = 2*logical(descriptor_vq<(codesize+1))-1;
patch_sim = sum(label .* exp(-tmph/theta));

for p = 1:patchnum
    histogram(descriptor_vq(p)) = histogram(descriptor_vq(p)) + exp(-tmph(p)/theta);
end

histogram = histogram ./ sum(histogram);

sigma = .5;
hist_conf = exp(-slmetric_pw(histogram', hist_all', 'chisq') / sigma);
hist_sim = max(hist_conf);
