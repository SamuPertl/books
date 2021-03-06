function RetMatrix = ChaoticPendulumTRBDF(T,dt,wD,qval,gval,theta1_init,theta1dot_init,maxiters,Doplot,DoplotEig)
%
%----------------------------------------------------------------------------------- 
%Animated the damped driven pendulum system with desired parameters using the TR-BDF2 Rule
% @ Sohan Dharmaraja MIT JUN2007

%Vectors we're defining:
% timevec - times
% avec - to store the angle theta
% adotvec - to store the velocity, thetadot

%set up initial conditions
gamma = 2 - sqrt(2);
timevec(1)=0;
avec(1)=theta1_init;
adotvec(1)=theta1dot_init;
q = qval;
gprime = gval;
dt=(dt/2);
N=T/dt;
Totiters=0;

xold=[theta1_init; theta1dot_init;0];
xnew=xold;

    %define the Trapezoidal scheme

    f1=inline('iternew1 - (dt/2)*iternew2 - orig1 - (dt/2)*orig2','dt','orig1','orig2','iternew1','iternew2');
    f2=inline('iternew2 - (dt/2)*((-1/q)*iternew2 - sin(iternew1) + gprime*cos(iternew3)) - orig2 - (dt/2)*((-1/q)*orig2 - sin(orig1) + gprime*cos(orig3))','dt','orig1','orig2','orig3','iternew1','iternew2','iternew3','q','gprime');
    f3=inline('iternew3 - wD*dt - orig3','dt','wD','orig3','iternew3');

    %define the 3pt BE scheme
    f1BE=inline('iternew1 - (4/3)*orig1older +(1/3)*orig1oldest - (2*dt/3)*iternew2','dt','orig1older','orig1oldest','iternew1','iternew2');
    f2BE=inline('iternew2 - (4/3)*orig2older +(1/3)*orig2oldest - (2*dt/3)*(-(1/2)*iternew2 - sin(iternew1) + gval*cos(iternew3))','dt','orig2older','orig2oldest','iternew1','iternew2','iternew3','gval');
    f3BE=inline('iternew3 - (4/3)*orig3older +(1/3)*orig3oldest - (2*dt/3)*(2/3)','dt','orig3older','orig3oldest','iternew3');

    flagval=0;

%Let user know how far along the calculation is
h = waitbar(0,'Calculating for the TRBDF scheme... Press ENTER afterwards to start animation');

tic
if DoplotEig =='Y'
    figure;
end

PhiInit = 0;
tpos = 1;

for iter=1:2:N-1
    tpos = tpos + 1;
    waitbar(iter/(N+1))
    xoldest=xnew;
    xinit=xnew;

    % DO FIVE NEWTON ITERATIONS: this can be changed for performance, if
    % desired, but 5 does a fairly good job. Tolerance checking alone causes
    % slight slow down...
    delxvec=1;
    counter=0;


    for reptimes=1:maxiters

        Totiters=Totiters+1;
        counter=counter+1;
        a=xnew(1,1);
        c=xnew(3,1);
        
        %Fill in the Jacobian element wise - easier debugging!
        Tempmat = zeros(3,3);
        Tempmat(1,1)=1;
        Tempmat(1,2)=-(dt/(2*q));

        Tempmat(2,1)=(dt/2)*cos(a);
        Tempmat(2,2)=(1 + (dt/(2*q)));
        Tempmat(2,3)=(dt/2)*gprime*sin(c);
        
        Tempmat(3,3)=1;
        % Jcommon = 2*gamma*(eye(3) - Tempmat);

        % Compute the Jacobian to be used for the Newton iteration

        RHSvec(1,1)=f1(dt,xinit(1,1),xinit(2,1),xold(1,1),xold(2,1));
        RHSvec(2,1)=f2(dt,xinit(1,1),xinit(2,1),xinit(3,1),xold(1,1),xold(2,1),xold(3,1),q,gprime);
        RHSvec(3,1)=f3(dt,wD,xinit(3,1),xold(3,1));
        
        J = Tempmat;
        deltax=inv(J)*((-1)*RHSvec);

        if DoplotEig=='Y'
        v=eig(J);
        plot(v,'bo','MarkerEdgeColor','k','MarkerFaceColor',[0 0 0],'MarkerSize',2)
        hold on
        end

        xnew=xold+deltax;
        xold=xnew;
        delxvec(counter)=norm(deltax);
    end
    

    % =====================================================================
    % =====================================================================
    
    xolder = xnew;
    for dotimes=1:maxiters
        Totiters=Totiters+1;
        counter=counter+1;
        a=xnew(1,1);
        b=xnew(2,1);
        c=xnew(3,1);

        BETempmat=zeros(3,3);
        %Fill in the Jacobian element wise - easier debugging!
        
        BETempmat(1,1)=1;
        BETempmat(1,2)=-(2*dt/3);

        BETempmat(2,1)=(2*dt/3)*cos(a);
        BETempmat(2,2)=1+(2*dt/3)*(1/2);
        BETempmat(2,3)=(2*dt/3)*gprime*sin(c);
        BETempmat(3,3)=1;
        
        RHSvec(1,1)=f1BE(dt,xolder(1,1),xoldest(1,1),xold(1,1),xold(2,1));
        RHSvec(2,1)=f2BE(dt,xolder(2,1),xoldest(2,1),xold(1,1),xold(2,1),xold(3,1),gprime);
        RHSvec(3,1)=f3BE(dt,xolder(3,1),xoldest(3,1),xold(3,1));

        deltax=inv(BETempmat)*((-1)*RHSvec);
        %det(inv(J));
        if DoplotEig =='Y'
            v=eig(J);
            plot(v,'bo','MarkerEdgeColor','k','MarkerFaceColor',[0.1 0.8 0.1],'MarkerSize',2)
            hold on
        end

        xnew=xold+deltax;
        xold=xnew;
        delxvec(counter)=norm(deltax);

    end

    % =====================================================================
    % =====================================================================

    avec(tpos)=xnew(1,1);
    adotvec(tpos)=xnew(2,1);
    timevec(tpos)=iter*dt;    
    
end

if DoplotEig=='Y'
    
    v=[-pi:0.01:pi];
    circ=cos(v)+sqrt(-1)*sin(v);
    plot(circ)
    axis([0.7 1.3 -0.4 0.4])
    hold off
    title('Eigenvalues and the unit circle - Trapezoidal Rule')
    figure;
end

close(h)

timereq=toc;
modavec = avec;

if Doplot=='Y'
    figure;

%Draw the axes where the animation will be
i = 1; j = 1;
set(gca,'XLim',[-(i+j) (i+j)],'YLim',[-(i+j) (i+j)],'XTick',[-(i+j):(i+j)],'YTick',[-(i+j):(i+j)],'Drawmode','fast','Visible','on','NextPlot','add');

plot(0,0,'ks')
grid on
axis equal
axis manual

bob1 = line('color',[0.1 0.8 0.1],'Marker','.','markersize',35,'erase','xor','xdata',[],'ydata',[]);
rod1 = line('color',[0.4 0.4 1],'LineStyle','-','LineWidth',2.5,'erase','xor','xdata',[],'ydata',[]);

%Animate!
tic
for Curtime=0:(length(avec)-1)
    
  xbob1=i*sin(avec(Curtime+1));
  ybob1 = -i*cos(avec(Curtime+1));
  xrod1 = [0 xbob1]; yrod1 = [0 ybob1];
  
  
  set(bob1,'xdata',i*sin(avec(Curtime+1)),'ydata',-i*cos(avec(Curtime+1)))
  set(rod1,'xdata',xrod1,'ydata',yrod1)
  
    drawnow; 
    if flagval==0
      flagval=1;
      pause
    end

  pause(dt/(1))

end
toc
end

RetMatrix=[timevec',avec',adotvec'];