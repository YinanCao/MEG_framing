if ~practice
    load([log_dir,SubName,'_contrast_JND.mat'])
    JND = Quest.Quantile_JND;
end

if practice
    JND = 0.12;
end

JND = 0.06;


tmp = [-2,-1,0,1,2]*JND + 0.5;
tmp(tmp>1) = 1;
tmp(tmp<0.15) = 0.15;
info.gabor_contrast_set = tmp;

%---------------
% Design matrix:
%---------------
% orientation = 2, location = 3, rep = 4;
n_contrast = 1;
design = [];
validity = 1;
trigger_id = 10; % sensory loc triggers starts with 11
for loc = 1:3
    for con = 1:5
        trigger_id = trigger_id + 1;
        for rep = 1:15
            design = [design; validity,loc,con,trigger_id];
        end
    end
end
validity = 0; % target trials
for loc = 1:3
    trigger_id = trigger_id + 1;
    for con = 1:5
    for rep = 1
        design = [design; validity,loc,con,trigger_id];
    end
    end
end
while 1 % not too close in time
    design = design(randperm(size(design,1)),:);
    idx = find(design(:,1)==0);
    if sum(diff(idx)<=6) == 0 && min(idx)>2
        break;
    end
end
nTrials = size(design,1);
TrialSL.design = design;


%---------------
% Start the task
%---------------
drawtext_realign(window, 'Flicker Detection', 'center', white, info)
drawtext_realign(window, 'Bitte machen Sie sich bereit', center_y + 175, white, info)
Screen('Flip', window);
waiting_screen;

ITI = [0.85, 1.1];
TrialSL.iti = min(ITI) + abs(diff(ITI))*rand(1,nTrials);
TrialSL.stimdur = info.sensory_loc_gabordur;
stimFrames = round(TrialSL.stimdur/ifi);
TrialSL.deadline = info.sensory_loc_rspdl;
TrialSL.FBD = info.feedbackdur;
TrialSL.timeout = info.sensory_loc_timeout;

if practice
    nTrials = 15;
    design(1:nTrials,1) = 1;
    design([6,13],1) = 0;
end


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
    fixFrames = round(TrialSL.iti(trial)/ifi);
    
    % Gabor:
    contrast = info.gabor_contrast_set(design(trial,3));
    location = design(trial,2);
    orientation = mean(info.framing_orientation);
    [textureIndexTarg,dstRect] = create_gabor(window, Gabor, contrast, location);
    stim_trig = design(trial,end);
    valid_trial = design(trial,1);
    
    % present stimulus:
    if valid_trial
        Screen('DrawTextures', window, textureIndexTarg, [], dstRect, orientation);
        Screen('FrameOval', window, Gabor.holder_c, dstRect, Gabor.outlineWidth);
        Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
        Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
        stimOnset = Screen('Flip', window, start_fix + (fixFrames - .5)*ifi);
        trig_id = stim_trig;
        trigger(trig_id); disp(['stim trig 1 == ',num2str(trig_id)])
        if info.ET
            Eyelink('message', num2str(trig_id));
        end
    else
        nflicker = 6;
        fix_dot_contrast = ones(1,stimFrames);
        fix_dot_contrast(end-nflicker+1:end) = rand(1,nflicker);
        vbl = start_fix + (fixFrames - .5)*ifi;
        for frame_i = 1:stimFrames
            Screen('DrawTextures', window, textureIndexTarg, [], dstRect, orientation);
            Screen('FrameOval', window, Gabor.holder_c, dstRect, Gabor.outlineWidth);
            Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
            Screen('FillOval', window, fix_dot_contrast(frame_i),...
                CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
            vbl = Screen('Flip', window, vbl + .5*ifi);
            if frame_i==1, stimOnset = vbl; 
                trig_id = stim_trig;
                trigger(trig_id); disp(['stim trig 1 == ',num2str(trig_id)])
                if info.ET
                    Eyelink('message', num2str(trig_id));
                end
            end
        end
    end
    
    % Stimulus ends:
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    stimOff = Screen('Flip', window, stimOnset + (stimFrames - .5)*ifi);
        trig_id = stim_trig;
        trigger(trig_id); disp(['stim trig 2 == ',num2str(trig_id)])
        if info.ET
            Eyelink('message', num2str(trig_id));
        end
    
    endrt = GetSecs;
    
    start_FB = nan;
    rsp_correct = nan;
    rsp = nan;
    start = nan;
    
    if ~valid_trial
        start = stimOff;
        flush_kbqueues(info.kbqdev);
        [keyIsDown, secs, press_key, deltaSecs] = KbCheck(-3,2);
        while ( (press_key(LH)==0  && press_key(RH)==0) && GetSecs-start<TrialSL.deadline)
            [keyIsDown, secs, press_key, deltaSecs] = KbCheck(-3,2);
            endrt = secs;
        end
        if press_key(LH) || press_key(RH)
        Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
        Screen('FillOval', window, green, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
        rsp_correct = 1;
        else
        Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
        Screen('FillOval', window, red, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
        drawtext_realign(window,'Missed',center_y-info.fb_pix,red,info)
        rsp_correct = 3;
        end
        
        response_func; % trigger inside

        TrialSL.RT(trial) = endrt - start;
        
        start_FB = Screen('Flip',window);
        WaitSecs(TrialSL.FBD);
        
        
        % postpone the feedback trigger a bit.
        trig_id = fb_trig_set(rsp_correct);
        trigger(trig_id); disp(['fb trig == ',num2str(trig_id)])
        
        Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
        Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
        Screen('Flip', window);
        % time out:
        WaitSecs(TrialSL.timeout);
        
        TrialSL.time(trial,:) = [start_fix,stimOnset,stimOff,endrt,start_FB];
    end
    Screen('Close', textureIndexTarg);
    
    TrialSL.validity(trial) = valid_trial;
    TrialSL.answer{trial} = rsp;
    TrialSL.correct(trial) = rsp_correct;
end

TrialSL.design = design;

WaitSecs(3);
