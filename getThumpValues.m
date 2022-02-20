function [thump_values, thump_times] = getThumpValues(seat_vert_accel, times_or_fs)
%GETTHUMPVALUES Get the Thump Values and times from accel timeseries
% Given vertical acceleration (in terms of m/s^2) at the seat and the times
% or sampling rate that acceleration was collected, return the thump values
% and times in seconds to which they correspond.
%
% USAGE: [thump_values, thump_times] = getThumpValues(seat_vert_accel, times_or_fs)
%   
% OUTPUT
%   thump_values: Array of length n containing thump values according to
%       the length of seat_vert_accel and times_or_fs. Units in (m^4/s^-7)
%   thump_times: Array of length n containing the times to which they
%       correspond. Units in seconds. If times_or_fs is input as a vector 
%       of length n of times in seconds, then thump_times will return an
%       array of times in seconds with the same starting time. If 
%       times_of_fs is input as a scaler (the sampling rate), then 
%       thump_times will start at 0 and be relative to the first sample. 
%       (If [100, 100.01, 100.02...] is input for times_or_fs, thump_times 
%       will start at 100. If a sampling rate is input, thump_times will 
%       start at 0.)
%
% INPUT
%   seat_vert_accel: Array of length m containing the vertical acceleration 
%       at the seat interface. Units in (m/s^2). 
%   times_or_fs: Array of length m OR scalar. If an array of length m,
%       timeseries corresponding to the measures of seat_vert_accel in
%       units of seconds. If a scalar, then represents the consistent 
%       sampling rate at which data is collected at in units of Hz. If
%       array is entered and the difference between samples are not
%       perfectly consistent, the interpretTimesOrFs function will end up
%       resampling at the median sampling rate. These functions assume a
%       perfectly consistent sampling rate.
%
% Notes
%   If times_or_fs is not a scaler, its length must equal that of
%       seat_vert_accel.

BINNED_WINDOW_DURATION = 0.1; % this is the duration of the window for our 
    % binned thump metric in seconds, set to 0.1 seconds to capture the 
    % quartersine wave of a 2.5 Hz signal
    
[times, fs] = interpretTimesOrFs(seat_vert_accel, times_or_fs);

binned_window_length    = round(BINNED_WINDOW_DURATION * fs); % the actual 
    % length of a bin in terms of index positions

% we don't bother with any clipped off ends of the data that doesn't fill a
% final bin
final_analysis_idx = length(seat_vert_accel) - mod(length(seat_vert_accel), ...
                                                    binned_window_length);

number_of_bins  = (final_analysis_idx / binned_window_length);

thump_values    = zeros([number_of_bins, 1]); % preallocate array
thump_times     = zeros([number_of_bins, 1]); % preallocate array

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
