function preprocess_manifold

SPIKEbin_beh = 0.1;

file = dir('*.spikes.cellinfo.mat');
load(file.name)

file = dir('*.cell_metrics.cellinfo.mat');
load(file.name)

file = dir('*.session.mat');
load(file.name)

file = dir('*.Tracking.Behavior.mat');
load(file.name)

file = dir('*.TrialBehavior.Behavior.mat');
load(file.name)

beh_interval = [tracking.timestamps(1), tracking.timestamps(end)];%[behavTrials.timestamps(1,1) behavTrials.timestamps(end,2)];
speed_lim = 1;


SPIKEMAT = bz_SpktToSpkmat_manifold(spikes, 'dt',SPIKEbin_beh,'win',beh_interval,'units','counts');
timestamp = [];
timestamp = [timestamp, SPIKEMAT.timestamps'];

%% tracking data
pos_x = smoothdata(tracking.position.x(InIntervals(tracking.timestamps,beh_interval)),'movmean',5);
pos_y = smoothdata(tracking.position.y(InIntervals(tracking.timestamps,beh_interval)),'movmean',5);
pos_v = smoothdata(tracking.position.v(InIntervals(tracking.timestamps,beh_interval)),'movmean',5);

%% Make masks for the behavior
trialnumberMask = zeros(size(tracking.timestamps)); % total trials within session
lickedPortMask = zeros(size(tracking.timestamps)); % chosen port
outcomeMask = zeros(size(tracking.timestamps)); % rewarded or not rewarded
chosenPortProbMask = zeros(size(tracking.timestamps));
patchNumMask = zeros(size(tracking.timestamps)); % 0 or 1
patchTrialMask = zeros(size(tracking.timestamps)); %patch number within trial
patchTypeMask = zeros(size(tracking.timestamps)); %High or low prob patch
staySwitchMask = zeros(size(tracking.timestamps));

for ii = 1:length(behavTrials.timestamps)
    posTrials = tracking.timestamps >= behavTrials.timestamps(ii,1) & ...
                tracking.timestamps < behavTrials.timestamps(ii,2);
    trialnumberMask(posTrials) = ii;
    lickedPortMask(posTrials) = behavTrials.port(ii);
    outcomeMask(posTrials) = behavTrials.reward_outcome(ii);
    chosenPortProbMask(posTrials) = behavTrials.ports_probability(ii, behavTrials.port(ii))
    patchNumMask(posTrials) = behavTrials.patch_number(ii);
    patchTrialMask(posTrials) = behavTrials.patch_trials(ii);
    patchTypeMask(posTrials) = behavTrials.patch_type(ii);
    staySwitchMask(posTrials) = behavTrials.patch_type(ii);

end

trialnumberMask = trialnumberMask(InIntervals(tracking.timestamps,beh_interval));
lickedPortMask = lickedPortMask(InIntervals(tracking.timestamps,beh_interval));
outcomeMask = outcomeMask(InIntervals(tracking.timestamps,beh_interval));
chosenPortProbMask = chosenPortProbMask(InIntervals(tracking.timestamps,beh_interval));
patchNumMask = patchNumMask(InIntervals(tracking.timestamps,beh_interval));
patchTrialMask = patchTrialMask(InIntervals(tracking.timestamps,beh_interval));
patchTypeMask = patchTypeMask(InIntervals(tracking.timestamps,beh_interval));
staySwitchMask = staySwitchMask(InIntervals(tracking.timestamps,beh_interval));

% interpolate
trial_num_ds = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),trialnumberMask,timestamp,'nearest');
licked_port_ds = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),lickedPortMask,timestamp,'nearest');
outcome_ds = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),outcomeMask,timestamp,'nearest');
chosen_port_prob_ds = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),chosenPortProbMask,timestamp,'nearest');
patch_num_ds = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),patchNumMask,timestamp,'nearest');
patch_trial_num_ds = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),patchTrialMask,timestamp,'nearest');
patch_type_ds = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),patchTypeMask,timestamp,'nearest');
stay_switch_ds = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),staySwitchMask,timestamp,'nearest');

position_x_all = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),pos_x,timestamp,'linear'); 
position_y_all = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),pos_y,timestamp,'linear'); 
speed_ds = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),pos_v,timestamp,'linear'); 
speed_all = speed_ds';
timestamp_beh = timestamp;


%% Separate CA1 and V1 cells
% spike_count_beh = [];
% spike_count_beh = [spike_count_beh,SPIKEMAT.data(:,:)'];
% spike_counts = spike_count_beh;
% data = normalize(spike_counts,1,'zscore');
% data(isnan(data))=0;
% data = data';
% save('IZ47_230626_sess15.data.mat','data','timestamp')
% save('IZ47_230626_sess15.position_behavior_.mat','timestamp_beh','trial_num_ds','trial_type_ds','correct_ds',...
%     'lick_loc_ds','position_x_all','position_y_all','speed_all','probe_ds','direction_ds');


%%Speed limit
trial_num_ds = trial_num_ds(speed_ds >= speed_lim);
licked_port_ds = licked_port_ds(speed_ds >= speed_lim);
outcome_ds = outcome_ds(speed_ds >= speed_lim);
chosen_port_prob_ds = chosen_port_prob_ds(speed_ds >= speed_lim);
patch_num_ds = patch_num_ds(speed_ds >= speed_lim);
patch_trial_num_ds = patch_trial_num_ds(speed_ds >= speed_lim);
patch_type_ds = patch_type_ds(speed_ds >= speed_lim);
stay_switch_ds = stay_switch_ds(speed_ds >= speed_lim);

position_x_all = position_x_all(speed_ds >= speed_lim); 
position_y_all = position_y_all(speed_ds >= speed_lim); 
speed_dsa = speed_ds(speed_ds>= speed_lim);
speed_all = speed_dsa';
timestamp_beh = timestamp(speed_ds >= speed_lim);

%% Separate CA1 and V1 cells
% spike_count_beh = [];
% spike_count_beh = [spike_count_beh,SPIKEMAT.data(:,:)'];
% 
% spike_counts = spike_count_beh;
% data = normalize(spike_counts,1,'zscore');
% data(isnan(data))=0;
% data = data';

data = data(speed_ds >= speed_lim, :);
timestamp = timestamp(speed_ds >= speed_lim);
save('IZ47_230626_sess15_speed1.data.mat','data','timestamp')


save('IZ47_230626_sess15.position_behavior_speed1.mat','timestamp_beh','trial_num_ds','licked_port_ds','outcome_ds',...
    'chosen_port_prob_ds','position_x_all','position_y_all','speed_all','patch_num_ds','patch_trial_num_ds', 'patch_type_ds', 'stay_switch_ds');

end