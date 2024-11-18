
patch_data = plotPatchBehavior('PatchBehav2024-11-06T11_52_46.6704128-05_00', true)

%LICK PROBABILITIES VS REWARD PROBABILITIES - PORTS
% Initialize an empty structure array
results_struct = struct('Port', {}, 'Patch', {}, 'PortRewardProbability', {}, 'PortLickProbability', {});

for port = unique(patch_data.licked_ports)

    %create patch mask
    patch_type_mask = zeros(length(patch_data.patch_type), 1);
    count = 1;
    patch_type_mask(1) = count;
    
    for i = 2:length(patch_data.patch_type)
        if patch_data.patch_type(i) ~= patch_data.patch_type(i - 1);
            count = count + 1;
        end
        patch_type_mask(i) = count;
    end
    
    %calcualte probability to lick in port X while port probability is Y
    port_probabilities = patch_data.reward_probabilities(port+1, :); %port's probability throughout session
    patch_type_mask = patch_type_mask';
    for patch = unique(patch_type_mask);
        licked_ports_count = nnz((patch_type_mask == patch) & (patch_data.licked_ports == port));
        total_patch_counts = nnz((patch_type_mask == patch));
        port_lick_probability = licked_ports_count / total_patch_counts;
        port_probability_patch = port_probabilities(find(patch_type_mask == patch, 1));
        
        result_entry = struct('Port', port, 'Patch', patch, ...
                              'PortRewardProbability', port_probability_patch, ...
                              'PortLickProbability', port_lick_probability);
                          
        results_struct(end+1) = result_entry;
    end

end

% Create a multiplot figure organized in a single row
unique_ports = unique([results_struct.Port]);
num_ports = length(unique_ports);
num_cols = num_ports;
num_rows = 1; 

figure;
for idx = 1:num_ports
    port = unique_ports(idx);
    
    subplot(num_rows, num_cols, idx);
    
    logicalIndex = [results_struct.Port] == port;
    filtered_values = results_struct(logicalIndex);
    bar([filtered_values.Patch], [filtered_values.PortLickProbability], 'FaceColor', [.7 .7 .7], 'EdgeColor', [.7 .7 .7]); 

   % plot([filtered_values.Patch], [filtered_values.PortLickProbability], 'k-', 'LineWidth', 2); 
    hold on;
    plot([filtered_values.Patch], [filtered_values.PortRewardProbability], 'r-', 'LineWidth', 2);

    xlabel('Patch');
    ylabel('Probability');
    title(['Port: ', num2str(port + 1)]);
    axis tight;      
end

for idx = 1:num_ports
    subplot(num_rows, num_cols, idx);
    ylim([0 1]); 
end
legend({'Lick Probability', 'Reward Probability'}, 'Location', 'BestOutside', 'Orientation', 'vertical');

sgtitle('Lick and Reward Probabilities Across Ports');
%LICK PROBABILITIES VS REWARD PROBABILITIES - PATCH

%PREDOMINANT PATCH OVER TIME
lickedPatch = patch_data.licked_ports;
lickedPatch(ismember(lickedPatch, [1, 2, 3])) = -1; 
lickedPatch(lickedPatch == 4) = 0;                  
lickedPatch(ismember(lickedPatch, [5, 6, 7])) = 1; 

%perform moving average
window_size = 40;
smoothed_ports = movmean(lickedPatch, window_size);
patchChangePoint = double(diff(patch_type_mask) ~= 0);

figure;
hold on;
%plot(licked_ports, 'k', 'DisplayName', 'Original Data');   % Original data in black
plot(smoothed_ports, 'b', 'DisplayName', 'Smoothed Data'); % Smoothed data in red
change_indices = find(patchChangePoint);

for i = 1:length(change_indices)
    xline(change_indices(i), 'r--', 'DisplayName', 'Patch Change'); 
end

xlabel('Index');
ylabel('Value');
legend;
grid on;
hold off;


%PROBABILITY OF CHANGING PATCH AS A FUNCTION OF CONSECUTIVE ERRORS
decisionOutcome = patch_data.rewarded_trials;

trialsNumber = length(lickedPatch);
nonRewardedTrials = zeros(1, trialsNumber); % Number of consecutive trials without reward
patchChange = zeros(1, trialsNumber - 1); 

% Calculate accumulated trials without reward
for i = 2:trialsNumber
    if decisionOutcome(i-1) == 0
        nonRewardedTrials(i) = nonRewardedTrials(i-1) + 1;
    else
        nonRewardedTrials(i) = 0;
    end
    
    % Detect decision changes
    if lickedPatch(i) ~= lickedPatch(i-1)
        patchChange(i-1) = 1; 
    end
end

% Group trials by the number of trials without reward
maxNonRewarded = max(nonRewardedTrials);
changeProbability = zeros(1, length(maxNonRewarded) + 1);

for n = 0:maxNonRewarded
    trials_n = (nonRewardedTrials == n);
    
    % Count how many of these trials have a decision change
    changes = sum(patchChange(trials_n(2:end)));
    totalTrials = sum(trials_n(2:end));
    disp(['n = ', num2str(n), ', totalTrials = ', num2str(totalTrials)]);
    if totalTrials > 0
        changeProbability(n + 1) = changes / totalTrials;
    else
        changeProbability(n + 1) = NaN;
    end
end

figure;
bar(0:maxNonRewarded, changeProbability, 'FaceColor', [0.2 0.6 0.8]);
xlabel('Trials without reward');
ylabel('Change probability');
title('Change probability based on trials without reward');
grid on;

for n = 0:maxNonRewarded
    text(n, changeProbability(n + 1) + 0.02, num2str(numSamples(n + 1)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
end

