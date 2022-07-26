function [sys,x0,str,ts] = ANFISMPC(t,x,u,flag)

% ״̬��=[y_dot,x_dot,phi,phi_dot,Y,X]��������Ϊǰ��ƫ��delta_f


switch flag,
 case 0
  [sys,x0,str,ts] = mdlInitializeSizes; % Initialization
  
 case 2
  sys = mdlUpdates(t,x,u); % Update discrete states
  
 case 3
  sys = mdlOutputs(t,x,u); % Calculate outputs
 
%  case 4
%   sys = mdlGetTimeOfNextVarHit(t,x,u); % Get next sample time 

 case {1,4,9} % Unused flags
  sys = [];
  
 otherwise
  error(['unhandled flag = ',num2str(flag)]); % Error handling
end
% End of dsfunc.

%==============================================================
% Initialization
%==============================================================

function [sys,x0,str,ts] = mdlInitializeSizes

% Call simsizes for a sizes structure, fill it in, and convert it 
% to a sizes array.

sizes = simsizes;
sizes.NumContStates  = 0;
sizes.NumDiscStates  = 6;
sizes.NumOutputs     = 1;
sizes.NumInputs      = 6;
sizes.DirFeedthrough = 1; % Matrix D is non-empty.
sizes.NumSampleTimes = 1;
sys = simsizes(sizes); 
x0 =[0.001;0.0001;0.0001;0.00001;0.00001;0.00001];    
global U;
U=[0];%��������ʼ��,���������һ�������켣����������ȥ����UΪһά��
% global x;
% x = zeros(md.ne + md.pye + md.me + md.Hu*md.me,1);   
% Initialize the discrete states.
str = [];             % Set str to an empty matrix.
ts  = [0.1 0];       % sample time: [period, offset]
%End of mdlInitializeSizes
		      
%==============================================================
% Update the discrete states
%==============================================================
function sys = mdlUpdates(t,x,u)
  
sys = x;
%End of mdlUpdate.

%==============================================================
% Calculate outputs
%==============================================================
function sys = mdlOutputs(t,x,u)
    load result1.mat out_fis1 out_fis2 out_fis3 out_fis4
    global a b; 
    %global u_piao;
    global U;
    %global kesi;
    tic
    Nx=6;%״̬���ĸ���
    Nu=1;%�������ĸ���
    Ny=2;%������ĸ���
    Np =20;%Ԥ�ⲽ��
    Nc=10;%���Ʋ���
    Row=1000;%�ɳ�����Ȩ��
    fprintf('Update start, t=%6.3f\n',t)
   
    phi=2*asin(u(3)); %����
    y_dot=u(1)*cos(phi)-u(2)*sin(phi);
    x_dot=u(2)*cos(phi)+u(1)*sin(phi);%m/s
    
    phi_dot=u(4);
    Y=u(5);%��λΪm
    X=u(6);%��λΪ��
    
%% ������������
%syms sf sr;%�ֱ�Ϊǰ���ֵĻ�����,��Ҫ�ṩ
    Sf=0.2; Sr=0.2;
%syms lf lr;%ǰ���־��복�����ĵľ��룬�������в���
    lf=1.232;lr=1.468;
%syms C_cf C_cr C_lf C_lr;%�ֱ�Ϊǰ���ֵ��ݺ����ƫ�նȣ��������в���
    Ccf=66900;Ccr=62700;Clf=66900;Clr=62700;
%syms m g I;%mΪ����������gΪ�������ٶȣ�IΪ������Z���ת���������������в���
    m=1600;g=9.8;I=4175;
   

%% �ο��켣����
    shape=2.4;%�������ƣ����ڲο��켣����
    dx1=25;dx2=21.95;%û���κ�ʵ�����壬ֻ�ǲ�������
    dy1=54.05;dy2=5.7;%û���κ�ʵ�����壬ֻ�ǲ�������
    Xs1=27.19;Xs2=56.46;%��������
    X_predict=zeros(Np,1);%���ڱ���Ԥ��ʱ���ڵ�����λ����Ϣ�����Ǽ��������켣�Ļ���
    phi_ref=zeros(Np,1);%���ڱ���Ԥ��ʱ���ڵ������켣
    Y_ref=zeros(Np,1);%���ڱ���Ԥ��ʱ���ڵ������켣
    
    %  ���¼���kesi,��״̬�������������һ��   
    kesi=zeros(Nx+Nu,1);
    kesi(1)=y_dot;%u(1)==X(1)
    kesi(2)=x_dot;%u(2)==X(2)
    kesi(3)=phi; %u(3)==X(3)
    kesi(4)=phi_dot;
    kesi(5)=Y;
    kesi(6)=X;
    kesi(7)=U(1);
    delta_f=U(1);
    fprintf('Update start, u(1)=%4.2f\n',U(1))

    T=0.1;%���沽��
    T_all=60;%�ܵķ���ʱ�䣬��Ҫ�����Ƿ�ֹ���������켣Խ��
     
    %Ȩ�ؾ������� 
    Q_cell=cell(Np,Np);
    for i=1:1:Np;
        for j=1:1:Np;
            if i==j
                %Q_cell{i,j}=[200 0;0 100;];
                Q_cell{i,j}=[2000 0;0 10000];
            else 
                Q_cell{i,j}=zeros(Ny,Ny);               
            end
        end 
    end 
    R=5*10^4*eye(Nu*Nc);
    %R=5*10^5*eye(Nu*Nc);


    %Anifs training result, put the trained weight and consequent peremeter
    %into an matrix
    state = [y_dot,x_dot,phi,phi_dot,delta_f];
    [output1,fuzzifiedIn1,ruleOut1,aggregatedOut1,ruleFiring1] = evalfis(state,out_fis1);
    [output2,fuzzifiedIn2,ruleOut2,aggregatedOut2,ruleFiring2] = evalfis(state,out_fis2);
    [output3,fuzzifiedIn3,ruleOut3,aggregatedOut3,ruleFiring3] = evalfis(state,out_fis3);
    [output4,fuzzifiedIn4,ruleOut4,aggregatedOut4,ruleFiring4] = evalfis(state,out_fis4);
    structure = zeros(4,6);
    outfis = [out_fis1,out_fis2,out_fis3,out_fis4];
    ruleFiring = [ruleFiring1,ruleFiring2,ruleFiring3,ruleFiring4];
    
    for o = 1:length(outfis)
        array = zeros(32,6);
        rule = ruleFiring(1:32,o);
        S = sum(rule,'all');
        for i = 1:32
            c = outfis(o).output.mf;
            consequent_para = c(i).params;
            layer_four = rule(i)*consequent_para/S;
            for j = 1:6
                array(i,j) = layer_four(j);
            end
        end
        for k = 1:6
            summation = sum(array,1);
            structure(o,k) = summation(k);
        end
    end 
    
    %�����Ҳ����Ҫ�ľ����ǿ������Ļ��������ö���ѧģ�ͣ��þ����복������������أ�ͨ���Զ���ѧ��������ſ˱Ⱦ���õ�
    a=[structure(1,1), structure(1,2),structure(1,3),structure(1,4), 0, 0
       structure(2,1), structure(2,2),structure(2,3),structure(2,4), 0, 0
       structure(3,1), structure(3,2),structure(3,3),structure(3,4), 0, 0
       structure(4,1), structure(4,2),structure(4,3),structure(4,4), 0, 0
       T*cos(phi), T*sin(phi), T*(x_dot*cos(phi) - y_dot*sin(phi)), 0, 1, 0
       -T*sin(phi), T*cos(phi), -T*(y_dot*cos(phi) + x_dot*sin(phi)), 0, 0, 1];
    
    b=[structure(1,5)
       structure(2,5)
       structure(3,5)
       structure(4,5)
       0
       0]; 

    d_k=zeros(Nx,1);%����ƫ��
    state_k1=zeros(Nx,1);%Ԥ�����һʱ��״̬�������ڼ���ƫ��
    %���¼�Ϊ������ɢ������ģ��Ԥ����һʱ��״̬��
    %ע�⣬Ϊ����ǰ�����ı��ʽ��a,b�����������a,b�����ͻ����ǰ�����ı��ʽ��Ϊlf��lr
    state_k1(1,1)=y_dot+T*(-x_dot*phi_dot+2*(Ccf*(delta_f-(y_dot+lf*phi_dot)/x_dot)+Ccr*(lr*phi_dot-y_dot)/x_dot)/m);
    state_k1(2,1)=x_dot+T*(y_dot*phi_dot+2*(Clf*Sf+Clr*Sr+Ccf*delta_f*(delta_f-(y_dot+phi_dot*lf)/x_dot))/m);
    state_k1(3,1)=phi+T*phi_dot;
    state_k1(4,1)=phi_dot+T*((2*lf*Ccf*(delta_f-(y_dot+lf*phi_dot)/x_dot)-2*lr*Ccr*(lr*phi_dot-y_dot)/x_dot)/I);
    state_k1(5,1)=Y+T*(x_dot*sin(phi)+y_dot*cos(phi));
    state_k1(6,1)=X+T*(x_dot*cos(phi)-y_dot*sin(phi));
    d_k=state_k1-a*kesi(1:6,1)-b*kesi(7,1);%����falcone��ʽ��2.11b�����d(k,t)
    d_piao_k=zeros(Nx+Nu,1);%d_k��������ʽ���ο�falcone(B,4c)
    d_piao_k(1:6,1)=d_k;
    d_piao_k(7,1)=0;
    
    A_cell=cell(2,2);
    B_cell=cell(2,1);
    A_cell{1,1}=a;
    A_cell{1,2}=b;
    A_cell{2,1}=zeros(Nu,Nx);
    A_cell{2,2}=eye(Nu);
    B_cell{1,1}=b;
    B_cell{2,1}=eye(Nu);
    %A=zeros(Nu+Nx,Nu+Nx);
    A=cell2mat(A_cell);
    B=cell2mat(B_cell);
   % C=[0 0 1 0 0 0 0;0 0 0 1 0 0 0;0 0 0 0 1 0 0;];%���Ǻ���������ܹ�����
    C=[0 0 1 0 0 0 0;0 0 0 0 1 0 0;];
    PSI_cell=cell(Np,1);
    THETA_cell=cell(Np,Nc);
    GAMMA_cell=cell(Np,Np);
    PHI_cell=cell(Np,1);
    for p=1:1:Np;
        PHI_cell{p,1}=d_piao_k;%��������˵�������Ҫʵʱ���µģ�����Ϊ�˼�㣬������һ�ν���
        for q=1:1:Np;
            if q<=p;
                GAMMA_cell{p,q}=C*A^(p-q);
            else 
                GAMMA_cell{p,q}=zeros(Ny,Nx+Nu);
            end 
        end
    end
    for j=1:1:Np
     PSI_cell{j,1}=C*A^j;
        for k=1:1:Nc
            if k<=j
                THETA_cell{j,k}=C*A^(j-k)*B;
            else 
                THETA_cell{j,k}=zeros(Ny,Nu);
            end
        end
    end
    PSI=cell2mat(PSI_cell);%size(PSI)=[Ny*Np Nx+Nu]
    THETA=cell2mat(THETA_cell);%size(THETA)=[Ny*Np Nu*Nc]
    GAMMA=cell2mat(GAMMA_cell);%��д��GAMMA
    PHI=cell2mat(PHI_cell);
    Q=cell2mat(Q_cell);
    H_cell=cell(2,2);
    H_cell{1,1}=THETA'*Q*THETA+R;
    H_cell{1,2}=zeros(Nu*Nc,1);
    H_cell{2,1}=zeros(1,Nu*Nc);
    H_cell{2,2}=Row;
    H=cell2mat(H_cell);
    H=(H+H')/2;
    error_1=zeros(Ny*Np,1);
    Yita_ref_cell=cell(Np,1);
    for p=1:1:Np
        if t+p*T>T_all
            X_DOT=x_dot*cos(phi)-y_dot*sin(phi);%��������ϵ�������ٶ�
            X_predict(Np,1)=X+X_DOT*Np*T;
            %X_predict(Np,1)=X+X_dot*Np*t;
            z1=shape/dx1*(X_predict(Np,1)-Xs1)-shape/2;
            z2=shape/dx2*(X_predict(Np,1)-Xs2)-shape/2;
            Y_ref(p,1)=dy1/2*(1+tanh(z1))-dy2/2*(1+tanh(z2));
            phi_ref(p,1)=atan(dy1*(1/cosh(z1))^2*(1.2/dx1)-dy2*(1/cosh(z2))^2*(1.2/dx2));

            %Test case 2
            %Y_ref(p,1)=0.005*(X_predict(Np,1))^2;
            %phi_ref(p,1)=atan(0.01*X_predict(Np,1));

            %Test case 3
            %Y_ref(p,1)=10*(X_predict(Np,1))^0.5;
            %phi_ref(p,1)=atan(5*(X_predict(Np,1))^-0.5); 

            %Test case 4
            %Y_ref(p,1)=50*sin(0.05*X_predict(Np,1));
            %phi_ref(p,1)=atan(2.5*cos(0.05*X_predict(Np,1)));
            
            Yita_ref_cell{p,1}=[phi_ref(p,1);Y_ref(p,1)];
            
        else
            X_DOT =x_dot*cos(phi)-y_dot*sin(phi);%��������ϵ�������ٶ�
            X_predict(p,1)=X+X_DOT*p*T;%���ȼ����δ��X��λ�ã�X(t)=X+X_dot*t
            z1=shape/dx1*(X_predict(p,1)-Xs1)-shape/2;
            z2=shape/dx2*(X_predict(p,1)-Xs2)-shape/2;
            Y_ref(p,1)=dy1/2*(1+tanh(z1))-dy2/2*(1+tanh(z2));
            phi_ref(p,1)=atan(dy1*(1/cosh(z1))^2*(1.2/dx1)-dy2*(1/cosh(z2))^2*(1.2/dx2));
            
            %Test case 2
            %Y_ref(p,1)=0.005*(X_predict(p,1))^2;
            %phi_ref(p,1)=atan(0.01*X_predict(p,1));

            %Test case 3
            %Y_ref(p,1)=10*(X_predict(p,1))^0.5;
            %phi_ref(p,1)=atan(5*(X_predict(p,1))^-0.5);     

            %Test case 4
            %Y_ref(p,1)=50*sin(0.05*X_predict(p,1));
            %phi_ref(p,1)=atan(2.5*cos(0.05*X_predict(p,1)));

            Yita_ref_cell{p,1}=[phi_ref(p,1);Y_ref(p,1)];

        end
    end
    Yita_ref=cell2mat(Yita_ref_cell);
    error_1=Yita_ref-PSI*kesi-GAMMA*PHI; %��ƫ��
    f_cell=cell(1,2);
    f_cell{1,1}=2*error_1'*Q*THETA; %see matlab ���ι滮����
    f_cell{1,2}=0;
%     f=(cell2mat(f_cell))';
    f=-cell2mat(f_cell);
    
 %% ����ΪԼ����������
 %������Լ��
    A_t=zeros(Nc,Nc);%��falcone���� P181
    for p=1:1:Nc
        for q=1:1:Nc
            if q<=p 
                A_t(p,q)=1;
            else 
                A_t(p,q)=0;
            end
        end 
    end 
    A_I=kron(A_t,eye(Nu));%������ڿ˻�
    Ut=kron(ones(Nc,1),U(1));
    umin=-0.6108;%ά������Ʊ����ĸ�����ͬ
    umax=0.6108;
    delta_umin=-0.05;
    delta_umax=0.05;
    Umin=kron(ones(Nc,1),umin);
    Umax=kron(ones(Nc,1),umax);
    
    %�����Լ��
    ycmax=[1.6;2000];
    ycmin=[-1.6;-400];
    Ycmax=kron(ones(Np,1),ycmax);
    Ycmin=kron(ones(Np,1),ycmin);
    
    %��Ͽ�����Լ���������Լ��
    A_cons_cell={A_I zeros(Nu*Nc,1);-A_I zeros(Nu*Nc,1);THETA zeros(Ny*Np,1);-THETA zeros(Ny*Np,1)};
    b_cons_cell={Umax-Ut;-Umin+Ut;Ycmax-PSI*kesi-GAMMA*PHI;-Ycmin+PSI*kesi+GAMMA*PHI};
    A_cons=cell2mat(A_cons_cell);%����ⷽ�̣�״̬������ʽԼ���������ת��Ϊ����ֵ��ȡֵ��Χ
    b_cons=cell2mat(b_cons_cell);%����ⷽ�̣�״̬������ʽԼ����ȡֵ
    
    %״̬��Լ��
    M=10; 
    delta_Umin=kron(ones(Nc,1),delta_umin);
    delta_Umax=kron(ones(Nc,1),delta_umax);
    lb=[delta_Umin;0];%����ⷽ�̣�״̬���½磬��������ʱ���ڿ����������ɳ�����
    ub=[delta_Umax;M];%����ⷽ�̣�״̬���Ͻ磬��������ʱ���ڿ����������ɳ�����
    
    %% ��ʼ������
       options = optimset('Algorithm','active-set');
       x_start=zeros(Nc+1,1);%����һ����ʼ��
      [X,fval,exitflag]=quadprog(H,f,A_cons,b_cons,[],[],lb,ub,x_start,options);
      fprintf('exitflag=%d\n',exitflag);
      fprintf('H=%4.2f\n',H(1,1));
      fprintf('f=%4.2f\n',f(1,1));
    %% �������
    u_piao=X(1);%�õ���������
    U(1)=kesi(7,1)+u_piao;%��ǰʱ�̵Ŀ�����Ϊ��һ��ʱ�̿���+��������
   %U(2)=Yita_ref(2);%���dphi_ref
    sys= U;
    toc
% End of mdlOutputs.


