function [times, fs] = interpretTimesOrFs(seat_vert_accel, times_or_fs)
%INTERPRETTIMESORFS Summary of this function goes here
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
end

