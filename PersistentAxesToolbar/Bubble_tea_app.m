% Note: manually drag or tile the two figures to see them side by side in a
% "dashboard" view

% ---------------- import data ---------------- %
bobaShops = readtimetable("bubble_tea_data.csv");
DailySteps = readtimetable("daily_steps.csv");
timelineData = retime(bobaShops(:,"Name"), 'daily',  'count');

% ---------------- setup map ---------------- %
figMap = figure(Name="Map");

% create geo axes
gx1 = geoaxes(figMap, Position=[0 0 1 1]);
gs = geoscatter(gx1, bobaShops, "Latitude", "Longitude", "filled",  ColorVariable="Rating", MarkerEdgeColor="white", Tag="mapScatter");
geolimits(gx1, [24.9 25.2],[121.4 121.6]);

% custom colormap
c1 = [0.8, 0.8, 0.8];
c2 = [0.2, 0.5, 0.75];
N = 256;
cm = [linspace(c1(1), c2(1), N).' ...
    linspace(c1(2), c2(2), N).' ...
    linspace(c1(3), c2(3), N).'];
colormap(cm);

% customize map's axes toolbar
tb = axtoolbar(gx1, "default");
tb.Expanded = "on";
gx1.ToolbarLocation = "inside";
btn = axtoolbarbtn(tb, "state", Tooltip="Add new bubble tea shop", ValueChangedFcn=@btnCallback);

% ---------------- setup figure 2 (plots) ---------------- %
figCharts = figure(Name="Data");

% create tiled layouts
tlTopLevel = tiledlayout(figCharts);
tlTimelineCharts = tiledlayout(tlTopLevel, "vertical", Padding="tight", TileSpacing="tight");

% create shared axes toolbar for 2 timeline charts
sharedToolbar = axtoolbar(tlTimelineCharts, {"pan", "zoom", "export"});

% ---------------- setup timeline chart 1 (teas per day) ---------------- %
axDailyTea = nexttile(tlTimelineCharts);
plot(timelineData, "Name", Marker='o', Tag="bobaTimeline");

ylim(axDailyTea, [0 inf]);
title(axDailyTea, "Teas per day");
axDailyTea.TitleHorizontalAlignment = "left";
xlabel ''
ylabel ''
axDailyTea.YGrid = "on";
axDailyTea.Box = "off";
xsecondarylabel(Visible="off");

% ---------------- setup timeline chart 2 (steps per day) ---------------- %
axDailySteps = nexttile(tlTimelineCharts);
plot(DailySteps, "Steps", Marker='o', Tag="stepTimeline");

ylim(axDailySteps, [0 inf]);
title(axDailySteps, "Steps per day");
xlabel ''
ylabel ''
axDailySteps.TitleHorizontalAlignment = "left";
axDailySteps.YGrid = "on";
axDailySteps.Box = "off";
ytickformat('%g k')
xsecondarylabel(Visible="off")

% ---------------- customize interactions on timeline charts ---------------- %
% link both charts in the tiledlayout so their x-limits match
linkaxes([axDailyTea axDailySteps], "x");

% only allow panning and zooming in the x direction
axDailyTea.InteractionOptions.LimitsDimensions = "x";
axDailySteps.InteractionOptions.LimitsDimensions = "x";

% ---------------- setup histogram ---------------- %
axHist = nexttile(tlTopLevel);
hist = histogram(axHist, bobaShops, "Rating", 0:0.5:5, Tag="bobaHist");
title(axHist, "How good is bubble tea in Taipei?");
axHist.YGrid = "on";
axHist.Box = "off";
axHist.TitleHorizontalAlignment = "left";

% customize available interactions and remove toolbar
axHist.Interactions = dataTipInteraction;
axHist.Toolbar = [];

% match initial theme, and listen for future theme changes
figMap.ThemeChangedFcn = @(obj, evd) swapIcon(evd.Theme, btn);
swapIcon(figMap.Theme, btn);

% ---------------- update all charts with initial data ---------------- %
updateCharts(bobaShops);



%% ========================== HELPER FUNCTIONS ========================== %
function swapIcon(newTheme, btn)
    if strcmpi(newTheme.BaseColorStyle, "light")
        btn.Icon = "tea.svg";
    else
        btn.Icon = "tea-dark.svg";
    end
end

function btnCallback(src, evd)
    gx = evd.Axes;
    f = gx.Parent;

    % temporarily disallow all interactions on the map, besides clicking to
    % add a new bubble tea shop
    disableDefaultInteractivity(gx);
    gx.ButtonDownFcn = @(~,~) addShop(gx, src);
    f.WindowButtonMotionFcn = @(src, event) setPointerWhenOverAxes(src, gx);
end

function setPointerWhenOverAxes(fig, ax)
    ax.Units = "pixels";
    axPos = ax.Position;
    mousePos = fig.CurrentPoint; % in pixels, from bottom-left

    % Check if mouse is within axes
    if mousePos(1) >= axPos(1) && mousePos(1) <= axPos(1) + axPos(3) && ...
            mousePos(2) >= axPos(2) && mousePos(2) <= axPos(2) + axPos(4)
        fig.Pointer = 'circle';
    else
        fig.Pointer = 'arrow';
    end
end

function addShop(gx, btn)
    f = gx.Parent;
    gs = gx.Children;

    coords = gx.CurrentPoint;
    lat = coords(1,1);
    lon = coords(1,2);

    % setup input dialog
    prompt = {'Shop name:', 'Rating (1-5):', 'Date visited:'};
    dlgTitle = 'New bubble tea shop';
    dims = [1 50; 1 50; 1 50]; % [rows cols] for each input field
    defaultInput = {'Chun Shui Tang', '4.0', '01/01/2026'};
    answer = inputdlg(prompt, dlgTitle, dims, defaultInput);

    if ~isempty(answer)
        % capture data from input dialog
        shopName = string(answer{1});
        rating = str2double(answer{2});
        dateVisited = datetime(answer{3}, InputFormat="MM/dd/uuuu");

        newRow = timetable(...
                dateVisited, ...
                shopName, ...
                lat, ...
                lon, ...
                rating, ...
                VariableNames=gs.SourceTable.Properties.VariableNames ...
            );

        % Add new shop to the table
        bobaShops = [gs.SourceTable; newRow];

        % Update the scatter plot
        updateCharts(bobaShops);
    else
        disp('User cancelled.');
    end
    
    % return to normal axes interactions
    f.WindowButtonMotionFcn = "";
    f.Pointer = "arrow";
    gx.ButtonDownFcn = "";
    enableDefaultInteractivity(gx);
    btn.Value = "off";
end

function updateCharts(bobaShopTable)
    timelineData = retime(bobaShopTable(:,"Name"), 'daily',  'count');

    figMap = findobj(groot, Type="figure", Name="Map");
    figPlots = findobj(groot, Type="figure", Name="Data");
    gs = findobj(figMap, Tag="mapScatter");
    hist = findobj(figPlots, Tag="bobaHist");
    bobaPlot = findobj(figPlots, Tag="bobaTimeline");
    
    % update charts with new data
    gs.SourceTable = bobaShopTable;
    hist.SourceTable = bobaShopTable;
    bobaPlot.SourceTable = timelineData;
    bobaPlot.Parent.XLimMode = "auto";

    % customize info displayed in the map's data tips
    dt = gs.DataTipTemplate;
    dt.DataTipRows = [ dataTipTextRow("Name", bobaShopTable.Name)
        dataTipTextRow("Rating", bobaShopTable.Rating)
        dataTipTextRow("Visited", bobaShopTable.DateVisited)
        ];
end