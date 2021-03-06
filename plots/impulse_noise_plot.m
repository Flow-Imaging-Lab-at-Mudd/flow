% Font.
font = 'Arial';
fontSize = 8;
% Only for title.
fontWeight = 'normal';

%%%%%% Plots of 3D Hill's vortex without noise %%%%%%%%
l = 1;
vr = 1;
% Radius of vortex.
spr = 0.05;

% lower resolution option for supplement
spr2 = 0.1;

[x, y, z, u, v, w] = Hill_Vortex(spr, l, vr, 1, 1);
[x2, y2, z2, u2, v2, w2] = Hill_Vortex(spr2, l, vr, 1, 1);
vf = VelocityField.importCmps(x, y, z, u, v, w);
vf2 = VelocityField.importCmps(x2, y2, z2, u2, v2, w2);

% Proportions of noise.
props = 0: 0.5: 3;

I0 = Hill_Impulse(vf.fluid.density, vf.scale.len, 1, 1);

% Panel figures.
t = tiledlayout(1,2);

nexttile
% Plot at two resolutions
impulse_err_run(vf2, props, [0 0 0]', I0, 20, [], {'mag'});

% figure formatting
title('(a) \kappa = 10','FontName',font,'FontSize',fontSize,'Interpreter','tex','FontWeight','normal')
axA = gca;
axA.FontName = font;
axA.FontSize = fontSize;

xlim([-0.1 3.1])
ylim([0 0.25])

axA.XLabel.FontSize = 1.5*fontSize;
axA.YLabel.FontSize = 1.5*fontSize;
axA.YLabel.Rotation = 0;
axA.YLabel.Position(1) = axA.YLabel.Position(1)-0.3;


nexttile
num_ite = 20;
% Plot error magnitude over iterations.
impulse_err_run(vf, props, [0 0 0]', I0, 20, [], {'mag'});

% figure formatting
title('(b) \kappa = 20','FontName',font,'FontSize',fontSize,'Interpreter','tex','FontWeight','normal')
axB = gca;
axB.FontName = font;
axB.FontSize = fontSize;

xlim([-0.1 3.1])
ylim([0 0.25])

axB.XLabel.FontSize = 1.5*fontSize;
axB.YLabel.FontSize = 1.5*fontSize;
axB.YLabel.Rotation = 0;
axB.YLabel.Position(1) = axB.YLabel.Position(1)-0.3;


% figure sizing and export
fig = gcf;
fig.Units = 'centimeters';
fig.Position(3) = 11.9;
fig.Position(4) = 7;
exportgraphics(fig,'HillImpulseNoise.pdf','ContentType','vector','BackgroundColor','None')
