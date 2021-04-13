clear; clc; close all;
SubName = 'XYZ26';
gabor_triangle_rotation = 'L';
EL_flag = 0;
trigger_flag = 0;
debug = 1; % small window
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