#!/usr/bin/python

# O. Bailey 29/08/15: Added line 150 to remove semicolon delimited comments
# from each line
# O.Bailey 13/07/2021: Converted 'print xyz' to python3 print(xyz)
# O.Bailey 15/07/2021: 
#                       added "org dddd" and "org 0xhhhh" handling of address) <<<< *** TBD to keep track of address!! ***
#                       line 121: f=open(file,'rU') changed to:  f=open(file,'r')
#                       added regex handling of comment removal
#                       added decimal integer or hex '0x...' handling of literals  <<<<< *** TBD!!! ****


import sys
import re
import time

instr_type1=['ldi','ldm','stm', 'adi']
instr_type2=['cmp','add','sub','and','oor','xor']
instr_type3=['jmp','jpz','jnz','jpc','jnc','csr', 'csz', 'cnz', 'csc', 'cnc']
instr_type4=['sl0','sl1','sr0','sr1','rrl','rrr', 'not']
instr_type5=['ret', 'nop']
directives=['.org']

tokens={}
tokens['ldi']=2
tokens['ldm']=3
tokens['stm']=4
tokens['cmp']=5
tokens['add']=6
tokens['sub']=7
tokens['and']=8
tokens['oor']=9
tokens['xor']=10
tokens['jmp']=11
tokens['jpz']=12
tokens['jnz']=13
tokens['jpc']=14
tokens['jnc']=15
tokens['csr']=16
tokens['ret']=17
tokens['adi']=18
tokens['csz']=19
tokens['cnz']=20
tokens['csc']=21
tokens['cnc']=22
tokens['sl0']=23
tokens['sl1']=24
tokens['sr0']=25
tokens['sr1']=26
tokens['rrl']=27
tokens['rrr']=28
tokens['not']=29
tokens['nop']=30
tokens['.org']=31 # address origin assembler directive, NOT a CPU opcode

def remove_comments_from_line(line_in):
    # regex for stripping out comments
    regex_rmv_comments = re.compile('[\s]?;.*?$')
    # try to remove any comments from current line
    try:
        comment_start_index = regex_rmv_comments.search(line_in).start()
        # keep only line before comment
        line = line_in[0:comment_start_index]
    except (SyntaxError, TypeError, AttributeError):
        line = line_in
    return line


def convert_address_to_integer(addr):
    try:
        if '0x' in addr:
            addr = int(addr,16)
        else:
            addr = int(addr)
        return addr
    except (TypeError,ValueError):
        print('invalid address after:' + addr)
        sys.exit(1)

def verify_args(line):
    if len(line)>1:
        line_split=line.split()
        opcode=line_split[0]
        if opcode in (instr_type1 + instr_type2 + instr_type4):
            args=re.findall(r'r(\d+)',line)
    else:
        return ('line too short: ' + line)
    if not opcode in (instr_type1 + instr_type2 + instr_type3 + instr_type4 + instr_type5 + directives):
        return ('unknown command: ' + opcode)
    else:
        if opcode in instr_type1:
            arg2=line.split(',')
            direccion=arg2[1]

            if len(args)!=1 :
                return 'incorrect number of arguments'
            else:
                if int(args[0])<0 or int(args[0])>7:
                    return 'arg1 out of range (0-7)'
                else:
                    if int(direccion)<0 or int(direccion)>255:
                        return 'addr out of range (0-255)'
                    else:
                        return 'ok'

        if opcode in instr_type2:
            if len(args)!=2:
                return 'incorrect number of arguments'
            else:
                if int(args[0])<0 or int(args[0])>7:
                    return 'arg1 out of range (0-7)'
                else:
                    if int(args[1])<0 or int(args[1])>7:
                        return 'arg2 out of range (0-7)'
                    else:
                        return 'ok'
        if opcode in instr_type3:
            addr=line_split[1]
            if len(line_split)!=2:
                return 'incorrect argument'
            else:
                if int(addr)<0 or int(addr)>2048:
                    return 'addr out of range (0-2048)'
                else:
                    return 'ok'

        if opcode in instr_type4:
            if len(args)!=2 :
                return 'incorrect number of arguments'
            else:
                if int(args[1])<0 or int(args[1])>7:
                    return 'arg1 out of range (0-7)'
                else:
                    return 'ok'

        if opcode in instr_type5:
            return 'ok'
        
        if opcode == '.org':
            addr = line_split[1]
            addr = convert_address_to_integer(addr)         
            if addr<0 or addr>2048:
                return ('address out of range (0-2048): ' + opcode + " " + addr)
            else:
                return 'ok'
            

def extract_info(file,flag):
    tags={}
    # open file and preprocess by converting to lower case
    f=open(file,'r')
    text=f.read()
    f.close()
    text=text.lower()
    current_address = 0;    # keep track of ROM address, as .org directive will 'shift' it.

   # remove whitespace, new lines and tabs from the end of the text
    while text[-1]=='\n' or text[-1]=='\t' or text[-1]=='\s' or text[-1]=='\r':
        text=text[:-1]
    
    lines=text.split('\n')
    line_number=0
    lines2=[]

    for line_in in lines:
        line = remove_comments_from_line(line_in)
        if len(line)!=0:
            line_split=line.split()
            opcode=line_split[0]
            # if the first tag is not an instruction or directive....
            if not opcode in ( instr_type1 + instr_type2 + instr_type3 + instr_type4 + instr_type5 + directives):
                # then it's a label, and if we haven't seen it aldready...
                if not opcode in tags:
                    # add it to the tag dictionary...
                    tags[opcode]=line_number
                    # and remove label from current line
                    line=' '.join(line_split[1:])
                    line='\t'+line
                else:
                    print ('label used more than once')

            lines2.append(line)
            line_number+=1

    text2='\n'.join(lines2)
    ##parte que se encarga de reemplazar los tags en las direcciones
    for tags_elements in tags.keys():
        line2=text2.split(tags_elements)
        text2=str(tags[tags_elements]).join(line2)


    lines=text2.split('\n')
    error_line=0
    text_asm=''
    for line in lines:  
        erro=verify_args(line)
        if erro!='ok':
            print ('error in line:',error_line)
            print (line, '->', erro,'\n')
            sys.exit(1)
        else:
            line_split=line.split()
            opcode=line_split[0]
            if opcode in (instr_type1 + instr_type2 + instr_type4):
                args=re.findall(r'r(\d+)',line)
            if opcode in instr_type1:
                arg2=line.split(',')
                direccion=arg2[1]
                dato=(tokens[opcode]<<11) | (int(args[0])<<8) | int(direccion)
                text_asm+= '%X' % dato + '\n'
            if opcode in instr_type2:
                dato=(tokens[opcode]<<11) | (int(args[0])<<8) | (int(args[1])<<5)
                text_asm+= '%X' % dato + '\n'
            if opcode in instr_type3:
                addr=line_split[1]
                dato=(tokens[opcode]<<11) | int(addr)
                text_asm+= '%X' % dato + '\n'
            if opcode in instr_type4:
                dato=(tokens[opcode]<<11) | (int(args[1])<<8)
                text_asm+= '%X' % dato + '\n'
            if opcode in instr_type5:
                dato=(tokens[opcode]<<11)
                text_asm+= '%X' % dato + '\n'
            if opcode in directives:
                addr=line_split[1]
                current_address = convert_address_to_integer(addr)
                text_asm += '@' + str(current_address) + '\n'
            else:
                current_address = current_address + 1 
                
        error_line+=1

    assembler=text2.split('\n')
    progword=text_asm.split('\n')

    if flag:
        print ('line no.\taddr\tinst\t\t\tasm')
        print ('-----------------------------------------------------')
        for line_num in range(len(assembler)):
                print (str(line_num) + '\t' + progword[line_num]+'\t\t\t'+assembler[line_num].lstrip())
    line_zero=''

    for i in range(2048-len(assembler)):
        line_zero=line_zero+'0000\n'
    text_asm+=line_zero

    return text_asm

def main():
    # get the arguments e.g "-s example.asm"
    args = sys.argv[1:]

    if not args:
        print ('usage: python3 assembler.py [-s] your_code.asm')
        print ('-s show the assembly output')
        sys.exit(1)

    show = False
    if args[0] == '-s':
        show = True
        del args[0]

    # assemble to machine code
    text=extract_info(args[0],show)
    # save results
    print ('\n\nSaving results to instructions.mem...')
    outf = open('instructions.mem', 'w')
    outf.write(text)
    outf.close()



if __name__ == '__main__':
  main()