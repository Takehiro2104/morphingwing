function sur = surrogate_fit_gp(X, Y)
% Fit separate GPs per objective; can be extended with fitrgp()
sur.obj1 = fitrgp(X, Y(:,1), 'KernelFunction','ardsquaredexponential');
sur.obj2 = fitrgp(X, Y(:,2), 'KernelFunction','ardsquaredexponential');
end
