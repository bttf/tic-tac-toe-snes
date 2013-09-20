tictactoe.smc: tictactoe.asm tictactoe.link
	./wla-65816 -vo tictactoe.asm tictactoe.obj
	./wlalink -vr tictactoe.link tictactoe.smc

clean: 
	rm *.obj *.smc
