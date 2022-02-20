function [thump_values, thump_times, impact_thump_values, impact_times, hatv, impact_bool_idx] = applyThumpMethod(seat_vert_accel, times_or_fs)
%APPLYTHUMPMETHOD Get all thump info from accel timeseries
% Given vertical acceleration (in terms of m/s^2) at the seat and the times
% or sampling rate that acceleration was collected, return all impact, 
% thump values, and times in seconds to which they correspond.
%
% USAGE: [thump_values, thump_times, impact_thump_values, impact_times, hatv,  impact_bool_idx] = applyThumpMethod(seat_vert_accel, times_or_fs)
%   
% OUTPUT
%   thump_values: Array of length n containing thump values according to
%       the length of seat_vert_accel and times_or_fs. Units in (m^4/s^-7).
%   thump_times: Array of length n containing the times to which they
%       correspond. Units in seconds. If times_or_fs is input as a vector 
%       of length n of times in seconds, then thump_times will return an
%       array of times in seconds with the same starting time. If 
%       times_of_fs is input as a scaler (the sampling rate), then 
%       thump_times will start at 0 and be relative to the first sample. 
%       (If [100, 100.01, 100.02...] is input for times_or_fs, thump_times 
%       will start at 100. If a sampling rate is input, thump_times will 
%       start at 0.)
%   impact_thump_values: Subset of thump_values that correspond to impacts.
%       Array of length <= n and units in (m^4/s^-7).
%   impact_times: Subset of thump_times that correspond to impacts. Array 
%       of length <= n and units in seconds.
%   hatv: The History Adjusted Thump Values (HATV) from the thump_values.
%       Array of length <= n and units in (m^4/s^-7).
%   impact_bool_idx: A boolean array of length <= n describing the location
%       of impacts within the thump_values/thump_times. 0 corresponds to no
%       impact and 1 corresponds to the presence of an impact.
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

[thump_values, thump_times] = getThumpValues(seat_vert_accel, times_or_fs);

[hatv, impact_bool_idx] = historyAdjustThumpValues(thump_values, thump_times);

impact_times = thump_times(impact_bool_idx);
impact_thump_values = thump_values(impact_bool_idx);
end

