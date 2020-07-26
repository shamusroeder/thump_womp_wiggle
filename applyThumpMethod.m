function [thump_values, thump_times, impact_thump_values, impact_times, hatv,  impact_bool_idx] = applyThumpMethod(seat_vert_accel, times_or_fs)
%APPLYTHUMPMETHOD Summary of this function goes here
%   Detailed explanation goes here
[thump_values, thump_times] = getThumpValues(seat_vert_accel, times_or_fs);

[hatv, impact_bool_idx] = historyAdjustThumpValues(thump_values, thump_times);

impact_times = thump_times(impact_bool_idx);
impact_thump_values = thump_values(impact_bool_idx);
end

