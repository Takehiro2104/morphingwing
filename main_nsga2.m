```matlab
% main_nsga2.m — NSGA-II with surrogate pre-screening
clear; clc; rng(1);


% --- Design variable bounds (example: 12 B-spline ordinates for camber/thickness)
ndv = 12; lb = -0.06*ones(1,ndv); ub = 0.06*ones(1,ndv);


% --- NSGA-II options (Global Optimization Toolbox)
opts = optimoptions('gamultiobj', ...
'PopulationSize', 120, ...
'MaxGenerations', 120, ...
'CrossoverFraction', 0.85, ...
'UseVectorized', false, ...
'FunctionTolerance', 1e-3, ...
'PlotFcn', {@gaplotpareto}, ...
'Display','iter');


% --- Seed initial designs (baseline + Latin hypercube)
nSeed = 30; X0 = [zeros(1,ndv); lhsdesign(nSeed,ndv).*(ub-lb)+lb];


% --- Fit initial surrogate using DOE
Y0 = zeros(size(X0,1),2); C0 = zeros(size(X0,1),1);
for i = 1:size(X0,1)
[Y0(i,:), C0(i)] = evalDesign(X0(i,:)); % [ -L_over_D , ActuationEnergy ]
end
sur = surrogate_fit_gp(X0, Y0); %#ok<NASGU>


% --- Wrapper objective with occasional surrogate screening
objfun = @(x) evalDesign(x); % keep simple; surrogate used inside evalDesign if desired


% --- Constraint function
confun = @(x) constraints(x);


% --- Run optimisation
[XPareto, YPareto] = gamultiobj(objfun, ndv, [], [], [], [], lb, ub, confun, opts);


save('../data/results/nsga2_run.mat','XPareto','YPareto');
