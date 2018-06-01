function histogram_all = do_vq(bag, centers, codebook_size, patchnum, f)
%%

trainbag = bag;
histogram_all = [];
theta = 0.2;

for i = 1:f
    descriptor = trainbag((i-1)*patchnum+1:i*patchnum, :)';
    
    distance = slmetric_pw(centers, descriptor, 'eucdist')';

    [tmp, descriptor_vq] = min(distance, [], 2);  
    histogram = zeros(1, 2*codebook_size);
    
    for p = 1:patchnum
        histogram(descriptor_vq(p)) = histogram(descriptor_vq(p)) + exp(-tmp(p)/theta);
    end
    histogram_all = [histogram_all; histogram ./ sum(histogram)];
end

