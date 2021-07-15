		ldi r0,0	; used as zero, DO NOT CHANGE	
		csr negro	; blank the screen
		ldi r1,25	; initialise variables:
		stm r1,21	; paddle1_y = 25
		stm r1,22	; paddle2_y = 25
		ldi r1,5
		stm r1,11	; paddle1_x = 5
		ldi r1,75
		stm r1,12	; paddle2_x = 75
		stm r0,5	; p1_score = 0
		stm r0,6	; p2_score = 0
		ldi r1,1
		stm r0,8	; ball_dir_x = 1
		stm r1,9	; ball_dir_y = 1
punto	ldi r1,40	; ball position:
		stm r1,10	; ball_x = 40
		ldi r1,30
		stm r1,20	; ball_y = 30
		csr dbl		; draw paddle and balls (~50ms)
		csr dbl		; delay for players to get ready at start...
		csr dbl
		csr dbl
		csr dbl
		csr dbl
		csr dbl
		csr dbl
		csr dbl
		csr dbl
		csr dbl
		csr dbl
		csr dbl
		csr dbl		; ...let's play!
inicio	csr marca	; draw scores
		csr vermarc	; check if winner
		csr negro	; blank screen
		csr marca	; draw scores
		ldm r2,21	; paddle1_y position
		ldm r5,32	; read buttons
		ldi r6,1
		and r6,r5	; r6 = up1 button, bit0
		ldi r7,2
		and r7,r5	; r7 = down1 button, bit 1
		sr0 r7		; r7 = down1 button, bit 0
		csr moli	; update paddle1_y pos
		stm r2,21	; store new paddle1_y pos
		ldm r2,22	; get paddle2_y pos from memory
		ldm r5,32	; read buttons
		ldi r6,4	
		and r6,r5	; r6 = up2 button, bit2
		sr0 r6
		sr0 r6		; r6 = up2 button, bit0
		ldi r7,8
		and r7,r5	; r7 = down2 button, bit3
		sr0 r7
		sr0 r7
		sr0 r7		; r7 = down2 button, bit0
		csr moli	; update paddle2_y pos
		stm r2,22	; store new paddle2_y pos
		csr cobo	; check ball bounce and goal
		csr mobo	; update ball position
		ldm r1,11
		ldm r2,21
		ldi r4,7
		csr lineav	; draw paddle1
		ldm r1,12
		ldm r2,22
		ldi r4,7
		csr lineav	; draw paddle2
		csr bola
		csr delay	; one frame delay
		csr delay	; one frame delay
		csr delay	; one frame delay
		csr delay	; one frame delay
		ldi r7,1
		stm r7,128
		stm r0,128	; reset up/down button latches
		jmp inicio	; end of game loop
delay	ldi r1,0	; 16ms base delay routine
		ldi r2,0
		ldi r3,255
pat04	cmp r1,r3	
		jpz pat03	; delay done, about 16ms (VGA VS)
pat02	cmp r2,r3	; ~60us for 255 r2 increments
		jpz pat01
		adi r2,1
		jmp pat02
pat01	adi r1,1
		ldi r2,0
		jmp pat04
pat03	ret
bola	ldm r1,10	;  ball pos
		ldm r2,20
		ldi r4,7
		stm r1,32
		stm r2,64
		stm r4,96
		csr we		; latch to memvideo
		ret
mobo	ldm r1,10	; update ball position using direction offsets
		ldm r2,20
		ldm r3,8
		ldm r4,9
		ldi r5,1
		cmp r3,r5
		jpz comp12
		sub r2,r5
		jmp comp13
comp12	adi r2,1
comp13	cmp r4,r5
		jnz comp14
		adi r1,1
		jmp comp15
comp14	sub r1,r5
comp15	stm r1,10
		stm r2,20
		ret
cobo	ldm r1,10		; ball x
		ldm r2,20		; ball y
		ldi r3,78		; bottom right x
		ldi r4,58		; bottom right y
		ldi r7,2
		cmp r1,r7		; check if ball out left
		jnz comp04		; jump if ball still in
		ldm r6,6
		adi r6,1
		stm r6,6		; p2 score up one
		ldi r6,1
		stm r6,9
		jmp punto		; update scores in memvideo
comp04	cmp r1,r3		; check if ball out right
		jnz comp05		; jump if ball still in
		ldm r6,5
		adi r6,1
		stm r6,5		; p1 score up by one
		stm r0,9
		jmp punto		; update scores in memvideo
comp05	cmp r2,r7		; check ball bounce of top
		jnz comp06
		ldi r6,1
		stm r6,8		; ball y direction changed
comp06	cmp r2,r4		; check ball bounce of bottom
		jnz comp07
		stm r0,8		; ball y direction changed
comp07	ldm r3,11		; has ball hit paddle1?
		ldm r4,21
		adi r3,1
		cmp r1,r3
		jnz comp08
		cmp r2,r4
		jpz comp09
		adi r4,1
		cmp r2,r4
		jpz comp09
		adi r4,1
		cmp r2,r4
		jpz comp09
		adi r4,1
		cmp r2,r4
		jpz comp09
		adi r4,1
		cmp r2,r4
		jpz comp09
		adi r4,1
		cmp r2,r4
		jnz comp08
comp09	ldi r6,1
		stm r6,9		; ball bounce off paddle1
comp08	ldm r3,12
		ldi r6,1
		ldm r4,22
		sub r4,r6
		cmp r1,r3
		jnz comp10
		cmp r2,r4
		jpz comp11
		adi r4,1
		cmp r2,r4
		jpz comp11
		adi r4,1
		cmp r2,r4
		jpz comp11
		adi r4,1
		cmp r2,r4
		jpz comp11
		adi r4,1
		cmp r2,r4
		jpz comp11
		adi r4,1
		cmp r2,r4
		jnz comp10
comp11	stm r0,9		; ball bounce off paddle2
comp10	ret
moli	ldi r3,1		; move paddle pos routine:		
		ldi r4,55
		ldi r5,2
		cmp r6,r3		
		jnz comp03
		cmp r2,r3
		jpz finmol
		sub	r2,r5		; move paddle up two squares
comp03	cmp r7,r3
		jnz finmol
		cmp r2,r4
		jpz finmol
		add r2,r5		; move paddle down two squares
finmol	ret
marca	ldm r5,5		; P1 score...
		ldi r1,19
		ldi r2,5
		ldi r4,6
		csr impnum		; ...display it
		ldm r5,6		; P2 score...
		ldi r1,57
		ldi r2,5
		csr impnum		; ...display it
		ret
vermarc	ldm r1,5		; P1 score
		ldm r2,6
		ldi r3,9			
		cmp r1,r3
		jnz comp01
		ldm r1,12
		ldm r2,22
		ldi r4,4
		csr lineav
gana1	jmp gana1
comp01	ldi r3,9
		cmp r2,r3
		jnz comp02
		ldm r1,11
		ldm r2,21
		ldi r4,4
		csr lineav
gana2	jmp gana2		; GAME OVER!! if either player gets to 9 points
comp02	ret
lineav	ldi r3,5		
		add r3,r2		; r3 = col + 5, length of paddle
con		cmp r2,r3		; when 5 cols done
		jnc ter
		stm r2, 64		; paddle row
		stm r1, 32		; paddle col
		stm r4, 96		; paddle color
		csr we			; pulse values in to memvideo
		adi r2,1		; next row of 5
		jmp con
ter		ret
negro	ldi r7,1		; blank the screen:
		stm r7,160		; set WE high
		stm r0,96		; set COLOR = black
		ldi r1,80    	; screen width
		ldi r2,60  		; screen height
		ldi r3,0   		
		ldi r4,0   
nextc	cmp r4,r1		; screen width loop
		jpz inc_fil		; if row complete, jump
		stm r3,64		; else output ROW
		stm r4,32		; output COL
		stm r1,96		; NEW LINE output COLOR as ROW!
		adi r4,1		; move to next COL
		jmp nextc
inc_fil	ldi r4,0		
		cmp r3,r2		; screen height loop
		jpz fneg		; if screen done, jump
		adi r3,1		; else next ROW
		jmp nextc
fneg 	stm r0,160		; WE low, memvideo inactive.
		ret
we 		ldi r7,1		; pulse WE:
		stm r7,160
		ldi r7,0
		stm r7,160
		ret
dbl		csr delay		; 16ms delay
		csr delay		; 16ms delay
		csr delay		; 16ms delay
		ldm r1,11
		ldm r2,21
		ldi r4,2
		csr lineav		; draw P1 paddle
		ldm r1,12
		ldm r2,22
		ldi r4,2
		csr lineav		; draw P2 paddle
		csr bola		; draw ball
		ret
segh	ldi r3,3
		add r3,r1
pon1	cmp r1,r3
		jpz mer1
		stm r2, 64
		stm r1, 32
		stm r4, 96
		csr we
		adi r1,1
		jmp pon1
mer1	ldi r3,3
		sub r1,r3
		ret
segv	ldi r3,3
		add r3,r2
pon2	cmp r2,r3
		jpz mer2
		stm r2, 64
		stm r1, 32
		stm r4, 96
		csr we
		adi r2,1
		jmp pon2
mer2	ldi r3,3
		sub r2,r3
		ret
sega	csr segh
		ret
segb	ldi r7,2
		add r1,r7
		csr segv
		ldi r7,2
		sub r1,r7
		ret
segc	ldi r7,2
		add r1,r7
		add r2,r7
		csr segv
		ldi r7,2
		sub r1,r7
		sub r2,r7
		ret
segd	ldi r7,4
		adi r2,4
		csr segh
		ldi r7,4
		sub r2,r7
		ret
sege	ldi r7,2
		adi r2,2
		csr segv
		ldi r7,2
		sub r2,r7
		ret
segf	csr segv
		ret
segg	ldi r7,2
		adi r2,2
		csr segh
		ldi r7,2
		sub r2,r7
		ret
impnum	ldi r7,1		;
		cmp r5,r7
		jpz num01		; 1 has no segment a
		ldi r7,4
		cmp r5,r7
		jpz num01		; 4 has no segment a
		csr sega		; all others do
num01	ldi r7,5		
		cmp r5,r7
		jpz num02		; 5 has no segment b
		ldi r7,6
		cmp r5,r7
		jpz num02		; 6 has no segment b
		csr segb		; all others do	
num02	ldi r7,2		
		cmp r5,r7
		jpz num03		; 2 has no segment c
		csr segc		; all others do
num03	ldi r7,1
		cmp r5,r7		; 1 has no segment d
		jpz num04
		ldi r7,4
		cmp r5,r7
		jpz num04		; 4 has no segment d
		ldi r7,7
		cmp r5,r7
		jpz num04		; 7 has no segment d
		csr segd		; all others do
num04	ldi r7,0
		cmp r5,r7
		jpz num05		; 0 has segment e
		ldi r7,2
		cmp r5,r7
		jpz num05		; 2 has segment e
		ldi r7,6
		cmp r5,r7
		jpz num05		; 6 has segment e
		ldi r7,8
		cmp r5,r7		; 8 has segment e
		jnz num06
num05	csr sege		; no others do
num06	ldi r7,1
		cmp r5,r7
		jpz num07		; 1 has no segment f
		ldi r7,2
		cmp r5,r7
		jpz num07		; 2 has no segment f
		ldi r7,3
		cmp r5,r7
		jpz num07		; 3 has no segment f
		ldi r7,7
		cmp r5,r7
		jpz num07		; 7 has no segment f
		csr segf		; all others do
num07	ldi r7,0
		cmp r5,r7		
		jpz num08		; 0 has no segment g
		ldi r7,1
		cmp r5,r7
		jpz num08		; 1 has no segment g
		csr segg		; all others do
num08	ret