function SocialCognitionTask()

    % Clear the workspace and the Screen
    sca;
    DeviceIndex = [];

    if isunix
        InScan = -1;
        StartRun = -1;
        EndRun = -1;
        Testing = -1;
        Suppress = -1;
    
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
            Testing = input('Testing? (1:Yes, 0:No): ');
        end
    
        while ~any(Suppress == [1 0])
            Suppress = input('Suppress? (1: Yes, 0:No): ');
        end
    else
        Responses = inputdlg({'Scan (1:Yes, 0:No):', ...
            'Participant ID:', 'Start run: 1 - 2:', 'End run: 1 - 2:'});
        InScan = str2num(Responses{1});
        Participant = Responses{2};
        StartRun = str2num(Responses{3});
        EndRun = str2num(Responses{4});
        Testing = 0;
        Suppress = 1;
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
        DesignFid = fopen('Design.csv', 'r');
    end
    Tmp = textscan(DesignFid, '%f%f%f%f%s%f%s%s%s%s%s%s%s', ...
        'Delimiter', ',', 'Headerlines', 1);
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
    clear Tmp i k
    
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
    if ~Suppress
        Screen('Preference', 'SuppressAllWarnings', 1);
        Screen('Preference', 'Verbosity', 0);
    end
    Screens = Screen('Screens'); % get scren number
    ScreenNumber = max(Screens);
    
    % Define black and white
    White = [255 255 255];
    Black = [0 0 0];
    Grey = White * 0.5;
    
    % we want X = Left-Right, Y = top-bottom
    [Window, Rect] = Screen('OpenWindow', ScreenNumber, Black); % open Window on Screen
    PriorityLevel = MaxPriority(Window);
    Priority(PriorityLevel);
    [ScreenXpixels, ScreenYpixels] = Screen('WindowSize', Window); % get Window size
    [XCenter, YCenter] = RectCenter(Rect); % get the center of the coordinate Window
    Refresh = Screen('GetFlipInterval', Window);
    
    % Set up alpha-blending for smooth (anti-aliased) lines
    Screen('BlendFunction', Window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    % set up keyboard
    KbName('UnifyKeyNames');
    KbNames = KbName('KeyNames');
    KeyNamesOfInterest = {'1!', '2@', '3#', '4$', '5%', ...
        '6^', '7&', '8*', '9(', '0)', ...
        '1', '2', '3', '4', '5', ...
        '6', '7', '8', '9', '0'};
    % KeyNamesOfInterest = { '1', '2', '3', '4', '5', ...
    %     '6', '7', '8', '9', '0'};
    KeysOfInterest = zeros(1, 256);
    for i = 1:numel(KeyNamesOfInterest)
        KeysOfInterest(KbName(KeyNamesOfInterest{i})) = 1;
    end
    clear i
    KbQueueCreate(DeviceIndex, KeysOfInterest);
    
    % set default text type for window
    Screen('TextFont', Window, 'Arial');
    Screen('TextSize', Window, 50);
    Screen('TextColor', Window, White);

    % preload images and assign values for bar and text location
    PictureY = 0;
    fprintf(1, 'Preloading images. This will take some time.\n');
    for iRun = 1:2
        RunIdx = [Design{:, RUN}]' == iRun;
        RunDesign = Design(RunIdx, :);
        for iTrial = 1:size(RunDesign, 1)
            Context = fullfile(pwd, 'Contextual', RunDesign{iTrial, CONTEXTCATEGORY}, ...
                RunDesign{iTrial, CONTEXTSUBCATEGORY}, RunDesign{iTrial, CONTEXTFILENAME});
            Face = fullfile(pwd, 'Faces', RunDesign{iTrial, FACEGENDER}, ...
                RunDesign{iTrial, FACEFILENAME});

            ImContext{iRun}{iTrial} = imread(Context, 'jpg');
            ImFace{iRun}{iTrial} = imread(Face, 'png');

            if size(ImFace{iRun}{iTrial}, 1) > PictureY
                PictureY = size(ImFace{iRun}{iTrial}, 1);
            end

            TexContext{iRun}{iTrial} = Screen('MakeTexture', Window, ...
                ImContext{iRun}{iTrial});
            TexFace{iRun}{iTrial} = Screen('MakeTexture', Window, ...
                ImFace{iRun}{iTrial});
        end
    end
    clear iRun iTrial
    PictureX = 256;
    ImBotLoc = floor(PictureY/2) + YCenter;
    ImTopLoc = YCenter - ceil(PictureY/2);
    ImRightLoc = floor(PictureX/2) + XCenter;
    ImLeftLoc = XCenter - ceil(PictureX/2);
    FromXBar = ImLeftLoc - 90;
    FromYBar = ImBotLoc + 15;
    ToXBar = ImRightLoc + 90;
    ToYBar = FromYBar;

    % run the experiment
    for i = StartRun:EndRun
        RunIdx = [Design{:, RUN}]' == i;
        RunDesign = Design(RunIdx, :);

        % pre-populate RT and Response with NaN
        for k = 1:size(RunDesign)
            RunDesign{k, FACERESPONSE} = nan;
            RunDesign{k, FACERT} = nan;
        end
        clear k;

        KbEventFlush;
    
        % handle file naming
        OutName = sprintf('%s_Run_%02d_%s', Participant, i, ...
            datestr(now, 'yyyymmdd_HHMMSS'));
        OutCsv = fullfile(OutDir, [OutName '.csv']);
        OutMat = fullfile(OutDir, [OutName '.mat']);

        % show directions while waiting for trigger '^'
        DrawFormattedText(Window, ... 
            'These are the task directions.\n\n Waiting for ''^'' to continue.', ...
            'center', 'center');
        Screen('Flip', Window);
        FlushEvents;
        ListenChar;
        while 1
            if CharAvail && GetChar == '^'
                break;
            end
        end
    
        Stop = 0; 
        BeginTime = GetSecs;
        for k = 1:size(RunDesign, 1)
            % Tex = Screen('MakeTexture', Window, ImContext{i}{k});
            Screen('DrawTexture', Window, TexContext{i}{k}, [], [], 0);
            ContextVbl = Screen('Flip', Window, Stop);
            % Screen('Close', Tex);
            RunDesign{k, CONTEXTONSET} = ContextVbl - BeginTime;

            % Tex = Screen('MakeTexture', Window, ImFace{i}{k});
            Screen('DrawTexture', Window, TexFace{i}{k}, [], [], 0);
            CondVbl = Screen('Flip', Window, ContextVbl + 2 - Refresh, 1);
            RunDesign{k, FACEONSET} = CondVbl - BeginTime;

            % [PictureY, PictureX] = size(ImFace{i}{k});
            Screen('FillRect', Window, [0 0 255/2], ...
                [FromXBar FromYBar ToXBar (ToYBar + 15)]);
            Screen('DrawText', Window, 'Negative', FromXBar - 203, FromYBar - 15); 
            Screen('DrawText', Window, 'Positive', ToXBar + 3, FromYBar - 15); 
            BarVbl = Screen('Flip', Window, CondVbl + 1 - Refresh);
            % Screen('Close', Tex);

            KbQueueStart(DeviceIndex);
            Stop = BarVbl + 4 - Refresh;
            while GetSecs < Stop
                [Pressed, FirstPress] = KbQueueCheck(DeviceIndex);
                if Pressed
                    FirstPress(FirstPress == 0) = nan;
                    [RT, Idx] = min(FirstPress);
                    RunDesign{k, FACERESPONSE} = KbNames{Idx};
                    RunDesign{k, FACERT} = RT - BarVbl;
                    break;
                end
                WaitSecs(0.01);
            end
            KbQueueStop(DeviceIndex);
            KbQueueFlush(DeviceIndex);
            fprintf(1, 'Run: %d, Trial: %d, RT: %0.4f, Response: %s\n', ...
                i, k, RunDesign{k, FACERT}, RunDesign{k, FACERESPONSE});
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
    
            % handle resposne now
            Response = RunDesign{DesignIdx, FACERESPONSE};
            if ischar(Response)
                if any(strcmp(KeyNamesOfInterest(1:10), Response))
                    Response = find(strcmp(KeyNamesOfInterest(1:10), Response));
                elseif any(strcmp(KeyNamesOfInterest(11:end), Response, Response))
                    Response = find(strcmp(KeyNamesOfInterest(11:end), Response));
                else
                    Response = nan;
                end
    
                if Response == 10
                    Response = 0;
                end
            end
            fprintf(OutFid, '%d,', Response);
    
            fprintf(OutFid, '%0.4f,', RunDesign{DesignIdx, FACERT});
            fprintf(OutFid, '%0.4f\n', RunDesign{DesignIdx, CONTEXTONSET});
        end
        fclose(OutFid);
    
        fprintf(1, '\n');
    end
            
    DrawFormattedText(Window, 'Goodbye!', 'center', 'center');
    Screen('Flip', Window);
    WaitSecs(3);
    
    % close everything
    KbQueueRelease(DeviceIndex);
    sca;
    Priority(0);
end
