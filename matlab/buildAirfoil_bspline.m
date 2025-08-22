function geom = buildAirfoil_bspline(x)
% Map 12-D vector to upper/lower surface control-point offsets
npt = 80; xi = linspace(0,1,npt)';
% Split variables into upper/lower perturbations (symmetric example)
du = x(1:6); dl = x(7:12);
% Basis (cubic B-spline) via MATLAB spmak/ppval
ku = spmak(linspace(0,1,8), [du du(end)]); % simple replication end-knot
kl = spmak(linspace(0,1,8), [dl dl(end)]);
cu = ppval(ku, xi);
cl = ppval(kl, xi);
xcoord = xi; y_u = 0.06*(1 - (xcoord-0.5).^2) + cu; % base + perturb
y_l = -0.06*(1 - (xcoord-0.5).^2) + cl;
geom.x = xcoord; geom.yu = y_u; geom.yl = y_l;
end
