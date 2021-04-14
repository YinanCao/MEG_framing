clear; clc; close all;

EL_flag = 0;
trigger_flag = 1;
debug = 0; % small window
practice = 0;

%---------------
% initialization:
global_variables;
%---------------

JND_quest;

% Close and clear all
Screen('CloseAll');
ShowCursor;
fclose('all');
Priority(0);
sca;
