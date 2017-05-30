% VLF spectrum analyzer in MATLAB
% Version 0.1
% license GPL v3.0
% Alexey V. Voronin @ FoxyLab © 2017
% Email: support@foxylab.com
% Website: https://acdc.foxylab.com
% -----------------------------------
% for 32 bit MATLAB
clc; % cmd wnd clear
close all;  % fig del
disp('***** VLF spectrum analyzer *****');
disp('© 2017 Alexey V. Voronin @ FoxyLab');
disp('https://acdc.foxylab.com');
disp('**************************');
% high-pass filter cutoff frequency
prompt = {'Low Frequency (f)'};
defans = {'6000'};
answer = inputdlg(prompt,'Low Frequency (f), Hz',1,defans);
[low_freq status] = str2num(answer{1});
if ~status
    error('Incorrect value!');
end;
prompt = {'Interval (dt)'};
defans = {'20'};
answer = inputdlg(prompt,'Interval (dt), msec',1,defans);
[window status] = str2num(answer{1});
if ~status
    error('Incorrect value!');
end;
prompt = {'Numbers (N)'};
defans = {'5000'};
answer = inputdlg(prompt,'Numbers (N)',1,defans);
[nums status] = str2num(answer{1});
if ~status
    error('Incorrect value!');
end;
prompt = {'Low Frequency (peak) (f)'};
defans = {'17000'};
answer = inputdlg(prompt,'Low Frequency (peak) (f), Hz',1,defans);
[peak_low status] = str2num(answer{1});
if ~status
    error('Incorrect value!');
end;
prompt = {'High Frequency (peak) (f)'};
defans = {'26500'};
answer = inputdlg(prompt,'High Frequency (peak) (f), Hz',1,defans);
[peak_high status] = str2num(answer{1});
if ~status
    error('Incorrect value!');
end;
disp(sprintf('f(filter) = %d Hz',low_freq));
disp(sprintf('dt = %d msec',window));
disp(sprintf('N = %d',nums));
disp(sprintf('f(low) = %d Hz',peak_low));
disp(sprintf('f(high) = %d Hz',peak_high));
Fs = 96000; % sampling freq, Hz
duration = window/1000; % measure interval, sec
while (true)
ai = analoginput('winsound'); 
addchannel(ai,1); % HW ch add
% ch 1 - mono
set (ai, 'SampleRate', Fs); % sampling freq set
set (ai, 'SamplesPerTrigger', duration*Fs); % samples number set
set (ai, 'TriggerType', 'Manual'); % manual start
set(ai,'TriggerRepeat',Inf);
start(ai); % acquire ready
bins = []; % bin array create
trigger(ai); % acquire start
data = getdata(ai); % data read
L = length(data); % data array size
% disp(sprintf('L = %d samples',L));
% disp(sprintf('dF = %d Hz/bin',Fs/L));
for m =1:1:L/2+1 % bin array clear
    bins(m) = 0;
end;
count = 0;
trigger(ai); % acquire start
while (count < nums) % acquire loop
    data = getdata(ai); % data read
    
    % wait
    Y = fft(data); 
    % P2 = abs(Y/L);
    % P1 = P2(1:L/2+1);
    % P1(2:end-1) = 2*P1(2:end-1);
    for m =1:1:L/2+1
        bins(m) = (bins(m)*count+abs(Y(m))*2/L)/(count+1);
    end;
    count = count+1;
    disp(sprintf('#%d',count));   
    trigger(ai); % acquire start
end
stop(ai); % acquire stop
delete(ai); % analog input object delete
clear ai; % analog input object clear
f = Fs*(0:(L/2))/L; % freqs
for m =1:1:L/2+1 % low pass filter
    if ((m-1)*Fs/L < low_freq) 
        bins(m) = 0;
    end;
end;
%file name
formatOut = 'dd.mm.yyyy HH:MM'; % date time
unique = datestr(now,formatOut);
disp(unique);
formatOut = 'yyyymmddHHMMSS'; % date time
unique = datestr(now,formatOut);
unique_txt = strcat(unique,'.txt'); % png-file save  
unique_png = strcat(unique,'.png'); % png-file save  
txt_file = fopen(unique_txt,'w'); % log file open
fprintf(txt_file,'f = %d Hz\r\n',low_freq);
fprintf(txt_file,'dt = %d msec\r\n',window);
fprintf(txt_file,'N = %d\r\n',nums);
% peak detection
peak_thres = 100e-6; %peak level
peak_width = 3; % peak width/2
for m =peak_width+1:1:L/2+1-(peak_width+1) % low pass filter
    peak=true;
    %asc test
    for k=m-peak_width:1:m-1
        if (bins(k)>=bins(m)) %peak fail
            peak = false;
        end;
    end;
    %desc test
    for k=m+1:1:m+peak_width
        if (bins(k)>=bins(m)) %peak fail
            peak = false;
        end;
    end;
    %width test
    if ((bins(m)-bins(m-peak_width))<peak_thres) || ((bins(m)-bins(m+peak_width))<peak_thres)
        peak = false; %peak fail
    end;
    if (peak==true)
        if (((m-1)*Fs/L)>=peak_low) && (((m-1)*Fs/L)<=peak_high)
            peak_level = bins(m)-bins(m-peak_width);
            if ((bins(m)-bins(m+peak_width))<peak_level)
                peak_level = bins(m)-bins(m+peak_width);
            end;
            disp(sprintf('Peak: %d Level: %5.0fu',(m-1)*Fs/L,peak_level*1e6));
            fprintf(txt_file,'Peak: %d ',(m-1)*Fs/L);
            fprintf(txt_file,'Level: %5.0fu\r\n',peak_level*1e6);
        end;
    end;
end;
fclose(txt_file); % log file close

k=1;
for m =1:1:L/2+1 % low pass filter
    if ((m-1)*Fs/L >= peak_low) && ((m-1)*Fs/L <= peak_high)
        graph(k) = bins(m); % y axis
        freq(k) = (m-1)*Fs/L; % x axis
        k = k + 1;
    end;
end;
h = figure(1);
plot(freq,graph); % spectrum
grid on;
title('Spectrum'); % plot title
xlabel('f, Hz') % OX axis label
saveas(h, unique_png, 'png'); % plot save
close(h); % plot close 
end;
clear all; % objects delete