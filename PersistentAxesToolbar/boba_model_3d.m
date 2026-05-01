% -------- Parameters -------- %
cupHeight  = 10;
baseRadius = 2;
topRadius  = 3;
bobaSize   = 0.25;
strawRadius = bobaSize*1.05;

edgeColor     = [0.8  0.8  0.8];
cupColor      = [0.7  0.7  0.7];
strawColor    = [0.65 0.85 0.8];
baseColor     = [0.75 0.55 0.7];
lidColor      = [0.8  0.6  0.35];
bobaColor     = [0.2  0.15 0.15];

% -------- Setup -------- %
f = figure(Theme="light", Position=[100 100 600 700]);

% enable "orbit" interaction (camera interactions)
cameratoolbar(SetMode="orbit");

ax = axes(f);
hold(ax,"on")

ax.Position = [0 0.1 1 0.8];
axis(ax,"equal")
ax.XColor = "none";
ax.YColor = "none";
ax.ZColor = "none";
ax.GridColor = "#666666";

grid(ax,"on");
view(ax,135,20)

% -------- Pin axes toolbar to the figure -------- %
ax.ToolbarLocation = "container";

% -------- Cup body -------- %
theta = linspace(0, 2*pi, 40);
z = linspace(-cupHeight*0.03, cupHeight, 20);
[Theta,Z] = meshgrid(theta, z);
R = baseRadius + (topRadius-baseRadius) .* (Z/cupHeight);
X = R .* cos(Theta);
Y = R .* sin(Theta);

m = mesh(ax, X, Y, Z, ...
    EdgeColor=edgeColor, EdgeAlpha=0.4, ...
    FaceColor=cupColor, FaceAlpha=0.15);

% -------- Straw -------- %
theta = linspace(0, 2*pi, 20);
z = linspace(0, cupHeight*1.2, 30);
[Theta,Z] = meshgrid(theta, z);
R = strawRadius;
X = R .* cos(Theta);
Y = R .* sin(Theta);

surf(ax, X, Y, Z, ...
    EdgeColor="none", FaceColor=strawColor, FaceAlpha=0.7);

% -------- Cup base -------- %
base_theta = linspace(0, 2*pi, 60);
base_x = baseRadius * cos(base_theta);
base_y = baseRadius * sin(base_theta);
base_z = zeros(size(base_x));

fill3(ax, base_x, base_y, base_z, ...
    baseColor, FaceAlpha=0.5, EdgeColor=edgeColor);

% -------- Cup top -------- %
top_theta = linspace(0, 2*pi, 60);
top_x = (topRadius*1.05) * cos(top_theta);
top_y = (topRadius*1.05) * sin(top_theta);
top_z = ones(size(top_x)) * cupHeight;

fill3(ax, top_x, top_y, top_z, ...
    lidColor, FaceAlpha=0.5, EdgeColor=edgeColor);

% -------- Bubbles -------- %
[Xs,Ys,Zs] = sphere(10);
Xs = Xs * bobaSize;
Ys = Ys * bobaSize;
Zs = Zs * bobaSize;

numBobaInCup = 60;
maxBobaHeight = cupHeight * 0.8;

for i = 1:numBobaInCup
    zOffset = (1 - rand.^0.1) * (maxBobaHeight - 2*bobaSize) + bobaSize;

    rOffset = rand * ((topRadius - baseRadius) * zOffset / cupHeight ...
              + baseRadius - 3*bobaSize) + 2*bobaSize;
    thetaOffset = rand * 2*pi;
    xOffset = rOffset * cos(thetaOffset);
    yOffset = rOffset * sin(thetaOffset);

    surf(ax, Xs + xOffset, Ys + yOffset, Zs + zOffset, ...
        FaceColor=bobaColor, EdgeAlpha=0.0, FaceAlpha=0.65);
    material(ax,"dull")
end

% -------- Bubbles inside straw -------- %
numBobaInStraw = 3;
for i = 1:numBobaInStraw
    surf(ax, Xs, Ys, Zs + rand*(cupHeight - 2*bobaSize) + bobaSize, ...
        FaceColor=bobaColor, EdgeAlpha=0.0, FaceAlpha=0.65);
    material(ax,"dull")
end

% -------- Grid lines align with box -------- %
ax.XTick = [ax.XLim(1) (ax.XLim(1)+ax.XLim(2))/2 ax.XLim(2)];
ax.YTick = [ax.YLim(1) (ax.YLim(1)+ax.YLim(2))/2 ax.YLim(2)];
ax.ZTick = ax.ZLim;

% -------- Lighting -------- %
lighting(ax,"gouraud")
light(ax, Style="infinite", Position=[10 10 10])
light(ax, Style="infinite", Position=[-10 -10 10])

surfList = findall(ax, Type="Surface");  % includes mesh(), surf(), etc.
set(surfList, ...
    AmbientStrength=0.6, ...
    DiffuseStrength=0.6, ...
    SpecularStrength=0.3, ...
    SpecularExponent=5, ...
    SpecularColorReflectance=0.05);

hold(ax,"off")