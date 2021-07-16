; this is a simple program for the Natalius II testbench simulation.
; it exercises most instructions!
		    ldi r1,123	; load r1 with 123
		    ldi r2,0	; clear r2
		    add r2,r1   ; copy r1 to r2, so r2 should now be 123
		    stm r2,10	; put R2 at location 10 in RAM
		    nop
		    nop			; waste some time...
		    nop
		    ldm r3,10	; get the value from RAM location 10, and put in r3. i.e. r3 should be 123
		    cmp r2,r3 	; r2 and r3 should be the same, 123, so Z flag will set
		    csz test_call ; so this call should happen (stack push)
		    ldi r2, 122  
		    sub r1,r2 	; r1 = r1 - r2 = 123 - 122 = 1
		    not r1      ; r1 should now be 254
end         nop;
            jmp end ; finish in a empty nop loop
test_call   ldi r4, 85  ; 0101_0101 in binary
            ldi r5, 170 ; 1010_1010 
            ldi r6, 255 ; 1111_1111
            ldi r7, 1   ; 0000_0001
            oor r4,r5   ; r4 should be 1111_1111 = 0xFF
            and r4, r7  ; r4 should be 0000_0001 
            xor r5,r6   ; r5 should be 0101_0101 = 0x55
            ret         ; test the return from subroutine stack pop