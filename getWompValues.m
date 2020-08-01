function [womp_values, womp_times, jerk_comparison, jerk_impact_values, impact_bool_idx] = getWompValues(seat_vert_accel, times_or_fs)
%GETWOMPVALUES Summary of this function goes here
%   Detailed explanation goes here

%given what are essentially jerkbool regions, take in those values for the
%entire dataset, then outputs the locations for the beginning and ending of
%these regions. We will also assume some natural decay for these regions with a
%halflife equal to 1/2 the rise time when the summated value is no longer rising, and straight to zero once the value
%dips below 10%. This is to ensure that we don't have a briefly interrupted
%impact be considered two different impacts.
%regions in question and create

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
k = 0; %iterator for impact s

% we make a struct for readability, could just as easily be a table or
% matrix
s = struct('start_loci',{},...  % where the impact started
            'end_loci',{},...   % where the impact ended
            'max_loci',{},...   % where the impact had the maximum jerk occur
            'total_mag',{},...  % what the total womp value was for the impact
            'max_value',{});    % what the maximum jerk value was

% I could have made this more efficient, but it is what it is

while i<length(jerk_compare) % we iterate through all the points in the data
    target_region = jerk_comparison(i : min(i + min_womp_bin - 1, ...
                                            length(jerk_compare)));
    if all(target_region) && length(target_region) > min_womp_bin % if the short target region is sustained enough
        k = k + 1;
        s(k).start_loci = i;
        s(k).endloci = 0;
        
        % first, we find the end of the impact region, which will be
        % between the end of the min_womp_bin and the max_womp_bin bounds
        while ((jerk_comparison(i) > 0 || (i-s(k).start_loci) < max_womp_bin)...
                && (i < length(jerk_compare)))
            if jerkcompare(i) == 0
                if jerkcompare(i-1 > 0)
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
impact_bool_idx = s.max_loci;                                        
womp_values = s.total_mag; 
womp_times = time_expect(impact_bool_idx);
jerk_impact_values = s.max_value;
end

