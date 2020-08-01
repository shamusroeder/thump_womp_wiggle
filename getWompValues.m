function [outputArg1,outputArg2] = getWompValues(seat_vert_accel, times_or_fs)
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
                    
stdnum=2;  %DEFAULT TO 2

doublestandard=1;
movingmeanapply=0;
smoothit=0;
ISOadjust=1;

[times, fs] = interpretTimesOrFs(seat_vert_accel, times_or_fs);


end

