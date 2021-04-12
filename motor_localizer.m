

%---------------
% Start the task
drawtext_realign(window, 'Movement Task', 'center', white, info)
drawtext_realign(window, 'Bitte machen Sie sich bereit', center_y + 175, white, info)
Screen('Flip', window);
waiting_screen;

motor_cue_name = {'Left Hand','Right Hand','Foot','Foot'};

cue_id = repmat([1;2;footid],30,1);
nTrials = length(cue_id);
cue_id = cue_id(randperm(nTrials));

if practice
    cue_id = repmat([1;2;footid],2,1);
    nTrials = length(cue_id);
    cue_id = cue_id(randperm(nTrials));
end

TrialML.motor_text_cue_dur = info.motor_loc_cue_dur;
TrialML.motordelay = info.motor_loc_delay;
TrialML.motor_loc_deadline = info.motor_loc_dl;
ITI = [0.75, 1.5];
TrialML.motoriti = min(ITI) + abs(diff(ITI))*rand(1,nTrials);
TrialML.FBD = info.feedbackdur;
TrialML.timeout = info.motor_rest_postrsp;

for trial = 1:nTrials
    
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
    fixFrames = round(TrialML.motoriti(trial)/ifi);
    
    % response cue text:
    drawtext_realign(window, motor_cue_name{cue_id(trial)}, center_y-info.fb_pix, white, info)
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    cueOn = Screen('Flip', window, start_fix + (fixFrames - .5)*ifi);
    trig_id = info.motor_cueon_trig;
    trigger(trig_id); disp(['rsp cue trig == ',num2str(trig_id)])
    WaitSecs(TrialML.motor_text_cue_dur);
    
    % delay period:
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    cueOff = Screen('Flip', window);
    trig_id = info.motor_cueoff_trig;
    trigger(trig_id); disp(['delay trig == ',num2str(trig_id)])
    
    % go signal:
    delayFrames = round(TrialML.motordelay/ifi);
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[45,90+45]);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    motorGo = Screen('Flip', window, cueOff + (delayFrames - .5)*ifi);
    trig_id = info.motor_go_trig;
    trigger(trig_id); disp(['go trig == ',num2str(trig_id)])
    
    % response & feedback:
    start = motorGo;
    flush_kbqueues(info.kbqdev);
    [keyIsDown, secs, press_key, deltaSecs] = KbCheck(-3,2);
    while ( press_key(LH)==0  && press_key(RH)==0 && ...
            press_key(LF)==0  && press_key(RF)==0 && ...
            GetSecs-start < TrialML.motor_loc_deadline )
        [keyIsDown, secs, press_key, deltaSecs] = KbCheck(-3,2);
        endrt = secs;
    end
    response_func; % >>>>>>>>>>
    if ~isnan(rsp_code)
        if rsp_code == cue_id(trial)
            Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]+45);
            Screen('FillOval', window, green, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
            rsp_correct = 1;
        else
            Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]+45);
            Screen('FillOval', window, red, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
            rsp_correct = 2;
        end
    else
        Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]+45);
        Screen('FillOval', window, red, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
        drawtext_realign(window,'Missed',center_y-info.fb_pix,red,info)
        rsp_correct = 3;
    end
    TrialML.answer{trial} = rsp;
    
    Screen('Flip', window);
    
    WaitSecs(TrialML.FBD);
    
    % postpone the feedback trigger a bit.
    trig_id = fb_trig_set(rsp_correct);
    trigger(trig_id); disp(['fb trig == ',num2str(trig_id)])
    
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    Screen('Flip', window);
    
    WaitSecs(TrialML.timeout);
    
end

