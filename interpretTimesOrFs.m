function [times, fs] = interpretTimesOrFs(seat_vert_accel, times_or_fs)
%INTERPRETTIMESORFS Correct for if times or sampling rate are input
% Given either an array of times (of length n) or a sampling rate (scaler)
% and an array of vertical seat acceleration values (of length n), return 
% both the times (array of length n) and the sampling rate (scalar).
% 
% USAGE: [times, fs] = interpretTimesOrFs(seat_vert_accel, times_or_fs)
%   
% OUTPUT
%   times: Array of length n. Units in seconds.
%   fs: Scalar sampling rate. Units in Hz.
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
% Notes
%   If times_or_fs is an array, times = times_or_fs. If times_or_fs is a
%       scalar, fs = times_or_fs. 

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

