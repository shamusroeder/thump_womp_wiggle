function [womp_values, womp_times, jerk_comparison, jerk_impact_values, impact_bool_idx] = getWompValues(seat_vert_accel, times_or_fs)
%GETWOMPVALUES Get all womp info from accel timeseries
% Given vertical acceleration (in terms of m/s^2) at the seat and the times
% or sampling rate that acceleration was collected, return all impact, 
% womp values, and times in seconds to which they correspond.
%
% USAGE: [womp_values, womp_times, jerk_comparison, jerk_impact_values, impact_bool_idx] = getWompValues(seat_vert_accel, times_or_fs)
%   
% OUTPUT
%   womp_values: Array of length n containing womp values. Units in 
%       (m/s^2). This array will be equal in length to the number of
%       impacts.
%   womp_times: Array of length n containing the times to which they
%       correspond. Units in seconds. If times_or_fs is input as a vector 
%       of length m of times in seconds, then thump_times will return an
%       array of times in seconds with the same starting time. If 
%       times_of_fs is input as a scaler (the sampling rate), then 
%       thump_times will start at 0 and be relative to the first sample. 
%       (If [100, 100.01, 100.02...] is input for times_or_fs, thump_times 
%       will start at 100. If a sampling rate is input, womp_times will 
%       start at 0.)
%   jerk_comparison: Array of length (m - 1). If the jerk expectation is
%       exceeded, returns how much the jerk is exceeded by. Otherwise,
%       returns 0.
%   jerk_impact_values: The value of the jerk wherever there is an impact.
%   impact_bool_idx: A boolean array of length <= m describing the location
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

ECHO_DURATION_SHORT = 1.0;  % ECHO_DURATION_SHORT describes the timespan  
                            % over which an individual would generate an 
                            % "expectation" for movement in the short term 
                            % in seconds. A period of 1.0 seconds 
                            % corresponds to taking in a quartersine of 
                            % 0.25 Hz. 
                            
ECHO_DURATION_LONG = 7.0;   % ECHO_DURATION_LONG describes the timespan  
                            % over which an individual would generate an 
                            % "expectation" for movement in the longer term 
                            % in seconds. 

% These two echo duration values were selected arbitrarily and provide an 
% opportunity for future study and optimization. 

ECHO_DELAY = 0.1;   % ECHO_DELAY approximates the time until a muscle 
                    % response to a sudden load occurs and assumes that 
                    % this is also the time for a movement to be 
                    % incorporated into their expectation of continued
                    % motion. Reference the following: 
                    
                    % Wilder, D., Aleksiev, A., Magnusson, M., Pope, M., 
                    % Spratt, K., & Goel, V. (1996). Muscular Response to 
                    % Sudden Load. Spine, 21(22), 2628-2639. 
                    % doi: 10.1097/00007632-199611150-00013

MIN_WOMP_DURATION = 0.01;   % MIN_WOMP_DURATION is the minimum impact 
                            % duration that the “Womp Threshold” must 
                            % continuously exceed and maintain for it to 
                            % be labelled as an impact, which we have set 
                            % at 10ms  
                            
MAX_WOMP_DURATION = 0.15;   % MAX_WOMP_DURATION is the maximum impact 
                            % duration that the “Womp Threshold” can 
                            % continuously exceed and maintain for it to 
                            % be labelled as an single impact, which we 
                            % have set at 150ms to avoid a sustained
                            % low-magnitude increase in vertical
                            % acceleration following a period of near
                            % motionlessness to be interpretted as a very
                            % severe impact.
                    
NUM_STD_THRESHOLD = 2;  % number of standard deviations to form our 
                        % womp threshold

APPLY_ISO_WEIGHTING = true; % boolean whether to apply ISO weighting

USE_DOUBLE_STANDARD = true; % boolean whether to use only the short echo 
                            % duration or to also use the long echo
                            % duration

COMPENSATE_FOR_ACCEL_CAPPING = true;   % boolean whether to ignore all 
                        % jerks equal to exactly zero. If on, this will
                        % protect against the influence of any acceleration
                        % capping (such as to compensate for movement
                        % artifacts).
                                        
[times, fs] = interpretTimesOrFs(seat_vert_accel, times_or_fs);

if APPLY_ISO_WEIGHTING
    seat_vert_accel = accelerationWeighting(seat_vert_accel, times);
end

echo_bin        = round(ECHO_DURATION_SHORT * fs);
echo_bin_long   = round(ECHO_DURATION_LONG * fs);
delay_bin       = round(ECHO_DELAY * fs);

min_womp_bin    = round(MIN_WOMP_DURATION * fs);
max_womp_bin    = round(MAX_WOMP_DURATION * fs);

jerk = diff(seat_vert_accel)./diff(times);  % we don't use the fs variable 
                                   % here because we want to retain as
                                   % accurate of time differentials as
                                   % possible, even if it means having
                                   % uneven values
                                
if COMPENSATE_FOR_ACCEL_CAPPING
    jerk(jerk == 0) = NaN;
end

jerk_std    = movstd(jerk, [echo_bin, 0], 'omitnan');
jerk_expect = sqrt(movmean(jerk.^2, [echo_bin, 0], 'omitnan')) ...
                + NUM_STD_THRESHOLD * jerk_std;

if USE_DOUBLE_STANDARD
    jerk_std    = movstd(jerk, [echo_bin_long, 0], 'omitnan');
    jerk_expect = max([jerk_expect, ...
                      sqrt(movmean(jerk.^2, [echo_bin_long, 0], 'omitnan')) ...
                        + NUM_STD_THRESHOLD * jerk_std], ...
                      [], 2);
end

if COMPENSATE_FOR_ACCEL_CAPPING
    jerk(isnan(jerk)) = 0; % undo our earlier replacement
end

%now we have the expected jerk threshold over the echobin. Now we need to
%shift it all over to the right by the delay bin.
jerk_expect(delay_bin+1 : end) = jerk_expect(1 : end-delay_bin);

% we 'recenter' the timevalues since we differentiated them earlier
time_expect = times(1 : end-1) + 1/(2*fs); 

jerk_comparison = max(jerk - jerk_expect,0); % find wherever the threshold 
                                             % is exceeded

jerk_comparison(1 : delay_bin + echo_bin) = 0;  % make the first part of the 
                                                % timeseries data 0

%now we search for the start and end points of positive regions in the
%comparison
%set up natural decay calculations
i = 1; % iterator for the jerk_compare vector
k = 0; % iterator for impact s

% we make a struct for readability, could just as easily be a table or
% matrix
s = struct('start_loci',{},...  % where the impact started
            'end_loci',{},...   % where the impact ended
            'max_loci',{},...   % where the impact had the maximum jerk occur
            'total_mag',{},...  % what the total womp value was for the impact
            'max_value',{});    % what the maximum jerk value was

% I could have made this more efficient, but it is what it is
%{
while i<length(jerk_comparison) % we iterate through all the points in the data
    target_region = jerk_comparison(i : min(i + min_womp_bin - 1, ...
                                            length(jerk_comparison)));
    if all(target_region) && (length(target_region) > min_womp_bin) % if the short target region is sustained enough
        k = k + 1;
        s(k).start_loci = i;
        s(k).endloci = 0;
        
        % first, we find the end of the impact region, which will be
        % between the end of the min_womp_bin and the max_womp_bin bounds
        while ((jerk_comparison(i) > 0 || (i-s(k).start_loci) < max_womp_bin)...
                && (i < length(jerk_comparison)))
            if jerk_comparison(i) == 0
                if jerk_comparison(i-1 > 0)
                    s(k).end_loci = i - 1;
                end           
            end
            i = i + 1;
        end
        if s(k).end_loci == 0 
            s(k).end_loci = i;
        end
        
        [~,s(k).maxloci]    = max(jerk_comparison(s(k).start_loci : s(k).end_loci));
        s(k).max_loci       = s(k).max_loci + s(k).start_loci - 1;
        s(k).max_value      = jerk(s(k).max_loci);
        s(k).total_mag      = trapz(time_expect(s(k).start_loci : s(k).end_loci), ...
                                jerk_comparison(s(k).start_loci : s(k).end_loci));
    else
        % quickly jump to the next possibly valid region
        i = i + find(~target_region, 1, 'last');
    end

end
%}
while i < length(jerk_comparison)
    if all(jerk_comparison(i:min(i+min_womp_bin-1, length(jerk_comparison))))
        k = k+1;
        s(k).start_loci = i;
        transient_measure = 0;
        mag = 0;
        s(k).end_loci=0;
        while (jerk_comparison(i)>0||transient_measure==0)&&(i < length(jerk_comparison))
            mag = mag + (jerk_comparison(i-1)+jerk_comparison(i))*(time_expect(i)-time_expect(i-1))/2; %ongoing trapezoidal integration
            if jerk_comparison(i)==0
                transient_measure=(i-s(k).start_loci>max_womp_bin);
                if jerk_comparison(i-1)>0
                    s(k).end_loci=i-1;
                end           
            end
            i=i+1;
        end
        if s(k).end_loci==0&&i==length(jerk_comparison)
            s(k).end_loci=i;
        end
        [~,s(k).max_loci]=max(jerk_comparison(s(k).start_loci:s(k).end_loci));
        s(k).max_loci=s(k).max_loci+s(k).start_loci-1;
        s(k).max_value=jerk(s(k).max_loci);
        s(k).total_mag=mag;
    else
        i=i+1;
    end
end
impact_bool_idx = logical(zeros(size(seat_vert_accel)));

if isempty(s)
    womp_values = [];
    womp_times = [];
    jerk_impact_values = [];

else
    impact_bool_idx([s.max_loci]) = 1;

    womp_values = [s.total_mag]; 
    womp_times = time_expect(impact_bool_idx);
    jerk_impact_values = [s.max_value];
end

