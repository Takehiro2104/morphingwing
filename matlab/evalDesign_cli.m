function evalDesign_cli
% DAKOTA driver: reads params.in, calls evalDesign(x), writes results.out
try
x = readParams('params.in');
[f, c] = evalDesign(x);
writeResults('results.out', f, c);
catch ME
% On failure, return heavy penalties to keep GA progressing
warning('evalDesign_cli:Failure %s', ME.message);
f = [1e6, 1e6]; c = 1e3;
writeResults('results.out', f, c);
end
end


function x = readParams(fname)
fid = fopen(fname,'r'); assert(fid>0, 'Cannot open %s', fname);
C = textscan(fid, '%f'); fclose(fid);
x = C{1}(:)';
end


function writeResults(fname, f, c)
fid = fopen(fname,'w'); assert(fid>0, 'Cannot write %s', fname);
% DAKOTA expects objectives first, then constraints
fprintf(fid, '% .16e\n', f(1));
fprintf(fid, '% .16e\n', f(2));
fprintf(fid, '% .16e\n', c); % single aggregated inequality (<=0 feasible)
fclose(fid);
end
