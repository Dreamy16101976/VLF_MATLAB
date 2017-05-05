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
disp(sprintf('f = %d Hz',low_freq));
disp(sprintf('dt = %d msec',window));
disp(sprintf('N = %d',nums));
Fs = 96000; % sampling freq, Hz
duration = window/1000; % measure interval, sec
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
disp(sprintf('L = %d samples',L));
disp(sprintf('dF = %d Hz/bin',Fs/L));
for m =1:1:L/2+1 % bin array clear
    bins(m) = 0;
end;
count = 0;
trigger(ai); % acquire start
while (count < nums) % acquire loop
    data = getdata(ai); % data read
    % wait
    trigger(ai); % acquire start
    Y = fft(data); 
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    for m =1:1:L/2+1
        bins(m) = (bins(m)*count+P1(m))/(count+1);
    end;
    count = count+1;
    disp(sprintf('#%d',count));   
end
stop(ai); % acquire stop
delete(ai); % analog input object delete
clear ai; % analog input object clear
f = Fs*(0:(L/2))/L; % freqs
for m =1:1:L/2+1 % low pass filter
    if (m*Fs/L < low_freq) 
        bins(m) = 0;
    end;
end;
h = figure(1);
plot(f,bins); % spectrum
grid on;
title('Spectrum'); % plot title
xlabel('f, Hz') % OX axis label
formatOut = 'yyyymmddHHMMSS'; % date time
unique = datestr(now,formatOut);
unique_png = strcat(unique,'.png'); % png-file save  
saveas(h, unique_png, 'png'); % plot save
close(h); % plot close 
clear all; % objects delete