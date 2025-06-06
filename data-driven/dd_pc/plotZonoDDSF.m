clear all
close all

% Choose base data file (without `.mat` extension)
baseName = 'zonoDDSF';
%baseName = 'ZPC_in4st100W0.01V0.002';
%baseNamePoly = strrep(baseName, 'ZPC', 'poly');
baseNamePoly = 'poly_W0.01V0.002';

% Define output folder
inputFolder = fullfile('zonoDDSF', 'workspaces', 'data-driven', 'pc');
if ~exist(inputFolder, 'dir')
    mkdir(inputFolder);
end

% Load workspaces
load(['zonoDDSF\workspaces\data-driven\pc\' baseName '.mat']);                 % ZPC workspace
load(fullfile('zonoDDSF\workspaces\data-driven\pc\', [baseNamePoly '.mat']));   % Poly workspace 

exportFolder = fullfile('zonoDDSF', 'outputs', 'data-driven', 'pc');
if ~exist(exportFolder, 'dir')
    mkdir(exportFolder);
end

%load work spaces
%load('workspaces\poly')
%load('workspaces\ZPC')

%less noise
%initpoints 4 step 100
%load('workspaces\ZPC_in4st100W0.01V0.002.mat');
%load('workspaces\poly_W0.01V0.002.mat');


%More noise
%load('workspaces\ZPC_in100st5W0.1V0.02N2.mat')
%load('workspaces\poly_W0.1V0.02N2.mat')

% renamed from 'plotReachabilityWithTrajectories'
plotTrajectories(Rplotall, y_t, YPred, [1 2], 'zonoDDSF/outputs/plots', 'reach_demo');
% renamed from 'plotInputFilteringComparison'
%plotUlvsUstar(0:maxsteps-1, u_l_hist, uPred, sys, exportFolder, 'input_filtering');
% renamed from 'plotOutputConstraintCompliance'
%plotConstraints(0:maxsteps-1, y, yl_hist, sys, 'zonoDDSF/outputs/plots', 'output_compliance');
% renamed from 'Inclusion'
%plotTerminalSet(R{N+1}, S_f, [1 2], 'zonoDDSF/outputs/plots', 'terminal_check');

% For future reference: warning('on', 'all') was used 