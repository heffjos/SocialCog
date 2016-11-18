% Clear the workspace and the Screen
sca;
close all;
clearvars;
clear all;

if isunix
    InScan = -1;
    StartRun = -1;
    EndRun = -1;
    Testing = -1;

    while ~any(InScan == [1 0])
        InScan = input('Scan? (1:Yes, 0:No): ');
    end

    Participant = input('Participant ID: ', 's');

    while ~any(StartRun == [1 2])
        StartRun = input('Start run: 1 - 2: ');
    end

    while ~any(EndRun == [1 2])
        EndRun = input('End run: 1 - 2: ');
    end

    while ~any(Testing == [1 0])
        Testing = input('Testing? (1:Yes, 0:No: ');
    end
else
    Responses = inputdlg({'Scan (1:Yes, 0:No):', ...
        'Participant ID:', 'Start run: 1 - 2:', 'End run: 1 - 2:'});
    InScan = str2num(Responses{1});
    Participant = Responses{2};
    StartRun = str2num(Responses{3});
    EndRun = str2num(Responses{4});
    Testing = 0;
end

if InScan == 0
    PsychDebugWindowConfiguration
end

OutDir = fullfile(pwd, 'Responses', Participant);
mkdir(OutDir);

% read in design
if Testing
    DesignFid = fopen('TestOrder.csv', 'r');
else
    DesignFid = foepn('Design.csv', 'r');
end
Tmp = textscan(DesignFid, '%f%f%f%f%s%f%s%s%s%s%s%s%s', 'Delimiter', ',', 'Headerlines', 1);
fclose(DesignFid);
% more columns: FaceOnset,FaceResponse,FaceRT,ContextOnset
Design = cell(numel(Tmp{1}), numel(Tmp) + 4);
for i = 1:numel(Tmp)
    for k = 1:numel(Tmp{1})
        if iscell(Tmp{i})
            Design{k, i} = Tmp{i}{k};
        else
            Design{k, i} = Tmp{i}(k);
        end
    end
end
clear Tmp

% assign constants
RUN = 1;
BLOCK = 2;
TRIAL = 3;
BLOCKSPLIT = 4;
CONDITION = 5;
FACENUM = 6;
FACEGENDER = 7;
FACEEXPRESSION = 8;
FACEFILENAME = 9;
FACERACE = 10;
CONTEXTCATEGORY = 11;
CONTEXTSUBCATEGORY = 12;
CONTEXTFILENAME = 13;
FACEONSET = 14;
FACERESPONSE = 15;
FACERT = 16;
CONTEXTONSET = 17;

PsychDefaultSetup(2); % default settings
Screen('Preference', 'VisualDebugLevel', 1); % skip introduction Screen
Screens = Screen('Screens'); % get scren number
ScreenNumber = max(Screens);

% Define black and white
White = [255 255 255];
Black = [0 0 0];
Grey = White * 0.5;

% we want X = Left-Right, Y = top-bottom
[Window, Rect] = Screen('OpenWindow', ScreenNumber, Grey); % open Window on Screen
PriorityLevel = MaxPriority(Window);
Priority(PriorityLevel);
[ScreenXpixels, ScreenYpixels] = Screen('WindowSize', Window); % get Window size
[XCenter, YCenter] = RectCenter(Rect); % get the center of the coordinate Window

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', Window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% set up keyboard
KbName('UnifyKeyNames');
DeviceIndex = [];
KbNames = KbName('KeyNames');
% KeyNamesOfInterest = {'1!', '2@', '3#', '4$', '5%', ...
%     '6^', '7&', '8*', '9(', '0)', ...
%     '1', '2', '3', '4', '5', ...
%     '6', '7', '8', '9', '0'};
KeyNamesOfInterest = { '1', '2', '3', '4', '5', ...
    '6', '7', '8', '9', '0'};
KeysOfInterest = zeros(1, 256);
for i = 1:numel(KeyNamesOfInterest)
    KeysOfInterest(KbName(KeyNamesOfInterest{i})) = 1;
end
KbQueueCreate(DeviceIndex, KeysOfInterest);

% set default text type for window
Screen('TextFont', Window, 'Arial');
Screen('TextSize', Window, 50);
Screen('TextColor', Window, White);

% run the experiment
for i = StartRun:EndRun
    RunIdx = [Design{:, RUN}]' == i;
    RunDesign = Design(RunIdx, :);
    KbEventFlush;

    % handle file naming
    OutName = sprintf('%s_Run_%02d_%s', Participant, i, ...
        datestr(now, 'yyyymmdd_HHMMSS'));
    OutCsv = fullfile(OutDir, [OutName '.csv']);
    OutMat = fullfile(OutDir, [OutName '.mat']);

    % wait for trigger '^'
    DrawFormattedText(Window, '+', 'center', 'center');
    Screen('Flip', Window);
    FlushEvents;
    ListenChar;
    while 1
        if CharAvail && GetChar == '^'
            break;
        end
    end

    BeginTime = GetSecs;

    % show direction screen until participant presses 1
    DrawFormattedText(Window, ... 
        'These are the task directions.\n\n Press ''1'' to continue.', ...
        'center', 'center');
    Screen('Flip', Window);
    while 1
        if CharAvail && GetChar == '1'
            ListenChar(0);
            break;
        end
    end
    
    for k = 1:size(RunDesign, 1)
        Picture = fullfile(pwd, 'Faces', RunDesign{k, FACEGENDER}, ...
            RunDesign{k, FACEFILENAME});
        Context = fullfile(pwd, 'Contextual', RunDesign{k, CONTEXTCATEGORY}, ...
            RunDesign{k, CONTEXTSUBCATEGORY}, RunDesign{k, CONTEXTFILENAME});
        ImContext = imread(Context, 'jpg');
        ImPicture = imread(Picture, 'png');

        [PictureY, PictureX] = size(ImPicture);
        ImBotLoc = floor(PictureY/2) + YCenter;
        ImTopLoc = YCenter - ceil(PictureY/2);
        ImRightLoc = floor(PictureX/2) + XCenter;
        ImLeftLoc = XCenter - ceil(PictureX/2);
        FromXBar = ImLeftLoc - 90;
        FromYBar = ImBotLoc + 15;
        ToXBar = ImRightLoc + 90;
        ToYBar = FromYBar;

        Tex = Screen('MakeTexture', Window, ImContext);
        Screen('DrawTexture', Window, Tex, [], [], 0);
        [~, ContextOnset] = Screen('Flip', Window);
        Screen('Close', Tex);
        RunDesign{k, CONTEXTONSET} = ContextOnset - BeginTime;
        WaitSecs(2);

        Tex = Screen('MakeTexture', Window, ImPicture);
        Screen('DrawTexture', Window, Tex, [], [], 0);
        [~, CondOnset] = Screen('Flip', Window);
        RunDesign{k, FACEONSET} = CondOnset - BeginTime;
        WaitSecs(1);

        Screen('DrawTexture', Window, Tex, [], [], 0);
        Screen('FillRect', Window, [0 0 255/2], ...
            [FromXBar FromYBar ToXBar (ToYBar + 15)]);
        Screen('DrawText', Window, 'Negative', FromXBar - 203, FromYBar - 15); 
        Screen('DrawText', Window, 'Positive', ToXBar + 3, FromYBar - 15); 
        [~, BarOnset] = Screen('Flip', Window);
        Screen('Close', Tex);
        KbQueueStart(DeviceIndex);
        NoResponse = 1;
        while GetSecs - BarOnset < 4
            if NoResponse
                [Pressed, FirstPress] = KbQueueCheck(DeviceIndex);
                if Pressed
                    FirstPress(FirstPress == 0) = nan;
                    [RT, Idx] = min(FirstPress);
                    RunDesign{k, FACERESPONSE} = KbNames{Idx};
                    RunDesign{k, FACERT} = RT - BarOnset;
                    NoResponse = 0;
                    fprintf(1, 'Trial: %d, RT: %0.4f, Response: %s\n', ...
                        k, RunDesign{k, FACERT}, RunDesign{k, FACERESPONSE});
                    KbQueueStop(DeviceIndex);
                    KbQueueFlush(DeviceIndex);
                end
            end
        end

        if NoResponse
            fprintf(1, 'Trial: %d, RT:  nan, Response: nan\n', k);
            RunDesign{k, FACERESPONSE} = nan;
            RunDesign{k, FACERT} = nan;
        end
    end

    % now write out run design
    save(OutMat, 'RunDesign');
    OutFid = fopen(OutCsv, 'w');
    fprintf(OutFid, ...
        ['Participant,', ...
        'Run,', ...
        'BlockNum,', ...
        'TrialNum,', ...
        'BlockSplit,', ...
        'Condition,', ...
        'FaceNum,', ...
        'FaceGender,', ...
        'FaceExpression,', ...
        'FaceFileName,', ...
        'FaceRace,', ...
        'ContextCategory,', ...
        'ContextSubCategory,', ...
        'ContextFileName,', ...
        'FaceOnset,', ...
        'FaceResponse,', ...
        'FaceRt,', ...
        'ContextOnset\n']);
    for DesignIdx = 1:size(RunDesign, 1)
        fprintf(OutFid, '%s,', Participant);
        fprintf(OutFid, '%d,', i);
        fprintf(OutFid, '%d,', RunDesign{DesignIdx, BLOCK});
        fprintf(OutFid, '%d,', RunDesign{DesignIdx, TRIAL});
        fprintf(OutFid, '%d,', RunDesign{DesignIdx, BLOCKSPLIT});
        fprintf(OutFid, '%s,', RunDesign{DesignIdx, CONDITION});
        fprintf(OutFid, '%d,', RunDesign{DesignIdx, FACENUM});
        fprintf(OutFid, '%s,', RunDesign{DesignIdx, FACEGENDER});
        fprintf(OutFid, '%s,', RunDesign{DesignIdx, FACEEXPRESSION});
        fprintf(OutFid, '%s,', RunDesign{DesignIdx, FACEFILENAME});
        fprintf(OutFid, '%s,', RunDesign{DesignIdx, FACERACE});
        fprintf(OutFid, '%s,', RunDesign{DesignIdx, CONTEXTCATEGORY});
        fprintf(OutFid, '%s,', RunDesign{DesignIdx, CONTEXTSUBCATEGORY});
        fprintf(OutFid, '%s,', RunDesign{DesignIdx, CONTEXTFILENAME});
        fprintf(OutFid, '%0.4f,', RunDesign{DesignIdx, FACEONSET});
        fprintf(OutFid, 's,', RunDesign{DesignIdx, FACERESPONSE});
        fprintf(OutFid, '%0.4f,', RunDesign{DesignIdx, FACERT});
        fprintf(OutFid, '%0.4f\n', RunDesign{DesignIdx, CONTEXTONSET});
    end
    fclose(OutFid);
end
        
KbQueueRelease(DeviceIndex);
Screen('CloseAll');
