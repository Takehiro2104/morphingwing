function [f, c] = evalDesign(x)
% Returns objectives and inequality constraint value(s)
% f = [f1, f2] = [ -L/D , ActuationEnergy ] (both to be minimised)
% c: positive values indicate constraint violation; aggregate via max()


% Build geometry
geom = buildAirfoil_bspline(x);


% Quick aerodynamic evaluation (choose one path)
useFluent = false; % set true in detailed phase
if ~useFluent
res = runCFD_xfoil(geom);
else
res = runCFD_fluent(geom);
end


% Objectives
f1 = -res.L_over_D; % maximise L/D -> minimise -L/D
f2 = res.actuationEnergy; % J per morph cycle or steady power proxy


% Constraints (Example): thickness/camber bounds + stall AoA margin
g = [];
g(end+1) = max(0, 0.12 - res.minThickness); % enforce ≥12% t/c
g(end+1) = max(0, res.maxCamber - 0.06); % enforce ≤6% camber
g(end+1) = max(0, 8 - res.stallMarginDeg); % stall margin ≥ 8°
g(end+1) = max(0, res.maxStress/120e6 - 1); % stress ≤ 120 MPa
g(end+1) = max(0, res.actuatorTorque/0.8 - 1);% torque ≤ 0.8 N·m


c = max(g); % single aggregate inequality for gamultiobj()
f = [f1, f2];
end
