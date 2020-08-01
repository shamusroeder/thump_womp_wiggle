%
disp(' ');
disp('  th_weighted.m  ver 1.2  May 31, 2013 ');
disp(' ');
disp('  by Tom Irvine  Email: tom@vibrationdata.com ');
disp('  ');
disp('  '); 
disp('  This program converts an acceleration time history to a ');
disp('  weighted format per ISO 2631. ');
disp('  ');
disp('  The input file must be time(sec) and amplitude(units) ');
disp('  The format is free, but no header lines allowed.');
disp(' ');
%
close all;
%
clear amp;
clear f;
clear length;
clear THM;
clear y;
clear ww;
%
fig_num=1;
%
[t,f,dt,sr,tmx,tmi,~,ncontinue]=enter_time_history();
%
disp(' ');
disp(' Remove mean?  1=yes 2=no');
%
imr=input(' ');
if(imr==1)
    f=f-mean(f);
end    
%
THM=[t f];
%
iunits=0;
%
while( iunits ~= 1 && iunits ~=2 )
%
    out1=sprintf('\n Enter input unit:\n  1=G  2= m/sec^2  ');
    disp(out1);
	iunits=input(' ');
%
end
%
if(iunits==1)
    p_unit=sprintf('G');
else
    p_unit=sprintf('m/sec^2');    
end
%
x_label=sprintf('Time(sec)');
y_label=sprintf('Accel(%s)',p_unit);
t_string=sprintf('Time History');
[fig_num]=plot_TH(fig_num,x_label,y_label,t_string,THM);
%
disp(' ');
st=input(' Enter starting time (sec) ');
%
disp(' ');
te=input(' Enter ending time (sec) ');
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
%
tim=double(THM(jfirst:jlast,1));
amp=double(THM(jfirst:jlast,2));    
%
if(iunits==1)
    amp=amp*9.81;
end
%
if(imr==1)
    amp=amp-mean(amp);
end
%
[fwl,fw,fwu,wk,wd,wf,wc,we,wj,wb,www,iweight]=weight_factors();
%
aw=zeros(length(amp),1);
%
iband=3;  % bandpass filtering
iphase=1; % refiltering for phase correction
%
progressbar;
for i=1:44
%
    progressbar(i/44);
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
%
pause(0.5);
progressbar(1);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
n=length(aw);
%
AW=std(aw);
MTW=AW;
%
VDV=0;
for i=1:n
    VDV=VDV+aw(i)^4;
end
VDV=(VDV*dt)^0.25;
%
disp(' ');
disp(' Subdivide time history into segments?  1=yes 2=no');
ig=input(' ');
%
if(ig==1)
    disp(' ');
    dur=input(' Enter segment duration (sec) ');
%
    ns=round(dur/dt);
%
    loops=floor(n/ns);
%
    ia=1;
%
    disp(' ');
    disp(' Time         aw     ');
    disp(' (sec)     (m/sec^2) RMS ');
%
    for i=1:loops
        ib=ia+ns-1;
        if(ib>n)
            break;
        end
        ttt=dt*(ib+ia)/2;
        as=std(aw(ia:ib));
        out1=sprintf('%8.0f  %8.2f ',ttt,as);
        disp(out1);
        if(as>MTW)
            MTW=as;
        end
        ia=ib;
    end
%
end
disp(' ');
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
out1=sprintf('\n Composite Weighted Level  AW = %8.4g (m/sec^2)RMS ',AW);
disp(out1);
%
out1=sprintf('\n Maximum Transient Vibration MTW = %8.4g (m/sec^2)RMS ',MTW);
disp(out1);
%
out1=sprintf('\n Fourth Power Vibration Dose VDV = %8.4g (m/sec^(1.75)) \n',VDV);
disp(out1);
%
out1=sprintf('\n                          MTW/AW = %8.4g\n',MTW/AW);
disp(out1);