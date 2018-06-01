function hist = rgb_hist(n, bin)
%%
hist = zeros(1, bin^3);
n = sort(n(:));
s = length(n);
n = [n; n(end)+1];
u = n(diff(sort(n(:))) == 1);
% u = unique(n);
for i=1:length(u)
    hist(u(i)) = sum(n==u(i)) / s;
end
% hist = hist' / sum(hist);

% n = nnz(diff(sort(n(:)))) + 1;
% 
% hist = zeros(1, bin^3);
% rn = floor(r(:)/(256/bin));
% gn = floor(g(:)/(256/bin));
% bn = floor(b(:)/(256/bin));
% h = rn * bin * bin + gn * bin + bn + 1;
% h = tabulate(h);
% hist(h(:,1)) = h(:,3);