function patch_data = PatchPlot(filename, makePlot)

    fid = fopen(filename, 'r');
    
    % Initialize variables
    trial_count = 0;
    trial_numbers = [];
    rewarded_trials = [];
    licked_ports = [];
    reward_probabilities = [];
    patch_numbers = [];
    timestamps_licks = []
    previous_rewarded_count = NaN; % (NaN for first trial)
    
    while ~feof(fid)
        % Read first line (trial data)
        trial_line = fgetl(fid);
        trial_count = trial_count + 1;  

        % Split line at the arrow '->' (separates time stamp from data)
        parts = split(trial_line, '_');
        timestamp = parts{1};
        timestamps_licks(trial_count) = str2double(timestamp);
        trialCount = parts{2};
        rewardedTrialCount = parts{3};
        portLick = parts{4};

        trial_numbers(trial_count) = str2double(trialCount);  % trial number
        current_rewarded_count = str2double(rewardedTrialCount);      % current rewarded trial count
        licked_ports(trial_count) = str2double(portLick);   % port licked
        
        % get reward probabilities
        prob_str = parts{5};
        reward_probs = str2double(split(prob_str, ','));
        reward_probabilities(trial_count, :) = reward_probs;
            


        % Determine trial was rewarded based on previous trial
        if trial_count == 1
            if str2double(rewardedTrialCount) == 1
                rewarded_trials(trial_count) = 1; % No previous trial, first trial is not rewarded
            else
                rewarded_trials(trial_count) = 0;
            end
        else
            if current_rewarded_count == previous_rewarded_count + 1
                rewarded_trials(trial_count) = 1; % trial rewarded
            else
                rewarded_trials(trial_count) = 0; % trial not rewarded
            end
        end 

        previous_rewarded_count = current_rewarded_count;
        
        % read next line (patch number)
        if ~feof(fid)
            patch_line = fgetl(fid);
            %disp(patch_line);
            patch_parts = split(patch_line, '_');
            patch_trial(trial_count) = str2double(patch_parts{1});
            patch_type(trial_count) = str2double(patch_parts{2});
            
        end
    end

    port_4_probs = zeros(length(reward_probabilities), 1);
    reward_probabilities_all = [reward_probabilities(:, 1:4-1), port_4_probs, reward_probabilities(:, 4:end)];
    reward_probabilities_all = reward_probabilities_all';

    fclose(fid);

    % create struct
    patch_data = struct;
    patch_data.trial_numbers = trial_numbers;            
    patch_data.rewarded_trials = rewarded_trials;  % whether trial was rewarded (1 = rewarded, 0 = not)
    patch_data.licked_ports = licked_ports;             
    patch_data.reward_probabilities = reward_probabilities_all;  
    patch_data.patch_trials = patch_trial;    
    patch_data.patch_type = patch_type;
    patch_data.timestamps = timestamps_licks;

    if makePlot == 1  
        timestamps = patch_data.timestamps; 
        licked_ports = patch_data.licked_ports;
      
        
        %LICKS AND PROBABILITIES
        figure;
        colormap(flipud(gray)); 
        hold on;
        
        num_trials = length(reward_probabilities);
        x_limits = [min(timestamps), max(timestamps)];
        y_limits = [min(licked_ports), max(licked_ports)]; 
        
        %imagesc(x_limits, y_limits, repmat(reward_probabilities', [1, 2]), 'AlphaData', 0.8); % Transparencia del 30%
        %set(gca, 'YDir', 'normal'); 
        
        plot(timestamps, licked_ports, 'Color', [0.5, 0.5, 0.5]);  
        hold on;
        
        rewarded_indices = find(rewarded_trials == 1);
        not_rewarded_indices = find(rewarded_trials == 0);
        scatter(timestamps(rewarded_indices), licked_ports(rewarded_indices), 'g', 'filled');
        scatter(timestamps(not_rewarded_indices), licked_ports(not_rewarded_indices), 'r', 'filled');
        
        xlabel('Timestamps');
        ylabel('Licked Ports');
        grid on;
    
      
        %LICKS OVER TIME
        licks_matrix = [licked_ports', timestamps_licks'];
        timeBin = 0.5*60*1000; %min x sec x ms
        
        max_time = max(timestamps);  
        num_bins = ceil(max_time / timeBin);
    
        bin_edges = 0:timeBin:(num_bins * timeBin);
    
        unique_ports = unique(licked_ports);
        num_ports = length(unique_ports);
        licks_per_bin = zeros(num_bins, num_ports);  % Matrix bins x ports
    
        for i = 1:num_ports
            port = unique_ports(i);
            port_indices = licked_ports == port;
            port_timestamps = timestamps(port_indices);
            counts_per_bin = histcounts(port_timestamps, bin_edges);
            licks_per_bin(:, i) = counts_per_bin';
        end
    
        licksBin = licks_per_bin';
    
        figure;  
        heatmap(licksBin, 'Colormap', parula);
        xlabel('Ports');
        ylabel('Bins');
    end
        
end