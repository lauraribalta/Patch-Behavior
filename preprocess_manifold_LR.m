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
trialnumberMask = zeros(size(tracking.timestamps));
typeMask = 7 * ones(size(tracking.timestamps));
correctMask = zeros(size(tracking.timestamps));
licklocMask = 7 * ones(size(tracking.timestamps));
directionMask = zeros(size(tracking.timestamps));
probeMask = zeros(size(tracking.timestamps));

for ii = 1:length(behavTrials.timestamps)
    if ii < length(behavTrials.timestamps)
            posTrials = tracking.timestamps >= behavTrials.timestamps(ii,1) & ...
                        tracking.timestamps <= behavTrials.timestamps(ii+1,1);
            trialnumberMask(posTrials) = ii;
    else
            posTrials = tracking.timestamps >= behavTrials.timestamps(ii,1) & ...
                        tracking.timestamps <= behavTrials.timestamps(ii,2);
            trialnumberMask(posTrials) = ii;
    end

       

    if behavTrials.timestamps(ii,1) ~= behavTrials.timestamps(end,1)
        posTrials = tracking.timestamps >= behavTrials.timestamps(ii,1) & ...
                    tracking.timestamps <= behavTrials.timestamps(ii,2);
        directionMask(posTrials) = 1;
        licklocMask(posTrials) = behavTrials.lickLoc(ii);
        typeMask(posTrials) = behavTrials.toneGain(ii);
        probeMask(posTrials) = behavTrials.probe(ii);
        correctMask(posTrials) = behavTrials.correct(ii);
        posTrials = tracking.timestamps > behavTrials.timestamps(ii,2) & ...
                    tracking.timestamps <= behavTrials.timestamps(ii+1,1); 
        directionMask(posTrials) = 2;
        
    
    else 
        posTrials = tracking.timestamps >= behavTrials.timestamps(ii,1) & ...
                    tracking.timestamps <= behavTrials.timestamps(ii,2);
        licklocMask(posTrials) = behavTrials.lickLoc(ii);
        typeMask(posTrials) = behavTrials.toneGain(ii);
        directionMask(posTrials) = 1;
        probeMask(posTrials) = behavTrials.probe(ii);
        correctMask(posTrials) = behavTrials.correct(ii);
    end

end

trialnumberMask = trialnumberMask(InIntervals(tracking.timestamps,beh_interval));
typeMask = typeMask(InIntervals(tracking.timestamps,beh_interval));
correctMask = correctMask(InIntervals(tracking.timestamps,beh_interval));
licklocMask = licklocMask(InIntervals(tracking.timestamps,beh_interval));
directionMask = directionMask(InIntervals(tracking.timestamps,beh_interval));
probeMask = probeMask(InIntervals(tracking.timestamps,beh_interval));

% interpolate
trial_num_ds = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),trialnumberMask,timestamp,'nearest');
trial_type_ds = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),typeMask,timestamp,'nearest');
correct_ds = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),correctMask,timestamp,'nearest');
lick_loc_ds = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),licklocMask,timestamp,'nearest');
direction_ds = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),directionMask,timestamp,'nearest');
probe_ds = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),probeMask,timestamp,'nearest');

position_x_all = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),pos_x,timestamp,'linear'); 
position_y_all = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),pos_y,timestamp,'linear'); 
speed_ds = interp1(tracking.timestamps(InIntervals(tracking.timestamps,beh_interval)),pos_v,timestamp,'linear'); 
speed_all = speed_ds';
timestamp_beh = timestamp;



%% Separate CA1 and V1 cells
spike_count_beh = [];
spike_count_beh = [spike_count_beh,SPIKEMAT.data(:,:)'];

spike_counts = spike_count_beh;
data = normalize(spike_counts,1,'zscore');
data(isnan(data))=0;
data = data';
save('IZ47_230626_sess15_speed0.data.mat','data','timestamp')


save('IZ47_230626_sess15.position_behavior_speed0.mat','timestamp_beh','trial_num_ds','trial_type_ds','correct_ds',...
    'lick_loc_ds','position_x_all','position_y_all','speed_all','probe_ds','direction_ds');


%%Speed limit
trial_num_ds = trial_num_ds(speed_ds >= speed_lim);
trial_type_ds = trial_type_ds(speed_ds >= speed_lim);
correct_ds = correct_ds(speed_ds >= speed_lim);
lick_loc_ds = lick_loc_ds(speed_ds >= speed_lim);
direction_ds = direction_ds(speed_ds >= speed_lim);
probe_ds = probe_ds(speed_ds >= speed_lim);

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


save('IZ47_230626_sess15.position_behavior_speed1.mat','timestamp_beh','trial_num_ds','trial_type_ds','correct_ds',...
    'lick_loc_ds','position_x_all','position_y_all','speed_all','probe_ds','direction_ds');

end
