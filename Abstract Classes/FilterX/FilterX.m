classdef (Abstract) FilterX < BaseX  % Extends trackingX.BaseX
% FilterX Abstract class
%
% Summary of FilterX:
% This is the base class for all Tracking filters.
% Any custom defined Filters should be derived from this FilterX base class. 
%
% FilterX Properties:
%   + Model   = Object handle to StateSpaceModelX Sub/class
%
%   (*) Signifies properties necessary to instantiate a class object
%
% FilterX Methods:
%   + FilterX    - Constructor method
%   + predict    - Performs filter prediction step
%   + update     - Performs filter update/correction step
%
% (+) denotes puplic properties/methods
% 
% See also DynamicModel, ObservationModel and ControlModel
%
% January 2018 Lyudmil Vladimirov, University of Liverpool.
    
    properties
        Model
    end
    
    properties (Access = protected, Hidden)
        %FilterState - Current execution state of filter
        %   0: Filter Initialised
        %   1: Filter Predicted
        %   2: Filter Updated
        FilterState = 0
    end
      
    methods
        function this = FilterX(varargin)
        % FILTER Constructor method
        %   
        % DESCRIPTION: 
        % * FilterX("Model", ssm) returns a "FilterX" object handle, configured
        %   to operate in the provided ssm "StateSpaceModel" object handle.
        % * FilterX(config), returns a "FilterX" object handle, configured
        %   to operate in the provided config.Model "StateSpaceModel" object handle.
        %   
        %  See also predict, update, iterate, smooth.
            
            if(nargin==0)
                return;
            end
            
            % First check to see if a structure was received
            if(nargin==1)
                if(isstruct(varargin{1}))
                    if (isfield(varargin{1},'Model'))
                        this.Model = varargin{1}.Model;
                    end
                    return;
                end
            end
            
            % Otherwise, fall back to input parser
            parser = inputParser;
            parser.KeepUnmatched = true;
            parser.addOptional('Model',[]);
            parser.parse(varargin{:});
            
            if(~isempty(parser.Results.Model))
                this.Model = parser.Results.Model;
            end         
        end
        
        function initialise(this,varargin)
            this.FilterState = 0;
        end
        
        function predict(this,varargin)
            this.FilterState = 1;
        end
        
        function update(this,varargin)
            this.FilterState = 2;
        end
        
        % ===============================>
        % ACCESS METHODS
        % ===============================>
        function set.Model(this,newModel)
            this.Model = setModel(this,newModel);
        end
    end

    methods (Access = private)
        % ===============================>
        % ACCESS METHOD HANDLES
        % ===============================>
        function Model = setModel(this,newModel)
            Model = newModel;
        end
    end
end