function [sys, R0, U, p_true] = custom_loadDynamics(dynamics, type, sysparams)
% loadDynamics - load system dynamics and uncertainty sets
%
% Syntax:
%    [sys, R0, U] = loadDynamics(dynamics)
%
% Inputs:
%    dynamics - string specifying the dynamical system
%    type - string "standard" (default) for the normal uncertainty sets or
%               "diag" for diagonal generator matrices with random elements
%               "rand" for non-diagonal generator matrices
%    p - [optional] model parameters 
%
% Outputs:
%    sys - dynamical system
%    R0 - default initial state set
%    U - default input set
%    p_true - true model parameters
%
% References:
%   [1] L. Luetzow, M. Althoff, "Reachability analysis of ARMAX models," in 
%       Proc. of the 62nd IEEE Conference on Decision and Control, pp. 
%       7021–7028, 2023.
%   [2] E. N. Lorenz, “Deterministic nonperiodic flow,” Journal of
%       Atmospheric Sciences, vol. 20, no. 2, pp. 130 – 141, 1963.
%   [3] A. Kroll and H. Schulte, “Benchmark problems for nonlinear system
%       identification and control using soft computing methods: Need and
%       overview," Applied Soft Computing, vol. 25, pp. 496–513, 2014.
%   [4] J. M. Bravo. "Robust MPC of constrained discrete-time nonlinear 
%       systems based on approximated reachable sets", Automatica, 2006.
%   [5] M. Althoff et al. "Reachability analysis of nonlinear systems with 
%       uncertain parameters using conservative linearization", in Proc. 
%       of the 62nd IEEE Conference on Decision and Control, pp.
%       4042-4048, 2008.
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: testCase

% Authors:       Laura Luetzow
% Written:       01-March-2024
% Last update:   ---
% Last revision: ---
%
% Adapted by:                       Aybüke Ulusarslan
% Adaptation last updated on:       11-June-2025

% ------------------------------ BEGIN CODE -------------------------------

if nargin == 1
    type = "standard";
end

switch dynamics
    case "test_nlARX"
        p_true = [];
        A_c = [-1 -4 0 0 0;
                4 -1 0 0 0;
                0  0 -3 1 0;
                0  0 -1 -3 0;
                0  0  0  0 -2];
        B_c = ones(5,1);
        
        dt  = 0.05;                               % sampling time
        sys_d = c2d(ss(A_c,B_c,eye(5),0), dt);    % MATLAB ZOH discretisation
        A_d  = sys_d.A;   B_d = sys_d.B;
        
        %%  Step 1  –  ARX function handle (linear but declared “nonlinear” in CORA)
        f_arx = @(y_hist, u_hist) ...
                A_d * y_hist(1:5) + B_d * u_hist(1);   % uses y[k-1] and u[k]
        
        %%  Step 2  –  wrap it into a nonlinearARX object
        p      = 1;                 % number of past outputs/inputs
        dim_y  = 5;                 % output dimension (=state dimension)
        dim_u  = 1;                 % single scalar input
        
        sys_arx = nonlinearARX('lin2nonlinSys_ARX', ...
                               f_arx, dt, dim_y, dim_u, p);
        
        %%  Step 3  –  initial sets (same statistical shape as original)
        R0_arx = zonotope(ones(dim_y,1), 0.1*eye(dim_y));  % history y[k-1]
        U_arx  = zonotope(10, 0.25);                       % input set

        sys = sys_arx; R0 = R0_arx; U = U_arx;

    case "test_nlSysDT"
        % Syntax:
        %    % only dynamic equation
        %    nlnsysDT = nonlinearSysDT(fun,dt)
        %    nlnsysDT = nonlinearSysDT(name,fun,dt)
        %    nlnsysDT = nonlinearSysDT(fun,dt,states,inputs)
        %    nlnsysDT = nonlinearSysDT(name,fun,dt,states,inputs)
        %
        %    % dynamic equation and output equation
        %    nlnsysDT = nonlinearSysDT(fun,dt,out_fun)
        %    nlnsysDT = nonlinearSysDT(name,fun,dt,out_fun)
        %    nlnsysDT = nonlinearSysDT(fun,dt,states,inputs,out_fun,outputs)
        %    nlnsysDT = nonlinearSysDT(name,fun,dt,states,inputs,out_fun,outputs)
        %

        p_true = [];
        dim_x = 5;
        A_cont = [-1 -4 0 0 0; 4 -1 0 0 0; 0 0 -3 1 0; 0 0 -1 -3 0; 0 0 0 0 -2];
        B_cont = ones(5,1);
        C_cont = eye(5);
        %C_cont = [1,0,0,0,0];
        D_cont = 0;

        % Initial state set and input set
        R0 = zonotope(ones(dim_x,1), 0.1*diag(ones(dim_x,1)));
        U = zonotope(10, 0.25);
        
        sys_c = ss(A_cont, B_cont, C_cont, D_cont); % Define continuous time system    
        samplingtime = 0.05; % Convert to discrete system
        sys_d = c2d(sys_c, samplingtime);
        dim_y = size(C_cont, 1);
        dim_u = size(B_cont, 2);
        dt = samplingtime;
        f = @(x,u) sys_d.A * x + sys_d.B * u;
        g = @(x,u) sys_d.C * x + sys_d.D * u;
        sys = nonlinearSysDT('lin2nonlinSys', f, dt, dim_x, dim_u, g, dim_y);
        % nlnsysDT = nonlinearSysDT(name,fun,dt,states,inputs,out_fun,outputs)
    case "testSys"
        % This case reproduces the system from the original a_linearDT.m script
        p_true = [];
        dim_x = 5;
        A_cont = [-1 -4 0 0 0; 4 -1 0 0 0; 0 0 -3 1 0; 0 0 -1 -3 0; 0 0 0 0 -2];
        B_cont = ones(5,1);
        C_cont = [1,0,0,0,0];
        D_cont = 0;

        % Define continuous time system
        sys_c = ss(A_cont, B_cont, C_cont, D_cont);

        % Convert to discrete system
        samplingtime = 0.05;
        sys_d = c2d(sys_c, samplingtime);
        
        % Create a CORA linearSysDT object from the discretized system
        sys = linearSysDT(sys_d.A, sys_d.B, [], sys_d.C, sys_d.D, sys_d.Ts);

        % Initial state set and input set
        R0 = zonotope(ones(dim_x,1), 0.1*diag(ones(dim_x,1)));
        U = zonotope(10, 0.25);
    case "testSys2"
        % This case reproduces the system from the original a_linearDT.m script
        p_true = [];
        dim_x = 5;
        A_cont = [-1 -4 0 0 0; 4 -1 0 0 0; 0 0 -3 1 0; 0 0 -1 -3 0; 0 0 0 0 -2];
        B_cont = ones(5,1);
        C_cont = eye(5);
        D_cont = zeros(5, 1);

        % Define continuous time system
        sys_c = ss(A_cont, B_cont, C_cont, D_cont);

        % Convert to discrete system
        samplingtime = 0.05;
        sys_d = c2d(sys_c, samplingtime);
        
        % Create a CORA linearSysDT object from the discretized system
        sys = linearSysDT(sys_d.A, sys_d.B, [], sys_d.C, sys_d.D, sys_d.Ts);
        %sys.n_p = 0; % Added after the error in nonlinearARX/computeGO - line 109

        % Initial state set and input set
        R0 = zonotope(ones(dim_x,1), 0.1*diag(ones(dim_x,1)));
        U = zonotope(10, 0.25);

    case "mockSysARX"
        % Auto-regressive (AR) version of the mock system
        p_true = [];
        if nargin < 3
            n = 4; % Default dimension
        else
            n = sysparams.dim;
        end

        % Define the equivalent state-space matrices first for clarity
        A_ss = eye(n) + 1.01 * diag(ones(n-1,1), 1);
        B_ss = ones(n, 1);

        % --- Convert to linearARX model with n_p = 1 ---
        % The model is y(k) = A_bar{1}*y(k-1) + B_bar{1}*u(k) + B_bar{2}*u(k-1)
        
        n_p = 1; % Number of past time steps for the output
        
        A_bar{1} = A_ss; % Coefficient for y(k-1)
        
        % The B_bar cell array must have n_p + 1 elements
        B_bar{1} = zeros(n, 1); % Coefficient for u(k) is zero
        B_bar{2} = B_ss;        % Coefficient for u(k-1)
        
        dt = 0.1;
        dim_y = n;
        dim_u = 1;

        % Create the linearARX system object
        sys = linearARX(A_bar, B_bar, dt);
        
        % Initial state set R0
        % For ARX, the state is the history of outputs: [y(k-1), ..., y(k-n_p)]'
        % For n_p=1, the state dimension is dim_y * n_p = n * 1 = n
        c_R0 = zeros(dim_y * n_p, 1);
        G_R0 = 0.05 * eye(dim_y * n_p);
        R0 = zonotope([c_R0, G_R0]);

        % Input uncertainty
        switch type
            case "rand"
                c_U = randn(dim_u,1);
                G_U = rand(dim_u, dim_u);
            case "diag"
                c_U = 0.1 * randn(dim_u,1);
                G_U = diag(0.1 * rand(dim_u,1));
            case "standard"
                c_U = zeros(dim_u,1);
                G_U = 0.2 * eye(dim_u);
        end
        U = zonotope([c_U, G_U]);
    case "mockSys"
        p_true = [];
        if nargin < 3
            n = 4; % Default dimension
        else
            n = sysparams.dim;
        end
        A = eye(n) + 1.01 * diag(ones(n-1,1), 1);
        B = ones(n, 1);
        C = eye(n);
        D = zeros(n, 1);

        %f = @(y, u) A * y + B .* u;
        %f = @(y, u) A * y(:,1) + B .* u(:,1);  
        dt = 0.1;
        dim_y = n;
        dim_u = 1;
        %% TODO: Not sure what this is used for
        n_p = 1;
        %sys = nonlinearARX('customNARX', f, dt, dim_y, dim_u, p_dim);
        sys = linearSysDT(A, B, [], C, D, dt);

        % Initial state set R0
        c_R0 = zeros(dim_y * n_p, 1);
        G_R0 = 0.05 * eye(dim_y * n_p);
        R0 = zonotope([c_R0, G_R0]);

        % Input uncertainty
        switch type
            case "rand"
                c_U = randn(dim_u,1);
                G_U = rand(dim_u, dim_u);
            case "diag"
                c_U = 0.1 * randn(dim_u,1);
                G_U = diag(0.1 * rand(dim_u,dim_u));
            case "standard"
                c_U = zeros(dim_u,1);
                G_U = 0.2 * eye(dim_u);
        end
        U = zonotope([c_U, G_U]);

    case "example_NARX"
        % Custom NARX with full observability x = y + ε
        p_true = [1.0, -0.5]'; % example parameters

        % Nonlinear ARX update function
        f = @(y,u) [p_true(1) * tanh(y(1,1)) + u(1,1);
                    p_true(2) * sin(y(2,1)) + u(2,1)];
        dt = 0.1;
        dim_y = 2;
        dim_u = 2;
        n_p = 1;
        sys = nonlinearARX('customNARX', f, dt, dim_y, dim_u, n_p);

        % Initial state set R0
        c_R0 = zeros(dim_y * n_p, 1);
        G_R0 = 0.05 * eye(dim_y * n_p);
        R0 = zonotope([c_R0, G_R0]);

        % Input uncertainty
        switch type
            case "rand"
                c_U = randn(dim_u,1);
                G_U = rand(dim_u, dim_u);
            case "diag"
                c_U = 0.1 * randn(dim_u,1);
                G_U = diag(0.1 * rand(dim_u,1));
            case "standard"
                c_U = zeros(dim_u,1);
                G_U = 0.2 * eye(dim_u);
        end
        U = zonotope([c_U, G_U]);
    case "polyNARX"
        % Polynomial NARX system: x = y + ε
        p_true = [1.5, -0.8]';

        % Polynomial update: quadratic nonlinearity
        f = @(y,u) [p_true(1) * y(1,1)^2 + u(1,1);
                    p_true(2) * y(2,1)^2 + u(2,1)];
        g = @(y,u) [y(1); y(2)];
        dt = 0.1;
        dim_y = 2;
        dim_u = 2;
        n_p = 1; % ARX parameter
        %sys = nonlinearARX('polyNARX', f, dt, dim_y, dim_u, n_p);
        sys = nonlinearSysDT('polyNARX', f, dt, dim_y, dim_u, g, dim_y);

        % Initial state
        c_R0 = zeros(dim_y, 1);
        G_R0 = 0.05 * eye(dim_y);
        R0 = zonotope([c_R0, G_R0]);

        % Input uncertainty
        switch type
            case "rand"
                c_U = randn(dim_u,1);
                G_U = rand(dim_u, dim_u);
            case "diag"
                c_U = 0.1 * randn(dim_u,1);
                G_U = diag(0.1 * rand(dim_u,1));
            case "standard"
                c_U = zeros(dim_u,1);
                G_U = 0.2 * eye(dim_u);
        end
        U = zonotope([c_U, G_U]);

    case "lipschitzNARX"
        % Lipschitz-continuous NARX system: x = y + ε
        p_true = [0.6, -1.2]';

        % Smooth update: bounded slope with tanh, logs
        f = @(y,u) [p_true(1) * tanh(y(1,1)) + 0.1 * log(1 + abs(y(2,1))) + u(1,1);
                    p_true(2) * tanh(y(2,1)) + 0.05 * y(1,1) + u(2,1)];
        dt = 0.1;
        dim_y = 2;
        dim_u = 2;
        n_p = 1;
        sys = nonlinearARX('lipschitzNARX', f, dt, dim_y, dim_u, n_p);

        % Initial state
        c_R0 = zeros(dim_y, 1);
        G_R0 = 0.05 * eye(dim_y);
        R0 = zonotope([c_R0, G_R0]);

        % Input uncertainty
        switch type
            case "rand"
                c_U = randn(dim_u,1);
                G_U = rand(dim_u, dim_u);
            case "diag"
                c_U = 0.1 * randn(dim_u,1);
                G_U = diag(0.1 * rand(dim_u,1));
            case "standard"
                c_U = zeros(dim_u,1);
                G_U = 0.2 * eye(dim_u);
        end
        U = zonotope([c_U, G_U]);

    % Modified version of lipschitzNARX using nonlinearSysDT
    case "lipschitzSysDT"
        % Lipschitz-continuous system redefined as nonlinearSysDT
        p_true = [0.6, -1.2]';
    
        % Define system dynamics function f(x,u)
        f = @(x,u) [p_true(1) * tanh(x(1,1)) + 0.1 * log(1 + abs(x(2,1))) + u(1,1);
                    p_true(2) * tanh(x(2,1)) + 0.05 * x(1,1) + u(2,1)];      
    
        dt = 0.1;
        dim_x = 2;
        dim_u = 2;
        dim_y = 2;
        %out_fun = @(x,u) x; % Fully observable system
        out_fun = @(x,u) [x(1); x(2)];

        sys = nonlinearSysDT('lipschitzSysDT', f, dt, dim_x, dim_u, out_fun, dim_y);

        % Initial state
        c_R0 = zeros(dim_x, 1);
        G_R0 = 0.05 * eye(dim_x);
        R0 = zonotope([c_R0, G_R0]);
    
        % Input uncertainty
        switch type
            case "rand"
                c_U = randn(dim_u,1);
                G_U = rand(dim_u, dim_u);
            case "diag"
                c_U = 0.1 * randn(dim_u,1);
                G_U = diag(0.1 * rand(dim_u,1));
            case "standard"
                c_U = zeros(dim_u,1);
                G_U = 0.2 * eye(dim_u);
        end
        U = zonotope([c_U, G_U]);

    case "chain_of_integrators"
        % Chain-of-integrators linear discrete-time model
        % We take 'dim' from the third argument 'params'
        p_true = [];
        if nargin < 3
            n = sysparams;
        else
            n = 4;
        end 
        A  = diag(ones(n-1,1),1);
        B  = zeros(n,1); B(end)=1;
        C  = eye(n);
        D  = zeros(n,1);
        dt = 0.05;  
    
        sys = linearSysDT(A,B,[],C,D,dt);
    
        % create uncertainty sets
        dim_x = size(A, 1);
        dim_u = size(B, 2);
        dim_v = size(C, 1);
        switch type
            case "rand"
                c_R0 = [-0.76; -9.68; 0.21; -5.42];
                c_U = [-0.16; -8.93];
                c_V = [1.48; -7.06];
                G_R0 = [-0.02 0.13 0.10 0.06
                    0.30 -0.24  0.21 -0.16
                    0.28  0.14  0.15  0.18
                    0.28  0.33 -0.06 -0.23];
                G_U = [0.07   -0.25
                    -0.28   -0.11];
                G_V = [-0.08    0.01
                    -0.00   -0.03];
            case "diag"
                c_R0 = 0.1*[-0.76; -9.68; 0.21; -5.42];
                c_U = 0.1*[-0.16; -8.93];
                c_V = 0.1*[1.48; -7.06];
                G_R0 = diag([0.22 0.13 0.10 0.06]);
                G_U = diag([0.07 0.25]);
                G_V = diag([0.08 0.01]);
            case "standard"
                c_R0 = zeros(dim_x,1);
                G_R0 = [];
                c_U = 0.1+zeros(dim_u,1);
                G_U = 0.2*diag(ones(dim_u,1));
                c_V =  -0.05+zeros(dim_v,1);
                G_V = 0.1*[diag(ones(dim_v,1)) ones(dim_v,1)];
        end
        R0 = zonotope([c_R0,G_R0]);
        V = zonotope([c_V,G_V]);
        U = cartProd(zonotope([c_U,G_U]), V);
    
    case "pedestrian"
        % pedestrian model as a state-space model [1]
        sysparams = [1 0.01 5e-5 0.01]'; p_true = sysparams;        
        A = [sysparams(1)	0	    sysparams(2)	0
            0	    sysparams(1)	0	    sysparams(2)
            0	    0	    sysparams(1)	0
            0	    0	    0	    sysparams(1)];
        B =[sysparams(3)    0       0       0
            0	    sysparams(3)    0       0
            sysparams(4)    0       0       0
            0	    sysparams(4)    0       0];
        C =[1	    0	    0	    0
            0	    1	    0	    0];
        D =[0	    0       1       0
            0	    0       0       1];

        dt = 0.01;
        sys = linearSysDT(A,B,[],C,D, dt);

        % create uncertainty sets
        dim_x = length(sys.A);
        dim_u = 2;
        dim_v = 2;
        switch type
            case "rand"
                c_R0 = [-0.76; -9.68; 0.21; -5.42];
                c_U = [-0.16; -8.93];
                c_V = [1.48; -7.06];
                G_R0 = [-0.02 0.13 0.10 0.06
                    0.30 -0.24  0.21 -0.16
                    0.28  0.14  0.15  0.18
                    0.28  0.33 -0.06 -0.23];
                G_U = [0.07   -0.25
                    -0.28   -0.11];
                G_V = [-0.08    0.01
                    -0.00   -0.03];
            case "diag"
                c_R0 = 0.1*[-0.76; -9.68; 0.21; -5.42];
                c_U = 0.1*[-0.16; -8.93];
                c_V = 0.1*[1.48; -7.06];
                G_R0 = diag([0.22 0.13 0.10 0.06]);
                G_U = diag([0.07 0.25]);
                G_V = diag([0.08 0.01]);
            case "standard"
                c_R0 = zeros(dim_x,1);
                G_R0 = [];
                c_U = 0.1+zeros(dim_u,1);
                G_U = 0.2*diag(ones(dim_u,1));
                c_V =  -0.05+zeros(dim_v,1);
                G_V = 0.1*[diag(ones(dim_v,1)) ones(dim_v,1)];
        end
        R0 = zonotope([c_R0,G_R0]);
        V = zonotope([c_V,G_V]);
        U = cartProd(zonotope([c_U,G_U]), V);

    case "pedestrianARX"
        % pedestrian model as an ARX model [1]
        p_true = [2 -1 5e-5 -2]';
        if nargin < 3
            sysparams = p_true;
        end
        A{1,1} = [  sysparams(1)	0	    
                    0	    sysparams(1)];
        A{2,1} = [  sysparams(2)	0	    
                    0	    sysparams(2)];
        B{1,1} = [  0	    0       1       0
                    0	    0       0       1];
        B{2,1} = [  sysparams(3)    0       sysparams(4)    0
                    0	    sysparams(3)    0       sysparams(4)];
        B{3,1} = [  sysparams(3)    0       1       0
                    0	    sysparams(3)    0       1];
        dt = 0.01;
        sys = linearARX(A, B, dt);

        % create uncertainty sets
        dim_x = 4;
        dim_u = 2;
        dim_v = 2;
        switch type
            case "rand"
                c_U = [-0.16; -8.93];
                c_V = [1.48; -7.06];
                G_U = [0.07   -0.25
                    -0.28   -0.11];
                G_V = [-0.08    0.01
                    -0.00   -0.03];
            case "diag"
                c_U = 0.1*[-0.16; -8.93];
                c_V = 0.1*[1.48; -7.06];
                G_U = diag([0.07 0.25]);
                G_V = diag([0.08 0.01]);
            case "standard"
                c_U = 0.1+zeros(dim_u,1);
                G_U = 0.2*diag(ones(dim_u,1));
                c_V =  -0.05+zeros(dim_v,1);
                G_V = 0.1*[diag(ones(dim_v,1)) ones(dim_v,1)];
        end
        R0 = zonotope(zeros(dim_x,1));
        V = zonotope([c_V,G_V]);
        U = cartProd(zonotope([c_U,G_U]), V);            

    case "lorenz"
        % Lorenz system [2]
        p_true = [10 28 8/3]';
        if nargin < 3
            sysparams = p_true;
        end
        dt = 0.01;
        fun = @(x,u) aux_dynLorenz(x,u,dt,sysparams);
        dim_x = 3;
        dim_u = 3;
        dim_y = 2;
        out_fun = @(x,u) x(1:dim_y);
        sys = nonlinearSysDT('lorenz', fun, dt, dim_x, dim_u, out_fun, dim_y);

        switch type 
            case "rand"
                c_R0 = [6.01; 9.36; -3.73];
                c_U = [7.56; -8.03; -1.57];
                G_R0 = [-0.11   -0.11    0.04
                    -0.07    0.08    0.14
                    0.02     0       0.02];
                G_U = [0.06   -0.02    0.04
                    -0.04    0.08   -0.09
                    -0.07    0.20   -0.10];
            case "diag"
                c_R0 = 0.1*[6.01; 9.36; -3.73];
                c_U = 0.1*[7.56; -8.03; -1.57];
                G_R0 = 0.03*diag([0.11   0.11    0.24]);
                G_U = diag([0.06   -0.02    0.04]);
            case "standard"
                c_U = [0.5;0.1;-0.2];
                c_R0 = [2; -1; 4];
                G_U =  diag([0.1;2;0.2]);
                G_R0 = 0.2*eye(dim_x);
        end
        R0 = zonotope([c_R0,G_R0]);
        W = zonotope([c_U,G_U]);
        V = zonotope([]);
        U = cartProd(W, V);
    
    case "lorenz_2D"
        % first two dimensions of the Lorenz system [2]
        p_true = [10 28]';
        if nargin < 3
            sysparams = p_true;
        end
        dt = 0.01;
        fun = @(x,u) aux_dynLorenz2D(x,u,dt,sysparams);
        dim_x = 2;
        dim_u = 2;
        dim_y = 2;
        out_fun = @(x,u) x(1:dim_y);
        sys = nonlinearSysDT('lorenz', fun, dt, dim_x, dim_u, out_fun, dim_y);

        switch type 
            case "rand"
                c_R0 = [6.01; 9.36];
                c_U = [7.56; -8.03];
                G_R0 = [-0.11   -0.11
                    -0.07    0.08];
                G_U = [0.06   -0.02
                    -0.04    0.08];
            case "diag"
                c_R0 = 0.1*[6.01; 9.36];
                c_U = 0.1*[7.56; -8.03];
                G_R0 = 0.03*diag([0.11   0.11]);
                G_U = diag([0.06   -0.02]);
            case "standard"
                c_U = [0.5;0.1];
                c_R0 = [2; -1];
                G_U =  diag([0.1;2]);
                G_R0 = 0.2*eye(dim_x);
        end
        R0 = zonotope([c_R0,G_R0]);
        W = zonotope([c_U,G_U]);
        V = zonotope([]);
        U = cartProd(W, V);

    case "NARX" 
        % artificial NARX model, adapted from [3]
        p_true = [0.8 1.2]';
        if nargin < 3
            sysparams = p_true;
        end

        f = @(y,u) [y(1,1)/(1+y(2,1)^2) + sysparams(1)*u(3,1); ...
            (y(1,1) * y(2,1))/(1+y(2,1)^2)+ sysparams(2)*u(6,1)];
        dt = 0.1;
        dim_y = 2;
        dim_u = 2;
        n_p = 2;
        sys = nonlinearARX(dynamics,f,dt,dim_y, dim_u, n_p);

        % initilization
        R0 = zonotope(zeros(dim_y*n_p,1));

        % input
        switch type
            case "rand"
                c_U = [-1.66; 4.41];
                G_U = [-0.1   0.13
                    0.25   -0.09];
            case "diag"
                c_U = 0.1*[-1.66; 4.41];
                G_U = 0.7*diag([0.1   0.13]);
            case "standard"
                c_U = [0;0.05];
                G_U =  0.2*eye(2);
        end
        U = zonotope(c_U, G_U);

    case "Square" 
        % artificial, simple NARX model
        p_true = [0.8 1.2]';
        if nargin < 3
            sysparams = p_true;
        end

        f = @(y,u) [y(1,1)^2 + sysparams(1)*u(3,1); ...
            y(2,1)^2+sysparams(2)*u(2,1)];
        dt = 0.1;
        dim_y = 2;
        dim_u = 2;
        n_p = 1;
        sys = nonlinearARX(dynamics,f,dt,dim_y, dim_u, n_p);

        % initilization
        R0 = zonotope(zeros(dim_y*n_p,1));

        % input
        switch type
            case "rand"
                c_U = [-1.66; 4.41];
                G_U = [-0.1   0.13
                    0.25   -0.09];
            case "diag"
                c_U = 0.1*[-1.66; 4.41];
                G_U = 0.7*diag([0.1   0.13]);
            case "standard"
                c_U = [0;0.05];
                G_U =  0.2*eye(2);
        end
        U = zonotope(c_U, G_U);

    case "bicycle"
        % bicycle dynamics (see DOTBicycleDynamics_SRX_velEq.m)
        dt = 0.001;
        p_true = []; % no parameters defined
        fun = @(x,u) x + dt*DOTBicycleDynamics_SRX_velEq(x,u);
        dim_x = 6;
        dim_u = 8;
        out_fun = @(x,u) [x(4); x(5)] + [u(7); u(8)];
        dim_y = 2;
        sys = nonlinearSysDT('bicycle', fun, dt, dim_x, dim_u, out_fun, dim_y);

        if nargin > 1 && type == "rand"
            c_R0 = [1.86; 3.46; 3.97; 5.39; 4.19; 6.85];
            c_W = [2.04; 8.78; 0.27; 6.70; 4.17; 5.59];
            c_V = [-0.02; 0.06];
            G_R0 = 0.01*[1.78 -1.37  0.79  0.60 -1.17 -1.4800
                1.77 -0.29  0.93 -0.54 -0.69  0.26
                -1.87  1.27 -0.49 -0.16  0.93 -2.02
                -1.05  0.07  1.80  0.61 -1.48  0.20
                -0.42  0.45  0.59 -1.04 -0.56  0.43
                1.40 -0.32 -0.64 -0.35 -0.03 -1.27];
            G_W = 0.01*diag([0.55 0.17 -0.19 0.58 -0.85 0.81]);
            G_W(1,2) = 0.2; G_W(2,5) = 1; G_W(6,1) = -0.5;
            G_V = 0.002*eye(dim_y);
        else
            c_R0 = [1.2;0.5; 0; 0; 0; 0];
            c_W = zeros(dim_x,1);
            c_V = zeros(dim_y,1);
            G_R0 = eye(6);
            G_W = eye(dim_x);
            G_V = eye(dim_y);
        end
        R0 = zonotope([c_R0,G_R0]);
        W = zonotope([c_W,G_W]);
        V = zonotope([c_V,G_V]);
        U = cartProd(W, V);

    case "bicycleHO"
        % higher-order bicycle dynamics (see highorderBicycleDynamics.m)
        dt = 0.001;
        p_true = []; % no parameters defined
        fun = @(x,u) x + dt*highorderBicycleDynamics(x,u);
        dim_x = 18;
        dim_u = 4;
        out_fun = @(x,u) [x(5); x(6)] + [u(3); u(4)];
        dim_y = 2;
        sys = nonlinearSysDT('bicycleHO', fun, dt, dim_x, dim_u, out_fun, dim_y);

        if type ~= "standard"
            throw(CORAerror('CORA:specialError',"Only standard uncertainty sets defined."))
        end
        R0 = zonotope([[1.2;0.5; 0; 5; zeros(14,1)],0.01*eye(dim_x)]);
        W = zonotope([zeros(2,1),0.004*eye(2)]);
        V = zonotope([zeros(dim_y,1),0.002*eye(dim_y)]);
        U = cartProd(W, V);

    case "cstrDiscr"
        % stirred-tank reactor system [5]        
        dt = 0.015;
        p_true = []; % no parameters defined
        fun = @(x,u) cstrDiscr(x,u,dt);
        dim_x = 2;
        dim_u = 4;
        out_fun = @(x,u) [x(1); x(2)] + [u(3); u(4)];
        dim_y = 2;
        sys = nonlinearSysDT('cstrDiscr', fun, dt, dim_x, dim_u, out_fun, dim_y);
        
        if type ~= "standard"
            throw(CORAerror('CORA:specialError',"Only standard uncertainty sets defined."))
        end
        c_R0 = [-0.15;-45];
        c_W = zeros(dim_x,1);
        c_V = zeros(dim_y,1);
        G_R0 = diag([0.005;3]);
        G_W = diag([0.1;2]);
        G_V = 0.002*eye(dim_y);
        R0 = zonotope([c_R0,G_R0]);
        W = zonotope([c_W,G_W]);
        V = zonotope([c_V,G_V]);
        U = cartProd(W, V);

    case "tank"
        % stirred-tank reactor system with 6 dimensions [5]
        dt = 0.5;
        p_true = []; % no parameters defined
        fun = @(x,u) tank6EqDT(x,u,dt);
        dim_x = 6;
        dim_u = 4;
        out_fun = @(x,u) [x(1); x(2)] + [u(3); u(4)];
        dim_y = 2;
        sys = nonlinearSysDT('tank6', fun, dt, dim_x, dim_u, out_fun, dim_y);
        
        if type ~= "standard"
            throw(CORAerror('CORA:specialError',"Only standard uncertainty sets defined."))
        end
        c_R0 = [2; 4; 4; 2; 10; 4];
        c_W = zeros(2,1);
        c_V = zeros(dim_y,1);
        G_R0 = 0.2*eye(6);
        G_W = diag([0.1;2]);
        G_V = 0.002*eye(dim_y);
        R0 = zonotope([c_R0,G_R0]);
        W = zonotope([c_W,G_W]);
        V = zonotope([c_V,G_V]);
        U = cartProd(W, V);

    case "tank30"
        % stirred-tank reactor system with 30 dimensions [5]
        dt = 0.5;
        p_true = []; % no parameters defined
        fun = @(x,u) tank30EqDT_inflow15(x,u,dt);
        dim_x = 30;
        dim_u = 15;
        dim_y = 6;
        out_fun = @(x,u) x(1:dim_y) + u(1:dim_y);
        sys = nonlinearSysDT('tank30', fun, dt, dim_x, dim_u, out_fun, dim_y);
        
        if type ~= "standard"
            throw(CORAerror('CORA:specialError',"Only standard uncertainty sets defined."))
        end
        R0 = zonotope([12*rand(dim_x,1),0.2*eye(dim_x)]);
        W = zonotope([zeros(dim_y-dim_y,1),0.01*eye(dim_u-dim_y)]);
        V = zonotope([zeros(dim_y,1),0.002*eye(dim_y)]);
        U = cartProd(W, V);

    case "tank60"
        % stirred-tank reactor system with 60 dimensions [4]
        dt = 0.5;
        p_true = []; % no parameters defined
        fun = @(x,u) tank60EqDT_inflow30(x,u,dt);
        dim_x = 60;
        dim_u = 30;
        dim_y = 2;
        out_fun = @(x,u) x(1:dim_y) + u(1:dim_y);
        sys = nonlinearSysDT('tank60', fun, dt, dim_x, dim_u, out_fun, dim_y);
        
        if type ~= "standard"
            throw(CORAerror('CORA:specialError',"Only standard uncertainty sets defined."))
        end
        R0 = zonotope([12*rand(dim_x,1),0.2*eye(dim_x)]);
        W = zonotope([zeros(dim_y-dim_y,1),0.01*eye(dim_u-dim_y)]);
        V = zonotope([zeros(dim_y,1),0.002*eye(dim_y)]);
        U = cartProd(W, V);

end
end


% Auxiliary functions -----------------------------------------------------

function xnew = aux_dynLorenz2D(x,u,dt,p)
% dynamics of the Lorenz system

xdot = [(p(1)+u(1))*(x(2)-x(1)); ...
    (p(2)+u(2))*x(1)-x(2)-x(1)];
xnew = x + dt*xdot; 
end

function xnew = aux_dynLorenz(x,u,dt,p)
% dynamics of the Lorenz system

xdot = [(p(1)+u(1))*(x(2)-x(1)); ...
    (p(2)+u(2))*x(1)-x(2)-x(1)*x(3); ...
    x(1)*x(2)-(p(3)+u(3))*x(3)];
xnew = x + dt*xdot; 
end

% ------------------------------ END OF CODE ------------------------------
