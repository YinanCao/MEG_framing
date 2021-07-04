
SubName = 'MSE24';
gabor_triangle_rotation = 'L';


addpath(genpath('/usr/share/psychtoolbox-3/'))
if IsLinux
log_dir = '/home/usera/Documents/MEG_framing_data/';
else
log_dir = '/Users/yinancaojake/Documents/Postdoc/UKE/MEG_framing_data/';
end
Screen('CloseAll');


if ~practice
    load([log_dir,SubName,'_contrast_JND.mat'])
    JND = Quest.Quantile_JND;
end
%JND=0.09;

Screen('Preference', 'SkipSyncTests', 2);
%--------------------------------------
% Open the window and Setup PTB
%--------------------------------------
PsychDefaultSetup(2);
AssertOpenGL;
screenNumber = max(Screen('Screens'));

% Define the keys
keyLR = {'z','g','1!','2@'}; % b,z,g,r for 1,2,3,4
if debug
   keyLR = {'a','f','s','d'}; % b,z,g,r for 1,2,3,4
end

KbName('UnifyKeyNames');
LH = KbName(keyLR{1});
RH = KbName(keyLR{2});
LF = KbName(keyLR{3});
RF = KbName(keyLR{4});

% Define the colors
white     = WhiteIndex(screenNumber);
black     = BlackIndex(screenNumber);
grey      = white / 2;
green     = [0,200,0];
red       = [200,0,0];
blue      = [0,0,200];
pink      = [255,20,147];
dark_grey = white / 4;

info.frametxt_color = black;

Gabor.holder_c  = [0 1 1];
info.gabor_color = 'W';
info.fb_color_set = {green,red};
Gabor.background = grey;
info.backgroundcolor = grey;
info.lateral_offset = -75; % correct for lateral offset of the projected image

info.feedback_text_above = 1.05;

PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
smallWindow4Debug = [];
if debug
    smallWindow4Debug  = [0 0 1920 1080]/1.2;
    disp('>>>>>> debugging mode <<<<<<')
end 
Screen('Preference', 'TextRenderer', 1); % smooth text 
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, smallWindow4Debug, 32, 2,...
     [], [], kPsychNeed32BPCFloat);
% [window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);
[center_x, center_y] = RectCenter(windowRect);
Screen('TextFont', window, 'Helvetica'); % define text font
Screen('TextSize', window, 20); % define text font
info.window_rect  = windowRect;
info.frameDur     = Screen('GetFlipInterval', window); %duration of one frame
info.frameRate    = Screen('NominalFrameRate', window);
ifi = info.frameDur;
% Maximum priority level
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
HideCursor;
center_x = center_x + info.lateral_offset;
%%
info.SubName       = SubName;
info.eccentricity  = 'f';
info.ET            = EL_flag;
info.do_trigger    = trigger_flag;
info.mon_width_cm  = 45;   % width of monitor (cm)
info.mon_height_cm = 26.5; % height of monitor (cm)
info.view_dist_cm  = 56;   % viewing distance (cm)
info.pix_per_deg   = info.window_rect(3) *(1 ./ (2 * atan2(info.mon_width_cm / 2, info.view_dist_cm))) * pi/180;
info.fb_pix = info.pix_per_deg*info.feedback_text_above;

% for eyelink:
info.width = info.mon_width_cm;
info.height = info.mon_height_cm;
info.dist = info.view_dist_cm;

rng('shuffle');
% trigger_enc = setup_trigger;

if info.do_trigger
    addpath matlabtrigger/
else
    addpath faketrigger/
end

% make Kb Queue: Need to specify the device to query button box
% Find the keyboard + MEG buttons.
[idx, names, all] = GetKeyboardIndices();
info.kbqdev = idx;
keyList = ones(1, 256);
for kbqdev = info.kbqdev
    PsychHID('KbQueueCreate', kbqdev, keyList);
    PsychHID('KbQueueStart', kbqdev);
    WaitSecs(.1);
    PsychHID('KbQueueFlush', kbqdev);
end

%----------------
% Gabor Parameters
%----------------
if strcmp(info.gabor_color,'B')
    Gabor.WorB =  1; % 1:black
else
    Gabor.WorB = -1; %-1:white
end

% Gabor.tr_contrast           = all_contrast;
Gabor.freq_deg              = 4; % spatial frequency (cycles/deg)
Gabor.period                = 1/Gabor.freq_deg*info.pix_per_deg; % in pixels
Gabor.freq_pix              = 1/Gabor.period;% in pixels
Gabor.diameter_deg          = 1.6;
Gabor.patchHalfSize         = round(info.pix_per_deg*(Gabor.diameter_deg/2));
Gabor.SDofGaussX            = Gabor.patchHalfSize/2;
Gabor.patchPixel            = -Gabor.patchHalfSize:Gabor.patchHalfSize;
Gabor.elp                   = 1;
Gabor.numGabors             = 3;
Gabor.numGabors_JND         = 2;
Gabor.foil_contrast         = 0; % JND task
Gabor.gabor_orientation_set = -75:30:75;

if info.eccentricity == 'n'
    Gabor.gc_from_sc_deg    = 1.25;
elseif info.eccentricity == 'f'
    Gabor.gc_from_sc_deg    = 2.2;
end

Gabor.gc_from_sc_pix        = round(info.pix_per_deg*Gabor.gc_from_sc_deg);
Gabor.X_Shift_deg           = round(((sqrt(3)/2) * Gabor.gc_from_sc_deg));
Gabor.Y_Shift_deg           = round(((1/2) * Gabor.gc_from_sc_deg));
Gabor.X_Shift_pix           = round(info.pix_per_deg * Gabor.X_Shift_deg);
Gabor.Y_Shift_pix           = round(info.pix_per_deg * Gabor.Y_Shift_deg);
Gabor.size_fluctuation      = 0;
Gabor.outlineWidth          = 1;
Gabor.Triangle_dir          = 'U';
Gabor.Gabor_arng_rotation   = gabor_triangle_rotation; % 'R' or 'L'
Gabor.rot_deg               = 6;

if Gabor.Triangle_dir == 'U'
    x                  = [-Gabor.X_Shift_pix,0,Gabor.X_Shift_pix];
    y                  = [Gabor.Y_Shift_pix,-Gabor.gc_from_sc_pix,Gabor.Y_Shift_pix];
else
    x                  = [-Gabor.X_Shift_pix,0,Gabor.X_Shift_pix];
    y                  = [-Gabor.Y_Shift_pix,Gabor.gc_from_sc_pix,-Gabor.Y_Shift_pix];
end

if Gabor.Gabor_arng_rotation == 'R'
    x_rot              = round(x*cosd(Gabor.rot_deg) - y*sind(Gabor.rot_deg));
    y_rot              = round(y*cosd(Gabor.rot_deg) + x*sind(Gabor.rot_deg));
    Xpos               = [center_x,center_x,center_x] + x_rot;
    Ypos               = [center_y,center_y,center_y] + y_rot;
    footid = 4;
    foot_name = 'RF';
    info.framing_orientation = Gabor.gabor_orientation_set(Gabor.gabor_orientation_set<0);
else
    x_rot              = round(x*cosd(360-Gabor.rot_deg) - y*sind(360-Gabor.rot_deg));
    y_rot              = round(y*cosd(360-Gabor.rot_deg) + x*sind(360-Gabor.rot_deg));
    Xpos               = [center_x,center_x,center_x] + x_rot;
    Ypos               = [center_y,center_y,center_y] + y_rot;
    footid = 3;
    foot_name = 'LF';
    info.framing_orientation = Gabor.gabor_orientation_set(Gabor.gabor_orientation_set>0);
end

info.rsp_names = {foot_name,'LH','RH'};

% we need to change it to mid (top), left, right
Gabor.Xpos = Xpos([2,1,3]); 
Gabor.Ypos = Ypos([2,1,3]);

% Crossed fixation information
Gabor.Fixation_dot_deg        = 0.15;
Gabor.Fixation_cross_h_deg    = Gabor.Fixation_dot_deg;
Gabor.Fixation_cross_w_deg    = Gabor.Fixation_dot_deg*4;
Gabor.Fixation_dot_pix        = round(info.pix_per_deg*Gabor.Fixation_dot_deg);
Gabor.Fixation_cross_h_pix    = round(info.pix_per_deg*Gabor.Fixation_cross_h_deg);
Gabor.Fixation_cross_w_pix    = round(info.pix_per_deg*Gabor.Fixation_cross_w_deg);
fixCrossDimPix                = round(info.pix_per_deg*(Gabor.Fixation_cross_w_deg/2));%12 pix
xCoords                       = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords                       = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords                     = [xCoords; yCoords];
lineWidthPix                  = round(info.pix_per_deg*Gabor.Fixation_dot_deg);%6 pix
fix_rect                      = [-fixCrossDimPix -lineWidthPix./2 fixCrossDimPix lineWidthPix./2];

%% global trigger code:
info.resp_LH_trig = 101;
info.resp_RH_trig = 102;
info.resp_LF_trig = 103;
info.resp_RF_trig = 104;
info.resp_invalid_trig = 105;
info.fix_trig = 99;

% sensory loc triggers starts with 11
% valid = 11 ~ 28
% invalid = 29,30,31

info.motor_cueon_trig = 81;
info.motor_cueoff_trig = 82;
info.motor_go_trig = 83;

info.fb_correct = 111;
info.fb_wrong   = 112;
info.fb_missed  = 113;
fb_trig_set = [info.fb_correct,info.fb_wrong,info.fb_missed];

info.frame_on_trig = 71;
info.delayon_trig = 72;
info.frame_rspon_trig = 73;

% framing stim trigger:
info.frame_c = (1:5) + 40;
info.frame_o = (1:6) + 50;
info.frame_f = (1:2) + 60;

info.eyelinkstart = 2;

%% Timing:
info.stimoff2rsp = 0.15;
info.rsp_win = 3;
info.feedbackdur = 0.2;
info.intertrial_gap = 1;

% motor loc:
info.motor_loc_cue_dur = 0.3;
info.motor_loc_delay = 1;
info.motor_loc_dl = 3;
info.motor_rest_postrsp = 0.5;

info.sensory_loc_gabordur = 0.35;
info.sensory_loc_rspdl = 0.7;
info.sensory_loc_timeout = 0.5;

info.frame_sensorydur = 1;
info.framing_rspdl = 3;
info.frame_dur = 0.3;
info.frame_decision_delay = 2.5;

