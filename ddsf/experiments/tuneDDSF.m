%% systype   -   OPTIONS:
%               linear: {'quadrotor', 'damper', 'inverted_pendulum'}
%
%            - Specifies the type of system for which the DDSF is being designed.
%           -  See algorithms\ddsf\systemsDDSF.m for details.
%
%% mode  -   Options: {
%                       'r':        vary det(R),
%                       'nt':       vary T_ini and N (prediction horizon) simultaneously,
%                       'constr':   multiply the pre-defined (by systemsDDSF.m)
%                                   input/output constraints with a scalar,
%                       'mixed':    vary all of the above simulteneously,
%                       'single':   executes the algorithm for a single
%                                   parameter configuration
%                     }
%% vals  - Specify parameter configuration
%
%% T_sim - # Simulation steps   
%
%% toggle_save = 1 will save the input/output sequence to a csv file under
%%               ddsf/outputs/data

systype = 'quadrotor';

mode = 'nt';

%% Example parameter spaces initializations
vals_large = struct( ...
    'r', 10.^(-8:1:8), ... % value range for mode 'r'
    'NvsTini', [ ... % value range for mode 'nt'
    1 * ones(6, 1), (5:5:30)'; ...
    2 * ones(6, 1), (5:5:30)'; ...
    5 * ones(5, 1), (10:5:30)'; ...
    10 * ones(4, 1), (15:5:30)' ...
    ], ...
    'constraints', [1e+8, 0.1, 0.5, 1.5, 2, 10, 100], ... % value ranges for mode 'constr'
    'mixed', struct( ...
                    'nt', [repelem([1; 2], 4), repmat(5:5:20, 1, 2)'], ...
                    'constr', [1e+8, 0.1, 0.5, 1.5, 2], ...
                    'R', [1e-4, 1e-3,0.01, 0.1, 1, 10, 100, 1e+4, 1e+8] ...
                    ) ...
    );

% DEFAULT
vals = struct( ...
            'pendulum', struct( ...
                            'r', [1, 10, 100, 1000, 1e+5], ... % value range for mode 'r'
                            'NvsTini', [2 5; 2 10; 3 15], ...
                            'constraints', 1, ... % value ranges for mode 'constr'
                            'mixed', struct( ...
                                            'nt', [2 5; 2 10; 3 15], ...
                                            'constr', 1, ...
                                            'R', [1, 10, 100, 1000, 1e+5] ...
                                            ) ...
                            ), ...
            'quadrotor', struct( ...
                            'r', [1, 10, 100, 1000], ... % value range for mode 'r'
                            'NvsTini', [2 5; 2 10; 2 15], ...
                            'constraints', 1, ... % value ranges for mode 'constr'
                            'mixed', struct( ...
                                            'nt', [2 5; 2 10; 2 15], ...
                                            'constr', 1, ...
                                            'R', [1, 10, 100, 1000] ...
                                            ) ...
                            ) ...
    );


vals_single = struct( ...
            'N', 5, ...
            'T_ini', 2, ...
            'scale_constraints', -1, ... % Equivalent to a << don't care >>
            'R', 100, ...
            'toggle_plot', 1 ...
    );

T_sim = 10;

toggle_save = 1;


% Plot the simulation results
if strcmp(mode, 'single') == 0
    [u, ul, y, yl, descriptions, filename] = ddsfTunerFlex(mode, vals.quadrotor, systype, T_sim, toggle_save);
    
    % Extract the full path of the data files
    filename_inputs = filename.u;
    filename_outputs = filename.y;
    
    % Construct (and save) plots from the data files
    batchplot(filename_inputs);
    batchplot(filename_outputs);
else
    [lookup, time, logs] = runDDSF(systype, T_sim, vals_single.N, vals_single.T_ini, ...
        vals_single.scale_constraints, vals_single.R, vals_single.toggle_plot);
    plotDDSF(time, logs, lookup);
end

% Optional - Compute conservatism scores
if strcmp(mode, 'single') == 0
    [ranked_scores, ranked_configs]  = ddsfConservatism(filename_outputs);
else
    c_d = ddsfConservatismSingle(lookup, logs);
end
