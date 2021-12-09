% Optimize origin selection by minimizing deviation from the integral objective
% origin constraints computed in objective_origin.m, which is suggested in
% (De Voria 2014).
%
% Derek Li, July 2021

% Synethetic data set.
% Paremeters held constant.
sp = 0.1;
fr = 1;
u0 = 1;
[x, y, z, u, v, w, ~] = Hill_Vortex(sp, fr, u0, 1, 1);

vf = VelocityField.importCmps(x, y, z, u, v, w);
% Zoom in on vortical region.
vf.setRangePosition(fr*repmat([-1 1], 3, 1))

% % Use experimental vortex.
% load(sprintf('%s%s', folder, '\data\turbulent_vortex_post.mat'))
% vf = VelocityField.importCmps(x, y, z, u, v, w);% Vortical region.
% vf.setRangePosition([-20 0; -5 25; -35 -5])

% Consider stochatic effect of noise introduction.
num_ite = 10;
% Proportional noise.
props = [0 2];
props_count = size(props, 2);

% Set constant maximal magnitude of noise.
u_mean = vf.meanSpeed(0, 0);

% Theoretical momentum.
I0 = HillImpulse(vf.fluid.density, vf.scale.len, fr, u0, fr);
i0 = I0(2);

% % Momentum computed without noise.
% I0 = vf.impulse([0 0 0]', 0);
% i0 = norm(I0);

% Objective origins identified per noise level per trial. For no filtering,
% box filtering, and Gaussian filtering.
origin_unf = zeros(props_count, num_ite, 3);
err_unf = zeros(props_count, num_ite, 3);
origin_box = zeros(props_count, num_ite, 3);
err_box = zeros(props_count, num_ite, 3);
origin_gss = zeros(props_count, num_ite, 3);
err_gss = zeros(props_count, num_ite, 3);

% Central origin used for comparison.
origin_ref = [0 0 0]';
err0_unf = zeros(props_count, num_ite, 3);
err0_box = zeros(props_count, num_ite, 3);
err0_gss = zeros(props_count, num_ite, 3);

% Minimization options.
min_opt = optimoptions(@fminunc,'Algorithm','trust-region','SpecifyObjectiveGradient',true);
origin0 = [0 0 0]';
% % Central location for experimental vortex.
% origin0 = [-8 10 -21]';

% Identify objective origin under different proportions of noise.
for i = 1: props_count
    for j = 1: num_ite
        vf.clearNoise()
        % Add noise.
        N = vf.noise_uniform(props(i)*u_mean);
        % Identify objective origin without smoothing.
%         % Randomize initial origin guess.
%         origin0 = -2 + 4*rand(3, 1);
        origin = fminunc(@(o) objective_origin(o, vf), origin0, min_opt);
        % Compute corresponding error.
        err_unf(i,j,:) = vf.impulse(origin, 1) - I0;
        err0_unf(i,j,:) = vf.impulse(origin_ref, 1) - I0;
        origin_unf(i,j,:) = origin;
        % Box smoothing and origin identification.
        vf.smoothNoise('box');
        origin = fminunc(@(o) objective_origin(o, vf), origin0, min_opt);
        err_box(i,j,:) = vf.impulse(origin, 1) - I0;
        err0_box(i,j,:) = vf.impulse(origin_ref, 1) - I0;
        origin_box(i,j,:) = origin;
        % Gaussian smoother and identification.
        vf.setNoise(N)
        vf.smoothNoise('gaussian');
        origin = fminunc(@(o) objective_origin(o, vf), origin0, min_opt);
        err_gss(i,j,:) = vf.impulse(origin, 1) - I0;
        err0_gss(i,j,:) = vf.impulse(origin_ref, 1) - I0;
        origin_gss(i,j,:) = origin;
    end
end

err_unf = err_unf / i0;
mag_err_unf = sqrt(sum(err_unf.^2, 3));
err0_unf = err0_unf / i0;
mag_err0_unf = sqrt(sum(err0_unf.^2, 3));

err_box = err_box / i0;
mag_err_box = sqrt(sum(err_box.^2, 3));
err0_box = err0_box / i0;
mag_err0_box = sqrt(sum(err0_box.^2, 3));

err_gss = err_gss / i0;
mag_err_gss = sqrt(sum(err_gss.^2, 3));
err0_gss = err0_gss / i0;
mag_err0_gss = sqrt(sum(err0_gss.^2, 3));

% Mean error profiles.
mean_err_unf = mean(mag_err_unf, 2);
mean_err_box = mean(mag_err_box, 2);
mean_err_gss = mean(mag_err_gss, 2);

mean_err0_unf = mean(mag_err0_unf, 2);
mean_err0_box = mean(mag_err0_box, 2);
mean_err0_gss = mean(mag_err0_gss, 2);

% Relative errors.
err_rel_unf = mean_err0_unf - mean_err_unf;
err_rel_box = mean_err0_box - mean_err_box;
err_rel_gss = mean_err0_gss - mean_err_gss;


%%%%%%%%%%%%%%%%%% Scatter plot of objective origins %%%%%%%%%%%%%%%%%%%
% Font size for title.
fsize = 15;

% Unfiltered.
figure;
dot_size = 20;
origins = squeeze(origin_unf(2,:,:));
scatter3(origins(:,1), origins(:,2), origins(:,3), dot_size, mag_err_unf(2,:), 'filled')

cb = colorbar;
cb.Label.String = 'error per $I$';
cb.Label.Interpreter = 'latex';
xlabel('$x$')
ylabel('$y$')
zlabel('$z$')
title('Error of objective origins without filtering', 'FontSize', fsize)

% Box filtered.
figure;
dot_size = 20;
origins = squeeze(origin_box(2,:,:));
scatter3(origins(:,1), origins(:,2), origins(:,3), dot_size, mag_err_box(2,:), 'filled')

cb = colorbar;
cb.Label.String = 'error per $I$';
cb.Label.Interpreter = 'latex';
xlabel('$x$')
ylabel('$y$')
zlabel('$z$')
title('Error of objective origins after box-filtering', 'FontSize', fsize)

% Gaussian Filtered.
figure;
dot_size = 20;
origins = squeeze(origin_gss(2,:,:));
scatter3(origins(:,1), origins(:,2), origins(:,3), dot_size, mag_err_gss(2,:), 'filled')

cb = colorbar;
cb.Label.String = 'error per $I$';
cb.Label.Interpreter = 'latex';
xlabel('$x$')
ylabel('$y$')
zlabel('$z$')
title('Error of objective origins after Gaussian-filtering', 'FontSize', fsize)

disp('Average error at objective origin:')
fprintf('Unfilteed: %f\n', mean(mag_err_unf(2,:)))
fprintf('Box: %f\n', mean(mag_err_box(2,:)))
fprintf('Gaussian: %f\n', mean(mag_err_gss(2,:)))