function [hatv, impact_bool_idx] = historyAdjustThumpValues(thump_values, thump_times)
%HISTORYADJUSTTHUMPVALUES Get impact events from thump values
% Given an array of thump values (of length n) and times (of length n), 
% return a list of history adjusted thump values (HATVs) and a boolean 
% array (of length n) describing indices where impacts are labelled to have 
% occurred.
% 
% USAGE: [hatv, impact_bool_idx] = historyAdjustThumpValues(thump_values, thump_times)
%   
% OUTPUT
%   hatv: the History Adjusted Thump Values (HATV) from the thump_values.
%       Array of length <= n and units in (m^4/s^-7).
%   impact_bool_idx: A boolean array of length <= n describing the location
%       of impacts within the thump_values/thump_times. 0 corresponds to no
%       impact and 1 corresponds to the presence of an impact.
%
% INPUT
%   seat_vert_accel: Array of length n containing the vertical acceleration 
%       at the seat interface. Units in (m/s^2). Only used to ensure the
%       correct length of the times output if times_or_fs is a scalar
%       (sampling rate).
%   times_or_fs: Array of length n OR scalar. If an array of length n,
%       timeseries corresponding to the measures of seat_vert_accel in
%       units of seconds. If a scalar, then represents the consistent 
%       sampling rate at which data is collected at in units of Hz. If
%       array is entered and the difference between samples are not
%       perfectly consistent, the interpretTimesOrFs function will end up
%       resampling at the median sampling rate. These functions assume a
%       perfectly consistent sampling rate.
%

BINNED_WINDOW_DURATION = 0.1; % this is the duration of the window for our 
    % binned thump metric in seconds, set to 0.1 seconds to capture the 
    % quartersine wave of a 2.5 Hz signal
    
MINIMUM_INTER_IMPACT_INTERVAL = 0.1; % this is the minimum duration 
    % allowable between identified impacts in seconds using the thump
    % method, set to 0.1 seconds arbitrarily

FADE_LIMIT_DURATION = 5.0; % seconds until 99% of a given prior thump's 
    % effect is gone during history adjustment, which we will treat as the 
    % point it disappears
    
HISTORY_ADJUSTED_THUMP_VALUE_COEFFICIENT = sqrt(2); % admittedly an 
    % arbitrary value at this time, something potentially worth improving
    % upon in the future

decay_time_constant = -log(0.01) / FADE_LIMIT_DURATION;
    
fade_limit_length = round(FADE_LIMIT_DURATION / BINNED_WINDOW_DURATION);

hatv = zeros(size(thump_times)); % preallocate array

for i=(fade_limit_length+1):length(thump_times)
    target_preceding_range_idx = (i-fade_limit_length):(i-1);
    
    % get an array of all relevant preceding thump values for adjustment
    preceding_thump_values = thump_values(target_preceding_range_idx); 
    
    % negative array of time elapsed since each relevant preceding thump 
    % value
    preceding_thump_times = thump_times(target_preceding_range_idx) ...
                                - thump_times(i); 
    
    history_adjustment = dot(exp(preceding_thump_times ...
                                        * decay_time_constant), ...
                                    preceding_thump_values)...
                            * HISTORY_ADJUSTED_THUMP_VALUE_COEFFICIENT;
    
    hatv(i) = max(0, thump_values(i) - history_adjustment); 
end

[pks, locs]=findpeaks(hatv, ...
    'MinPeakDistance', ...
    ceil(MINIMUM_INTER_IMPACT_INTERVAL/BINNED_WINDOW_DURATION));

hatv(:) = 0;
hatv(locs) = pks;
impact_bool_idx = hatv > 0;
end
