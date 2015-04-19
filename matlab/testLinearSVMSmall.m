close all
clear all
clc

% Note: don't forget to add splitdata, monqp and svmkernel to the path.
% Results: error rate 1.4901%, bestC 20.0070 and runtime 28.257857s


%%  Load the data and replace text labels

data = load('../dataset/dish_area_dataset/attributesSmall.csv');

% Gets the columns from the text file
Y = load('../dataset/dish_area_dataset/labelsSmall.csv');

% Replaces the label background (1) with -1 and the label car (2) with 1
Y = (Y - 1) * 2 - 1;

%% Split the data into app, val and test
[Xapp, Yapp, Xtest, Ytest] = splitdata(data, Y, 0.5);
[Xval, Yval, Xtest, Ytest] = splitdata(Xtest, Ytest, 0.5);

[nApp, p] = size(Xapp);
[nTest, p] = size(Xtest);
[nVal, p] = size(Xval);

moyenne = mean(Xapp);
variance = std(Xapp);

% Center and reduce
Xapp = (Xapp - ones(nApp, 1) * moyenne) ./ (ones(nApp, 1) * variance); 
Xval = (Xval - ones(nVal, 1) * moyenne) ./ (ones(nVal, 1) * variance); 
Xtest = (Xtest - ones(nTest, 1) * moyenne) ./ (ones(nTest, 1) * variance);



DY = diag(Yapp);
G = Xapp * Xapp';
H = DY * G * DY + 1e-8*eye(size(G));

e = ones(nApp,1);
lambda = eps^.5;

tic

% Validation for C : rough C first
C_listBig = logspace(log10(.1), log10(10000), 50);
nbErrMin = inf;
bestC = 0;

for i = 1:length(C_listBig)
	C = C_listBig(i);
	[alpha, b, pos] = monqp(H, e, Yapp, 0, C, lambda, 0);    
	w = Xapp(pos, :)' *(Yapp(pos) .* alpha);
	nbErr = sum((Xval * w + b) .* Yval < 0);
	if (nbErr < nbErrMin)
		nbErrMin = nbErr;
		bestC = C;
	end
end


% Validation for C : precise C next
C_listSmall = logspace(log10(0.9 * bestC), log10(1.1 * C), 50);
nbErrMin = inf;
bestC = 0;

for i = 1:length(C_listSmall)
	C = C_listSmall(i);
	[alpha, b, pos] = monqp(H, e, Yapp, 0, C, lambda, 0);    
	w = Xapp(pos, :)' *(Yapp(pos) .* alpha);
	nbErr = sum((Xval * w + b) .* Yval < 0);
	if (nbErr < nbErrMin)
		nbErrMin = nbErr;
		bestC = C;
	end
end

toc

bestC
erreur = (sum((Xtest * w + b) .* Ytest < 0) / nTest) * 100
