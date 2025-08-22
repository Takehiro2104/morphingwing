function res = runCFD_xfoil(geom)
% Writes a temporary airfoil file, calls XFOIL externally, parses polar.
% Requires XFOIL in PATH. Use AoA sweep and extract L/D at target Re.
tmp = tempname; afl = [tmp '.dat'];
fid = fopen(afl,'w'); fprintf(fid,'TEMP\n');
for i=1:numel(geom.x)
fprintf(fid,'%f %f\n', geom.x(i), geom.yu(i));
end
for i=numel(geom.x):-1:1
fprintf(fid,'%f %f\n', geom.x(i), geom.yl(i));
end
fclose(fid);


Re = 5e5; Mach = 0.1; aoa = 2:0.5:10; % example
pol = [tmp '.pol'];
cmd = sprintf('xfoil << EOF\nLOAD %s\nPPAR\nN 200\n\nOPER\nVISC %g\nMACH %g\nPACC\n%s\n\n', afl, Re, Mach, pol);
for a = aoa
cmd = sprintf('%sALFA %g\n', cmd, a);
end
cmd = sprintf('%s\nQUIT\nEOF', cmd);
system(cmd);


T = readtable(pol,'FileType','text');
[~,k] = max(T.CL./T.CD);
res.L_over_D = max(T.CL./T.CD);
res.stallMarginDeg = 12 - T.AoA(k); % crude proxy
res.minThickness = min(geom.yu - geom.yl);
res.maxCamber = max((geom.yu + geom.yl)/2);
res.maxStress = 80e6; % placeholder until coupled to FEA
res.actuatorTorque = 0.5; % placeholder from actuation model
res.actuationEnergy = 3.2; % J per manoeuvre (example)
end
