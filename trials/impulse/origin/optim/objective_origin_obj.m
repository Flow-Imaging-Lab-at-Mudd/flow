function [err] = objective_origin_obj(origin, vf)
% Objective function for the two integral equations that determine the
% Ringuette objective origin, given in (De Voria, 2014).
% 
% Derek Li, July 2021

% Distance units (specified in vf) are not multiplied in this problem.
dv = abs(vf.xsp*vf.ysp*vf.zsp);

% Noisy velocity.
U = vf.U_e + vf.N_e;
% Noisy velocity gradient.
ugrad = vf.gradient(U);
% Noisy vorticity.
vort = vf.vorticity(1);
% Relative position to the given origin.
X_rel = VelocityField.operate3Vector(vf.X_e, origin, @minus);
% Compute the matrix product of velocity gradient and velocity.
dux = zeros([vf.span 3]);

for j = 1: size(vf.X_e, 1)
    for i = 1: size(vf.X_e, 2)
        for k = 1: size(vf.X_e, 3)
            if size(vf.X_e,5)==1
                dux(j,i,k,:) = squeeze(ugrad(j,i,k,:,:)) * squeeze(U(j,i,k,:));
            else
                for l = 1:size(vf.X_e, 5)
                    dux(j,i,k,:,l) = squeeze(ugrad(j,i,k,:,l,:)) * squeeze(U(j,i,k,:,l));
                end
            end
        end
    end
end

dux(isnan(dux)) = 0;

% A term appearing in the vector integral of the second equation.
mat_cross = dux + cross(U, vort, 4);

% Remainders of the two equations, both vectors, their norms to be
% minimized.

% first equation: momentum DMT
momentum = dv*squeeze(sum(U, [1 2 3], 'omitnan'));
impulse = 0.5*dv*squeeze(sum(cross(X_rel, vort, 4), [1 2 3], 'omitnan'));
flux = 0.5*vf.intCubicSurf_doublecross(X_rel, U);

rem1 = momentum - impulse + flux;

% second equation: energy identity
u_sq = squeeze(sum(0.5*U.^2,4));
lhs = 2*vf.intCubicSurf_vec(u_sq);
rhs = vf.intCubicSurf_doublecross(X_rel, mat_cross);

rem2 = lhs + rhs;

r1 = norm(rem1);
r2 = norm(rem2);

err = r1 + r2;

% Compute gradient for this objective function.
% derv = zeros(3, 1);
% % Identity matrix used for diff indexing.
% I = eye(3);
% 
% for i = 1: 3
%     derv1 = rem1'/r1 * cross(I(:,i), squeeze(dv*sum(vort, [1 2 3], 'omitnan')) + ...
%         vf.intCubicSurf_cross(U));
%     derv2 = -rem2'/r2 * cross(I(:,i), vf.intCubicSurf_cross(mat_cross));
%     derv(i) = derv1 + derv2;
% end
