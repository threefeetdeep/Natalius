; Read the four user button and light the corresponding LEDs.
; The switch registers are read by reading any memory address
; The switch registers are cleared by writing to memory address 0x80
; The LEDs are written to from IO mapped memory at any address 0x00 to 0x0F
; Every 2 seconds, the button register is cleared, which clears the LEDs also.
; (There is no RAM in this project)

start		csr delay_2s
			ldm r5,0	; read button registers (IO read from any address)
			stm r5,0    ; write to LEDs (IO write to e.g. 0x00)
			stm r5, 128	; clear button registers (IO write to 0x80)
			jmp start	; and do this forever and ever, amen.
delay_16ms	ldi r1,0	; r1 is incremented in the inner loop
			ldi r2,0	; r2 in incremented in the outer loop
			ldi r3,255	; both r1 and r2 are compared to r3
outer		cmp r1,r3	
			jpz done	; delay done, about 16ms (VGA VS)
inner		cmp r2,r3	; ~60us for 255 r2 increments
			jpz reinit  ; reset inner loop
			adi r2,1
			jmp inner
reinit		adi r1,1
			ldi r2,0
			jmp outer
done		ret
delay_2s	ldi r4,254   ; 256 - 122 = 134 loops for 2 seconds
;delay_2s	ldr r4,7 
inc_r4		adi r4,1    ; increment r4
			jpz done
			csr delay_16ms
			jmp inc_r4

			
			


