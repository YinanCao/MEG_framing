
if practice
    nTrials = 10;
else
    nTrials = 100;
end

% Position
Gabor.Xpos_jnd                    = [center_x-Gabor.X_Shift_pix,center_x+Gabor.X_Shift_pix];
Gabor.Ypos_jnd                    = [center_y,center_y];
TrialJND.all_pos                 = ['L','R'];
TrialJND.Gabor_position          = Shuffle(repmat(TrialJND.all_pos,[1 nTrials/2]));
TrialJND.Gabor_orientation_type  = Shuffle(repmat(['R','L'], [1 nTrials/2]));% 'R':clockwise 'L':Couter-clockwis
TrialJND.Gabor_orientation_R     = Gabor.gabor_orientation_set(Gabor.gabor_orientation_set>0);
TrialJND.Gabor_orientation_L     = Gabor.gabor_orientation_set(Gabor.gabor_orientation_set<0);
TrialJND.Gabor_all_contrast_base = [0.5 0.5];
TrialJND.num_quests              = 2;
TrialJND.Which_quest             = Shuffle(repmat([1:TrialJND.num_quests],[1 nTrials/TrialJND.num_quests]));
TrialJND.near_rng                = [1.03 1.07];
TrialJND.far_rng                 = [1.6 1.8];
TrialJND.t_guess                 = TrialJND.Gabor_all_contrast_base...
    .*([diff(TrialJND.near_rng)*rand + min(TrialJND.near_rng) ...
    diff(TrialJND.far_rng)*rand + min(TrialJND.far_rng)]);
TrialJND.Gabor_contrast          = TrialJND.Gabor_all_contrast_base(TrialJND.Which_quest);

TrialJND.t_guess                 = TrialJND.t_guess - TrialJND.GB_all_contrast_base;

%    Make a truncated distributaion for inter_trial delay
pd                            = makedist('Exponential','mu',0.75);
t                             = truncate(pd,0.5,1);
TrialJND.BRD                     = random(t,[1,nTrials]);% Being Ready duration
TrialJND.SD                      = 0.75*ones(1,nTrials);% Stimulus duration
TrialJND.StRCD                   = info.stimoff2rsp; % Stimulus offset to Response Cue onset duration
TrialJND.RCD                     = info.rsp_win; % Response Cue duration
TrialJND.FBD                     = info.feedbackdur; % FeedBack duration

for trial = 1:nTrials
    if TrialJND.Gabor_orientation_type(trial)=='R'
        nori = length(TrialJND.Gabor_orientation_R);
        which_o = randi(nori,1,2);
            TrialJND.orientation(trial,:) = TrialJND.Gabor_orientation_R(which_o);
    else
        nori = length(TrialJND.Gabor_orientation_L);
        which_o = randi(nori,1,2);
            TrialJND.orientation(trial,:) = TrialJND.Gabor_orientation_L(which_o);
    end
    % first column: left gabor and second column: right gabor
    TrialJND.Center_X_fluc(trial,:)=Gabor.Xpos_jnd+((sign(randn(1,2)).*rand(1,2))*Gabor.size_fluctuation);
    TrialJND.Center_Y_fluc(trial,:)=Gabor.Ypos_jnd+((sign(randn(1,2)).*rand(1,2))*Gabor.size_fluctuation);
end
%-------------------------
% Set the QUEST Parameters
%-------------------------
% Here we use two Quests to avoid biasing
t_guess = log10(TrialJND.t_guess);
for q = 1:TrialJND.num_quests
    eval(['Quest.tGuess' num2str(q) '= t_guess(q)' ]);
    eval(['Quest.tGuessSd' num2str(q) '= 0.5']);
    eval(['Quest.pThreshold' num2str(q) '= 0.70']);
    eval(['Quest.beta' num2str(q) '= 3.5']);
    eval(['Quest.delta' num2str(q) '= 0.01']);
    eval(['Quest.gamma' num2str(q) '= 0.5']);
    eval(['Quest.q' num2str(q) '(1)= QuestCreate(Quest.tGuess' num2str(q) ...
        ',Quest.tGuessSd' num2str(q) ',Quest.pThreshold' num2str(q) ...
        ',Quest.beta' num2str(q) ',Quest.delta' num2str(q) ',Quest.gamma' num2str(q) ');']);
end

%---------------
% Start the task
%---------------
drawtext_realign(window, 'Brightness Judgement', 'center', white, info)
drawtext_realign(window, 'Bitte machen Sie sich bereit', center_y + 175, white, info)
Screen('Flip', window); 
waiting_screen;

%%% waiting for the first trial and not start the task immediately
Rotated_fixation(window, fix_rect, center_x, center_y,dark_grey,[0,90]);
Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
Screen('Flip', window);
WaitSecs(1);

% Define Quest counter to know which quest should be updated in each trial

for q_c = 1:TrialJND.num_quests
    eval(['q_counter' num2str(q_c) '=1']);
end

for trial = 1:nTrials
    
    Trial_run_JND_diff;

    % Update the Quest
    if (TrialJND.eval_answer(trial))==2
        w_q = num2str(TrialJND.Which_quest(trial));
        eval (['Quest.q' w_q '(q_counter' w_q ') = Quest.q' w_q ...
            '(q_counter' w_q '-1);']);
    else
        response = TrialJND.eval_answer(trial);
        w_q = num2str(TrialJND.Which_quest(trial));
        eval (['Quest.q' w_q '(q_counter' w_q ') = QuestUpdate(Quest.q' w_q ...
            '(q_counter' w_q '-1),TrialJND.log10_tr(trial),response);']);
    end
end
TrialJND.Acc_withoutMissed   = sum(TrialJND.eval_answer==1)./(sum(TrialJND.eval_answer==1)+sum(TrialJND.eval_answer==0));
TrialJND.Acc_withMissed      = sum(TrialJND.eval_answer==1)./nTrials;
TrialJND.NoMissed            = sum(TrialJND.eval_answer==2);

if nTrials > 20
    e = (round(nTrials./(TrialJND.num_quests*10))-1)*10+1;
else
    e = nTrials./TrialJND.num_quests;
end

for q_c = 1:TrialJND.num_quests
    
    if q_c == 1
        eval (['quantile_list_log10 = QuestQuantile(Quest.q' num2str(q_c) '(e:end-1));']);
        eval (['mean_list_log10 = QuestMean(Quest.q' num2str(q_c) '(e:end-1));']);
        eval (['mode_list_log10 = QuestMode(Quest.q' num2str(q_c) '(e:end-1));']);
        eval (['quantile_list = 10.^(QuestQuantile(Quest.q' num2str(q_c) '(e:end-1)));']);
        eval (['mean_list = 10.^(QuestMean(Quest.q' num2str(q_c) '(e:end-1)));']);
        eval (['mode_list = 10.^(QuestMode(Quest.q' num2str(q_c) '(e:end-1)));']);
        eval (['JND_contrast_list= Quest.JND_contrast' num2str(q_c) '(e:end)']);
        eval (['JND_log10contrast_list =  Quest.JND_log10contrast' num2str(q_c) '(e:end)']);
    else
        eval (['quantile_list_log10 = [quantile_list_log10 QuestQuantile(Quest.q' num2str(q_c) '(e:end-1))]']);
        eval (['mean_list_log10 = [mean_list_log10 QuestMean(Quest.q' num2str(q_c) '(e:end-1))]']);
        eval (['mode_list_log10 = [mode_list_log10 QuestMode(Quest.q' num2str(q_c) '(e:end-1))]']);
        eval (['quantile_list = [quantile_list 10.^(QuestQuantile(Quest.q' num2str(q_c) '(e:end-1)))]']);
        eval (['mean_list = [mean_list 10.^(QuestMean(Quest.q' num2str(q_c) '(e:end-1)))]']);
        eval (['mode_list = [mode_list 10.^(QuestMode(Quest.q' num2str(q_c) '(e:end-1)))]']);
        eval (['JND_contrast_list = [JND_contrast_list Quest.JND_contrast' num2str(q_c) '(e:end)]']);
        eval (['JND_log10contrast_list = [JND_log10contrast_list Quest.JND_log10contrast' num2str(q_c) '(e:end)]']);
        
    end
    
%     if q_c == 1
%         eval (['quantile_list_log10 = QuestQuantile(Quest.q' num2str(q_c)...
%             '(e:end-1))-log10(TrialJND.Gabor_all_contrast_base('  int2str(q_c) '));']);
%         eval (['mean_list_log10 = QuestMean(Quest.q' num2str(q_c)...
%             '(e:end-1))-log10(TrialJND.Gabor_all_contrast_base('  int2str(q_c) '));']);
%         eval (['mode_list_log10 = QuestMode(Quest.q' num2str(q_c)...
%             '(e:end-1))-log10(TrialJND.Gabor_all_contrast_base('  int2str(q_c) '));']);
%         eval (['quantile_list = 10.^(QuestQuantile(Quest.q' num2str(q_c)...
%             '(e:end-1)))-(TrialJND.Gabor_all_contrast_base('  int2str(q_c) '));']);
%         eval (['mean_list = 10.^(QuestMean(Quest.q' num2str(q_c)...
%             '(e:end-1)))-(TrialJND.Gabor_all_contrast_base('  int2str(q_c) '));']);
%         eval (['mode_list = 10.^(QuestMode(Quest.q' num2str(q_c)...
%             '(e:end-1)))-(TrialJND.Gabor_all_contrast_base('  int2str(q_c) '));']);
%         eval (['JND_contrast_list= Quest.JND_contrast' num2str(q_c) '(e:end)']);
%         eval (['JND_log10contrast_list =  Quest.JND_log10contrast' num2str(q_c) '(e:end)']);
%     else
%         eval (['quantile_list_log10 = [quantile_list_log10 QuestQuantile(Quest.q' num2str(q_c)...
%             '(e:end-1))-log10(TrialJND.Gabor_all_contrast_base('  int2str(q_c) '))]']);
%         eval (['mean_list_log10 = [mean_list_log10 QuestMean(Quest.q' num2str(q_c)...
%             '(e:end-1))-log10(TrialJND.Gabor_all_contrast_base('  int2str(q_c) '))]']);
%         eval (['mode_list_log10 = [mode_list_log10 QuestMode(Quest.q' num2str(q_c)...
%             '(e:end-1))-log10(TrialJND.Gabor_all_contrast_base('  int2str(q_c) '))]']);
%         eval (['quantile_list = [quantile_list 10.^(QuestQuantile(Quest.q' num2str(q_c)...
%             '(e:end-1)))-(TrialJND.Gabor_all_contrast_base('  int2str(q_c) '))]']);
%         eval (['mean_list = [mean_list 10.^(QuestMean(Quest.q' num2str(q_c)...
%             '(e:end-1)))-(TrialJND.Gabor_all_contrast_base('  int2str(q_c) '))]']);
%         eval (['mode_list = [mode_list 10.^(QuestMode(Quest.q' num2str(q_c)...
%             '(e:end-1)))-(TrialJND.Gabor_all_contrast_base('  int2str(q_c) '))]']);
%         eval (['JND_contrast_list = [JND_contrast_list Quest.JND_contrast' num2str(q_c) '(e:end)]']);
%         eval (['JND_log10contrast_list = [JND_log10contrast_list Quest.JND_log10contrast'...
%             num2str(q_c) '(e:end)]']);
%     end
end
Quest.Quantile_JND_log10     = mean(quantile_list_log10);
Quest.Mean_JND_log10         = mean(mean_list_log10);
Quest.Mode_JND_log10         = mean(mode_list_log10);
Quest.Quantile_JND           = mean(quantile_list);
Quest.Mean_JND               = mean(mean_list);
Quest.Mode_JND               = mean(mode_list);

% End of the Task
final_message = sprintf('Danke! Your accuracy was: %0.2f %%', TrialJND.Acc_withMissed*100);
drawtext_realign(window, final_message, center_y, white, info)
Screen('Flip', window);
WaitSecs(3);
JND_BDMOGtask.info = info;
JND_BDMOGtask.Trial = TrialJND;
JND_BDMOGtask.Gabor = Gabor;
JND_BDMOGtask.Quest = Quest;

JND.quantile         = Quest.Quantile_JND;
JND.mean             = Quest.Mean_JND;
JND.mode             = Quest.Mode_JND;
JND.quantile_log10   = Quest.Quantile_JND_log10;
JND.mean_log10       = Quest.Mean_JND_log10;
JND.mode_log10       = Quest.Mode_JND_log10;
JND.list_tr          = JND_contrast_list;
JND.list_tr_q1       = JND_contrast_list(1:(length(JND.list_tr)/2));
JND.list_tr_q2       = JND_contrast_list((length(JND.list_tr)/2)+1:end);
JND.mean_tr_q1       = mean(JND.list_tr_q1);
JND.mean_tr_q2       = mean(JND.list_tr_q2);
JND.list_tr_log10    = JND_log10contrast_list;
JND.list_tr_q1_log10 = JND_log10contrast_list(1:(length(quantile_list)/2));
JND.list_tr_q2_log10 = JND_log10contrast_list((length(quantile_list)/2)+1:end);
JND.mean_tr_q1_log10 = mean(JND.list_tr_q1_log10);
JND.mean_tr_q2_log10 = mean(JND.list_tr_q2_log10);
JND.base_value       = TrialJND.Gabor_all_contrast_base(1);

% save this varr: Quest.Mean_JND
estimated_jnd = [Quest.Quantile_JND, Quest.Mean_JND]
disp(['JND = ', num2str(estimated_jnd)])

if ~practice
    if ~exist([log_dir,SubName,'_contrast_JND.mat'],'file')
        save([log_dir,SubName,'_contrast_JND.mat'],'JND_BDMOGtask','Quest','JND');
    end
end
