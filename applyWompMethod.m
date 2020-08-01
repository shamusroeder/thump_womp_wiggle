function [womp_values, womp_times, jerk_comparison, jerk_impact_values, impact_bool_idx] = applyWompMethod(seat_vert_accel, times_or_fs)
%APPLYWOMPMETHOD Wrapper for getWompValues
%   Because the womp method doesn't require extra functions, I made this
%   wrapper function for style consistency with the Thump Method function 
%   naming schema.
[womp_values, womp_times, jerk_comparison, jerk_impact_values, impact_bool_idx] = getWompValues(seat_vert_accel, times_or_fs);

end

