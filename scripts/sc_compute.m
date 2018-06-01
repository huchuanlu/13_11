function [BH, mean_dist] = sc_compute(spatial)
% [BH,mean_dist]=sc_compute(Bsamp,Tsamp,mean_dist,nbins_theta,nbins_r,r_inner,r_outer,out_vec);
%
% compute (r,theta) histograms for points along boundary 
%
% Bsamp is 2 x nsamp (x and y coords.)
% Tsamp is 1 x nsamp (tangent theta)
% out_vec is 1 x nsamp (0 for inlier, 1 for outlier)
%
% mean_dist is the mean distance, used for length normalization
% if it is not supplied, then it is computed from the data
%
% outliers are not counted in the histograms, but they do get
% assigned a histogram
%
nsamp = size(spatial,1);   
Bsamp = spatial';
Tsamp = zeros(1,nsamp);
out_vec = zeros(1,nsamp);
nbins_theta = 5;
nbins_r = 4;
% r_inner = 1/2;
% r_outer = 3;
in_vec = out_vec == 0;

% compute r,theta arrays
r_array = real(sqrt(dist2(Bsamp',Bsamp'))); % real is needed to
                                          % prevent bug in Unix version
theta_array_abs = atan2(Bsamp(2,:)'*ones(1,nsamp)-ones(nsamp,1)*Bsamp(2,:),Bsamp(1,:)'*ones(1,nsamp)-ones(nsamp,1)*Bsamp(1,:))';
theta_array = theta_array_abs-Tsamp'*ones(1,nsamp);

% create joint (r,theta) histogram by binning r_array and
% theta_array

% normalize distance by mean, ignoring outliers
mean_dist = mean(r_array(1,2:nsamp));

r_outer = log10(max(r_array(1,2:nsamp))) + 1/8;
r_inner = log10(min(r_array(1,2:nsamp))) + 1/8;

% use a log. scale for binning the distances
r_bin_edges = logspace(log10(r_inner(1)),log10(r_outer(1)),5);
r_array_q = zeros(nsamp,nsamp);
for m = 1:nbins_r
   r_array_q = r_array_q+(log10(r_array)<r_bin_edges(m));
end
fz = r_array_q>0; % flag all points inside outer boundary

% put all angles in [0,2pi) range
theta_array_2 = rem(rem(theta_array,2*pi)+2*pi,2*pi);
% quantize to a fixed set of angles (bin edges lie on 0,(2*pi)/k,...2*pi
theta_array_q = 1+floor(theta_array_2/(2*pi/nbins_theta));

nbins = nbins_theta*nbins_r;
fzn = fz(1,:)&in_vec;
Sn = sparse(theta_array_q(1,fzn),r_array_q(1,fzn),1,nbins_theta,nbins_r);
BH = Sn(:)';




