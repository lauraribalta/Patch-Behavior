function [behavTrials] = getPatchBehavior(varargin)

p = inputParser;
addParameter(p,'saveMat',true,@islogical);
addParameter(p,'plotfig',true,@islogical)
addParameter(p,'forceRun',true,@islogical)
addParameter(p,'updatedIntan',true,@islogical)

parse(p,varargin{:});
saveMat = p.Results.saveMat;
plotfig = p.Results.plotfig;
forceRun = p.Results.forceRun;
updatedIntan = p.Results.updatedIntan;

basepath = pwd;

%% Deal with inputs
if ~isempty(dir([basepath filesep '*.TrialBehavior.Events.mat'])) && ~forceRun
    disp('Trial behavior already detected! Loading file.');
    file = dir([basepath filesep '*.TrialBehavior.Events.mat']);
    load(file.name);
    return
end

%% Get digital inputs
if exist('settings.xml')
    delete 'settings.xml'
end
disp('Loading digital In...');
digitalIn = bz_getDigitalIn; % Figure out why periodLag is crashing
if isempty(digitalIn)
    toneBehav = [];
    return
end


% Start of trial
startTrial = digitalIn.timestampsOn{1,2};
durTrial = digitalIn.dur{1,2}';
endTrial = startTrial + durTrial;
endTrial = endTrial(2:end);
timestamps = [startTrial(1:end-1),endTrial];
[~, idxTS] = sort(timestamps(:,1));

behavTrials.trialNumber = idxTS;
behavTrials.timestamps = timestamps;

% Initialize
behavTrials.trialNumber = zeros(size(behavTrials.timestamps,1),1);
behavTrials.patchTrialNumber = zeros(size(behavTrials.timestamps,1),1); %Trial within patch
behavTrials.licks = zeros(size(behavTrials.timestamps,1),7); %Total licks in trial
behavTrials.chosenPort =  zeros(size(behavTrials.timestamps,1),1);
behavTrials.rewardOutcome = zeros(size(behavTrials.timestamps,1),1); %rewarded (1), not rearded (0)
behavTrials.portProbability = zeros(size(behavTrials.timestamps,1),1);
behavTrials.patchProbability = zeros(size(behavTrials.timestamps,1),1); 


for ii = 1:size(behavTrials.timestamps,1)
   for lickSens = 3:9
   behavTrials.licks(ii,lickSens-2) = sum(InIntervals(digitalIn.timestampsOn{lickSens},[behavTrials.timestamps(ii,1) behavTrials.timestamps(ii,2)]));
   behavTrials.chosenPort(ii,lickSens-2) = sum(InIntervals(digitalIn.timestampsOn{lickSens},[behavTrials.timestamps(ii,2)-0.005 behavTrials.timestamps(ii,2)]));
   end   
end


