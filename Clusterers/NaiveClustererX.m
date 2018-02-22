classdef NaiveClustererX < ClustererX
% NAIVECLUSTERERX Class 
%
% Summary of NaiveClustererX:
% This is a class implementation of a multinomial resampler.
%
% NaiveClustererX Properties:
%   None
%
% NaiveClustererX Methods:
%    NaiveClustererX  - Constructor method
%    cluster - Perform clustering and generate a list of clusters
% 
% See also SystematicResamplerX
    properties 
    end
    
    properties (SetAccess = immutable)
        NumObsDims
    end
    
    methods
        function this = NaiveClustererX(varargin)
        % ELLIPSOIDALGATERX Constructor method
        %   
        % DESCRIPTION: 
        % * nv = NaiveClustererX() returns a NaiveClustererX object
        %
        % See also NaiveClustererX/cluster
            
        end
        
        function [ClusterList,UnassocTrackInds] = cluster(this,ValidationMatrix)
        % CLUSTER Perform naive clustering to generate a clusters of
        % tracks sharing common measurements.
        %   
        % DESCRIPTION: 
        % * [ClusterList,UnassocTracks] = cluster(this,ValidationMatrix) 
        %   returns a list of clusters ClusterList and a list of unassociated
        %   track indices UnassocTracks (corresponding to the row indices of 
        %   ValidationMatrix).
        %   ClusterList is a list of Cluster objects, where each cluster
        %   object has two properties:
        %       - ObsIndList: A list of the indices of all measurements
        %                     contained within the cluster.
        %       - TrackIndList: A list of indices of all tracks belonging
        %                       to the cluster.
        %
        % See also NaiveClustererX/NaiveClustererX

            % Initiate parameters
            NumTracks = size(ValidationMatrix,1); % Number of measurements
           
            % Form clusters of tracks sharing measurements
            UnassocTrackInds = [];
            ClusterList = [];
            ClusterObj.ObsIndList = [];
            ClusterObj.TrackIndList = [];
            
            % Iterate over all tracks
            for trackInd=1:NumTracks 
                % Extract valid measurement indices
                validObsInds = find(ValidationMatrix(trackInd,:));

                % If there exist valid measurements
                if (~isempty(validObsInds)) 
                    
                    % Check if matched measurements are members of any clusters
                    NumClusters = numel(ClusterList);
                    matchedClusterIndFlags = zeros(1, NumClusters); 
                    for ClusterInd=1:NumClusters
                        if (sum(ismember(validObsInds, ClusterList{ClusterInd}.ObsIndList)))
                            matchedClusterIndFlags(ClusterInd) = 1; % Store matched cluster ids
                        end   
                    end

                    NumMatchedClusters = sum(matchedClusterIndFlags);
                    matchedClusterInds = find(matchedClusterIndFlags);

                    % If only matched with a single cluster, join.
                    switch(NumMatchedClusters)
                        case(1)
                            ClusterList{matchedClusterInds}.TrackIndList = union(ClusterList{matchedClusterInds}.TrackIndList, trackInd);
                            ClusterList{matchedClusterInds}.ObsIndList = union(ClusterList{matchedClusterInds}.ObsIndList, validObsInds);
                        case(0)
                            ClusterObj.TrackIndList = trackInd;
                            ClusterObj.ObsIndList = validObsInds;
                            ClusterList{end+1} = ClusterObj;
                        otherwise
                            % Start from last cluster, joining each one with the previous
                            %   and removing the former.  
                            for matchedClusterInd = NumMatchedClusters-1:-1:1
                                ClusterList{matchedClusterInds(matchedClusterInd)}.TrackIndList = ...
                                    union(ClusterList{matchedClusterInds(matchedClusterInd)}.TrackIndList, ...
                                        ClusterList{matchedClusterInds(matchedClusterInd+1)}.TrackIndList);
                                ClusterList{matchedClusterInds(matchedClusterInd)}.ObsIndList = ...
                                    union(ClusterList{matchedClusterInds(matchedClusterInd)}.ObsIndList, ...
                                        ClusterList{matchedClusterInds(matchedClusterInd+1)}.ObsIndList);
                                ClusterList(matchedClusterInds(matchedClusterInd+1)) = [];
                            end
                            % Finally, join with associated track.
                            ClusterList{matchedClusterInds(matchedClusterInd)}.TrackIndList = ...
                                union(ClusterList{matchedClusterInds(matchedClusterInd)}.TrackIndList, trackInd);
                            ClusterList{matchedClusterInds(matchedClusterInd)}.ObsIndList = ...
                                union(ClusterList{matchedClusterInds(matchedClusterInd)}.ObsIndList, validObsInds);
                    end
                else
                    UnassocTrackInds = [UnassocTrackInds trackInd];
                end
                this.ClusterList = ClusterList;
                this.UnassocTrackInds = UnassocTrackInds;
            end
        end
    end
end

