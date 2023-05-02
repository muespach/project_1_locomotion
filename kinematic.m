
%% Kinematic file

% In this file, we visualise the kinematic data and the gate detection 

% filter and plot the signal
% cut in gate cycle
% animation of the movement
% plot the gate cycle

%% Loading the data

close all;

%dataset sain 
%data_healthy=load("Healthy dataset (CHUV recording - 03.03.2023)-20230310/3_AML01_1kmh.mat");

% dataset SCI Human
data_SCI=load("SCI Human/DM002_TDM_08_1kmh.mat");

%% Plot the movement

% animation : decomment the one you want (healthy, SCI)

%test range

%if you want all the data
%N = length(data_healthy.data.LHIP(:,1));

%if you want just one gait
start = 100; %this values come from the gate detection, we decided to plot one gait randomly
stop = 1000;

T = 1/100;
dec = 1000/3600*T*1000; %change here the velocity

%visualisation 2 limb
double_dec = 1000;
%double_dec = 0;


%filter the data (here toe) and gate calculation
%S_L = filtering(data_healthy.data.LTOE(:,2));
%time_L = gate(S_L);

%plot the gate cycle
plot_gate(data_SCI.data,start,stop,'B',1,dec,double_dec)

%animate the data for comparison with visualisation

%animate(data_healthy.data, start, stop,dec) 
%animate(data_SCI.data)

%% function

% filtering : take a signal (ex the y value for a marker) and return a
% clean signa
function [S_f] = filtering(S)

    %low, high pass filter
    d1 = designfilt("lowpassiir",FilterOrder=2, HalfPowerFrequency=0.03,DesignMethod="butter");
    S_f = filtfilt(d1,S);
end
    
% gate : take a signal and calculate the gate cycle (using the gradient)
% time take the value foot off and foot strike at the correct timing
function time = gate(S) 

    % calculate the gradient
    G = gradient(S);
    
    %initialisation
    time = {''};

    % calculate the position
    for i = 2:length(G)
        if sign(G(i)) ~= sign(G(i-1)) % if change sign, pass 0
            if sign(G(i)) > 0
                time = [time,"foot strike"]; 
            else
                time = [time,"foot off"];
            end
        else
            time = [time,""];
        end
    end

end

% cut_gate : cut the date in gate cycle (using a gradient)
% each value represent a foot strike
% data is the dataset
% gate is a array of position 
function Gate = cut_gate(data) 

    %filtering
     S_L = filtering(data.LTOE(:,2));
     S_R = filtering(data.RTOE(:,2));

%     filtering
%     S_L = data.LTOE(:,2);
%     S_R = data.RTOE(:,2);

    % calculate the gradient
    Gl = gradient(S_L);
    Gr = gradient(S_R);

    %initialisation
    Gate = [];
    gate = [];
    
    on_gate = false;

    % calculate the position
    i = 1;
    while i <=(length(Gl)-1)
        i = i+1;
        if sign(Gl(i)) ~= sign(Gl(i-1)) && sign(Gl(i)) < 0 
            
            if isfield(gate,'strikeR')
                gate.offnext = i;
                Gate = [Gate,gate];
            end

            on_gate = true;
            gate = [];
            gate.offL = i;

            while on_gate && i <=(length(Gl)-1)
                i = i+1;
                if sign(Gl(i-1)) ~= sign(Gl(i)) && sign(Gl(i)) > 0 && isfield(gate,'offL')
                    gate.strikeL = i;
                elseif sign(Gr(i-1)) ~= sign(Gr(i)) && sign(Gr(i)) < 0 && isfield(gate,'strikeL')
                    gate.offR = i;
                elseif sign(Gr(i-1)) ~= sign(Gr(i)) && sign(Gr(i)) > 0 && isfield(gate,'offR')
                    gate.strikeR = i;
                    on_gate = false;
                end
            end

        end
    end
end

% plot_gate : take the dataset, a starting time and ending time (ex
% start/end of a gate cycle)
% plot the gate as a line for each time 
% data is the dataset
% N1 is the start position
% N2 is the end position
% side is a string giving the limb to plot => L/R/B (left, right,both)
% frame say how much to display (if 1 all the timepoint, if 5 every 5
% delta_time for exemple)
% dec permit to introduce a decalage in the y direction. We walk on a
% treadmill so all the gate appear on the same position. If we want to
% introduce a movement in y or visualise more gate cycle we can introduce a
% decalage, like a velocity. if 0 all fixed. 
function plot_gate(data,N1,N2,side,frame, dec, double_dec)

    xlabel('x'), ylabel('y')
    title('kinematic reconstruction')

    Min = ceil(N1/frame);

    Max = ceil(N2/frame);

    Gate = cut_gate(data);

    V = 1;
    while V < length(Gate)-1 && Gate(V).offL < Min
        V = V+1;
    end

    for Val = Min:Max
        
        n = Val*frame;
        first = true;

        color_left = 'black';
        color_right = 'green';
        color_gateoff = 'red';
        color_gatestrike = 'blue';


        Lcolor = color_left;
        Rcolor = color_right;
        onevent = false;
        
        if onevent == false 
            if n == Gate(V).offL
                Lcolor = color_gateoff;
                onevent = true;
            elseif n == Gate(V).strikeL
                Lcolor = color_gatestrike;
                onevent = true;
            elseif n == Gate(V).offR
                Rcolor = color_gateoff;
                onevent = true;
            elseif n == Gate(V).strikeR
                Rcolor = color_gatestrike;
                onevent = true;
                V = V+1;
            end
        else 
            Lcolor = color_left;
            Rcolor = color_right;
            onevent = false;
        end

        if side == 'L' || side == 'B'

            plot([data.LHIP(n,2)-dec*(n-Min*frame) data.LKNE(n,2)-dec*(n-Min*frame)],[data.LHIP(n,3) data.LKNE(n,3)],Lcolor)
            if first
                hold on
                first = false;
            end
            plot([data.LKNE(n,2)-dec*(n-Min*frame) data.LANK(n,2)-dec*(n-Min*frame)],[data.LKNE(n,3) data.LANK(n,3)],Lcolor)
            plot([data.LANK(n,2)-dec*(n-Min*frame) data.LTOE(n,2)-dec*(n-Min*frame)],[data.LANK(n,3) data.LTOE(n,3)],Lcolor)
        end

        if side == 'R' || side == 'B'

            plot([data.RHIP(n,2)-dec*(n-Min*frame) data.RKNE(n,2)-dec*(n-Min*frame)],[data.RHIP(n,3)+double_dec data.RKNE(n,3)+double_dec],Rcolor)
            if first && side == 'R'
                hold on
                first = false;
            end
            plot([data.RKNE(n,2)-dec*(n-Min*frame) data.RANK(n,2)-dec*(n-Min*frame)],[data.RKNE(n,3)+double_dec data.RANK(n,3)+double_dec],Rcolor)
            plot([data.RANK(n,2)-dec*(n-Min*frame) data.RTOE(n,2)-dec*(n-Min*frame)],[data.RANK(n,3)+double_dec data.RTOE(n,3)+double_dec],Rcolor)
        end

    end

    hold off
end

% animate : plot a animation of a dataset
% the left legs is represented by full circular markers
% the left legs is represented by empty circular markers
% on the corner, a text display "foot strike/foot off" at the correct time
% the toe is use to cal
% culate the gate
% data is the dataset
function animate(data, start, stop,dec)

    %marker = ["LHIP","LKNE", "LANK","LTOE"];
    T = 1/120;

    % calculate timing left and right 
    S_L = filtering(data.LTOE(:,2));
    time_L = gate(S_L);

    S_R = filtering(data.RTOE(:,2));
    time_R = gate(S_R);


    %left plot
    hip = scatter(data.LHIP(start,2),data.LHIP(start,3),'o','MarkerFaceColor','red');
    hold on 
    knee = scatter(data.LKNE(start,2),data.LKNE(start,3),'o','MarkerFaceColor','blue');
    ankle = scatter(data.LANK(start,2),data.LANK(start,3),'o','MarkerFaceColor','magenta');
    toe = scatter(data.LTOE(start,2),data.LTOE(start,3),'o','MarkerFaceColor','green');
    

    %right plot
    hip2 = scatter(data.RHIP(start,2),data.RHIP(start,3),'o','red');
    knee2 = scatter(data.RKNE(start,2),data.RKNE(start,3),'o','blue');
    ankle2 = scatter(data.RANK(start,2),data.RANK(start,3),'o','magenta');
    toe2 = scatter(data.RTOE(start,2),data.RTOE(start,3),'o','green');

    hold off 

    axis([-1000 1000 100 1200])
    xlabel('x'), ylabel('y')
    title('kinematic reconstruction')

    %update the markers and text at each time
    for n = (start+1):stop
        move_L = text(1000,1000,"left : " + time_L(n));
        move_R = text(1000,900,"right : " + time_R(n));

        hip.XData = data.LHIP(n,2)-dec*(n-start);
        hip.YData = data.LHIP(n,3);
        knee.XData = data.LKNE(n,2)-dec*(n-start);
        knee.YData = data.LKNE(n,3);
        ankle.XData = data.LANK(n,2)-dec*(n-start);
        ankle.YData = data.LANK(n,3);
        toe.XData = data.LTOE(n,2)-dec*(n-start);
        toe.YData = data.LTOE(n,3);

        hip2.XData = data.RHIP(n,2)-dec*(n-start);
        hip2.YData = data.RHIP(n,3);
        knee2.XData = data.RKNE(n,2)-dec*(n-start);
        knee2.YData = data.RKNE(n,3);
        ankle2.XData = data.RANK(n,2)-dec*(n-start);
        ankle2.YData = data.RANK(n,3);
        toe2.XData = data.RTOE(n,2)-dec*(n-start);
        toe2.YData = data.RTOE(n,3);
        
        % give the time to see before change
        drawnow
        pause(T)

        delete(move_L)
        delete(move_R)
    end

end