function out = accelerationWeighting(seat_vert_accel, times_or_fs)
%ACCELERATIONWEIGHTING Filter the acceleration in accordance with ISO 2631
%   I've created a custom automatic filter function from the scripts 
%   provided by 
%   https://vibrationdata.wordpress.com/2012/10/21/iso-2631-matlab-scripts/
%   The documentation, structure, and level of optimizatation are not at
%   the level I'd like, but they are sufficient for now. 

size_of_first_argin = size(seat_vert_accel);

if nargin == 1 && size_of_first_argin(2) == 2 % in case they were bundled 
    q = seat_vert_accel;                        % together
elseif nargin == 2
    [times, ~] = interpretTimesOrFs(seat_vert_accel, times_or_fs);
    q = [times, seat_vert_accel];
else
    error("accelerationWeighting requires both acceleration and time data");
end

[t,f,dt,sr,tmx,tmi,~,ncontinue]=enter_time_history(q);

%
imr=0;
if(imr==1)
    f=f-mean(f);
end    
%
THM=[t f];
%
st=0;
%
te=t(end);
%
j=1;
jfirst=1;
jlast=max(size(THM));
for i=1:max(size(THM))
    if(THM(i,1)<st)
        jfirst=i;
    end
    if(THM(i,1)>te)
        jlast=i;
        break;
    end
end
tim=double(THM(jfirst:jlast,1));
amp=double(THM(jfirst:jlast,2));

[fwl,fw,fwu,wk,wd,wf,wc,we,wj,wb,www,iweight]=weight_factors();

aw=zeros(length(amp),1);
%
iband=3;  % bandpass filtering
iphase=1; % refiltering for phase correction
%
for i=1:44
%
  
%
    fh=fwl(i);  % highpass filter frequency
    fl=fwu(i);  % lowpass filter frequency
%
    if(fl<sr/2.1)
        [y,mu,sd,rms(i)]=...
                Butterworth_filter_function_alt(amp,dt,iband,fl,fh,iphase);
%
        aw=aw+y*www(i);
    end
%
end

out=aw;
end