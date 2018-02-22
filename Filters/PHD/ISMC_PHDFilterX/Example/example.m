% phd_test.m
% ====================================================>
% This is a test script which demonstrates the usage of the "SMC_PHD" class.
% 
% SETUP:
%  * Before running the simulation, open "2_crossing_targets.mat" or "3_roaming_targets.mat" datasets, from the "datasets" folder
%  * The datasets have been extracted by simulating the motion of differential robots in a 2D-plane (x,y)
%  * The "gen_obs_cluttered_multi3" function takes as an input the ground truth data, including information about the measurement noise and clutter rate
%     and then produces 1xNk cell array of corrupted and cluttered measurements, Nk being the total number of timesteps

load('example.mat');

% Plot settings
ShowPlots = 1;              % Set to 0 to hide plots
ShowPrediction = 0;         % Set to 0 to skip showing prediction
ShowUpdate = 1;             % Set to 0 to skip showing update
TrackNum = size(x_true,2);

% Instantiate a Dynamic model
dyn = ConstantVelocityModelX_2D('VelocityErrVariance',0.0001);

% Instantiate an Observation model
obs = LinGaussObsModelX_2D('NumStateDims',4,'ObsErrVariance',0.01,'Mapping',[1 3]);

% Compile the State-Space model
ssm = StateSpaceModelX(dyn,obs);

% n_x = 4;      % state dimensions
% q = 0.01;     % std of process noise 
% n_y = 2;      % measurement dimensions
% r = 0.1;      % std of measurement noise
lambdaV = 100; % Expected number of clutter measurements over entire surveillance region
V = 10^2;     % Volume of surveillance region (10x10 2D-grid)
V_bounds = [0 10 0 10]; % [x_min x_max y_min y_max]

% Generate observations (Poisson number with rate of lambdaV, positions are uniform over surveillance region)
[DataList,x1,y1] = gen_obs_cluttered_multi3(TrackNum, x_true, y_true, 0.1, lambdaV, 1); 
N=size(DataList,2); % timesteps 

% Assign PHD parameter values
config.NumParticles = 0;              % number of particles
config.priorParticles = [];
config.priorWeights = [];
config.Model = ssm;
q = dyn.covariance();
transformM = @(x) [x(1,:);zeros(1,size(x,2));x(2,:);zeros(1,size(x,2))];
%BirthIntFcn = @(Np) [(V_bounds(2)-V_bounds(1))*rand(Np,1), mvnrnd(zeros(Np,1), q(3,3)'),(V_bounds(4)-V_bounds(3))*rand(Np,1),mvnrnd(zeros(Np,1), q(4,4)')]'; % Uniform position and heading, Gaussian speed
config.BirthIntFcn = @(Np,z) [transformM(z(:,ones(1,Np))+config.Model.Obs.random(Np)) + mvnrnd(zeros(Np,4), q)']; % Uniform position and heading, Gaussian speed
%config.PriorDistFcn = @ (Np) deal(BirthIntFcn(Np), repmat(1/Np, Np, 1)');
config.BirthScheme = {'Mixture', 0.1};
%config.BirthScheme = {'Expansion', 5000};
config.ProbOfDeath = 0.005;
config.ProbOfDetection = 0.9;
config.ClutterRate = lambdaV/V;
config.NumParticlesPerTarget = 10000;
config.NumParticlesPerMeasurement = 100;
config.ExpectedNumBornTargets = .1;

% config.particles_init = config.gen_x0(config.Np)'; % Generate inital particles as per gen_x0
% config.w_init = repmat(1/config.Np, config.Np, 1)'; % Uniform weights
% config.gen_x0 = @(Np) [(V_bounds(2)-V_bounds(1))*rand(Np,1),(V_bounds(4)-V_bounds(3))*rand(Np,1), mvnrnd(zeros(Np,1), CVmodel.Params.q^2), 2*pi*rand(Np,1)]; % Uniform position and heading, Gaussian speed
% config.Jk = 500;
% config.pConf = 0.9;
% config.NpConf = 1000;
% config.type = 'search';
% config.birth_strategy = 'mixture';

% Instantiate PHD filter
myphd = ISMC_PHDFilterX(config);

% Create figure windows
if(ShowPlots)
    img = imread('maze.png');
    
    % set the range of the axes
    % The image will be stretched to this.
    min_x = 0;
    max_x = 10;
    min_y = 0;
    max_y = 10;

    % make data to plot - just a line.
    x = min_x:max_x;
    y = (6/8)*x;

    figure('units','normalized','outerposition',[0 0 .5 1])
    ax(1) = gca;
    figure('units','normalized','outerposition',[.5 0 .5 1])
    ax(2) = gca;
end

% START OF SIMULATION
% ===================>
for k=1:N
    fprintf('Iteration = %d/%d\n================>\n',k,N);
    
    % Extract DataList at time k
    tempDataList = DataList{k}(:,:);
    tempDataList( :, ~any(tempDataList,1) ) = [];       
    
    % Change PHD filter parameters
    myphd.MeasurementList = tempDataList; % New observations
    %myphd.ClutterRate = (size(tempDataList,2)-myphd.NumTargets)/V;
    
    % Predict PHD filter
    myphd.predict();
    
    % Plot prediction step results
    if(ShowPlots && ShowPrediction)
        % Plot data
        cla(ax(1));
         % Flip the image upside down before showing it
        imagesc(ax(1),[min_x max_x], [min_y max_y], flipud(img));

        % NOTE: if your image is RGB, you should use flipdim(img, 1) instead of flipud.
        hold on;
        h2 = plot(ax(1), DataList{k}(1,:),DataList{k}(2,:),'k*','MarkerSize', 10);
        for j=1:TrackNum
            h2 = plot(ax(1), x_true(1:k,j),y_true(1:k,j),'b.-','LineWidth',1);
            if j==2
                set(get(get(h2,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
            end
            h2 = plot(ax(1), x_true(k,j),y_true(k,j),'bo','MarkerSize', 10);
            set(get(get(h2,'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); % Exclude line from legend
        end

        % set the y-axis back to normal.
        set(ax(1),'ydir','normal');
        str = sprintf('Robot positions (Prediction)');
        title(ax(1),str)
        xlabel('X position (m)')
        ylabel('Y position (m)')
        axis(ax(1),V_bounds)
            
        % Plot PHD
        cla(ax(2), 'reset');
        [bandwidth,density,X,Y]=kde2d(myphd.PredParticles([1,3],:)');
        %contour3(X,Y,density,50);
        h = surf(ax(2),X,Y,density);
        shading interp
        colormap(ax(2), jet(3000))
        set(h, 'edgecolor','none')
        hold on;
        plot(ax(2), myphd.PredParticles(1,:), myphd.PredParticles(3,:), '.')
        hold on;
        plot(ax(2), myphd.MeasurementList(1,:), myphd.MeasurementList(2,:), 'y*');
        axis(ax(2), [V_bounds 0 10]);
        str = sprintf('PHD intensity (Prediction)');
        xlabel(ax(2),'X position (m)')
        ylabel(ax(2),'Y position (m)')
        zlabel(ax(2),'Intensity')
        title(ax(2),str)
        pause(0.01)
    end
        
    % Update PHD filter
    myphd.update();
    fprintf("Estimated number of targets: %f\n\n", myphd.NumTargets);
    
    % Plot update step results
    if(ShowPlots && ShowUpdate)
        % Plot data
        cla(ax(1));
         % Flip the image upside down before showing it
        imagesc(ax(1),[min_x max_x], [min_y max_y], flipud(img));

        % NOTE: if your image is RGB, you should use flipdim(img, 1) instead of flipud.
        hold on;
        h2 = plot(ax(1), DataList{k}(1,:),DataList{k}(2,:),'k*','MarkerSize', 10);
        for j=1:TrackNum
            h2 = plot(ax(1), x_true(1:k,j),y_true(1:k,j),'b.-','LineWidth',1);
            if j==2
                set(get(get(h2,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
            end
            h2 = plot(ax(1), x_true(k,j),y_true(k,j),'bo','MarkerSize', 10);
            set(get(get(h2,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
            if(myphd.NumParticles>0)
                plot(ax(1), myphd.Particles(1,:), myphd.Particles(3,:), '.')
            end
             % Exclude line from legend
        end
        % set the y-axis back to normal.
        set(ax(1),'ydir','normal');
        str = sprintf('Robot positions (Update)');
        title(ax(1),str)
        xlabel('X position (m)')
        ylabel('Y position (m)')
        axis(ax(1),V_bounds)
            
        if(myphd.NumParticles>0)
            % Plot PHD
            cla(ax(2), 'reset');
            [bandwidth,density,X,Y]=kde2d(myphd.Particles([1,3],:)');
            %contour3(X,Y,density,50);
            h = surf(ax(2),X,Y,density);        
            shading interp
            colormap(ax(2), jet(3000))
            %set(h, 'edgecolor','none')
            hold on;
            plot(ax(2), myphd.Particles(1,:), myphd.Particles(3,:), '.')
            hold on;
            plot(ax(2), myphd.BornParticles(1,:), myphd.BornParticles(3,:), 'r.')
            plot(ax(2), myphd.MeasurementList(1,:), myphd.MeasurementList(2,:), 'y*');
            axis(ax(2), [V_bounds]);
            str = sprintf('PHD intensity (Update)');
            xlabel(ax(2),'X position (m)')
            ylabel(ax(2),'Y position (m)')
            zlabel(ax(2),'Intensity')
            title(ax(2),str)
            pause(0.01)
        end
    end
end