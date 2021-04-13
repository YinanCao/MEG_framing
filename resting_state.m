clear; clc; close all;
SubName = 'BPA23';
gabor_triangle_rotation = 'L';
EL_flag = 1;
trigger_flag = 1;
debug = 0; % small window
practice = 0;
realframing = 0;   

%---------------
% initialization:
global_variables;
%---------------

% HideCursor;
info.whichsess = 0; % practice
info.whichrun = 4; % resting state

drawtext_realign(window, 'Eye Position Calibration', 'center', white, info)
drawtext_realign(window, 'Bewegen Sie Ihre Augen, um den schwarzen Punkt zu verfolgen', center_y + 175, white, info)
Screen('FillOval', window, black, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix]*6, center_x, center_y + 200));
Screen('Flip', window);
waiting_screen;

% ET calibration:
if info.ET
    disp('ET calibrating')
    % 8 digits limit: XXX01_12
    [el, info] = ELconfig_yc(window,[SubName,'_',num2str(info.whichsess),num2str(info.whichrun)],info,screenNumber);
    % Calibrate the eye tracker
    el.callback = [];
    EyelinkDoTrackerSetup(el);
end
disp('ET calibration done! >>>>>>>>>>')

drawtext_realign(window, 'Head Position Localization', 'center', white, info)
drawtext_realign(window, 'Bitte nicht bewegen!', center_y + 175, white, info)
Screen('Flip', window);
waiting_screen;


% Start Eyelink recording
if info.ET
    disp('ET recording >>>>>>>>>')
    Eyelink('StartRecording');
    WaitSecs(0.1);
    Eyelink('message', 'Start recording Eyelink');
    trigger(info.eyelinkstart);
end


% fixation presentation before stimulus onset
Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
start_fix = Screen('Flip', window);
trig_id = info.fix_trig;
trigger(trig_id); disp(['fix trig == ',num2str(trig_id)])
if info.ET
    Eyelink('command', 'record_status_message "TRIAL %d/%d"', trial, nTrials);
    Eyelink('message', 'TRIALID %d', trial);
    Eyelink('message', num2str(trig_id));
end


waiting_screen;


% Save Eyelink data
if info.ET
    disp('>>> attempting to save ET data >>>')
    time_str = strrep(mat2str(fix(clock)),' ','_');
    eyefilename = fullfile([log_dir,time_str,'_',info.edfFile]);
    Eyelink('CloseFile');
    Eyelink('WaitForModeReady', 500);
    try
        status = Eyelink('ReceiveFile', info.edfFile, eyefilename);
        disp(['File ' eyefilename ' saved to disk']);
    catch
        warning(['File ' eyefilename ' not saved to disk']);
    end
    Eyelink('StopRecording');
end

% Close and clear all
Screen('CloseAll');
ShowCursor;
fclose('all');
Priority(0);
sca;
