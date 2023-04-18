clc
clear
close all

%% 模型参数设定
%产消者/零售商从主网购电价格 元/MW
u_Db=1e3*[0.4,0.4,0.4,0.4,0.4,0.4,0.79,0.79,0.79,1.2,1.2,1.2,1.2,1.2,0.79,0.79,0.79,1.2,1.2,1.2,0.79,0.79,0.4,0.4];
%产消者/零售商向主网售电价格 元/MW
u_Ds=1e3*[0.35,0.35,0.35,0.35,0.35,0.35,0.68,0.68,0.68,1.12,1.12,1.12,1.12,1.12,0.68,0.68,0.68,1.12,1.12,1.12,0.79,0.79,0.35,0.35];
%零售商与产消者的交易价格上下限
u_Pbmax=1e3*[0.7,0.7,0.7,0.7,0.7,0.7,1.1,1.1,1.1,1.5,1.5,1.5,1.5,1.5,1,1,1,1.5,1.5,1.5,1.1,1.1,0.7,0.7];%购价上限
u_Pbmin=u_Pbmax-0.5*1e3*ones(1,24);%购价下限
u_Psmax=u_Ds;%售价上限
u_Psmin=u_Psmax-0.35*1e3*ones(1,24);%售价下限
%产消者1-3  电负荷 MW
P_load_1=[6.62295082,5.770491803,5.442622951,5.31147541,5.37704918,5.573770492,6.295081967,6.491803279,7.213114754,7.803278689,8.131147541,8.131147541,7.93442623,7.278688525,7.016393443,7.016393443,7.147540984,8.262295082,9.442622951,9.37704918,9.37704918,7.93442623,6.819672131,5.901639344];
P_load_2=[3.344262295,3.016393443,2.754098361,2.754098361,2.754098361,2.885245902,3.147540984,3.344262295,3.639344262,3.93442623,4,4.131147541,4,3.737704918,3.475409836,3.606557377,3.606557377,4.131147541,4.721311475,4.655737705,4.721311475,4,3.409836066,3.016393443];
P_load_3=[11.60655738,10.16393443,9.442622951,9.245901639,9.114754098,9.639344262,10.75409836,11.3442623,12.45901639,13.50819672,14.10772834,14.16393443,13.63934426,12.72131148,12.19672131,12.32786885,12.59016393,14.29508197,16.59016393,16.45901639,16.26229508,13.7704918,12.13114754,10.55737705];
%产消者1-3  导入10个场景的出力和概率
Sw=10; %场景数量
load P_Gen.mat  %产消者1风电出力    P_Gen_1  维度：10*24     P_Gen_2    P_Gen_3 
%产消者1-3风电场景概率
pai_1=10*ones(1,10);pai_2=10*ones(1,10);pai_3=10*ones(1,10);
%其它固定参数
C_E=80; %储能充放成本
P_Pbmax=15; %最大购电量
P_Psmax=15; %最大售电量
Cap=10; %最大储能容量MW
P_Ecmax=3; %充放能功率上限
P_Edmax=3; %充放能功率上限
SOCmin=0.2; %最小存储量百分比 单位%
SOCmax=0.85; %最大容量百分比
SOCini=0.33; %初始容量百分比
SOCexp=0.85; %末段容量百分比
M=1E8; %大M法
beta=0.1; %厌恶风险系数
%% 决策变量初始化
delta=sdpvar(1,3);
eta_1=sdpvar(Sw,1); %产消者1的风险调度辅助变量
eta_2=sdpvar(Sw,1); %产消者2的风险调度辅助变量
eta_3=sdpvar(Sw,1); %产消者3的风险调度辅助变量
P_Ps_1=sdpvar(Sw,24); %零售商向产消者1售能量
P_Ps_2=sdpvar(Sw,24); %零售商向产消者2售能量
P_Ps_3=sdpvar(Sw,24); %零售商向产消者3售能量
P_Pb_1=sdpvar(Sw,24); %零售商从产消者1购能量
P_Pb_2=sdpvar(Sw,24); %零售商从产消者2购能量
P_Pb_3=sdpvar(Sw,24); %零售商从产消者3购能量
u_Ps=sdpvar(3,24); %零售商向产消者购能价格
u_Pb=sdpvar(3,24); %零售商从产消者购能价格
P_trading_1=sdpvar(Sw,24); %产消者1合作博弈交易量
P_trading_2=sdpvar(Sw,24); %产消者2合作博弈交易量
P_trading_3=sdpvar(Sw,24); %产消者3合作博弈交易量
SOC_1=sdpvar(Sw,24); %产消者1储能容量状态 单位%
SOC_2=sdpvar(Sw,24); %产消者2储能容量状态 单位%
SOC_3=sdpvar(Sw,24); %产消者3储能容量状态 单位%
P_Ec_1=sdpvar(Sw,24); %储能充电
P_Ec_2=sdpvar(Sw,24); %储能充电
P_Ec_3=sdpvar(Sw,24); %储能充电
P_Ed_1=sdpvar(Sw,24); %储能放电
P_Ed_2=sdpvar(Sw,24); %储能放电
P_Ed_3=sdpvar(Sw,24); %储能放电
Uabs_1=binvar(Sw,24); %储能充放电状态，0-1变量
Uabs_2=binvar(Sw,24); %储能充放电状态，0-1变量
Uabs_3=binvar(Sw,24); %储能充放电状态，0-1变量
Urelea_1=binvar(Sw,24); %储能充放电状态，0-1变量
Urelea_2=binvar(Sw,24); %储能充放电状态，0-1变量
Urelea_3=binvar(Sw,24); %储能充放电状态，0-1变量
%定义KKT条件中的拉格朗日乘子
lamda_pro_1=sdpvar(Sw,24);
lamda_pro_2=sdpvar(Sw,24);
lamda_pro_3=sdpvar(Sw,24);
lamda_trading=sdpvar(Sw,24);
lamda_Pb_1=sdpvar(Sw,24);
lamda_Pb_2=sdpvar(Sw,24);
lamda_Pb_3=sdpvar(Sw,24);
lamda_Ps_1=sdpvar(Sw,24);
lamda_Ps_2=sdpvar(Sw,24);
lamda_Ps_3=sdpvar(Sw,24);
lamda_Ec_1=sdpvar(Sw,24);
lamda_Ec_2=sdpvar(Sw,24);
lamda_Ec_3=sdpvar(Sw,24);
lamda_Ed_1=sdpvar(Sw,24);
lamda_Ed_2=sdpvar(Sw,24);
lamda_Ed_3=sdpvar(Sw,24);
lamda_SOCmin_1=sdpvar(Sw,24);
lamda_SOCmin_2=sdpvar(Sw,24);
lamda_SOCmin_3=sdpvar(Sw,24);
lamda_SOCmax_1=sdpvar(Sw,24);
lamda_SOCmax_2=sdpvar(Sw,24);
lamda_SOCmax_3=sdpvar(Sw,24);
lamda_SOC1_1=sdpvar(Sw,24);
lamda_SOC1_2=sdpvar(Sw,24);
lamda_SOC1_3=sdpvar(Sw,24);%公式17和18共用
lamda_SOC2_1=sdpvar(Sw,1);
lamda_SOC2_2=sdpvar(Sw,1);
lamda_SOC2_3=sdpvar(Sw,1);
%% 零售商/领导者的约束条件 公式2-6
u_Ps_ave=0.85*1e3;%最大平均售电价
u_Pb_ave=1.20*1e3;%最大平均购电价
C=[];
C=[ C,
    u_Pbmin<=u_Pb(1,:)<=u_Pbmax,%公式2
    u_Pbmin<=u_Pb(2,:)<=u_Pbmax,
    u_Pbmin<=u_Pb(3,:)<=u_Pbmax,
    u_Psmin<=u_Ps(1,:)<=u_Psmax,%公式3
    u_Psmin<=u_Ps(2,:)<=u_Psmax,
    u_Psmin<=u_Ps(3,:)<=u_Psmax,
    sum(u_Pb(1,:))/24<=u_Pb_ave,%公式4
    sum(u_Pb(2,:))/24<=u_Pb_ave,
    sum(u_Pb(3,:))/24<=u_Pb_ave,
    sum(u_Ps(1,:))/24<=u_Ps_ave,%公式5
    sum(u_Ps(2,:))/24<=u_Ps_ave,    
    sum(u_Ps(3,:))/24<=u_Ps_ave,
    ];
%风险调度
biliner_eq1=0;biliner_eq2=0;biliner_eq3=0;
for w=1:Sw    %计算非线性项等效
    biliner_eq1=biliner_eq1+sum(lamda_pro_1(w,:).*(P_load_1(1,:)-P_Gen_1(w,:)))+sum(lamda_Pb_1(w,:)*P_Pbmax)+sum(lamda_Ps_1(w,:)*P_Psmax)+...
                sum(lamda_Ec_1(w,:)*P_Ecmax)+sum(lamda_Ed_1(w,:)*P_Edmax)+sum(lamda_SOCmax_1(w,:)*SOCmax)+sum(lamda_SOCmin_1(w,:)*SOCmin);
    biliner_eq2=biliner_eq2+sum(lamda_pro_2(w,:).*(P_load_2(1,:)-P_Gen_2(w,:)))+sum(lamda_Pb_2(w,:)*P_Pbmax)+sum(lamda_Ps_2(w,:)*P_Psmax)+...
                sum(lamda_Ec_2(w,:)*P_Ecmax)+sum(lamda_Ed_2(w,:)*P_Edmax)+sum(lamda_SOCmax_2(w,:)*SOCmax)+sum(lamda_SOCmin_2(w,:)*SOCmin);
    biliner_eq3=biliner_eq3+sum(lamda_pro_3(w,:).*(P_load_3(1,:)-P_Gen_3(w,:)))+sum(lamda_Pb_3(w,:)*P_Pbmax)+sum(lamda_Ps_3(w,:)*P_Psmax)+...
                sum(lamda_Ec_3(w,:)*P_Ecmax)+sum(lamda_Ed_3(w,:)*P_Edmax)+sum(lamda_SOCmax_3(w,:)*SOCmax)+sum(lamda_SOCmin_3(w,:)*SOCmin);            
end
for w=1:Sw   %公式6
    C=[C,
        delta(1)-(u_Ds*P_Ps_1(w,:)'-u_Db*P_Pb_1(w,:)'+biliner_eq1)<=eta_1(w),
        delta(2)-(u_Ds*P_Ps_2(w,:)'-u_Db*P_Pb_2(w,:)'+biliner_eq2)<=eta_2(w),
        delta(3)-(u_Ds*P_Ps_3(w,:)'-u_Db*P_Pb_3(w,:)'+biliner_eq3)<=eta_3(w),
        0<=eta_1(w),
        0<=eta_2(w),
        0<=eta_3(w),
    ];
end
%% 产消者/跟随者的约束条件 公式10-19
%公式10 电功率守恒
for w=1:Sw
    C=[C,
       P_Pb_1(w,:)+P_Gen_1(w,:)+P_Ed_1(w,:)+P_trading_1(w,:)==P_Ps_1(w,:)+P_load_1(1,:)+P_Ec_1(w,:), 
       P_Pb_2(w,:)+P_Gen_2(w,:)+P_Ed_2(w,:)+P_trading_2(w,:)==P_Ps_2(w,:)+P_load_2(1,:)+P_Ec_2(w,:), 
       P_Pb_3(w,:)+P_Gen_3(w,:)+P_Ed_3(w,:)+P_trading_3(w,:)==P_Ps_3(w,:)+P_load_3(1,:)+P_Ec_3(w,:), 
       ];    
end
%公式11 总交易量守恒
P_trading_max=0;%最大交易量限制
for w=1:Sw
   for t=1:24
       C=[C,
           P_trading_1(w,t)+P_trading_2(w,t)+P_trading_3(w,t)==0,%任意时刻总交易量之和为零
           -P_trading_max<=P_trading_1(w,t)<=P_trading_max,%交易量上下限
           -P_trading_max<=P_trading_2(w,t)<=P_trading_max,
           -P_trading_max<=P_trading_3(w,t)<=P_trading_max,
           ];
   end
end
%公式12-19
C=[ C,
    0<=P_Pb_1(1:Sw,:)<=P_Pbmax,%公式12
    0<=P_Pb_2(1:Sw,:)<=P_Pbmax,
    0<=P_Pb_3(1:Sw,:)<=P_Pbmax,
    0<=P_Ps_1(1:Sw,:)<=P_Psmax,%公式13
    0<=P_Ps_2(1:Sw,:)<=P_Psmax,
    0<=P_Ps_3(1:Sw,:)<=P_Psmax,
    0<=P_Ec_1(1:Sw,:)<=P_Ecmax,%公式14
    0<=P_Ec_2(1:Sw,:)<=P_Ecmax,
    0<=P_Ec_3(1:Sw,:)<=P_Ecmax,
    0<=P_Ed_1(1:Sw,:)<=P_Edmax,%公式15
    0<=P_Ed_2(1:Sw,:)<=P_Edmax,
    0<=P_Ed_3(1:Sw,:)<=P_Edmax,
    SOCmin<=SOC_1(1:Sw,:)<=SOCmax,%公式16
    SOCmin<=SOC_2(1:Sw,:)<=SOCmax,
    SOCmin<=SOC_2(1:Sw,:)<=SOCmax,
    SOC_1(:,1)*Cap==(SOCini*Cap+(0.95*P_Ec_1(:,1)-1/1.05*P_Ed_1(:,1))),%公式17
    SOC_2(:,1)*Cap==(SOCini*Cap+(0.95*P_Ec_2(:,1)-1/1.05*P_Ed_2(:,1))),
    SOC_3(:,1)*Cap==(SOCini*Cap+(0.95*P_Ec_3(:,1)-1/1.05*P_Ed_3(:,1))),
    SOC_1(:,24)==SOCexp,%公式19
    SOC_2(:,24)==SOCexp,
    SOC_3(:,24)==SOCexp,
    ];
for t=2:24%公式18
    C=[C,
        SOC_1(:,t)*Cap==(SOC_1(:,t-1)*Cap+(0.95*P_Ec_1(:,t)-1/1.05*P_Ed_1(:,t))), %储能电站与上一时段的能量变化约束
        SOC_2(:,t)*Cap==(SOC_2(:,t-1)*Cap+(0.95*P_Ec_2(:,t)-1/1.05*P_Ed_2(:,t))),
        SOC_3(:,t)*Cap==(SOC_3(:,t-1)*Cap+(0.95*P_Ec_3(:,t)-1/1.05*P_Ed_3(:,t))),
        ];
end
for t=1:24%额外的大M法
    C=[C,
        0<=P_Ec_1(:,t)<=P_Ecmax,
        0<=P_Ec_1(:,t)<=Uabs_1(:,t)*M,
        0<=P_Ed_1(:,t)<=P_Edmax,
        0<=P_Ed_1(:,t)<=Urelea_1(:,t)*M,
        Uabs_1(:,t) + Urelea_1(:,t)<=1,   %确定充放电状态不可能同时发生
        0<=P_Ec_2(:,t)<=P_Ecmax,
        0<=P_Ec_2(:,t)<=Uabs_2(:,t)*M,
        0<=P_Ed_2(:,t)<=P_Edmax,
        0<=P_Ed_2(:,t)<=Urelea_2(:,t)*M,
        Uabs_2(:,t) + Urelea_2(:,t)<=1,   %确定充放电状态不可能同时发生
        0<=P_Ec_3(:,t)<=P_Ecmax,
        0<=P_Ec_3(:,t)<=Uabs_3(:,t)*M,
        0<=P_Ed_3(:,t)<=P_Edmax,
        0<=P_Ed_3(:,t)<=Urelea_3(:,t)*M,
        Uabs_3(:,t) + Urelea_3(:,t)<=1,   %确定充放电状态不可能同时发生
        ];
end
%% KKT条件 对偶约束  公式27-公式33
for w=1:Sw
   C=[C,
       lamda_pro_1(w,:)+lamda_Pb_1(w,:)<=u_Pb(1,:),   %公式27
       lamda_pro_2(w,:)+lamda_Pb_2(w,:)<=u_Pb(2,:), 
       lamda_pro_3(w,:)+lamda_Pb_3(w,:)<=u_Pb(3,:), 
       -lamda_pro_1(w,:)+lamda_Ps_1(w,:)<=-u_Ps(1,:), %公式28
       -lamda_pro_2(w,:)+lamda_Ps_2(w,:)<=-u_Ps(2,:), 
       -lamda_pro_3(w,:)+lamda_Ps_3(w,:)<=-u_Ps(3,:), 
       lamda_pro_1(w,:)+lamda_trading(w,:)==0,        %公式29
       lamda_pro_2(w,:)+lamda_trading(w,:)==0,
       lamda_pro_3(w,:)+lamda_trading(w,:)==0,
       -lamda_pro_1(w,:)+lamda_Ec_1(w,:)-0.95*lamda_SOC1_1(w,:)<=C_E*ones(1,24),%公式30
       -lamda_pro_2(w,:)+lamda_Ec_2(w,:)-0.95*lamda_SOC1_2(w,:)<=C_E*ones(1,24),
       -lamda_pro_3(w,:)+lamda_Ec_3(w,:)-0.95*lamda_SOC1_3(w,:)<=C_E*ones(1,24),
       lamda_pro_1(w,:)+lamda_Ed_1(w,:)+1/1.05*lamda_SOC1_1(w,:)<=C_E*ones(1,24),%公式31
       lamda_pro_2(w,:)+lamda_Ed_2(w,:)+1/1.05*lamda_SOC1_2(w,:)<=C_E*ones(1,24),
       lamda_pro_3(w,:)+lamda_Ed_3(w,:)+1/1.05*lamda_SOC1_3(w,:)<=C_E*ones(1,24),     
       lamda_SOCmax_1(w,24)+lamda_SOCmin_1(w,24)+Cap*lamda_SOC1_1(w,24)+lamda_SOC2_1(w)==0%公式33
       lamda_SOCmax_2(w,24)+lamda_SOCmin_2(w,24)+Cap*lamda_SOC1_2(w,24)+lamda_SOC2_2(w)==0%公式33
       lamda_SOCmax_3(w,24)+lamda_SOCmin_3(w,24)+Cap*lamda_SOC1_3(w,24)+lamda_SOC2_3(w)==0%公式33
     ]; 
end
for w=1:Sw
   for t=1:23
       C=[C,
           lamda_SOCmax_1(w,t)+lamda_SOCmin_1(w,t)+Cap*lamda_SOC1_1(w,t)-Cap*lamda_SOC1_1(w,t+1)==0, %公式32
           lamda_SOCmax_2(w,t)+lamda_SOCmin_2(w,t)+Cap*lamda_SOC1_2(w,t)-Cap*lamda_SOC1_2(w,t+1)==0,
           lamda_SOCmax_3(w,t)+lamda_SOCmin_3(w,t)+Cap*lamda_SOC1_3(w,t)-Cap*lamda_SOC1_3(w,t+1)==0,
         ];
   end
end
%% KKT条件 互补松弛 Big-M法处理割平面约束  公式34-公式43
%引入Big-M法所需的布尔变量
v34_1=binvar(Sw,24);%公式34的布尔变量
v34_2=binvar(Sw,24);%公式34的布尔变量
v34_3=binvar(Sw,24);%公式34的布尔变量
v35_1=binvar(Sw,24);%公式35的布尔变量
v35_2=binvar(Sw,24);%公式35的布尔变量
v35_3=binvar(Sw,24);%公式35的布尔变量
v36_1=binvar(Sw,24);v36_2=binvar(Sw,24);v36_3=binvar(Sw,24);
v37_1=binvar(Sw,24);v37_2=binvar(Sw,24);v37_3=binvar(Sw,24);
v38_1=binvar(Sw,24);v38_2=binvar(Sw,24);v38_3=binvar(Sw,24);
v39_1=binvar(Sw,24);v39_2=binvar(Sw,24);v39_3=binvar(Sw,24);
v40_1=binvar(Sw,24);v40_2=binvar(Sw,24);v40_3=binvar(Sw,24);
v41_1=binvar(Sw,24);v41_2=binvar(Sw,24);v41_3=binvar(Sw,24);
v42_1=binvar(Sw,24);v42_2=binvar(Sw,24);v42_3=binvar(Sw,24);
v43_1=binvar(Sw,24);v43_2=binvar(Sw,24);v43_3=binvar(Sw,24);
for w=1:Sw
   for t=1:24
       C=[C,
            0>=lamda_Pb_1(w,t)>=-M*v34_1(w,t),%公式34
            0>=P_Pb_1(w,t)-P_Pbmax>=-M*(1-v34_1(w,t)),
            0>=lamda_Pb_2(w,t)>=-M*v34_2(w,t),
            0>=P_Pb_2(w,t)-P_Pbmax>=-M*(1-v34_2(w,t)),
            0>=lamda_Pb_3(w,t)>=-M*v34_3(w,t),
            0>=P_Pb_3(w,t)-P_Pbmax>=-M*(1-v34_3(w,t)),            
            0>=lamda_Ps_1(w,t)>=-M*v35_1(w,t),%公式35
            0>=P_Ps_1(w,t)-P_Psmax>=-M*(1-v35_1(w,t)),
            0>=lamda_Ps_2(w,t)>=-M*v35_2(w,t),
            0>=P_Ps_2(w,t)-P_Psmax>=-M*(1-v35_2(w,t)),
            0>=lamda_Ps_3(w,t)>=-M*v35_3(w,t),
            0>=P_Ps_3(w,t)-P_Psmax>=-M*(1-v35_3(w,t)),            
            0>=lamda_Ec_1(w,t)>=-M*v36_1(w,t),%公式36
            0>=P_Ec_1(w,t)-P_Ecmax>=-M*(1-v36_1(w,t)),            
            0>=lamda_Ec_2(w,t)>=-M*v36_2(w,t),
            0>=P_Ec_2(w,t)-P_Ecmax>=-M*(1-v36_2(w,t)),              
            0>=lamda_Ec_3(w,t)>=-M*v36_3(w,t),
            0>=P_Ec_3(w,t)-P_Ecmax>=-M*(1-v36_3(w,t)),            
            0>=lamda_Ed_1(w,t)>=-M*v37_1(w,t),%公式37
            0>=P_Ed_1(w,t)-P_Edmax>=-M*(1-v37_1(w,t)),            
            0>=lamda_Ed_2(w,t)>=-M*v37_2(w,t),
            0>=P_Ed_2(w,t)-P_Edmax>=-M*(1-v37_2(w,t)),              
            0>=lamda_Ed_3(w,t)>=-M*v37_3(w,t),
            0>=P_Ed_3(w,t)-P_Edmax>=-M*(1-v37_3(w,t)),              
            0>=lamda_SOCmax_1(w,t)>=-M*v38_1(w,t),%公式38
            0>=SOC_1(w,t)-SOCmax>=-M*(1-v38_1(w,t)),    
            0>=lamda_SOCmax_2(w,t)>=-M*v38_2(w,t),
            0>=SOC_2(w,t)-SOCmax>=-M*(1-v38_2(w,t)),  
            0>=lamda_SOCmax_3(w,t)>=-M*v38_3(w,t),
            0>=SOC_3(w,t)-SOCmax>=-M*(1-v38_3(w,t)),            
            0<=lamda_SOCmin_1(w,t)<=M*v39_1(w,t),%公式39
            0<=SOC_1(w,t)-SOCmin<=M*(1-v39_1(w,t)),    
            0<=lamda_SOCmin_2(w,t)<=M*v39_2(w,t),
            0<=SOC_2(w,t)-SOCmin<=M*(1-v39_2(w,t)),  
            0<=lamda_SOCmin_3(w,t)<=M*v39_3(w,t),
            0<=SOC_3(w,t)-SOCmin<=M*(1-v39_3(w,t)),             
            0<=P_Pb_1(w,t)<=M*v40_1(w,t),%公式40
            0<=u_Pb(1,t)-lamda_pro_1(w,t)-lamda_Pb_1(w,t)<=M*(1-v40_1(w,t)),             
            0<=P_Pb_2(w,t)<=M*v40_2(w,t),
            0<=u_Pb(2,t)-lamda_pro_2(w,t)-lamda_Pb_2(w,t)<=M*(1-v40_2(w,t)),    
            0<=P_Pb_3(w,t)<=M*v40_3(w,t),
            0<=u_Pb(3,t)-lamda_pro_3(w,t)-lamda_Pb_3(w,t)<=M*(1-v40_3(w,t)),           
            0<=P_Ps_1(w,t)<=M*v41_1(w,t),%公式41
            0<=-u_Ps(1,t)+lamda_pro_1(w,t)-lamda_Ps_1(w,t)<=M*(1-v41_1(w,t)),              
            0<=P_Ps_2(w,t)<=M*v41_2(w,t),
            0<=-u_Ps(2,t)+lamda_pro_2(w,t)-lamda_Ps_2(w,t)<=M*(1-v41_2(w,t)), 
            0<=P_Ps_3(w,t)<=M*v41_3(w,t),
            0<=-u_Ps(3,t)+lamda_pro_3(w,t)-lamda_Ps_3(w,t)<=M*(1-v41_3(w,t)),             
            0<=P_Ec_1(w,t)<=M*v42_1(w,t),%公式42
            0<=C_E+lamda_pro_1(w,t)-lamda_Ec_1(w,t)+0.95*lamda_SOC1_1(w,t)<=M*(1-v42_1(w,t)),              
            0<=P_Ec_2(w,t)<=M*v42_2(w,t),
            0<=C_E+lamda_pro_2(w,t)-lamda_Ec_2(w,t)+0.95*lamda_SOC1_2(w,t)<=M*(1-v42_2(w,t)),                 
            0<=P_Ec_3(w,t)<=M*v42_3(w,t),
            0<=C_E+lamda_pro_3(w,t)-lamda_Ec_3(w,t)+0.95*lamda_SOC1_3(w,t)<=M*(1-v42_3(w,t)),              
            0<=P_Ed_1(w,t)<=M*v43_1(w,t),%公式43
            0<=C_E-lamda_pro_1(w,t)-lamda_Ed_1(w,t)-1/1.05*lamda_SOC1_1(w,t)<=M*(1-v43_1(w,t)),               
            0<=P_Ed_2(w,t)<=M*v43_2(w,t),
            0<=C_E-lamda_pro_2(w,t)-lamda_Ed_2(w,t)-1/1.05*lamda_SOC1_2(w,t)<=M*(1-v43_2(w,t)),   
            0<=P_Ed_3(w,t)<=M*v43_3(w,t),
            0<=C_E-lamda_pro_3(w,t)-lamda_Ed_3(w,t)-1/1.05*lamda_SOC1_3(w,t)<=M*(1-v43_3(w,t)),                                   
       ];
   end
end
%% 导入单层目标函数   公式26
%通过强对偶定理消去双线性项
obj_single=0;
for w=1:Sw
 obj_single=obj_single+...
   pai_1(w)*(u_Ds*P_Ps_1(w,:)'-u_Db*P_Pb_1(w,:)'-C_E*sum(P_Ec_1(w,:)+P_Ed_1(w,:))+sum(lamda_pro_1(w,:).*(P_load_1(1,:)-P_Gen_1(w,:)))+...
            sum(lamda_Pb_1(w,:)*P_Pbmax)+sum(lamda_Ps_1(w,:)*P_Psmax)+sum(lamda_Ec_1(w,:)*P_Ecmax)+sum(lamda_Ed_1(w,:)*P_Edmax)+...
            sum(lamda_SOCmax_1(w,:)*SOCmax)+sum(lamda_SOCmin_1(w,:)*SOCmin))+...
   pai_2(w)*(u_Ds*P_Ps_2(w,:)'-u_Db*P_Pb_2(w,:)'-C_E*sum(P_Ec_2(w,:)+P_Ed_2(w,:))+sum(lamda_pro_2(w,:).*(P_load_2(1,:)-P_Gen_2(w,:)))+...
            sum(lamda_Pb_2(w,:)*P_Pbmax)+sum(lamda_Ps_2(w,:)*P_Psmax)+sum(lamda_Ec_2(w,:)*P_Ecmax)+sum(lamda_Ed_2(w,:)*P_Edmax)+...
            sum(lamda_SOCmax_2(w,:)*SOCmax)+sum(lamda_SOCmin_2(w,:)*SOCmin))+...
   pai_3(w)*(u_Ds*P_Ps_3(w,:)'-u_Db*P_Pb_3(w,:)'-C_E*sum(P_Ec_3(w,:)+P_Ed_3(w,:))+sum(lamda_pro_3(w,:).*(P_load_3(1,:)-P_Gen_3(w,:)))+...
            sum(lamda_Pb_3(w,:)*P_Pbmax)+sum(lamda_Ps_3(w,:)*P_Psmax)+sum(lamda_Ec_3(w,:)*P_Ecmax)+sum(lamda_Ed_3(w,:)*P_Edmax)+...
            sum(lamda_SOCmax_3(w,:)*SOCmax)+sum(lamda_SOCmin_3(w,:)*SOCmin));
end
obj_single=obj_single+beta*(delta(1)-pai_1*eta_1/(1-0.95))+beta*(delta(2)-pai_2*eta_2/(1-0.95))+beta*(delta(3)-pai_3*eta_3/(1-0.95));%添加风险调度成本
obj_single=-obj_single;%最小化目标函数
%% 求解器相关配置
ops = sdpsettings('solver','cplex','verbose',2,'usex0',0);%cplex/gurobi
ops.cplex.mip.tolerances.mipgap = 1e-1;
%% 进行求解计算         
result = optimize(C,obj_single,ops);
if result.problem == 0 
    % problem =0 代表求解成功 
    % do nothing!
else
    error('求解出错');
end  
%% 文字输出运行结果
P_trading_1=double(P_trading_1);P_trading_2=double(P_trading_2);P_trading_3=double(P_trading_3);
%计算产消者合作成本C_trade
C_Non_1=zeros(1,10);C_Non_2=zeros(1,10);C_Non_3=zeros(1,10);
for w=1:Sw
    C_Non_1(w)=biliner_eq1+C_E*sum(P_Ec_1(w,:)+P_Ed_1(w,:));
    C_Non_2(w)=biliner_eq2+C_E*sum(P_Ec_2(w,:)+P_Ed_2(w,:));
    C_Non_3(w)=biliner_eq3+C_E*sum(P_Ec_3(w,:)+P_Ed_3(w,:));
end
save C_Non C_Non_1 C_Non_2 C_Non_3
%% 数据分析与画图
P_Ps_1=double(P_Ps_1);P_Ps_2=double(P_Ps_2);P_Ps_3=double(P_Ps_3);
P_Pb_1=double(P_Pb_1);P_Pb_2=double(P_Pb_2);P_Pb_3=double(P_Pb_3);
u_Ps=double(u_Ps);
u_Pb=double(u_Pb);
%
figure
plot(1:24,-u_Ps(1,:)','-r','LineWidth',1.5)
hold on
plot(1:24,-u_Ps(2,:)','-g','LineWidth',1.5)
hold on
plot(1:24,-u_Ps(3,:)','-b','LineWidth',1.5)
hold on
plot(1:24,-u_Psmax','--','LineWidth',1.5)
hold on
plot(1:24,-u_Psmin','--','LineWidth',1.5)
hold on
plot(1:24,u_Pb(1,:)','-r','LineWidth',1.5)
hold on
plot(1:24,u_Pb(2,:)','-g','LineWidth',1.5)
hold on
plot(1:24,u_Pb(3,:)','-b','LineWidth',1.5)
hold on
plot(1:24,u_Pbmax','--','LineWidth',1.5)
hold on
plot(1:24,u_Pbmin','--','LineWidth',1.5)
xlabel('时间/h');
ylabel('交易价格/（元/MW）');
legend('prosumer1','prosumer2','prosumer3')
title('prosumer与零售商交易价格')
