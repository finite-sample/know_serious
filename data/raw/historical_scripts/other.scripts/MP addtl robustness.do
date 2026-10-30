		recode t_disp1 0/3=1 4/max=0, gen(under4)
		replace under4 = 1 if t_disp2<4 & t_disp2~=.
		replace under4 = 0 if t_disp2>=4 & t_disp2~=.
		replace under4 = 1 if t_disp3<5 & t_disp3~=.
		replace under4 = 0 if t_disp3>=5 & t_disp3~=.
		
		recode t_disp1 0/4=1 5/max=0, gen(under5)
		replace under5 = 1 if t_disp2<6 & t_disp2~=.
		replace under5 = 0 if t_disp2>=6 & t_disp2~=.
		replace under5 = 1 if t_disp3<10 & t_disp3~=.
		replace under5 = 0 if t_disp3>=10 & t_disp3~=.
		
		recode t_disp1 0/26=0 27/max=1, gen(longx)
		replace longx = 1 if t_disp2>=78 & t_disp2~=.
		replace longx = 0 if t_disp2<78 & t_disp2~=.
		replace longx = 1 if t_disp3>=90 & t_disp3~=.
		replace longx = 0 if t_disp3<90 & t_disp3~=.
		
