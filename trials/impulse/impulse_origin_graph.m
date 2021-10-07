% Prsent the effect of origin selection on the error of impulse
% computation, as shown by a scatter plot of error on various origin
% locations.
%
% Derek Li, July 2021

% Whether figures generated are to be automatically saved.
savefig = true;

% Paremeters held constant.
sp = 0.1;
fr = 1;
u0 = 1;

[x, y, z, u, v, w, ~] = hill_vortex_3D(sp, fr, u0, 1);

vf = VelocityField.import_grid_separate(x,y,z,u,v,w);
% Subtract freestream.
vf.addVelocity(-vf.U(1,1,1,:))
% Zoom in on vortical region.
vf.setRangePosition(fr*repmat([-1 1], 3, 1))

% Consider stochatic effect of noise introduction.
num_ite = 5;
% Proportional noise. For biases to be properly computed, must include 0.
props = 0: 0.5: 3;
props_count = size(props, 2);

% Mean speed.
u_mean = vf.meanSpeed(0, 0);

% Theoretical momentum.
I0 = vf.fluid.density*[0 2*pi*fr^3*u0*vf.scale.len^4 0]';
% I0 = vf.impulse(0, origin);
i0 = I0(2);

%%%%%%%%%%%%%%%% Graph of error over grid of origins %%%%%%%%%%%%%%%%%%

% Sample origins uniformly from the grid. This is done by making another
% velocity field, which is only used for plotting. The positions of this
% velocity field are the origins.
osp = 1 * ones(1, 3);
oends = [-2 2; -2 2; -2 2];

clear X
[X(:,:,:,1), X(:,:,:,2), X(:,:,:,3)] = meshgrid(oends(1,1): osp(1): oends(1,2), ...
    oends(2,1): osp(2): oends(2,2), oends(3,1): osp(3): oends(3,2));
vfp = VelocityField(X, zeros(size(X)));


% Containers for data across all runs.
% Errors here are mean absolute errors.
err = zeros([vfp.dims 3 props_count num_ite]);
err_box = zeros([vfp.dims 3 props_count num_ite]);
err_gss = zeros([vfp.dims 3 props_count num_ite]);

% Iterate through grid and compute error profile.
% Plot energy estimation error for small and large values of noise.
for n = 1: num_ite
    % This section parallels impulse_err_run.m
    for p = 1: props_count
        vf.clearNoise()
        N = vf.noise_uniform(props(p)*u_mean);
        for j = 1: vfp.dims(1)
            for i = 1: vfp.dims(2)
                for k = 1: vfp.dims(3)
                    err(j,i,k,:,p,n) = vf.impulse(1, squeeze(vfp.X(j,i,k,:))) - I0;
                end
            end
        end
        % Result with box smoothing.
        vf.smoothNoise('box');
        for j = 1: vfp.dims(1)
            for i = 1: vfp.dims(2)
                for k = 1: vfp.dims(3)
                    err_box(j,i,k,:,p,n) = vf.impulse(1, squeeze(vfp.X(j,i,k,:))) - I0;
                end
            end
        end
        % Reset and smooth with gaussian filter.
        vf.setNoise(N)
        vf.smoothNoise('gaussian');
        for j = 1: vfp.dims(1)
            for i = 1: vfp.dims(2)
                for k = 1: vfp.dims(3)
                    err_gss(j,i,k,:,p,n) = vf.impulse(1, squeeze(vfp.X(j,i,k,:))) - I0;
                end
            end
        end
    end
end

% Normalize.
err = abs(err) / i0;
err_box = abs(err_box) / i0;
err_gss = abs(err_gss) / i0;

% Extract bias from a 0 noise level.
bias_ori = squeeze(err(:,:,:,:,1,1));
bias_box = squeeze(err_box(:,:,:,:,1,1));
bias_gss = squeeze(err_gss(:,:,:,:,1,1));

% Average over noise proportions and trials.
err = squeeze(mean(err, [5 6]));
err_box = squeeze(mean(err_box, [5 6]));
err_gss = squeeze(mean(err_gss, [5 6]));

% Take magnitude.
mag_err = squeeze(sqrt(sum(err.^2, 4)));
mag_err_box = squeeze(sqrt(sum(err_box.^2, 4)));
mag_err_gss = squeeze(sqrt(sum(err_gss.^2, 4)));

mag_bias_ori = squeeze(sqrt(sum(bias_ori.^2, 4)));
mag_bias_box = squeeze(sqrt(sum(bias_box.^2, 4)));
mag_bias_gss = squeeze(sqrt(sum(bias_gss.^2, 4)));

%%%%%%%%%%%%%%%% Dimensional Plots %%%%%%%%%%%%%%%%%

% Dimension, i.e., x, y, z, to plot, specified correspondingly by 1, 2, 3.
dims = [];
dim_str = {'x', 'y', 'z'};

% Save plots.
img_fdr = strcat('C:\Users\derek\flow\trials\impulse\origin\global\sp=', ...
    string(osp(1)), '\', 's=', string(osp(1)), '\');
mkdir(img_fdr);

for dim = dims
    % Error due to origin selection.
    vfp.plotScalar(squeeze(bias_ori(:,:,:,dim)), 0, ...
        strcat('$', dim_str{dim}, '$ error of resolution and origin'));
    saveas(gcf, strcat(img_fdr, 'bias-ori-', string(dim), '.fig'))
    % Smoother biases.
    vfp.plotScalar(squeeze(bias_box(:,:,:,dim)), 0, ...
        strcat('$', dim_str{dim}, '$ box smoother bias'));
    saveas(gcf, strcat(img_fdr, 'bias-box-', string(dim), '.fig'))
    vfp.plotScalar(squeeze(bias_gss(:,:,:,dim)), 0, ...
        strcat('$', dim_str{dim}, '$ Gaussian smoother bias'));
    saveas(gcf, strcat(img_fdr, 'bias-gss-', string(dim), '.fig'))
    % Noise added.
    vfp.plotScalar(squeeze(err(:,:,:,dim)), 0, ...
        strcat('$', dim_str{dim}, '$ unfiltered error'));
    saveas(gcf, strcat(img_fdr, 'err-unf-', string(dim), '.fig'))
    % Smoothed.
    vfp.plotScalar(squeeze(err_box(:,:,:,dim)), 0, ...
        strcat('$', dim_str{dim}, '$ mean error after box smoothing'));
    saveas(gcf, strcat(img_fdr, 'err-box-', string(dim), '.fig'))
    vfp.plotScalar(squeeze(err_gss(:,:,:,dim)), 0, ...
        strcat('$', dim_str{dim}, '$ mean error after Gaussian smoothing'));
    saveas(gcf, strcat(img_fdr, 'err-gss-', string(dim), '.fig'))
end

% % Vector plots of error.
% % Error due to origin selection.
% vfp.plotVector(bias_ori, 0, ...
%     'Error of resolution and origin');
% saveas(gcf, strcat(img_fdr, 'bias-ori-v.fig'))
% % Smoother biases.
% vfp.plotVector(bias_box, 0, ...
%     strcat('Box smoother bias'));
% saveas(gcf, strcat(img_fdr, 'bias-box-v.fig'))
% vfp.plotVector(bias_gss, 0, ...
%     strcat('Gaussian smoother bias'));
% saveas(gcf, strcat(img_fdr, 'bias-gss-v.fig'))
% % Noise added.
% vfp.plotVector(err, 0, ...
%     strcat('Unfiltered error'));
% saveas(gcf, strcat(img_fdr, 'err-unf-v.fig'))
% % Smoothed.
% vfp.plotVector(err_box, 0, ...
%     strcat('Mean error after box smoothing'));
% saveas(gcf, strcat(img_fdr, 'err-box-v.fig'))
% vfp.plotVector(err_gss, 0, ...
%     strcat('Mean error after Gaussian smoothing'));
% saveas(gcf, strcat(img_fdr, 'err-gss-v.fig'))


%%%%%%%%%%%%% Magnitude Plots %%%%%%%%%%%%%
% % Error due to origin selection.
% vfp.plotScalar(mag_bias_ori, 0, ...
%     'Magnitude of error of resolution and origin');
% saveas(gcf, strcat(img_fdr, 'bias-ori.fig'))
% % Smoother biases.
% vfp.plotScalar(mag_bias_box, 0, ...
%     strcat('Magnitude of box smoother bias'));
% saveas(gcf, strcat(img_fdr, 'bias-box.fig'))
% vfp.plotScalar(mag_bias_gss, 0, ...
%     strcat('Magnitude of Gaussian smoother bias'));
% saveas(gcf, strcat(img_fdr, 'bias-gss.fig'))

% % Noise added.
% vfp.plotScalar(mag_err, 0, ...
%     strcat('Magnitude of unfiltered error'));
% saveas(gcf, strcat(img_fdr, 'err-unf.fig'))
% % Smoothed.
% vfp.plotScalar(mag_err_box, 0, ...
%     strcat('Magnitude of mean error after box smoothing'));
% saveas(gcf, strcat(img_fdr, 'err-box.fig'))
% vfp.plotScalar(mag_err_gss, 0, ...
%     strcat('Magnitude of mean error after Gaussian smoothing'));
% saveas(gcf, strcat(img_fdr, 'err-gss.fig'))
% 
% % % Save workspace.
% % save(strcat(img_fdr, 'data', string(size(X, 2)), '.mat'))
% 
% disp('Minimum error on hrid')
% disp(min(mag_err(:)))
% 
% disp('Mean error sampled from grid')
% disp(mean(mag_err, 'all'))

% % Optimal origin throgh minimization on THE LAST error profile. Used when a
% % single error profile is considered.
% [origin_min, err_min] = optimal_origin(vf, I0, [0 0 0]', oends);
% disp('Minimum Error within Grid')
% disp(err_min)
% origin_min