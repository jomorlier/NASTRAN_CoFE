% define node locations
function obj = element(obj,FEM)

% find GRIDs
h1 = find(FEM.gnum==obj.G1);
if size(h1,2)~=1; error(['There should be one and only one GRID with ID#',num2str(obj.G1),'']); end
h2 = find(FEM.gnum==obj.G2);
if size(h2,2)~=1,error(['There should be one and only one GRID with ID#',num2str(obj.G2),'']); end
h3 = find(FEM.gnum==obj.G3);
if size(h3,2)~=1,error(['There should be one and only one GRID with ID#',num2str(obj.G3),'']); end
h4 = find(FEM.gnum==obj.G4);
if size(h4,2)~=1,error(['There should be one and only one GRID with ID#',num2str(obj.G4),'']); end

% global dof
obj.gdof = [FEM.gnum2gdof(1:3,h1);
            FEM.gnum2gdof(1:3,h2);
            FEM.gnum2gdof(1:3,h3);
            FEM.gnum2gdof(1:3,h4)];

% nodal locations
obj.x1 = [FEM.GRID(h1).X1;FEM.GRID(h1).X2;FEM.GRID(h1).X3];
obj.x2 = [FEM.GRID(h2).X1;FEM.GRID(h2).X2;FEM.GRID(h2).X3];
obj.x3 = [FEM.GRID(h3).X1;FEM.GRID(h3).X2;FEM.GRID(h3).X3];
obj.x4 = [FEM.GRID(h4).X1;FEM.GRID(h4).X2;FEM.GRID(h4).X3];

% nodal unit normals
j1=@(xi,eta) [obj.x1,obj.x2,obj.x3,obj.x4]*...
    [obj.dNdxi(1,xi,eta);
     obj.dNdxi(2,xi,eta);
     obj.dNdxi(3,xi,eta);
     obj.dNdxi(4,xi,eta)]; % tanget vector
 
j2=@(xi,eta) [obj.x1,obj.x2,obj.x3,obj.x4]*...
    [obj.dNdeta(1,xi,eta);
     obj.dNdeta(2,xi,eta);
     obj.dNdeta(3,xi,eta);
     obj.dNdeta(4,xi,eta)]; % tanget vector

obj.n1 = cross3(j1(-1,-1),j2(-1,-1)); obj.n1 = obj.n1./norm_cs(obj.n1);
obj.n2 = cross3(j1( 1,-1),j2( 1,-1)); obj.n2 = obj.n2./norm_cs(obj.n2); 
obj.n3 = cross3(j1( 1, 1),j2( 1, 1)); obj.n3 = obj.n3./norm_cs(obj.n3); 
obj.n4 = cross3(j1(-1, 1),j2(-1, 1)); obj.n4 = obj.n4./norm_cs(obj.n4);

% element y direction
v13 = obj.x3 - obj.x1;
v24 = obj.x4 - obj.x2;
ye = norm(v24)*v13+norm(v13)*v24;
obj.ye = ye./norm(ye);

% find property
pidH = [FEM.PSHELL.PID]==obj.PID;
if sum(pidH)~=1; error(['There should be one and only one PROD with ID#',num2str(obj.PID),'']); end

% find MAT1
mat1H = [FEM.MAT1.MID]==FEM.PSHELL(pidH).MID1;
if sum(mat1H)~=1; error(['There should be one and only one MAT1 with ID#',num2str(FEM.PSHELL(pidH).MID1),'']); end

% stress-strain matrix
obj.G = FEM.MAT1(mat1H).stress_strain_mat;
rho = FEM.MAT1(mat1H).RHO;

% thinkness - assumed constant for alpha testing
t = FEM.PSHELL(pidH).T;

%% element integration
ke = zeros(12);
me = zeros(4);

% normal terms - ASTROS QUAD4 will need to integrate through thickness for bending
for i = 1:2
    for j = 1:2
        [kp,mp] = ele_p(obj,i,j);
        ke = ke + kp;
        me = me + mp;
    end
end
obj.ke = t*ke;
obj.me = zeros(12);
obj.me([1,2,7,8],[1,2,7,8]) = rho*t*me;


% keyboard
% % %% compare to bliq for planer
% kbliq = bliqmix( [obj.x1(1:2),obj.x2(1:2),obj.x3(1:2),obj.x4(1:2)]', t, obj.G );
% obj.ke([1,2,4,5,7,8,10,11],[1,2,4,5,7,8,10,11])
% kbliq
% (obj.ke([1,2,4,5,7,8,10,11],[1,2,4,5,7,8,10,11])-kbliq)./kbliq
end

%% cheaper 3x3 Cross product
function p = cross3(u,v)
    p = [u(2)*v(3); u(3)*v(1); u(1)*v(2)]-[u(3)*v(2); u(1)*v(3); u(2)*v(1)];
end
%% complex step friendly norm
function p = norm_cs(v)
    p = sqrt(v(1).^2+v(2).^2+v(3).^2);
end