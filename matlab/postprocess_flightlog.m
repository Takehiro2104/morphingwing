function S = postprocess_flightlog(csvFile)
T = readtable(csvFile);
% Required cols: time, V, AoA, CL_est, CD_est, morphAngle, I_act, V_act, distance_km
T = rmmissing(T);
% Harmonize timebase
T.time = T.time - T.time(1);


rho = 1.225; Sref = 0.25; % adjust to UAV
q = 0.5*rho.*T.V.^2;
L = T.CL_est.*q*Sref; D = T.CD_est.*q*Sref;
S.LoverD = L./max(D,1e-6);
S.P_act = T.I_act .* T.V_act;
S.E_total = trapz(T.time, S.P_act);
S.E_per_km = S.E_total / max(T.distance_km(end), 1e-6);


% Phase segmentation by speed thresholds (edit as needed)
edges = [0 10 18 40 inf]; names = {'idle','loiter','cruise','dash'};
S.phase = categorical(discretize(T.V, edges, 'categorical', names));


% Basic plots for reports
figure; plot(T.time, S.LoverD); xlabel('Time [s]'); ylabel('L/D'); grid on;
figure; plot(T.time, S.P_act); xlabel('Time [s]'); ylabel('Actuation Power [W]'); grid on;


% Export summary CSV
sumT = table(S.E_total, S.E_per_km, 'VariableNames',{'E_total_J','E_per_km_Jpkm'});
writetable(sumT, 'data/results/flight_summary.csv');
end
