function [thump_values, thump_times] = getThumpValues(seat_vert_accel, times_or_fs)
%GETTHUMPVALUES Summary of this function goes here
%   Detailed explanation goes here


    
user_provided_fs = isscalar(times_or_fs);

if user_provided_fs
    times   = (0:length(seat_vert_accel) - 1) ./ times_or_fs;
    fs      = times_or_fs;
else
    times   = times_or_fs;
    fs      = 1./ median(diff(times)); %while this function assumes a 
        % perfectly consistently sampled acceleration signal, we include
        % this logic to account for small variations in sampling rate,
        % assuming that they all even out in the end 
end

binned_window_length    = round(BINNED_WINDOW_DURATION * fs); % the actual 
    % length of a bin in terms of indices

% we don't bother with any clipped off ends of the data that doesn't fill a
% final bin
final_analysis_idx = length(seat_vert_accel) - mod(length(seat_vert_accel), ...
                                                    binned_window_length);

number_of_bins = (final_analysis_idx / binned_window_length);

thump_values = zeros([number_of_bins, 1]); % preallocate array
thump_times = zeros([number_of_bins, 1]); % preallocate array

for i = 1:number_of_bins
    target_bin_idx  = ((1+(i-1)*binned_window_length)...
                        : ((i)*binned_window_length));
    
    time_included   = times(target_bin_idx);
    accel_included  = seat_vert_accel(target_bin_idx);
    
    % after removing the mean, take the time-integrated 4th power of the 
    % acceleration over the window to create the thump value
    thump_values(i) = trapz(time_included, ...
                        (accel_included - mean(accel_included)).^4); 
                    
    thump_times(i)  = time_included(1);
end
end
