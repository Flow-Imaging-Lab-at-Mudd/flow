function [dI, dI_box, dI_gss, dI0, bias_box, bias_gss, dI_sd, dI_sd_box, dI_sd_gss, ...
    di, di_box, di_gss, di0, mag_bias_box, mag_bias_gss, di_sd, di_sd_box, di_sd_gss, vf] = ...
    impulse_err_run(vf, props, origin, I0, num_ite, window_params, display_plots)
% The theoretical (expected) impulse of the currently effective region is
% passed in as 'I0' to determine the error.
% 
% Introduce levels of noise proportional to the mean speed in the effective
% region, according to 'props', e.g. 0: 0.1: 3. 'vf' is presume to have
% range properly set. 'origin' specifies the reference point to which
% impulse calculations are performed.
%
% 'num_ite' specifies the number of iterations the computation is to be
% repeated and their results averaged to account for stochasticity.
%
% 'display_plots' is a boolean for displaying plots generated noise
% propagation plots herein. Which specific types of plots are chosen must
% be indicated inside this file. Magnitude plots are by deafult displayed
% if a true value is passed in.
%
% Derek Li, November 2021

% Optional windowing operation.
if isvector(window_params) && length(window_params) == 2
    winsize = window_params(1);
    overlap = window_params(2);
    vf = vf.downsample(winsize, overlap, 0);
end

props_count = length(props);

% Set constant maximal magnitude of noise.
u_mean = vf.meanSpeed(0, 0);

% Theoretical momentum.
i0 = norm(I0);

% Error in impulse computation given noise.
dI = zeros(3, props_count, num_ite);
% Box smoothing.
dI_box = zeros(3, props_count, num_ite);
% Gaussian smoothing.
dI_gss = zeros(3, props_count, num_ite);

% Plot energy estimation error for small and large values of noise.
for i = 1: props_count
    for j = 1: num_ite
        vf.clearNoise();
        N = vf.noise_uniform(props(i)*u_mean);
        dI(:,i,j) = vf.impulse(origin, 1) - I0;
        % Result with box smoothing.
        vf.smoothNoise('box');
        dI_box(:,i,j) = vf.impulse(origin, 1) - I0;
        % Reset and smooth with gaussian filter.
        vf.setNoise(N)
        vf.smoothNoise('gaussian');
        dI_gss(:,i,j) = vf.impulse(origin, 1) - I0;
    end
end

% Normalize by magnitude of impulse in the region.
dI = dI / i0;
dI0 = dI(:,1,1);
di = squeeze(sqrt(sum(dI.^2, 1)));
di0 = di(1,1);
dI_box = dI_box / i0;
di_box = squeeze(sqrt(sum(dI_box.^2, 1)));
dI_gss = dI_gss / i0;
di_gss = squeeze(sqrt(sum(dI_gss.^2, 1)));

% Average.
dI_sd = std(dI, 0, 3);
di_sd = std(di, 0, 2);
dI_sd_box = std(dI_box, 0, 3);
di_sd_box = std(di_box, 0, 2);
dI_sd_gss = std(dI_gss, 0, 3);
di_sd_gss = std(di_gss, 0, 2);

dI = squeeze(mean(dI, 3));
di = mean(di, 2);
dI_box = squeeze(mean(dI_box, 3));
di_box = mean(di_box, 2);
dI_gss = squeeze(mean(dI_gss, 3));
di_gss = mean(di_gss, 2);

% Baseline smoother biases.
bias_box = dI_box(:, 1);
bias_gss = dI_gss(:, 1);

mag_bias_box = di_box(1);
mag_bias_gss = di_gss(1);

%%%%%%%%%%%%%%%%%%%%% Visualization %%%%%%%%%%%%%%%%%%%%%%
if ~exist('display_plots', 'var') || ~display_plots
    return
end
% Dimension, i.e., x, y, z, to plot, specified correspondingly by 1, 2, 3.
dims = [2];
dim_str = {'x', 'y', 'z'};

%%%%%%%%%%% Plot signed impulse error %%%%%%%%%%%%%%%
plot_dim_err = 1;

if plot_dim_err
    for dim = dims
        figure;
        errorbar(props, dI(dim,:), dI_sd(dim,:), 'ko', 'MarkerFaceColor', 'black', 'LineWidth', 1)
        hold on
        errorbar(props, dI_box(dim,:), dI_sd_box(dim,:), 'ko', 'MarkerFaceColor', 'red', 'LineWidth', 1)
        hold on
        err_mean_box = mean(dI_box(dim,:));
        yline(err_mean_box, '-')
        hold on
        errorbar(props, dI_gss(dim,:), dI_sd_gss(dim,:), 'ko', 'MarkerFaceColor', 'blue', 'LineWidth', 1)
        hold on
        err_mean_gss = mean(dI_gss(dim,:));
        yline(err_mean_gss, '-')
        
        legend({'unfiltered error', ...
            'box-filtered $\vec{u}$', ...
            strcat('box mean $\frac{\delta I_y}{I} = $', string(err_mean_box)), ...
            'Gaussian-filtered $\vec{u}$', ...
            strcat('Gaussian mean $\frac{\delta I_y}{I} = $', string(err_mean_gss))})
        xlabel('$\frac{|\delta u|}{\bar{u}}$')
        ylabel(strcat('$\frac{\delta I_', dim_str{dim}, '}{I}$'))
        title(strcat('$', dim_str{dim}, '$ Impulse Error'))
    end
end

%%%%%%%%%%%%%%%%%% Plot absolute impulse error %%%%%%%%%%%%%%%%%%%%
plot_abs = 0;

if plot_abs
    for dim = dims
        abs_dI = abs(dI);
        abs_dI_box = abs(dI_box);
        abs_dI_gss = abs(dI_gss);
        
        figure;
        errorbar(props, abs_dI(dim,:), dI_sd(dim,:), 'ko', 'MarkerFaceColor', 'black', 'LineWidth', 1)
        hold on
        err_mean0 = mean(abs_dI(dim, :));
        yline(err_mean0, '-')
        hold on
        errorbar(props, abs_dI_box(dim,:), dI_sd_box(dim,:), 'ko', 'MarkerFaceColor', 'red', 'LineWidth', 1)
        hold on
        err_mean_box = mean(abs_dI_box(dim,:));
        yline(err_mean_box, '-')
        hold on
        errorbar(props, abs_dI_gss(dim,:), dI_sd_gss(dim,:), 'ko', 'MarkerFaceColor', 'blue', 'LineWidth', 1)
        hold on
        err_mean_gss = mean(abs_dI_gss(dim,:));
        yline(err_mean_gss, '-')
        
        legend({'unfiltered error', ...
            strcat('unfiltered mean $|\frac{\delta I_y}{I}| = $', string(err_mean0)), ...
            'box-filtered $\vec{u}$', ...
            strcat('box mean $|\frac{\delta I_y}{I}| = $', string(err_mean_box)), ...
            'Gaussian-filtered $\vec{u}$', ...
            strcat('Gaussian mean $|\frac{\delta I_y}{I}| = $', string(err_mean_gss))})
        xlabel('$\frac{|\delta u|}{\bar{u}}$')
        ylabel(strcat('$\left|\frac{\delta I_', dim_str{dim}, '}{I}\right|$'))
        title(strcat('Absolute', ' $', dim_str{dim}, '$ Impulse Error'))
    end
end

%%%%%%%%%%% Error magnitude %%%%%%%%%%%%
figure;
errorbar(props, di, di_sd, 'ko', 'MarkerFaceColor', 'black', 'LineWidth', 1)
hold on
errorbar(props, di_box, di_sd_box, 'ko', 'MarkerFaceColor', 'red', 'LineWidth', 1)
hold on
errorbar(props, di_gss, di_sd_gss, 'ko', 'MarkerFaceColor', 'blue', 'LineWidth', 1)
hold on
yline(mag_bias_box, '-', 'Color', 'r')
hold on
yline(mag_bias_gss, '-', 'Color', 'b')

legend({'unfiltered error', 'box-filtered', 'Gaussian-filtered', ...
   sprintf('box $\\kappa = %.3f$', string(mag_bias_box)), ...
   sprintf('Gaussian $\\kappa = %.3f$', string(mag_bias_gss))})

xlabel('$\frac{|\delta u|}{\bar{u}}$')
ylabel('$\frac{|\delta I|}{\bar{I}}$')
title('Magnitude of Impulse Error')

%%%%%%%%%%%% Impulse error vs impulse noise, in magnitude%%%%%%%%%%%%
plot_noise_err = 0;

if plot_noise_err
    figure;
    scatter(di, di_box, 'r', 'filled')
    hold on
    scatter(di, di_gss, 'b', 'filled')
    hold on
    % 1-1 line.
    plot(di, di, 'black')
    hold on
    yline(mag_bias_box, '-', 'Color', 'r')
    hold on
    yline(mag_bias_gss, '-', 'Color', 'b')
    
    legend({'box-filtered', 'Gaussian-filtered', ...
        'identity line', ...
        sprintf('box $\\kappa = %.3f$', string(mag_bias_box)), ...
        sprintf('Gaussian $\\kappa = %.3f$', string(mag_bias_gss))}, ...
        'Interpreter', 'latex')
    
    xlabel('Unfiltered $|\frac{\delta I}{I}|$')
    ylabel('Filtered $\frac{|\delta I|}{\bar{I}}$')
    title('Smoother Efficacy')
end

%%%%%%%%%%%%% Smoothing errors as proportion of smoother bias %%%%%%%%%%%%
err_prop_box = abs(dI_box / mag_bias_box);
err_prop_gss = abs(dI_gss / mag_bias_gss);

plot_prop_err = 0;

if plot_prop_err
    for dim = dims
        figure;
        scatter(props, err_prop_box(dim,:), 'r', 'filled')
        hold on
        scatter(props, err_prop_gss(dim,:), 'b', 'filled')       
        legend({sprintf('box $\\kappa = %.3f$', string(mag_bias_box)), ...
            sprintf('Gaussian $\\kappa = %.3f$', string(mag_bias_gss))}, ...
            'Interpreter', 'latex')
        xlabel('$\frac{|\delta u|}{\bar{u}}$')
        ylabel(strcat('$\frac{\left|\frac{\delta I_', dim_str{dim}, '}{I}\right|}{\kappa}$'))
        title(strcat('$', dim_str{dim}, '$ Error Proportional to Smoother Bias'))
    end
end