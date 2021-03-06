function [fres, dI, dI_box, dI_gss, dI0, bias_box, bias_gss, di, di_box, ...
    di_gss, di0, mag_bias_box, mag_bias_gss, dI_sd, dI_sd_box, dI_sd_gss, ...
    di_sd, di_sd_box, di_sd_gss, vfds, t] = ...
    impulse_resol(l, vr, u0, min_fres, max_fres, fres_inc, origin, props, err_level, ...
        num_ite, window_params, display_plot, vfds)
% Variation of error with feature resolution. Parameters held constant are
% 'fr', 'origin', and 'props'. At low resolutions, depending on whether the
% spacing perfectly divides the (-1, 1) region, e.g. s = 0.1 does, s = 0.3
% does not, rather discrepant behavior can be observed.
%
% Note that the proportions of error given in 'props' must include 0 as the
% first entry, so that the baseline resolution errors can be computed. When
% the error over various noise levels are averaged, supposing more than one
% nonzero noise level is given in props, the average does not include the
% baseline error with no noise.

% Radius of vortex.
fr = l*vr;
% Desired feature resolutions.
fres = min_fres: fres_inc: max_fres;

% If a cell array of VelocityField objects are given, assume they are of
% the appropriate resolutions and already downsampled.
if ~exist('vfds', 'var')
    vfds = cell(1, length(fres));
else
    % Non-trivial windowing parameters will be ignored if an array of VFs
    % is provided.
    window_params = [];
end

% Configure windowing parameters, if applicable.
windowing = false;
if isvector(window_params) && length(window_params) == 2
    windowing = true;
    winsize = window_params(1);
    overlap = window_params(2);
end

% Generate range of spacings for evenly spaced feature resolutions.
if ~windowing
    % Global spacing of downsampled data.
    sps = zeros(1, floor((max_fres-min_fres)/fres_inc) + 1);
    % Minimal feature resolution.
    sps(1) = fr / min_fres;
    for i = 2: size(sps, 2)
        sps(i) = fr / (fres_inc + fr/sps(i-1));
    end
else
    % Compute initial resolutions to produce the desired given feature
    % resolutions after downsampling.
    op = round(winsize .* overlap);
    op = min([op; winsize-1], [], 1);
    sps = 2*fr ./ (2*fres * (winsize-op) + winsize - 1);
end
sps_count = size(sps, 2);
% Normalize spacing.
spr = sps / fr;
% Record feature resolutions.
fres = zeros(1, sps_count);

% Vortex parameters.
density = 1000;
len_unit = 1e-3;
% Theoretical impulse values.
I0 = Hill_Impulse(density, len_unit, fr, u0);

% Containers of error.
dI = zeros(3, sps_count);
dI_box = zeros(3, sps_count);
dI_gss = zeros(3, sps_count);

dI_sd = zeros(3, sps_count);
dI_sd_box = zeros(3, sps_count);
dI_sd_gss = zeros(3, sps_count);

% Magnitudes.
di = zeros(1, sps_count);
di_box = zeros(1, sps_count);
di_gss = zeros(1, sps_count);
di_sd = zeros(1, sps_count);
di_sd_box = zeros(1, sps_count);
di_sd_gss = zeros(1, sps_count);

di0 = zeros(1, sps_count);
mag_bias_box = zeros(1, sps_count);
mag_bias_gss = zeros(1, sps_count);

bias_box = zeros(3, sps_count, 1);
bias_gss = zeros(3, sps_count, 1);

% Error due purely to the imperfection of resolution and origin selection.
dI0 = zeros(3, sps_count);

for k = 1: sps_count
    disp(['Spacing ' num2str(k)])
    % Generate VF of appropriate resolution if necessary.
    if isempty(vfds{k})
        % Construct Hill vortex with specified resolution.
        [x, y, z, u, v, w] = Hill_Vortex(spr(k), l, vr, u0, 1);
        vf = VelocityField.importCmps(x, y, z, u, v, w);
        % Focus on vortical region.
        vf.setRangePosition(fr*repmat([-1 1], 3, 1));
    else
        vf = vfds{k};
    end
    
    [dI(:,k), dI_box(:,k), dI_gss(:,k), dI0(:,k), bias_box(:,k), bias_gss(:,k), ...
        dI_sd(:,k), dI_sd_box(:,k), dI_sd_gss(:,k), di(:,k), di_box(:,k), di_gss(:,k), ...
        di0(k), mag_bias_box(k), mag_bias_gss(k), di_sd(k), di_sd_box(k), di_sd_gss(k), vfd] = ...
        impulse_err_run_constN(vf, props, origin, I0, num_ite, window_params, {});
    % Compute resolutions after downsampling, if applicable.
    fres(k) = (vfd.span(1)-1)/2;
    % Store this vf to return.
    vfds{k} = vfd;
end

% Compute minimum resolution needed when smoothers are applied. First row
% corresponds to biases; second row, noisy error. Box, first column;
% Gaussian, second.
min_res = -1*ones(2, 2);

% Lowest feature resolutions to achieve the desired error level.
try
    min_res(1,1) = fres(find(di0 < err_level, 1));
catch
end
try
    min_res(1,2) = fres(find(mag_bias_gss < err_level, 1));
catch
end

% try
%     min_res(2,1) = fres(find(di_box < err_level, 1));
% catch
% end
try
    min_res(2,2) = fres(find(di_gss < err_level, 1));
catch
end

disp('---------Impulse minimal resolutions---------')
% Print resolution requirements.
fprintf('Minimum resolution for %.0f%% bias: \n', err_level*100)
fprintf('Original: %d \n', min_res(1,1))
fprintf('Gaussian: %d \n', min_res(1,2))

fprintf('Minimum resolution for %.0f%% noise-propagated error: \n', err_level*100)
% fprintf('Box: %d \n', min_res(2,1))
fprintf('Gaussian: %d \n', min_res(2,2))

%%%%%%%%%%%%%%%% Dimensional Plots %%%%%%%%%%%%%%%%%
% Dimension, i.e., x, y, z, to plot, specified correspondingly by 1, 2, 3.
dims = [3];
dim_str = {'x', 'y', 'z'};

if ~display_plot
    return
end

% Font.
font = 'Arial';
fontSize = 8;

% Handles to figures to return.
axes = {};

figure;
t = tiledlayout(1, 2);

for dim = dims
    % Smoother bias plot.
%     figure;
    nexttile;
    scatter(fres, dI0(dim,:), 'ko', 'MarkerFaceColor', 'black', 'LineWidth', 1)
    hold on
    scatter(fres, bias_box(dim,:), 'r*', 'LineWidth', 1)
    hold on
    scatter(fres, bias_gss(dim,:), 'b^','filled', 'LineWidth', 1)
    
    legend({'Unfiltered', 'Box', 'Gaussian'}, 'Interpreter', 'none','Location','northeast')
    
%     legend({'unfiltered', ...
%         'box-filtered', ...
%         'Gaussian-filtered'}, ...
%         'Interpreter', 'latex')
    xlabel('\kappa', 'FontName', font, 'FontSize', 1.25*fontSize,'interpreter','tex')
    ylabel('$\frac{\delta I}{I}$', 'FontName', font, 'FontSize', 1.5*fontSize)
    title('(a) Axial impulse error', 'FontName', font, 'FontSize', fontSize,'interpreter','latex','fontweight','normal')
    xlim([2 28])
    ylim([-0.041 0.041])
    axes{end+1} = gca;
    axes{end}.YLabel.Rotation = 0;
    axes{end}.YLabel.Position(1) = axes{end}.YLabel.Position(1)-0.1;
    box on

%     % Mean error plot.
%     figure;
%     errorbar(fres, dI(dim,:), dI_sd(dim,:), 'ko', 'MarkerFaceColor','black', 'LineWidth', 1)
%     hold on
%     errorbar(fres, dI_box(dim,:), dI_sd_box(dim,:), 'ko', 'MarkerFaceColor','red', 'LineWidth', 1)
%     hold on
%     errorbar(fres, dI_gss(dim,:), dI_sd_gss(dim,:), 'ko', 'MarkerFaceColor','blue', 'LineWidth', 1)
%     
%     legend({'unfiltered', ...
%         'box-filtered', ...
%         'Gaussian-filtered'}, ...
%         'Interpreter', 'latex')
%     xlabel('Feature resolution', 'FontName', font, 'FontSize', fontSize)
%     ylabel('Proportional error', 'FontName', font, 'FontSize', fontSize)
%     title(sprintf('Impulse error in $\\hat{%s}$ under noise', string(dim_str{dim})), 'FontName', font, 'FontSize', fontSize)
end


%%%%%%%%%%%%%%%%%%% Magnitude Plots %%%%%%%%%%%%%%%%%%%%

% % Smoother bias plot.
% figure;
% scatter(fres, di0, 'ko', 'MarkerFaceColor', 'black', 'LineWidth', 1)
% hold on
% scatter(fres, mag_bias_box, 'ko', 'MarkerFaceColor', 'red', 'LineWidth', 1)
% hold on
% scatter(fres, mag_bias_gss, 'ko', 'MarkerFaceColor', 'blue', 'LineWidth', 1)
% hold on
% 
% legend({'unfiltered', 'box filtered', ...
%     'Gaussian-filtered'}, ...  
%     'Interpreter', 'latex')
%     xlabel('Feature resolution', 'FontName', font, 'FontSize', fontSize)
%     ylabel('Proportional error', 'FontName', font, 'FontSize', fontSize)
% title('Impulse resolution error magnitude')

% Mean error plot.
% figure;
nexttile;
errorbar(fres, di, di_sd, 'ko', 'MarkerFaceColor','black', 'LineWidth', 1)
hold on
%errorbar(fres, di_box, di_sd_box, '*', 'Color', 'red', 'LineWidth', 1)
% hold on
errorbar(fres, di_gss, di_sd_gss, '^', 'Color','blue','MarkerFaceColor','blue','LineWidth', 1)

legend({'Unfiltered', 'Gaussian'}, 'Interpreter', 'none')
%legend({'Unfiltered', 'Box', 'Gaussian'}, 'Interpreter', 'none')
xlim([2 28])
xlabel('\kappa', 'FontName', font, 'FontSize', 1.25*fontSize,'interpreter','tex')
ylabel('$\frac{|\delta I|}{I}$', 'FontName', font, 'FontSize', 1.5*fontSize)
title('(b) $\frac{\delta u}{u_0}$ = 1.5','FontName', font, 'FontSize', fontSize,'interpreter','latex','fontweight','normal')
axes{end+1} = gca;
axes{end}.YLabel.Rotation = 0;
axes{end}.YLabel.Position(1) = axes{end}.YLabel.Position(1)-1.3;