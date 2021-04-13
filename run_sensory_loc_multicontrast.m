clear; clc; close all;
SubName = 'BPA23';
gabor_triangle_rotation = 'L';
EL_flag = 1;
trigger_flag = 1;
debug = 0; % small window
practice = 0;   

%---------------
% initialization:
global_variables;
%---------------

% HideCursor;
info.whichsess = 0;
info.whichrun = 3; % sensory loc multicontrast

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

sensory_localizer_multicontrast;

% stay still after all trials
drawtext_realign(window, 'Head Position Localization', 'center', white, info)
drawtext_realign(window, 'Bitte nicht bewegen!', center_y + 175, white, info)
Screen('Flip', window);

% Save Eyelink data
time_str = strrep(mat2str(fix(clock)),' ','_');
info.eyefilename = 'none';
if info.ET
    disp('>>> attempting to save ET data >>>')
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
    info.eyefilename = eyefilename;
end

info.matdatadir = log_dir;
if ~practice
    matname = [log_dir,SubName,'_SLmultic_ses',num2str(info.whichsess),'_run',...
        num2str(info.whichrun),time_str,'.mat'];
    save(matname,'info','Gabor','TrialSL')
end
waiting_screen;
Screen('CloseAll');
ShowCursor;
fclose('all');
Priority(0);
sca;
