function p_feas = montecarlo_robustness(N)
if nargin<1, N=200; end
X = lhsdesign(N,12)*0.12 - 0.06; % sample DVs within bounds
F = zeros(N,2); C = zeros(N,1);
for i=1:N
aeroNoise = 0.05*randn; % 5% model error
aoaBias = 0.5*randn; % ±0.5° sensor bias
gust = 0.10*randn; % 10% q fluctuation
[f, c] = evalDesign(X(i,:));
F(i,:) = f .* (1+aeroNoise);
C(i) = c + max(0,gust) + abs(aoaBias)/10;
end
p_feas = mean(C<=0);
save('data/results/robustness.mat','F','C','p_feas');
end
