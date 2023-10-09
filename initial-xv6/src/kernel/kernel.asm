
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a1010113          	addi	sp,sp,-1520 # 80008a10 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	87e70713          	addi	a4,a4,-1922 # 800088d0 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	6ec78793          	addi	a5,a5,1772 # 80006750 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7f83a86f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	58a080e7          	jalr	1418(ra) # 800026b6 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	88650513          	addi	a0,a0,-1914 # 80010a10 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	87648493          	addi	s1,s1,-1930 # 80010a10 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	90690913          	addi	s2,s2,-1786 # 80010aa8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7fc080e7          	jalr	2044(ra) # 800019bc <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	338080e7          	jalr	824(ra) # 80002500 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	076080e7          	jalr	118(ra) # 8000224c <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	44e080e7          	jalr	1102(ra) # 80002660 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00010517          	auipc	a0,0x10
    8000022a:	7ea50513          	addi	a0,a0,2026 # 80010a10 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00010517          	auipc	a0,0x10
    80000240:	7d450513          	addi	a0,a0,2004 # 80010a10 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	82f72b23          	sw	a5,-1994(a4) # 80010aa8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	74450513          	addi	a0,a0,1860 # 80010a10 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	41a080e7          	jalr	1050(ra) # 8000270c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	71650513          	addi	a0,a0,1814 # 80010a10 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	6f270713          	addi	a4,a4,1778 # 80010a10 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	6c878793          	addi	a5,a5,1736 # 80010a10 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7327a783          	lw	a5,1842(a5) # 80010aa8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	68670713          	addi	a4,a4,1670 # 80010a10 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	67648493          	addi	s1,s1,1654 # 80010a10 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	63a70713          	addi	a4,a4,1594 # 80010a10 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	6cf72223          	sw	a5,1732(a4) # 80010ab0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	5fe78793          	addi	a5,a5,1534 # 80010a10 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	66c7ab23          	sw	a2,1654(a5) # 80010aac <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	66a50513          	addi	a0,a0,1642 # 80010aa8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e6a080e7          	jalr	-406(ra) # 800022b0 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5b050513          	addi	a0,a0,1456 # 80010a10 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	007c3797          	auipc	a5,0x7c3
    8000047c:	98078793          	addi	a5,a5,-1664 # 807c2df8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5807a323          	sw	zero,1414(a5) # 80010ad0 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	dfc50513          	addi	a0,a0,-516 # 80008368 <digits+0x328>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	30f72923          	sw	a5,786(a4) # 80008890 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	516dad83          	lw	s11,1302(s11) # 80010ad0 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	4c050513          	addi	a0,a0,1216 # 80010ab8 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	36250513          	addi	a0,a0,866 # 80010ab8 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	34648493          	addi	s1,s1,838 # 80010ab8 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	30650513          	addi	a0,a0,774 # 80010ad8 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0927a783          	lw	a5,146(a5) # 80008890 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0627b783          	ld	a5,98(a5) # 80008898 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	06273703          	ld	a4,98(a4) # 800088a0 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	278a0a13          	addi	s4,s4,632 # 80010ad8 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	03048493          	addi	s1,s1,48 # 80008898 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	03098993          	addi	s3,s3,48 # 800088a0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	a1e080e7          	jalr	-1506(ra) # 800022b0 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	20a50513          	addi	a0,a0,522 # 80010ad8 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	fb27a783          	lw	a5,-78(a5) # 80008890 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	fb873703          	ld	a4,-72(a4) # 800088a0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	fa87b783          	ld	a5,-88(a5) # 80008898 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	1dc98993          	addi	s3,s3,476 # 80010ad8 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	f9448493          	addi	s1,s1,-108 # 80008898 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	f9490913          	addi	s2,s2,-108 # 800088a0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	930080e7          	jalr	-1744(ra) # 8000224c <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1a648493          	addi	s1,s1,422 # 80010ad8 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	f4e7bd23          	sd	a4,-166(a5) # 800088a0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	11c48493          	addi	s1,s1,284 # 80010ad8 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	007c3797          	auipc	a5,0x7c3
    80000a02:	59278793          	addi	a5,a5,1426 # 807c3f90 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	0f290913          	addi	s2,s2,242 # 80010b10 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	05650513          	addi	a0,a0,86 # 80010b10 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	007c3517          	auipc	a0,0x7c3
    80000ad2:	4c250513          	addi	a0,a0,1218 # 807c3f90 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	02048493          	addi	s1,s1,32 # 80010b10 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	00850513          	addi	a0,a0,8 # 80010b10 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	fdc50513          	addi	a0,a0,-36 # 80010b10 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e30080e7          	jalr	-464(ra) # 800019a0 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dfe080e7          	jalr	-514(ra) # 800019a0 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	df2080e7          	jalr	-526(ra) # 800019a0 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dda080e7          	jalr	-550(ra) # 800019a0 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d9a080e7          	jalr	-614(ra) # 800019a0 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d6e080e7          	jalr	-658(ra) # 800019a0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;
int getread_count = 0; 
// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  #ifdef MLFQ
    printf("\nMLFQ\n");
    80000e80:	00007517          	auipc	a0,0x7
    80000e84:	22050513          	addi	a0,a0,544 # 800080a0 <digits+0x60>
    80000e88:	fffff097          	auipc	ra,0xfffff
    80000e8c:	700080e7          	jalr	1792(ra) # 80000588 <printf>
  printf("\nRR\n");
  #endif
  #ifdef FCFS
  printf("\nFCFS\n");
  #endif
  if(cpuid() == 0){
    80000e90:	00001097          	auipc	ra,0x1
    80000e94:	b00080e7          	jalr	-1280(ra) # 80001990 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e98:	00008717          	auipc	a4,0x8
    80000e9c:	a1470713          	addi	a4,a4,-1516 # 800088ac <started>
  if(cpuid() == 0){
    80000ea0:	c139                	beqz	a0,80000ee6 <main+0x6e>
    while(started == 0)
    80000ea2:	431c                	lw	a5,0(a4)
    80000ea4:	2781                	sext.w	a5,a5
    80000ea6:	dff5                	beqz	a5,80000ea2 <main+0x2a>
      ;
    __sync_synchronize();
    80000ea8:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eac:	00001097          	auipc	ra,0x1
    80000eb0:	ae4080e7          	jalr	-1308(ra) # 80001990 <cpuid>
    80000eb4:	85aa                	mv	a1,a0
    80000eb6:	00007517          	auipc	a0,0x7
    80000eba:	20a50513          	addi	a0,a0,522 # 800080c0 <digits+0x80>
    80000ebe:	fffff097          	auipc	ra,0xfffff
    80000ec2:	6ca080e7          	jalr	1738(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ec6:	00000097          	auipc	ra,0x0
    80000eca:	0d8080e7          	jalr	216(ra) # 80000f9e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ece:	00002097          	auipc	ra,0x2
    80000ed2:	a8e080e7          	jalr	-1394(ra) # 8000295c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ed6:	00006097          	auipc	ra,0x6
    80000eda:	8ba080e7          	jalr	-1862(ra) # 80006790 <plicinithart>
  }

  scheduler();        
    80000ede:	00001097          	auipc	ra,0x1
    80000ee2:	022080e7          	jalr	34(ra) # 80001f00 <scheduler>
    consoleinit();
    80000ee6:	fffff097          	auipc	ra,0xfffff
    80000eea:	56a080e7          	jalr	1386(ra) # 80000450 <consoleinit>
    printfinit();
    80000eee:	00000097          	auipc	ra,0x0
    80000ef2:	87a080e7          	jalr	-1926(ra) # 80000768 <printfinit>
    printf("\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	47250513          	addi	a0,a0,1138 # 80008368 <digits+0x328>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1a250513          	addi	a0,a0,418 # 800080a8 <digits+0x68>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    printf("\n");
    80000f16:	00007517          	auipc	a0,0x7
    80000f1a:	45250513          	addi	a0,a0,1106 # 80008368 <digits+0x328>
    80000f1e:	fffff097          	auipc	ra,0xfffff
    80000f22:	66a080e7          	jalr	1642(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	b84080e7          	jalr	-1148(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f2e:	00000097          	auipc	ra,0x0
    80000f32:	326080e7          	jalr	806(ra) # 80001254 <kvminit>
    kvminithart();   // turn on paging
    80000f36:	00000097          	auipc	ra,0x0
    80000f3a:	068080e7          	jalr	104(ra) # 80000f9e <kvminithart>
    procinit();      // process table
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	99e080e7          	jalr	-1634(ra) # 800018dc <procinit>
    trapinit();      // trap vectors
    80000f46:	00002097          	auipc	ra,0x2
    80000f4a:	9ee080e7          	jalr	-1554(ra) # 80002934 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f4e:	00002097          	auipc	ra,0x2
    80000f52:	a0e080e7          	jalr	-1522(ra) # 8000295c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f56:	00006097          	auipc	ra,0x6
    80000f5a:	824080e7          	jalr	-2012(ra) # 8000677a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f5e:	00006097          	auipc	ra,0x6
    80000f62:	832080e7          	jalr	-1998(ra) # 80006790 <plicinithart>
    binit();         // buffer cache
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	9cc080e7          	jalr	-1588(ra) # 80003932 <binit>
    iinit();         // inode table
    80000f6e:	00003097          	auipc	ra,0x3
    80000f72:	070080e7          	jalr	112(ra) # 80003fde <iinit>
    fileinit();      // file table
    80000f76:	00004097          	auipc	ra,0x4
    80000f7a:	00e080e7          	jalr	14(ra) # 80004f84 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f7e:	00006097          	auipc	ra,0x6
    80000f82:	91a080e7          	jalr	-1766(ra) # 80006898 <virtio_disk_init>
    userinit();      // first user process
    80000f86:	00001097          	auipc	ra,0x1
    80000f8a:	d5c080e7          	jalr	-676(ra) # 80001ce2 <userinit>
    __sync_synchronize();
    80000f8e:	0ff0000f          	fence
    started = 1;
    80000f92:	4785                	li	a5,1
    80000f94:	00008717          	auipc	a4,0x8
    80000f98:	90f72c23          	sw	a5,-1768(a4) # 800088ac <started>
    80000f9c:	b789                	j	80000ede <main+0x66>

0000000080000f9e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f9e:	1141                	addi	sp,sp,-16
    80000fa0:	e422                	sd	s0,8(sp)
    80000fa2:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa4:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fa8:	00008797          	auipc	a5,0x8
    80000fac:	9087b783          	ld	a5,-1784(a5) # 800088b0 <kernel_pagetable>
    80000fb0:	83b1                	srli	a5,a5,0xc
    80000fb2:	577d                	li	a4,-1
    80000fb4:	177e                	slli	a4,a4,0x3f
    80000fb6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fb8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fbc:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fc0:	6422                	ld	s0,8(sp)
    80000fc2:	0141                	addi	sp,sp,16
    80000fc4:	8082                	ret

0000000080000fc6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc6:	7139                	addi	sp,sp,-64
    80000fc8:	fc06                	sd	ra,56(sp)
    80000fca:	f822                	sd	s0,48(sp)
    80000fcc:	f426                	sd	s1,40(sp)
    80000fce:	f04a                	sd	s2,32(sp)
    80000fd0:	ec4e                	sd	s3,24(sp)
    80000fd2:	e852                	sd	s4,16(sp)
    80000fd4:	e456                	sd	s5,8(sp)
    80000fd6:	e05a                	sd	s6,0(sp)
    80000fd8:	0080                	addi	s0,sp,64
    80000fda:	84aa                	mv	s1,a0
    80000fdc:	89ae                	mv	s3,a1
    80000fde:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe0:	57fd                	li	a5,-1
    80000fe2:	83e9                	srli	a5,a5,0x1a
    80000fe4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fe8:	04b7f263          	bgeu	a5,a1,8000102c <walk+0x66>
    panic("walk");
    80000fec:	00007517          	auipc	a0,0x7
    80000ff0:	0ec50513          	addi	a0,a0,236 # 800080d8 <digits+0x98>
    80000ff4:	fffff097          	auipc	ra,0xfffff
    80000ff8:	54a080e7          	jalr	1354(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffc:	060a8663          	beqz	s5,80001068 <walk+0xa2>
    80001000:	00000097          	auipc	ra,0x0
    80001004:	ae6080e7          	jalr	-1306(ra) # 80000ae6 <kalloc>
    80001008:	84aa                	mv	s1,a0
    8000100a:	c529                	beqz	a0,80001054 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100c:	6605                	lui	a2,0x1
    8000100e:	4581                	li	a1,0
    80001010:	00000097          	auipc	ra,0x0
    80001014:	cc2080e7          	jalr	-830(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001018:	00c4d793          	srli	a5,s1,0xc
    8000101c:	07aa                	slli	a5,a5,0xa
    8000101e:	0017e793          	ori	a5,a5,1
    80001022:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001026:	3a5d                	addiw	s4,s4,-9
    80001028:	036a0063          	beq	s4,s6,80001048 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102c:	0149d933          	srl	s2,s3,s4
    80001030:	1ff97913          	andi	s2,s2,511
    80001034:	090e                	slli	s2,s2,0x3
    80001036:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001038:	00093483          	ld	s1,0(s2)
    8000103c:	0014f793          	andi	a5,s1,1
    80001040:	dfd5                	beqz	a5,80000ffc <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001042:	80a9                	srli	s1,s1,0xa
    80001044:	04b2                	slli	s1,s1,0xc
    80001046:	b7c5                	j	80001026 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001048:	00c9d513          	srli	a0,s3,0xc
    8000104c:	1ff57513          	andi	a0,a0,511
    80001050:	050e                	slli	a0,a0,0x3
    80001052:	9526                	add	a0,a0,s1
}
    80001054:	70e2                	ld	ra,56(sp)
    80001056:	7442                	ld	s0,48(sp)
    80001058:	74a2                	ld	s1,40(sp)
    8000105a:	7902                	ld	s2,32(sp)
    8000105c:	69e2                	ld	s3,24(sp)
    8000105e:	6a42                	ld	s4,16(sp)
    80001060:	6aa2                	ld	s5,8(sp)
    80001062:	6b02                	ld	s6,0(sp)
    80001064:	6121                	addi	sp,sp,64
    80001066:	8082                	ret
        return 0;
    80001068:	4501                	li	a0,0
    8000106a:	b7ed                	j	80001054 <walk+0x8e>

000000008000106c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106c:	57fd                	li	a5,-1
    8000106e:	83e9                	srli	a5,a5,0x1a
    80001070:	00b7f463          	bgeu	a5,a1,80001078 <walkaddr+0xc>
    return 0;
    80001074:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001076:	8082                	ret
{
    80001078:	1141                	addi	sp,sp,-16
    8000107a:	e406                	sd	ra,8(sp)
    8000107c:	e022                	sd	s0,0(sp)
    8000107e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001080:	4601                	li	a2,0
    80001082:	00000097          	auipc	ra,0x0
    80001086:	f44080e7          	jalr	-188(ra) # 80000fc6 <walk>
  if(pte == 0)
    8000108a:	c105                	beqz	a0,800010aa <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000108e:	0117f693          	andi	a3,a5,17
    80001092:	4745                	li	a4,17
    return 0;
    80001094:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001096:	00e68663          	beq	a3,a4,800010a2 <walkaddr+0x36>
}
    8000109a:	60a2                	ld	ra,8(sp)
    8000109c:	6402                	ld	s0,0(sp)
    8000109e:	0141                	addi	sp,sp,16
    800010a0:	8082                	ret
  pa = PTE2PA(*pte);
    800010a2:	00a7d513          	srli	a0,a5,0xa
    800010a6:	0532                	slli	a0,a0,0xc
  return pa;
    800010a8:	bfcd                	j	8000109a <walkaddr+0x2e>
    return 0;
    800010aa:	4501                	li	a0,0
    800010ac:	b7fd                	j	8000109a <walkaddr+0x2e>

00000000800010ae <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ae:	715d                	addi	sp,sp,-80
    800010b0:	e486                	sd	ra,72(sp)
    800010b2:	e0a2                	sd	s0,64(sp)
    800010b4:	fc26                	sd	s1,56(sp)
    800010b6:	f84a                	sd	s2,48(sp)
    800010b8:	f44e                	sd	s3,40(sp)
    800010ba:	f052                	sd	s4,32(sp)
    800010bc:	ec56                	sd	s5,24(sp)
    800010be:	e85a                	sd	s6,16(sp)
    800010c0:	e45e                	sd	s7,8(sp)
    800010c2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c4:	c639                	beqz	a2,80001112 <mappages+0x64>
    800010c6:	8aaa                	mv	s5,a0
    800010c8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ca:	77fd                	lui	a5,0xfffff
    800010cc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d0:	15fd                	addi	a1,a1,-1
    800010d2:	00c589b3          	add	s3,a1,a2
    800010d6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010da:	8952                	mv	s2,s4
    800010dc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e0:	6b85                	lui	s7,0x1
    800010e2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010e6:	4605                	li	a2,1
    800010e8:	85ca                	mv	a1,s2
    800010ea:	8556                	mv	a0,s5
    800010ec:	00000097          	auipc	ra,0x0
    800010f0:	eda080e7          	jalr	-294(ra) # 80000fc6 <walk>
    800010f4:	cd1d                	beqz	a0,80001132 <mappages+0x84>
    if(*pte & PTE_V)
    800010f6:	611c                	ld	a5,0(a0)
    800010f8:	8b85                	andi	a5,a5,1
    800010fa:	e785                	bnez	a5,80001122 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010fc:	80b1                	srli	s1,s1,0xc
    800010fe:	04aa                	slli	s1,s1,0xa
    80001100:	0164e4b3          	or	s1,s1,s6
    80001104:	0014e493          	ori	s1,s1,1
    80001108:	e104                	sd	s1,0(a0)
    if(a == last)
    8000110a:	05390063          	beq	s2,s3,8000114a <mappages+0x9c>
    a += PGSIZE;
    8000110e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001110:	bfc9                	j	800010e2 <mappages+0x34>
    panic("mappages: size");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fce50513          	addi	a0,a0,-50 # 800080e0 <digits+0xa0>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001122:	00007517          	auipc	a0,0x7
    80001126:	fce50513          	addi	a0,a0,-50 # 800080f0 <digits+0xb0>
    8000112a:	fffff097          	auipc	ra,0xfffff
    8000112e:	414080e7          	jalr	1044(ra) # 8000053e <panic>
      return -1;
    80001132:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001134:	60a6                	ld	ra,72(sp)
    80001136:	6406                	ld	s0,64(sp)
    80001138:	74e2                	ld	s1,56(sp)
    8000113a:	7942                	ld	s2,48(sp)
    8000113c:	79a2                	ld	s3,40(sp)
    8000113e:	7a02                	ld	s4,32(sp)
    80001140:	6ae2                	ld	s5,24(sp)
    80001142:	6b42                	ld	s6,16(sp)
    80001144:	6ba2                	ld	s7,8(sp)
    80001146:	6161                	addi	sp,sp,80
    80001148:	8082                	ret
  return 0;
    8000114a:	4501                	li	a0,0
    8000114c:	b7e5                	j	80001134 <mappages+0x86>

000000008000114e <kvmmap>:
{
    8000114e:	1141                	addi	sp,sp,-16
    80001150:	e406                	sd	ra,8(sp)
    80001152:	e022                	sd	s0,0(sp)
    80001154:	0800                	addi	s0,sp,16
    80001156:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001158:	86b2                	mv	a3,a2
    8000115a:	863e                	mv	a2,a5
    8000115c:	00000097          	auipc	ra,0x0
    80001160:	f52080e7          	jalr	-174(ra) # 800010ae <mappages>
    80001164:	e509                	bnez	a0,8000116e <kvmmap+0x20>
}
    80001166:	60a2                	ld	ra,8(sp)
    80001168:	6402                	ld	s0,0(sp)
    8000116a:	0141                	addi	sp,sp,16
    8000116c:	8082                	ret
    panic("kvmmap");
    8000116e:	00007517          	auipc	a0,0x7
    80001172:	f9250513          	addi	a0,a0,-110 # 80008100 <digits+0xc0>
    80001176:	fffff097          	auipc	ra,0xfffff
    8000117a:	3c8080e7          	jalr	968(ra) # 8000053e <panic>

000000008000117e <kvmmake>:
{
    8000117e:	1101                	addi	sp,sp,-32
    80001180:	ec06                	sd	ra,24(sp)
    80001182:	e822                	sd	s0,16(sp)
    80001184:	e426                	sd	s1,8(sp)
    80001186:	e04a                	sd	s2,0(sp)
    80001188:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118a:	00000097          	auipc	ra,0x0
    8000118e:	95c080e7          	jalr	-1700(ra) # 80000ae6 <kalloc>
    80001192:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001194:	6605                	lui	a2,0x1
    80001196:	4581                	li	a1,0
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	b3a080e7          	jalr	-1222(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a0:	4719                	li	a4,6
    800011a2:	6685                	lui	a3,0x1
    800011a4:	10000637          	lui	a2,0x10000
    800011a8:	100005b7          	lui	a1,0x10000
    800011ac:	8526                	mv	a0,s1
    800011ae:	00000097          	auipc	ra,0x0
    800011b2:	fa0080e7          	jalr	-96(ra) # 8000114e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b6:	4719                	li	a4,6
    800011b8:	6685                	lui	a3,0x1
    800011ba:	10001637          	lui	a2,0x10001
    800011be:	100015b7          	lui	a1,0x10001
    800011c2:	8526                	mv	a0,s1
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	f8a080e7          	jalr	-118(ra) # 8000114e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011cc:	4719                	li	a4,6
    800011ce:	004006b7          	lui	a3,0x400
    800011d2:	0c000637          	lui	a2,0xc000
    800011d6:	0c0005b7          	lui	a1,0xc000
    800011da:	8526                	mv	a0,s1
    800011dc:	00000097          	auipc	ra,0x0
    800011e0:	f72080e7          	jalr	-142(ra) # 8000114e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e4:	00007917          	auipc	s2,0x7
    800011e8:	e1c90913          	addi	s2,s2,-484 # 80008000 <etext>
    800011ec:	4729                	li	a4,10
    800011ee:	80007697          	auipc	a3,0x80007
    800011f2:	e1268693          	addi	a3,a3,-494 # 8000 <_entry-0x7fff8000>
    800011f6:	4605                	li	a2,1
    800011f8:	067e                	slli	a2,a2,0x1f
    800011fa:	85b2                	mv	a1,a2
    800011fc:	8526                	mv	a0,s1
    800011fe:	00000097          	auipc	ra,0x0
    80001202:	f50080e7          	jalr	-176(ra) # 8000114e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001206:	4719                	li	a4,6
    80001208:	46c5                	li	a3,17
    8000120a:	06ee                	slli	a3,a3,0x1b
    8000120c:	412686b3          	sub	a3,a3,s2
    80001210:	864a                	mv	a2,s2
    80001212:	85ca                	mv	a1,s2
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	f38080e7          	jalr	-200(ra) # 8000114e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000121e:	4729                	li	a4,10
    80001220:	6685                	lui	a3,0x1
    80001222:	00006617          	auipc	a2,0x6
    80001226:	dde60613          	addi	a2,a2,-546 # 80007000 <_trampoline>
    8000122a:	040005b7          	lui	a1,0x4000
    8000122e:	15fd                	addi	a1,a1,-1
    80001230:	05b2                	slli	a1,a1,0xc
    80001232:	8526                	mv	a0,s1
    80001234:	00000097          	auipc	ra,0x0
    80001238:	f1a080e7          	jalr	-230(ra) # 8000114e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	608080e7          	jalr	1544(ra) # 80001846 <proc_mapstacks>
}
    80001246:	8526                	mv	a0,s1
    80001248:	60e2                	ld	ra,24(sp)
    8000124a:	6442                	ld	s0,16(sp)
    8000124c:	64a2                	ld	s1,8(sp)
    8000124e:	6902                	ld	s2,0(sp)
    80001250:	6105                	addi	sp,sp,32
    80001252:	8082                	ret

0000000080001254 <kvminit>:
{
    80001254:	1141                	addi	sp,sp,-16
    80001256:	e406                	sd	ra,8(sp)
    80001258:	e022                	sd	s0,0(sp)
    8000125a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125c:	00000097          	auipc	ra,0x0
    80001260:	f22080e7          	jalr	-222(ra) # 8000117e <kvmmake>
    80001264:	00007797          	auipc	a5,0x7
    80001268:	64a7b623          	sd	a0,1612(a5) # 800088b0 <kernel_pagetable>
}
    8000126c:	60a2                	ld	ra,8(sp)
    8000126e:	6402                	ld	s0,0(sp)
    80001270:	0141                	addi	sp,sp,16
    80001272:	8082                	ret

0000000080001274 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001274:	715d                	addi	sp,sp,-80
    80001276:	e486                	sd	ra,72(sp)
    80001278:	e0a2                	sd	s0,64(sp)
    8000127a:	fc26                	sd	s1,56(sp)
    8000127c:	f84a                	sd	s2,48(sp)
    8000127e:	f44e                	sd	s3,40(sp)
    80001280:	f052                	sd	s4,32(sp)
    80001282:	ec56                	sd	s5,24(sp)
    80001284:	e85a                	sd	s6,16(sp)
    80001286:	e45e                	sd	s7,8(sp)
    80001288:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128a:	03459793          	slli	a5,a1,0x34
    8000128e:	e795                	bnez	a5,800012ba <uvmunmap+0x46>
    80001290:	8a2a                	mv	s4,a0
    80001292:	892e                	mv	s2,a1
    80001294:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001296:	0632                	slli	a2,a2,0xc
    80001298:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000129e:	6b05                	lui	s6,0x1
    800012a0:	0735e263          	bltu	a1,s3,80001304 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a4:	60a6                	ld	ra,72(sp)
    800012a6:	6406                	ld	s0,64(sp)
    800012a8:	74e2                	ld	s1,56(sp)
    800012aa:	7942                	ld	s2,48(sp)
    800012ac:	79a2                	ld	s3,40(sp)
    800012ae:	7a02                	ld	s4,32(sp)
    800012b0:	6ae2                	ld	s5,24(sp)
    800012b2:	6b42                	ld	s6,16(sp)
    800012b4:	6ba2                	ld	s7,8(sp)
    800012b6:	6161                	addi	sp,sp,80
    800012b8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e4e50513          	addi	a0,a0,-434 # 80008108 <digits+0xc8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5650513          	addi	a0,a0,-426 # 80008120 <digits+0xe0>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e5650513          	addi	a0,a0,-426 # 80008130 <digits+0xf0>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ea:	00007517          	auipc	a0,0x7
    800012ee:	e5e50513          	addi	a0,a0,-418 # 80008148 <digits+0x108>
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	24c080e7          	jalr	588(ra) # 8000053e <panic>
    *pte = 0;
    800012fa:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012fe:	995a                	add	s2,s2,s6
    80001300:	fb3972e3          	bgeu	s2,s3,800012a4 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001304:	4601                	li	a2,0
    80001306:	85ca                	mv	a1,s2
    80001308:	8552                	mv	a0,s4
    8000130a:	00000097          	auipc	ra,0x0
    8000130e:	cbc080e7          	jalr	-836(ra) # 80000fc6 <walk>
    80001312:	84aa                	mv	s1,a0
    80001314:	d95d                	beqz	a0,800012ca <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001316:	6108                	ld	a0,0(a0)
    80001318:	00157793          	andi	a5,a0,1
    8000131c:	dfdd                	beqz	a5,800012da <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000131e:	3ff57793          	andi	a5,a0,1023
    80001322:	fd7784e3          	beq	a5,s7,800012ea <uvmunmap+0x76>
    if(do_free){
    80001326:	fc0a8ae3          	beqz	s5,800012fa <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000132a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000132c:	0532                	slli	a0,a0,0xc
    8000132e:	fffff097          	auipc	ra,0xfffff
    80001332:	6bc080e7          	jalr	1724(ra) # 800009ea <kfree>
    80001336:	b7d1                	j	800012fa <uvmunmap+0x86>

0000000080001338 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001338:	1101                	addi	sp,sp,-32
    8000133a:	ec06                	sd	ra,24(sp)
    8000133c:	e822                	sd	s0,16(sp)
    8000133e:	e426                	sd	s1,8(sp)
    80001340:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001342:	fffff097          	auipc	ra,0xfffff
    80001346:	7a4080e7          	jalr	1956(ra) # 80000ae6 <kalloc>
    8000134a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134c:	c519                	beqz	a0,8000135a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000134e:	6605                	lui	a2,0x1
    80001350:	4581                	li	a1,0
    80001352:	00000097          	auipc	ra,0x0
    80001356:	980080e7          	jalr	-1664(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000135a:	8526                	mv	a0,s1
    8000135c:	60e2                	ld	ra,24(sp)
    8000135e:	6442                	ld	s0,16(sp)
    80001360:	64a2                	ld	s1,8(sp)
    80001362:	6105                	addi	sp,sp,32
    80001364:	8082                	ret

0000000080001366 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001366:	7179                	addi	sp,sp,-48
    80001368:	f406                	sd	ra,40(sp)
    8000136a:	f022                	sd	s0,32(sp)
    8000136c:	ec26                	sd	s1,24(sp)
    8000136e:	e84a                	sd	s2,16(sp)
    80001370:	e44e                	sd	s3,8(sp)
    80001372:	e052                	sd	s4,0(sp)
    80001374:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001376:	6785                	lui	a5,0x1
    80001378:	04f67863          	bgeu	a2,a5,800013c8 <uvmfirst+0x62>
    8000137c:	8a2a                	mv	s4,a0
    8000137e:	89ae                	mv	s3,a1
    80001380:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001382:	fffff097          	auipc	ra,0xfffff
    80001386:	764080e7          	jalr	1892(ra) # 80000ae6 <kalloc>
    8000138a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	00000097          	auipc	ra,0x0
    80001394:	942080e7          	jalr	-1726(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001398:	4779                	li	a4,30
    8000139a:	86ca                	mv	a3,s2
    8000139c:	6605                	lui	a2,0x1
    8000139e:	4581                	li	a1,0
    800013a0:	8552                	mv	a0,s4
    800013a2:	00000097          	auipc	ra,0x0
    800013a6:	d0c080e7          	jalr	-756(ra) # 800010ae <mappages>
  memmove(mem, src, sz);
    800013aa:	8626                	mv	a2,s1
    800013ac:	85ce                	mv	a1,s3
    800013ae:	854a                	mv	a0,s2
    800013b0:	00000097          	auipc	ra,0x0
    800013b4:	97e080e7          	jalr	-1666(ra) # 80000d2e <memmove>
}
    800013b8:	70a2                	ld	ra,40(sp)
    800013ba:	7402                	ld	s0,32(sp)
    800013bc:	64e2                	ld	s1,24(sp)
    800013be:	6942                	ld	s2,16(sp)
    800013c0:	69a2                	ld	s3,8(sp)
    800013c2:	6a02                	ld	s4,0(sp)
    800013c4:	6145                	addi	sp,sp,48
    800013c6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013c8:	00007517          	auipc	a0,0x7
    800013cc:	d9850513          	addi	a0,a0,-616 # 80008160 <digits+0x120>
    800013d0:	fffff097          	auipc	ra,0xfffff
    800013d4:	16e080e7          	jalr	366(ra) # 8000053e <panic>

00000000800013d8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013d8:	1101                	addi	sp,sp,-32
    800013da:	ec06                	sd	ra,24(sp)
    800013dc:	e822                	sd	s0,16(sp)
    800013de:	e426                	sd	s1,8(sp)
    800013e0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e4:	00b67d63          	bgeu	a2,a1,800013fe <uvmdealloc+0x26>
    800013e8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ea:	6785                	lui	a5,0x1
    800013ec:	17fd                	addi	a5,a5,-1
    800013ee:	00f60733          	add	a4,a2,a5
    800013f2:	767d                	lui	a2,0xfffff
    800013f4:	8f71                	and	a4,a4,a2
    800013f6:	97ae                	add	a5,a5,a1
    800013f8:	8ff1                	and	a5,a5,a2
    800013fa:	00f76863          	bltu	a4,a5,8000140a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013fe:	8526                	mv	a0,s1
    80001400:	60e2                	ld	ra,24(sp)
    80001402:	6442                	ld	s0,16(sp)
    80001404:	64a2                	ld	s1,8(sp)
    80001406:	6105                	addi	sp,sp,32
    80001408:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140a:	8f99                	sub	a5,a5,a4
    8000140c:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000140e:	4685                	li	a3,1
    80001410:	0007861b          	sext.w	a2,a5
    80001414:	85ba                	mv	a1,a4
    80001416:	00000097          	auipc	ra,0x0
    8000141a:	e5e080e7          	jalr	-418(ra) # 80001274 <uvmunmap>
    8000141e:	b7c5                	j	800013fe <uvmdealloc+0x26>

0000000080001420 <uvmalloc>:
  if(newsz < oldsz)
    80001420:	0ab66563          	bltu	a2,a1,800014ca <uvmalloc+0xaa>
{
    80001424:	7139                	addi	sp,sp,-64
    80001426:	fc06                	sd	ra,56(sp)
    80001428:	f822                	sd	s0,48(sp)
    8000142a:	f426                	sd	s1,40(sp)
    8000142c:	f04a                	sd	s2,32(sp)
    8000142e:	ec4e                	sd	s3,24(sp)
    80001430:	e852                	sd	s4,16(sp)
    80001432:	e456                	sd	s5,8(sp)
    80001434:	e05a                	sd	s6,0(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f363          	bgeu	s3,a2,800014ce <uvmalloc+0xae>
    8000144c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000144e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001452:	fffff097          	auipc	ra,0xfffff
    80001456:	694080e7          	jalr	1684(ra) # 80000ae6 <kalloc>
    8000145a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000145c:	c51d                	beqz	a0,8000148a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000145e:	6605                	lui	a2,0x1
    80001460:	4581                	li	a1,0
    80001462:	00000097          	auipc	ra,0x0
    80001466:	870080e7          	jalr	-1936(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000146a:	875a                	mv	a4,s6
    8000146c:	86a6                	mv	a3,s1
    8000146e:	6605                	lui	a2,0x1
    80001470:	85ca                	mv	a1,s2
    80001472:	8556                	mv	a0,s5
    80001474:	00000097          	auipc	ra,0x0
    80001478:	c3a080e7          	jalr	-966(ra) # 800010ae <mappages>
    8000147c:	e90d                	bnez	a0,800014ae <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147e:	6785                	lui	a5,0x1
    80001480:	993e                	add	s2,s2,a5
    80001482:	fd4968e3          	bltu	s2,s4,80001452 <uvmalloc+0x32>
  return newsz;
    80001486:	8552                	mv	a0,s4
    80001488:	a809                	j	8000149a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000148a:	864e                	mv	a2,s3
    8000148c:	85ca                	mv	a1,s2
    8000148e:	8556                	mv	a0,s5
    80001490:	00000097          	auipc	ra,0x0
    80001494:	f48080e7          	jalr	-184(ra) # 800013d8 <uvmdealloc>
      return 0;
    80001498:	4501                	li	a0,0
}
    8000149a:	70e2                	ld	ra,56(sp)
    8000149c:	7442                	ld	s0,48(sp)
    8000149e:	74a2                	ld	s1,40(sp)
    800014a0:	7902                	ld	s2,32(sp)
    800014a2:	69e2                	ld	s3,24(sp)
    800014a4:	6a42                	ld	s4,16(sp)
    800014a6:	6aa2                	ld	s5,8(sp)
    800014a8:	6b02                	ld	s6,0(sp)
    800014aa:	6121                	addi	sp,sp,64
    800014ac:	8082                	ret
      kfree(mem);
    800014ae:	8526                	mv	a0,s1
    800014b0:	fffff097          	auipc	ra,0xfffff
    800014b4:	53a080e7          	jalr	1338(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b8:	864e                	mv	a2,s3
    800014ba:	85ca                	mv	a1,s2
    800014bc:	8556                	mv	a0,s5
    800014be:	00000097          	auipc	ra,0x0
    800014c2:	f1a080e7          	jalr	-230(ra) # 800013d8 <uvmdealloc>
      return 0;
    800014c6:	4501                	li	a0,0
    800014c8:	bfc9                	j	8000149a <uvmalloc+0x7a>
    return oldsz;
    800014ca:	852e                	mv	a0,a1
}
    800014cc:	8082                	ret
  return newsz;
    800014ce:	8532                	mv	a0,a2
    800014d0:	b7e9                	j	8000149a <uvmalloc+0x7a>

00000000800014d2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014d2:	7179                	addi	sp,sp,-48
    800014d4:	f406                	sd	ra,40(sp)
    800014d6:	f022                	sd	s0,32(sp)
    800014d8:	ec26                	sd	s1,24(sp)
    800014da:	e84a                	sd	s2,16(sp)
    800014dc:	e44e                	sd	s3,8(sp)
    800014de:	e052                	sd	s4,0(sp)
    800014e0:	1800                	addi	s0,sp,48
    800014e2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014e4:	84aa                	mv	s1,a0
    800014e6:	6905                	lui	s2,0x1
    800014e8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014ea:	4985                	li	s3,1
    800014ec:	a821                	j	80001504 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014ee:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014f0:	0532                	slli	a0,a0,0xc
    800014f2:	00000097          	auipc	ra,0x0
    800014f6:	fe0080e7          	jalr	-32(ra) # 800014d2 <freewalk>
      pagetable[i] = 0;
    800014fa:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014fe:	04a1                	addi	s1,s1,8
    80001500:	03248163          	beq	s1,s2,80001522 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001504:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001506:	00f57793          	andi	a5,a0,15
    8000150a:	ff3782e3          	beq	a5,s3,800014ee <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000150e:	8905                	andi	a0,a0,1
    80001510:	d57d                	beqz	a0,800014fe <freewalk+0x2c>
      panic("freewalk: leaf");
    80001512:	00007517          	auipc	a0,0x7
    80001516:	c6e50513          	addi	a0,a0,-914 # 80008180 <digits+0x140>
    8000151a:	fffff097          	auipc	ra,0xfffff
    8000151e:	024080e7          	jalr	36(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001522:	8552                	mv	a0,s4
    80001524:	fffff097          	auipc	ra,0xfffff
    80001528:	4c6080e7          	jalr	1222(ra) # 800009ea <kfree>
}
    8000152c:	70a2                	ld	ra,40(sp)
    8000152e:	7402                	ld	s0,32(sp)
    80001530:	64e2                	ld	s1,24(sp)
    80001532:	6942                	ld	s2,16(sp)
    80001534:	69a2                	ld	s3,8(sp)
    80001536:	6a02                	ld	s4,0(sp)
    80001538:	6145                	addi	sp,sp,48
    8000153a:	8082                	ret

000000008000153c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000153c:	1101                	addi	sp,sp,-32
    8000153e:	ec06                	sd	ra,24(sp)
    80001540:	e822                	sd	s0,16(sp)
    80001542:	e426                	sd	s1,8(sp)
    80001544:	1000                	addi	s0,sp,32
    80001546:	84aa                	mv	s1,a0
  if(sz > 0)
    80001548:	e999                	bnez	a1,8000155e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000154a:	8526                	mv	a0,s1
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	f86080e7          	jalr	-122(ra) # 800014d2 <freewalk>
}
    80001554:	60e2                	ld	ra,24(sp)
    80001556:	6442                	ld	s0,16(sp)
    80001558:	64a2                	ld	s1,8(sp)
    8000155a:	6105                	addi	sp,sp,32
    8000155c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000155e:	6605                	lui	a2,0x1
    80001560:	167d                	addi	a2,a2,-1
    80001562:	962e                	add	a2,a2,a1
    80001564:	4685                	li	a3,1
    80001566:	8231                	srli	a2,a2,0xc
    80001568:	4581                	li	a1,0
    8000156a:	00000097          	auipc	ra,0x0
    8000156e:	d0a080e7          	jalr	-758(ra) # 80001274 <uvmunmap>
    80001572:	bfe1                	j	8000154a <uvmfree+0xe>

0000000080001574 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001574:	c679                	beqz	a2,80001642 <uvmcopy+0xce>
{
    80001576:	715d                	addi	sp,sp,-80
    80001578:	e486                	sd	ra,72(sp)
    8000157a:	e0a2                	sd	s0,64(sp)
    8000157c:	fc26                	sd	s1,56(sp)
    8000157e:	f84a                	sd	s2,48(sp)
    80001580:	f44e                	sd	s3,40(sp)
    80001582:	f052                	sd	s4,32(sp)
    80001584:	ec56                	sd	s5,24(sp)
    80001586:	e85a                	sd	s6,16(sp)
    80001588:	e45e                	sd	s7,8(sp)
    8000158a:	0880                	addi	s0,sp,80
    8000158c:	8b2a                	mv	s6,a0
    8000158e:	8aae                	mv	s5,a1
    80001590:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001592:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001594:	4601                	li	a2,0
    80001596:	85ce                	mv	a1,s3
    80001598:	855a                	mv	a0,s6
    8000159a:	00000097          	auipc	ra,0x0
    8000159e:	a2c080e7          	jalr	-1492(ra) # 80000fc6 <walk>
    800015a2:	c531                	beqz	a0,800015ee <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015a4:	6118                	ld	a4,0(a0)
    800015a6:	00177793          	andi	a5,a4,1
    800015aa:	cbb1                	beqz	a5,800015fe <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ac:	00a75593          	srli	a1,a4,0xa
    800015b0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015b4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b8:	fffff097          	auipc	ra,0xfffff
    800015bc:	52e080e7          	jalr	1326(ra) # 80000ae6 <kalloc>
    800015c0:	892a                	mv	s2,a0
    800015c2:	c939                	beqz	a0,80001618 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015c4:	6605                	lui	a2,0x1
    800015c6:	85de                	mv	a1,s7
    800015c8:	fffff097          	auipc	ra,0xfffff
    800015cc:	766080e7          	jalr	1894(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015d0:	8726                	mv	a4,s1
    800015d2:	86ca                	mv	a3,s2
    800015d4:	6605                	lui	a2,0x1
    800015d6:	85ce                	mv	a1,s3
    800015d8:	8556                	mv	a0,s5
    800015da:	00000097          	auipc	ra,0x0
    800015de:	ad4080e7          	jalr	-1324(ra) # 800010ae <mappages>
    800015e2:	e515                	bnez	a0,8000160e <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015e4:	6785                	lui	a5,0x1
    800015e6:	99be                	add	s3,s3,a5
    800015e8:	fb49e6e3          	bltu	s3,s4,80001594 <uvmcopy+0x20>
    800015ec:	a081                	j	8000162c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015ee:	00007517          	auipc	a0,0x7
    800015f2:	ba250513          	addi	a0,a0,-1118 # 80008190 <digits+0x150>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015fe:	00007517          	auipc	a0,0x7
    80001602:	bb250513          	addi	a0,a0,-1102 # 800081b0 <digits+0x170>
    80001606:	fffff097          	auipc	ra,0xfffff
    8000160a:	f38080e7          	jalr	-200(ra) # 8000053e <panic>
      kfree(mem);
    8000160e:	854a                	mv	a0,s2
    80001610:	fffff097          	auipc	ra,0xfffff
    80001614:	3da080e7          	jalr	986(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001618:	4685                	li	a3,1
    8000161a:	00c9d613          	srli	a2,s3,0xc
    8000161e:	4581                	li	a1,0
    80001620:	8556                	mv	a0,s5
    80001622:	00000097          	auipc	ra,0x0
    80001626:	c52080e7          	jalr	-942(ra) # 80001274 <uvmunmap>
  return -1;
    8000162a:	557d                	li	a0,-1
}
    8000162c:	60a6                	ld	ra,72(sp)
    8000162e:	6406                	ld	s0,64(sp)
    80001630:	74e2                	ld	s1,56(sp)
    80001632:	7942                	ld	s2,48(sp)
    80001634:	79a2                	ld	s3,40(sp)
    80001636:	7a02                	ld	s4,32(sp)
    80001638:	6ae2                	ld	s5,24(sp)
    8000163a:	6b42                	ld	s6,16(sp)
    8000163c:	6ba2                	ld	s7,8(sp)
    8000163e:	6161                	addi	sp,sp,80
    80001640:	8082                	ret
  return 0;
    80001642:	4501                	li	a0,0
}
    80001644:	8082                	ret

0000000080001646 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001646:	1141                	addi	sp,sp,-16
    80001648:	e406                	sd	ra,8(sp)
    8000164a:	e022                	sd	s0,0(sp)
    8000164c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000164e:	4601                	li	a2,0
    80001650:	00000097          	auipc	ra,0x0
    80001654:	976080e7          	jalr	-1674(ra) # 80000fc6 <walk>
  if(pte == 0)
    80001658:	c901                	beqz	a0,80001668 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000165a:	611c                	ld	a5,0(a0)
    8000165c:	9bbd                	andi	a5,a5,-17
    8000165e:	e11c                	sd	a5,0(a0)
}
    80001660:	60a2                	ld	ra,8(sp)
    80001662:	6402                	ld	s0,0(sp)
    80001664:	0141                	addi	sp,sp,16
    80001666:	8082                	ret
    panic("uvmclear");
    80001668:	00007517          	auipc	a0,0x7
    8000166c:	b6850513          	addi	a0,a0,-1176 # 800081d0 <digits+0x190>
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	ece080e7          	jalr	-306(ra) # 8000053e <panic>

0000000080001678 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001678:	c6bd                	beqz	a3,800016e6 <copyout+0x6e>
{
    8000167a:	715d                	addi	sp,sp,-80
    8000167c:	e486                	sd	ra,72(sp)
    8000167e:	e0a2                	sd	s0,64(sp)
    80001680:	fc26                	sd	s1,56(sp)
    80001682:	f84a                	sd	s2,48(sp)
    80001684:	f44e                	sd	s3,40(sp)
    80001686:	f052                	sd	s4,32(sp)
    80001688:	ec56                	sd	s5,24(sp)
    8000168a:	e85a                	sd	s6,16(sp)
    8000168c:	e45e                	sd	s7,8(sp)
    8000168e:	e062                	sd	s8,0(sp)
    80001690:	0880                	addi	s0,sp,80
    80001692:	8b2a                	mv	s6,a0
    80001694:	8c2e                	mv	s8,a1
    80001696:	8a32                	mv	s4,a2
    80001698:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000169a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000169c:	6a85                	lui	s5,0x1
    8000169e:	a015                	j	800016c2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a0:	9562                	add	a0,a0,s8
    800016a2:	0004861b          	sext.w	a2,s1
    800016a6:	85d2                	mv	a1,s4
    800016a8:	41250533          	sub	a0,a0,s2
    800016ac:	fffff097          	auipc	ra,0xfffff
    800016b0:	682080e7          	jalr	1666(ra) # 80000d2e <memmove>

    len -= n;
    800016b4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ba:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016be:	02098263          	beqz	s3,800016e2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016c2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c6:	85ca                	mv	a1,s2
    800016c8:	855a                	mv	a0,s6
    800016ca:	00000097          	auipc	ra,0x0
    800016ce:	9a2080e7          	jalr	-1630(ra) # 8000106c <walkaddr>
    if(pa0 == 0)
    800016d2:	cd01                	beqz	a0,800016ea <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016d4:	418904b3          	sub	s1,s2,s8
    800016d8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016da:	fc99f3e3          	bgeu	s3,s1,800016a0 <copyout+0x28>
    800016de:	84ce                	mv	s1,s3
    800016e0:	b7c1                	j	800016a0 <copyout+0x28>
  }
  return 0;
    800016e2:	4501                	li	a0,0
    800016e4:	a021                	j	800016ec <copyout+0x74>
    800016e6:	4501                	li	a0,0
}
    800016e8:	8082                	ret
      return -1;
    800016ea:	557d                	li	a0,-1
}
    800016ec:	60a6                	ld	ra,72(sp)
    800016ee:	6406                	ld	s0,64(sp)
    800016f0:	74e2                	ld	s1,56(sp)
    800016f2:	7942                	ld	s2,48(sp)
    800016f4:	79a2                	ld	s3,40(sp)
    800016f6:	7a02                	ld	s4,32(sp)
    800016f8:	6ae2                	ld	s5,24(sp)
    800016fa:	6b42                	ld	s6,16(sp)
    800016fc:	6ba2                	ld	s7,8(sp)
    800016fe:	6c02                	ld	s8,0(sp)
    80001700:	6161                	addi	sp,sp,80
    80001702:	8082                	ret

0000000080001704 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001704:	caa5                	beqz	a3,80001774 <copyin+0x70>
{
    80001706:	715d                	addi	sp,sp,-80
    80001708:	e486                	sd	ra,72(sp)
    8000170a:	e0a2                	sd	s0,64(sp)
    8000170c:	fc26                	sd	s1,56(sp)
    8000170e:	f84a                	sd	s2,48(sp)
    80001710:	f44e                	sd	s3,40(sp)
    80001712:	f052                	sd	s4,32(sp)
    80001714:	ec56                	sd	s5,24(sp)
    80001716:	e85a                	sd	s6,16(sp)
    80001718:	e45e                	sd	s7,8(sp)
    8000171a:	e062                	sd	s8,0(sp)
    8000171c:	0880                	addi	s0,sp,80
    8000171e:	8b2a                	mv	s6,a0
    80001720:	8a2e                	mv	s4,a1
    80001722:	8c32                	mv	s8,a2
    80001724:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001726:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001728:	6a85                	lui	s5,0x1
    8000172a:	a01d                	j	80001750 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000172c:	018505b3          	add	a1,a0,s8
    80001730:	0004861b          	sext.w	a2,s1
    80001734:	412585b3          	sub	a1,a1,s2
    80001738:	8552                	mv	a0,s4
    8000173a:	fffff097          	auipc	ra,0xfffff
    8000173e:	5f4080e7          	jalr	1524(ra) # 80000d2e <memmove>

    len -= n;
    80001742:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001746:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001748:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000174c:	02098263          	beqz	s3,80001770 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001750:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001754:	85ca                	mv	a1,s2
    80001756:	855a                	mv	a0,s6
    80001758:	00000097          	auipc	ra,0x0
    8000175c:	914080e7          	jalr	-1772(ra) # 8000106c <walkaddr>
    if(pa0 == 0)
    80001760:	cd01                	beqz	a0,80001778 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001762:	418904b3          	sub	s1,s2,s8
    80001766:	94d6                	add	s1,s1,s5
    if(n > len)
    80001768:	fc99f2e3          	bgeu	s3,s1,8000172c <copyin+0x28>
    8000176c:	84ce                	mv	s1,s3
    8000176e:	bf7d                	j	8000172c <copyin+0x28>
  }
  return 0;
    80001770:	4501                	li	a0,0
    80001772:	a021                	j	8000177a <copyin+0x76>
    80001774:	4501                	li	a0,0
}
    80001776:	8082                	ret
      return -1;
    80001778:	557d                	li	a0,-1
}
    8000177a:	60a6                	ld	ra,72(sp)
    8000177c:	6406                	ld	s0,64(sp)
    8000177e:	74e2                	ld	s1,56(sp)
    80001780:	7942                	ld	s2,48(sp)
    80001782:	79a2                	ld	s3,40(sp)
    80001784:	7a02                	ld	s4,32(sp)
    80001786:	6ae2                	ld	s5,24(sp)
    80001788:	6b42                	ld	s6,16(sp)
    8000178a:	6ba2                	ld	s7,8(sp)
    8000178c:	6c02                	ld	s8,0(sp)
    8000178e:	6161                	addi	sp,sp,80
    80001790:	8082                	ret

0000000080001792 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001792:	c6c5                	beqz	a3,8000183a <copyinstr+0xa8>
{
    80001794:	715d                	addi	sp,sp,-80
    80001796:	e486                	sd	ra,72(sp)
    80001798:	e0a2                	sd	s0,64(sp)
    8000179a:	fc26                	sd	s1,56(sp)
    8000179c:	f84a                	sd	s2,48(sp)
    8000179e:	f44e                	sd	s3,40(sp)
    800017a0:	f052                	sd	s4,32(sp)
    800017a2:	ec56                	sd	s5,24(sp)
    800017a4:	e85a                	sd	s6,16(sp)
    800017a6:	e45e                	sd	s7,8(sp)
    800017a8:	0880                	addi	s0,sp,80
    800017aa:	8a2a                	mv	s4,a0
    800017ac:	8b2e                	mv	s6,a1
    800017ae:	8bb2                	mv	s7,a2
    800017b0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017b2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017b4:	6985                	lui	s3,0x1
    800017b6:	a035                	j	800017e2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017bc:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017be:	0017b793          	seqz	a5,a5
    800017c2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6161                	addi	sp,sp,80
    800017da:	8082                	ret
    srcva = va0 + PGSIZE;
    800017dc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e0:	c8a9                	beqz	s1,80001832 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017e2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017e6:	85ca                	mv	a1,s2
    800017e8:	8552                	mv	a0,s4
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	882080e7          	jalr	-1918(ra) # 8000106c <walkaddr>
    if(pa0 == 0)
    800017f2:	c131                	beqz	a0,80001836 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017f4:	41790833          	sub	a6,s2,s7
    800017f8:	984e                	add	a6,a6,s3
    if(n > max)
    800017fa:	0104f363          	bgeu	s1,a6,80001800 <copyinstr+0x6e>
    800017fe:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001800:	955e                	add	a0,a0,s7
    80001802:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001806:	fc080be3          	beqz	a6,800017dc <copyinstr+0x4a>
    8000180a:	985a                	add	a6,a6,s6
    8000180c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000180e:	41650633          	sub	a2,a0,s6
    80001812:	14fd                	addi	s1,s1,-1
    80001814:	9b26                	add	s6,s6,s1
    80001816:	00f60733          	add	a4,a2,a5
    8000181a:	00074703          	lbu	a4,0(a4)
    8000181e:	df49                	beqz	a4,800017b8 <copyinstr+0x26>
        *dst = *p;
    80001820:	00e78023          	sb	a4,0(a5)
      --max;
    80001824:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001828:	0785                	addi	a5,a5,1
    while(n > 0){
    8000182a:	ff0796e3          	bne	a5,a6,80001816 <copyinstr+0x84>
      dst++;
    8000182e:	8b42                	mv	s6,a6
    80001830:	b775                	j	800017dc <copyinstr+0x4a>
    80001832:	4781                	li	a5,0
    80001834:	b769                	j	800017be <copyinstr+0x2c>
      return -1;
    80001836:	557d                	li	a0,-1
    80001838:	b779                	j	800017c6 <copyinstr+0x34>
  int got_null = 0;
    8000183a:	4781                	li	a5,0
  if(got_null){
    8000183c:	0017b793          	seqz	a5,a5
    80001840:	40f00533          	neg	a0,a5
}
    80001844:	8082                	ret

0000000080001846 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001846:	7139                	addi	sp,sp,-64
    80001848:	fc06                	sd	ra,56(sp)
    8000184a:	f822                	sd	s0,48(sp)
    8000184c:	f426                	sd	s1,40(sp)
    8000184e:	f04a                	sd	s2,32(sp)
    80001850:	ec4e                	sd	s3,24(sp)
    80001852:	e852                	sd	s4,16(sp)
    80001854:	e456                	sd	s5,8(sp)
    80001856:	e05a                	sd	s6,0(sp)
    80001858:	0080                	addi	s0,sp,64
    8000185a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000185c:	0000f497          	auipc	s1,0xf
    80001860:	70448493          	addi	s1,s1,1796 # 80010f60 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001864:	8b26                	mv	s6,s1
    80001866:	00006a97          	auipc	s5,0x6
    8000186a:	79aa8a93          	addi	s5,s5,1946 # 80008000 <etext>
    8000186e:	04000937          	lui	s2,0x4000
    80001872:	197d                	addi	s2,s2,-1
    80001874:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001876:	00016a17          	auipc	s4,0x16
    8000187a:	0eaa0a13          	addi	s4,s4,234 # 80017960 <tickslock>
    char *pa = kalloc();
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	268080e7          	jalr	616(ra) # 80000ae6 <kalloc>
    80001886:	862a                	mv	a2,a0
    if (pa == 0)
    80001888:	c131                	beqz	a0,800018cc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000188a:	416485b3          	sub	a1,s1,s6
    8000188e:	858d                	srai	a1,a1,0x3
    80001890:	000ab783          	ld	a5,0(s5)
    80001894:	02f585b3          	mul	a1,a1,a5
    80001898:	2585                	addiw	a1,a1,1
    8000189a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000189e:	4719                	li	a4,6
    800018a0:	6685                	lui	a3,0x1
    800018a2:	40b905b3          	sub	a1,s2,a1
    800018a6:	854e                	mv	a0,s3
    800018a8:	00000097          	auipc	ra,0x0
    800018ac:	8a6080e7          	jalr	-1882(ra) # 8000114e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018b0:	1a848493          	addi	s1,s1,424
    800018b4:	fd4495e3          	bne	s1,s4,8000187e <proc_mapstacks+0x38>
  }
}
    800018b8:	70e2                	ld	ra,56(sp)
    800018ba:	7442                	ld	s0,48(sp)
    800018bc:	74a2                	ld	s1,40(sp)
    800018be:	7902                	ld	s2,32(sp)
    800018c0:	69e2                	ld	s3,24(sp)
    800018c2:	6a42                	ld	s4,16(sp)
    800018c4:	6aa2                	ld	s5,8(sp)
    800018c6:	6b02                	ld	s6,0(sp)
    800018c8:	6121                	addi	sp,sp,64
    800018ca:	8082                	ret
      panic("kalloc");
    800018cc:	00007517          	auipc	a0,0x7
    800018d0:	91450513          	addi	a0,a0,-1772 # 800081e0 <digits+0x1a0>
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	c6a080e7          	jalr	-918(ra) # 8000053e <panic>

00000000800018dc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018dc:	7139                	addi	sp,sp,-64
    800018de:	fc06                	sd	ra,56(sp)
    800018e0:	f822                	sd	s0,48(sp)
    800018e2:	f426                	sd	s1,40(sp)
    800018e4:	f04a                	sd	s2,32(sp)
    800018e6:	ec4e                	sd	s3,24(sp)
    800018e8:	e852                	sd	s4,16(sp)
    800018ea:	e456                	sd	s5,8(sp)
    800018ec:	e05a                	sd	s6,0(sp)
    800018ee:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018f0:	00007597          	auipc	a1,0x7
    800018f4:	8f858593          	addi	a1,a1,-1800 # 800081e8 <digits+0x1a8>
    800018f8:	0000f517          	auipc	a0,0xf
    800018fc:	23850513          	addi	a0,a0,568 # 80010b30 <pid_lock>
    80001900:	fffff097          	auipc	ra,0xfffff
    80001904:	246080e7          	jalr	582(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001908:	00007597          	auipc	a1,0x7
    8000190c:	8e858593          	addi	a1,a1,-1816 # 800081f0 <digits+0x1b0>
    80001910:	0000f517          	auipc	a0,0xf
    80001914:	23850513          	addi	a0,a0,568 # 80010b48 <wait_lock>
    80001918:	fffff097          	auipc	ra,0xfffff
    8000191c:	22e080e7          	jalr	558(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001920:	0000f497          	auipc	s1,0xf
    80001924:	64048493          	addi	s1,s1,1600 # 80010f60 <proc>
  {
    initlock(&p->lock, "proc");
    80001928:	00007b17          	auipc	s6,0x7
    8000192c:	8d8b0b13          	addi	s6,s6,-1832 # 80008200 <digits+0x1c0>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001930:	8aa6                	mv	s5,s1
    80001932:	00006a17          	auipc	s4,0x6
    80001936:	6cea0a13          	addi	s4,s4,1742 # 80008000 <etext>
    8000193a:	04000937          	lui	s2,0x4000
    8000193e:	197d                	addi	s2,s2,-1
    80001940:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001942:	00016997          	auipc	s3,0x16
    80001946:	01e98993          	addi	s3,s3,30 # 80017960 <tickslock>
    initlock(&p->lock, "proc");
    8000194a:	85da                	mv	a1,s6
    8000194c:	8526                	mv	a0,s1
    8000194e:	fffff097          	auipc	ra,0xfffff
    80001952:	1f8080e7          	jalr	504(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001956:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000195a:	415487b3          	sub	a5,s1,s5
    8000195e:	878d                	srai	a5,a5,0x3
    80001960:	000a3703          	ld	a4,0(s4)
    80001964:	02e787b3          	mul	a5,a5,a4
    80001968:	2785                	addiw	a5,a5,1
    8000196a:	00d7979b          	slliw	a5,a5,0xd
    8000196e:	40f907b3          	sub	a5,s2,a5
    80001972:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001974:	1a848493          	addi	s1,s1,424
    80001978:	fd3499e3          	bne	s1,s3,8000194a <procinit+0x6e>
  }
}
    8000197c:	70e2                	ld	ra,56(sp)
    8000197e:	7442                	ld	s0,48(sp)
    80001980:	74a2                	ld	s1,40(sp)
    80001982:	7902                	ld	s2,32(sp)
    80001984:	69e2                	ld	s3,24(sp)
    80001986:	6a42                	ld	s4,16(sp)
    80001988:	6aa2                	ld	s5,8(sp)
    8000198a:	6b02                	ld	s6,0(sp)
    8000198c:	6121                	addi	sp,sp,64
    8000198e:	8082                	ret

0000000080001990 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001996:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001998:	2501                	sext.w	a0,a0
    8000199a:	6422                	ld	s0,8(sp)
    8000199c:	0141                	addi	sp,sp,16
    8000199e:	8082                	ret

00000000800019a0 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    800019a0:	1141                	addi	sp,sp,-16
    800019a2:	e422                	sd	s0,8(sp)
    800019a4:	0800                	addi	s0,sp,16
    800019a6:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019a8:	2781                	sext.w	a5,a5
    800019aa:	079e                	slli	a5,a5,0x7
  return c;
}
    800019ac:	0000f517          	auipc	a0,0xf
    800019b0:	1b450513          	addi	a0,a0,436 # 80010b60 <cpus>
    800019b4:	953e                	add	a0,a0,a5
    800019b6:	6422                	ld	s0,8(sp)
    800019b8:	0141                	addi	sp,sp,16
    800019ba:	8082                	ret

00000000800019bc <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019bc:	1101                	addi	sp,sp,-32
    800019be:	ec06                	sd	ra,24(sp)
    800019c0:	e822                	sd	s0,16(sp)
    800019c2:	e426                	sd	s1,8(sp)
    800019c4:	1000                	addi	s0,sp,32
  push_off();
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	1c4080e7          	jalr	452(ra) # 80000b8a <push_off>
    800019ce:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019d0:	2781                	sext.w	a5,a5
    800019d2:	079e                	slli	a5,a5,0x7
    800019d4:	0000f717          	auipc	a4,0xf
    800019d8:	15c70713          	addi	a4,a4,348 # 80010b30 <pid_lock>
    800019dc:	97ba                	add	a5,a5,a4
    800019de:	7b84                	ld	s1,48(a5)
  pop_off();
    800019e0:	fffff097          	auipc	ra,0xfffff
    800019e4:	24a080e7          	jalr	586(ra) # 80000c2a <pop_off>
  return p;
}
    800019e8:	8526                	mv	a0,s1
    800019ea:	60e2                	ld	ra,24(sp)
    800019ec:	6442                	ld	s0,16(sp)
    800019ee:	64a2                	ld	s1,8(sp)
    800019f0:	6105                	addi	sp,sp,32
    800019f2:	8082                	ret

00000000800019f4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019f4:	1141                	addi	sp,sp,-16
    800019f6:	e406                	sd	ra,8(sp)
    800019f8:	e022                	sd	s0,0(sp)
    800019fa:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019fc:	00000097          	auipc	ra,0x0
    80001a00:	fc0080e7          	jalr	-64(ra) # 800019bc <myproc>
    80001a04:	fffff097          	auipc	ra,0xfffff
    80001a08:	286080e7          	jalr	646(ra) # 80000c8a <release>

  if (first)
    80001a0c:	00007797          	auipc	a5,0x7
    80001a10:	e347a783          	lw	a5,-460(a5) # 80008840 <first.0>
    80001a14:	eb89                	bnez	a5,80001a26 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a16:	00001097          	auipc	ra,0x1
    80001a1a:	f76080e7          	jalr	-138(ra) # 8000298c <usertrapret>
}
    80001a1e:	60a2                	ld	ra,8(sp)
    80001a20:	6402                	ld	s0,0(sp)
    80001a22:	0141                	addi	sp,sp,16
    80001a24:	8082                	ret
    first = 0;
    80001a26:	00007797          	auipc	a5,0x7
    80001a2a:	e007ad23          	sw	zero,-486(a5) # 80008840 <first.0>
    fsinit(ROOTDEV);
    80001a2e:	4505                	li	a0,1
    80001a30:	00002097          	auipc	ra,0x2
    80001a34:	52e080e7          	jalr	1326(ra) # 80003f5e <fsinit>
    80001a38:	bff9                	j	80001a16 <forkret+0x22>

0000000080001a3a <allocpid>:
{
    80001a3a:	1101                	addi	sp,sp,-32
    80001a3c:	ec06                	sd	ra,24(sp)
    80001a3e:	e822                	sd	s0,16(sp)
    80001a40:	e426                	sd	s1,8(sp)
    80001a42:	e04a                	sd	s2,0(sp)
    80001a44:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a46:	0000f917          	auipc	s2,0xf
    80001a4a:	0ea90913          	addi	s2,s2,234 # 80010b30 <pid_lock>
    80001a4e:	854a                	mv	a0,s2
    80001a50:	fffff097          	auipc	ra,0xfffff
    80001a54:	186080e7          	jalr	390(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a58:	00007797          	auipc	a5,0x7
    80001a5c:	dec78793          	addi	a5,a5,-532 # 80008844 <nextpid>
    80001a60:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a62:	0014871b          	addiw	a4,s1,1
    80001a66:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a68:	854a                	mv	a0,s2
    80001a6a:	fffff097          	auipc	ra,0xfffff
    80001a6e:	220080e7          	jalr	544(ra) # 80000c8a <release>
}
    80001a72:	8526                	mv	a0,s1
    80001a74:	60e2                	ld	ra,24(sp)
    80001a76:	6442                	ld	s0,16(sp)
    80001a78:	64a2                	ld	s1,8(sp)
    80001a7a:	6902                	ld	s2,0(sp)
    80001a7c:	6105                	addi	sp,sp,32
    80001a7e:	8082                	ret

0000000080001a80 <proc_pagetable>:
{
    80001a80:	1101                	addi	sp,sp,-32
    80001a82:	ec06                	sd	ra,24(sp)
    80001a84:	e822                	sd	s0,16(sp)
    80001a86:	e426                	sd	s1,8(sp)
    80001a88:	e04a                	sd	s2,0(sp)
    80001a8a:	1000                	addi	s0,sp,32
    80001a8c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a8e:	00000097          	auipc	ra,0x0
    80001a92:	8aa080e7          	jalr	-1878(ra) # 80001338 <uvmcreate>
    80001a96:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a98:	c121                	beqz	a0,80001ad8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a9a:	4729                	li	a4,10
    80001a9c:	00005697          	auipc	a3,0x5
    80001aa0:	56468693          	addi	a3,a3,1380 # 80007000 <_trampoline>
    80001aa4:	6605                	lui	a2,0x1
    80001aa6:	040005b7          	lui	a1,0x4000
    80001aaa:	15fd                	addi	a1,a1,-1
    80001aac:	05b2                	slli	a1,a1,0xc
    80001aae:	fffff097          	auipc	ra,0xfffff
    80001ab2:	600080e7          	jalr	1536(ra) # 800010ae <mappages>
    80001ab6:	02054863          	bltz	a0,80001ae6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aba:	4719                	li	a4,6
    80001abc:	05893683          	ld	a3,88(s2)
    80001ac0:	6605                	lui	a2,0x1
    80001ac2:	020005b7          	lui	a1,0x2000
    80001ac6:	15fd                	addi	a1,a1,-1
    80001ac8:	05b6                	slli	a1,a1,0xd
    80001aca:	8526                	mv	a0,s1
    80001acc:	fffff097          	auipc	ra,0xfffff
    80001ad0:	5e2080e7          	jalr	1506(ra) # 800010ae <mappages>
    80001ad4:	02054163          	bltz	a0,80001af6 <proc_pagetable+0x76>
}
    80001ad8:	8526                	mv	a0,s1
    80001ada:	60e2                	ld	ra,24(sp)
    80001adc:	6442                	ld	s0,16(sp)
    80001ade:	64a2                	ld	s1,8(sp)
    80001ae0:	6902                	ld	s2,0(sp)
    80001ae2:	6105                	addi	sp,sp,32
    80001ae4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ae6:	4581                	li	a1,0
    80001ae8:	8526                	mv	a0,s1
    80001aea:	00000097          	auipc	ra,0x0
    80001aee:	a52080e7          	jalr	-1454(ra) # 8000153c <uvmfree>
    return 0;
    80001af2:	4481                	li	s1,0
    80001af4:	b7d5                	j	80001ad8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001af6:	4681                	li	a3,0
    80001af8:	4605                	li	a2,1
    80001afa:	040005b7          	lui	a1,0x4000
    80001afe:	15fd                	addi	a1,a1,-1
    80001b00:	05b2                	slli	a1,a1,0xc
    80001b02:	8526                	mv	a0,s1
    80001b04:	fffff097          	auipc	ra,0xfffff
    80001b08:	770080e7          	jalr	1904(ra) # 80001274 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b0c:	4581                	li	a1,0
    80001b0e:	8526                	mv	a0,s1
    80001b10:	00000097          	auipc	ra,0x0
    80001b14:	a2c080e7          	jalr	-1492(ra) # 8000153c <uvmfree>
    return 0;
    80001b18:	4481                	li	s1,0
    80001b1a:	bf7d                	j	80001ad8 <proc_pagetable+0x58>

0000000080001b1c <proc_freepagetable>:
{
    80001b1c:	1101                	addi	sp,sp,-32
    80001b1e:	ec06                	sd	ra,24(sp)
    80001b20:	e822                	sd	s0,16(sp)
    80001b22:	e426                	sd	s1,8(sp)
    80001b24:	e04a                	sd	s2,0(sp)
    80001b26:	1000                	addi	s0,sp,32
    80001b28:	84aa                	mv	s1,a0
    80001b2a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b2c:	4681                	li	a3,0
    80001b2e:	4605                	li	a2,1
    80001b30:	040005b7          	lui	a1,0x4000
    80001b34:	15fd                	addi	a1,a1,-1
    80001b36:	05b2                	slli	a1,a1,0xc
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	73c080e7          	jalr	1852(ra) # 80001274 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b40:	4681                	li	a3,0
    80001b42:	4605                	li	a2,1
    80001b44:	020005b7          	lui	a1,0x2000
    80001b48:	15fd                	addi	a1,a1,-1
    80001b4a:	05b6                	slli	a1,a1,0xd
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	fffff097          	auipc	ra,0xfffff
    80001b52:	726080e7          	jalr	1830(ra) # 80001274 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b56:	85ca                	mv	a1,s2
    80001b58:	8526                	mv	a0,s1
    80001b5a:	00000097          	auipc	ra,0x0
    80001b5e:	9e2080e7          	jalr	-1566(ra) # 8000153c <uvmfree>
}
    80001b62:	60e2                	ld	ra,24(sp)
    80001b64:	6442                	ld	s0,16(sp)
    80001b66:	64a2                	ld	s1,8(sp)
    80001b68:	6902                	ld	s2,0(sp)
    80001b6a:	6105                	addi	sp,sp,32
    80001b6c:	8082                	ret

0000000080001b6e <freeproc>:
{
    80001b6e:	1101                	addi	sp,sp,-32
    80001b70:	ec06                	sd	ra,24(sp)
    80001b72:	e822                	sd	s0,16(sp)
    80001b74:	e426                	sd	s1,8(sp)
    80001b76:	1000                	addi	s0,sp,32
    80001b78:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b7a:	6d28                	ld	a0,88(a0)
    80001b7c:	c509                	beqz	a0,80001b86 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b7e:	fffff097          	auipc	ra,0xfffff
    80001b82:	e6c080e7          	jalr	-404(ra) # 800009ea <kfree>
  if (p->past_trap_frame)
    80001b86:	1984b503          	ld	a0,408(s1)
    80001b8a:	c509                	beqz	a0,80001b94 <freeproc+0x26>
    kfree((void *)p->past_trap_frame);
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	e5e080e7          	jalr	-418(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b94:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b98:	68a8                	ld	a0,80(s1)
    80001b9a:	c511                	beqz	a0,80001ba6 <freeproc+0x38>
    proc_freepagetable(p->pagetable, p->sz);
    80001b9c:	64ac                	ld	a1,72(s1)
    80001b9e:	00000097          	auipc	ra,0x0
    80001ba2:	f7e080e7          	jalr	-130(ra) # 80001b1c <proc_freepagetable>
  p->pagetable = 0;
    80001ba6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001baa:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bae:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bb2:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bb6:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bba:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bbe:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bc2:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc6:	0004ac23          	sw	zero,24(s1)
  p->ticks_when_switch = ticks;
    80001bca:	00007797          	auipc	a5,0x7
    80001bce:	cf67a783          	lw	a5,-778(a5) # 800088c0 <ticks>
    80001bd2:	16f4ac23          	sw	a5,376(s1)
  p->no_of_ticks = 0; 
    80001bd6:	1804a023          	sw	zero,384(s1)
  p->passed_ticks = 0; 
    80001bda:	1804a823          	sw	zero,400(s1)
}
    80001bde:	60e2                	ld	ra,24(sp)
    80001be0:	6442                	ld	s0,16(sp)
    80001be2:	64a2                	ld	s1,8(sp)
    80001be4:	6105                	addi	sp,sp,32
    80001be6:	8082                	ret

0000000080001be8 <allocproc>:
{
    80001be8:	1101                	addi	sp,sp,-32
    80001bea:	ec06                	sd	ra,24(sp)
    80001bec:	e822                	sd	s0,16(sp)
    80001bee:	e426                	sd	s1,8(sp)
    80001bf0:	e04a                	sd	s2,0(sp)
    80001bf2:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bf4:	0000f497          	auipc	s1,0xf
    80001bf8:	36c48493          	addi	s1,s1,876 # 80010f60 <proc>
    80001bfc:	00016917          	auipc	s2,0x16
    80001c00:	d6490913          	addi	s2,s2,-668 # 80017960 <tickslock>
    acquire(&p->lock);
    80001c04:	8526                	mv	a0,s1
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	fd0080e7          	jalr	-48(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001c0e:	4c9c                	lw	a5,24(s1)
    80001c10:	cf81                	beqz	a5,80001c28 <allocproc+0x40>
      release(&p->lock);
    80001c12:	8526                	mv	a0,s1
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	076080e7          	jalr	118(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c1c:	1a848493          	addi	s1,s1,424
    80001c20:	ff2492e3          	bne	s1,s2,80001c04 <allocproc+0x1c>
  return 0;
    80001c24:	4481                	li	s1,0
    80001c26:	a8bd                	j	80001ca4 <allocproc+0xbc>
  p->pid = allocpid();
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	e12080e7          	jalr	-494(ra) # 80001a3a <allocpid>
    80001c30:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c32:	4785                	li	a5,1
    80001c34:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	eb0080e7          	jalr	-336(ra) # 80000ae6 <kalloc>
    80001c3e:	892a                	mv	s2,a0
    80001c40:	eca8                	sd	a0,88(s1)
    80001c42:	c925                	beqz	a0,80001cb2 <allocproc+0xca>
  p->pagetable = proc_pagetable(p);
    80001c44:	8526                	mv	a0,s1
    80001c46:	00000097          	auipc	ra,0x0
    80001c4a:	e3a080e7          	jalr	-454(ra) # 80001a80 <proc_pagetable>
    80001c4e:	892a                	mv	s2,a0
    80001c50:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c52:	cd25                	beqz	a0,80001cca <allocproc+0xe2>
  memset(&p->context, 0, sizeof(p->context));
    80001c54:	07000613          	li	a2,112
    80001c58:	4581                	li	a1,0
    80001c5a:	06048513          	addi	a0,s1,96
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	074080e7          	jalr	116(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c66:	00000797          	auipc	a5,0x0
    80001c6a:	d8e78793          	addi	a5,a5,-626 # 800019f4 <forkret>
    80001c6e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c70:	60bc                	ld	a5,64(s1)
    80001c72:	6705                	lui	a4,0x1
    80001c74:	97ba                	add	a5,a5,a4
    80001c76:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c78:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c7c:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c80:	00007797          	auipc	a5,0x7
    80001c84:	c407a783          	lw	a5,-960(a5) # 800088c0 <ticks>
    80001c88:	16f4a623          	sw	a5,364(s1)
  p->passed_ticks = 0;
    80001c8c:	1804a823          	sw	zero,400(s1)
  p->flag_check_handler = 0;
    80001c90:	1a04a023          	sw	zero,416(s1)
  p->queue = 0;
    80001c94:	1604aa23          	sw	zero,372(s1)
  p->ticks_when_switch = 0;
    80001c98:	1604ac23          	sw	zero,376(s1)
  p->wait = 0;
    80001c9c:	1604ae23          	sw	zero,380(s1)
  p->new_flag = 0;
    80001ca0:	1a04a223          	sw	zero,420(s1)
}
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	60e2                	ld	ra,24(sp)
    80001ca8:	6442                	ld	s0,16(sp)
    80001caa:	64a2                	ld	s1,8(sp)
    80001cac:	6902                	ld	s2,0(sp)
    80001cae:	6105                	addi	sp,sp,32
    80001cb0:	8082                	ret
    freeproc(p);
    80001cb2:	8526                	mv	a0,s1
    80001cb4:	00000097          	auipc	ra,0x0
    80001cb8:	eba080e7          	jalr	-326(ra) # 80001b6e <freeproc>
    release(&p->lock);
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	fcc080e7          	jalr	-52(ra) # 80000c8a <release>
    return 0;
    80001cc6:	84ca                	mv	s1,s2
    80001cc8:	bff1                	j	80001ca4 <allocproc+0xbc>
    freeproc(p);
    80001cca:	8526                	mv	a0,s1
    80001ccc:	00000097          	auipc	ra,0x0
    80001cd0:	ea2080e7          	jalr	-350(ra) # 80001b6e <freeproc>
    release(&p->lock);
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	fb4080e7          	jalr	-76(ra) # 80000c8a <release>
    return 0;
    80001cde:	84ca                	mv	s1,s2
    80001ce0:	b7d1                	j	80001ca4 <allocproc+0xbc>

0000000080001ce2 <userinit>:
{
    80001ce2:	1101                	addi	sp,sp,-32
    80001ce4:	ec06                	sd	ra,24(sp)
    80001ce6:	e822                	sd	s0,16(sp)
    80001ce8:	e426                	sd	s1,8(sp)
    80001cea:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cec:	00000097          	auipc	ra,0x0
    80001cf0:	efc080e7          	jalr	-260(ra) # 80001be8 <allocproc>
    80001cf4:	84aa                	mv	s1,a0
  initproc = p;
    80001cf6:	00007797          	auipc	a5,0x7
    80001cfa:	bca7b123          	sd	a0,-1086(a5) # 800088b8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cfe:	03400613          	li	a2,52
    80001d02:	00007597          	auipc	a1,0x7
    80001d06:	b4e58593          	addi	a1,a1,-1202 # 80008850 <initcode>
    80001d0a:	6928                	ld	a0,80(a0)
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	65a080e7          	jalr	1626(ra) # 80001366 <uvmfirst>
  p->sz = PGSIZE;
    80001d14:	6785                	lui	a5,0x1
    80001d16:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d18:	6cb8                	ld	a4,88(s1)
    80001d1a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d1e:	6cb8                	ld	a4,88(s1)
    80001d20:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d22:	4641                	li	a2,16
    80001d24:	00006597          	auipc	a1,0x6
    80001d28:	4e458593          	addi	a1,a1,1252 # 80008208 <digits+0x1c8>
    80001d2c:	15848513          	addi	a0,s1,344
    80001d30:	fffff097          	auipc	ra,0xfffff
    80001d34:	0ec080e7          	jalr	236(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d38:	00006517          	auipc	a0,0x6
    80001d3c:	4e050513          	addi	a0,a0,1248 # 80008218 <digits+0x1d8>
    80001d40:	00003097          	auipc	ra,0x3
    80001d44:	c40080e7          	jalr	-960(ra) # 80004980 <namei>
    80001d48:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d4c:	478d                	li	a5,3
    80001d4e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d50:	8526                	mv	a0,s1
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	f38080e7          	jalr	-200(ra) # 80000c8a <release>
}
    80001d5a:	60e2                	ld	ra,24(sp)
    80001d5c:	6442                	ld	s0,16(sp)
    80001d5e:	64a2                	ld	s1,8(sp)
    80001d60:	6105                	addi	sp,sp,32
    80001d62:	8082                	ret

0000000080001d64 <growproc>:
{
    80001d64:	1101                	addi	sp,sp,-32
    80001d66:	ec06                	sd	ra,24(sp)
    80001d68:	e822                	sd	s0,16(sp)
    80001d6a:	e426                	sd	s1,8(sp)
    80001d6c:	e04a                	sd	s2,0(sp)
    80001d6e:	1000                	addi	s0,sp,32
    80001d70:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d72:	00000097          	auipc	ra,0x0
    80001d76:	c4a080e7          	jalr	-950(ra) # 800019bc <myproc>
    80001d7a:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d7c:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d7e:	01204c63          	bgtz	s2,80001d96 <growproc+0x32>
  else if (n < 0)
    80001d82:	02094663          	bltz	s2,80001dae <growproc+0x4a>
  p->sz = sz;
    80001d86:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d88:	4501                	li	a0,0
}
    80001d8a:	60e2                	ld	ra,24(sp)
    80001d8c:	6442                	ld	s0,16(sp)
    80001d8e:	64a2                	ld	s1,8(sp)
    80001d90:	6902                	ld	s2,0(sp)
    80001d92:	6105                	addi	sp,sp,32
    80001d94:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d96:	4691                	li	a3,4
    80001d98:	00b90633          	add	a2,s2,a1
    80001d9c:	6928                	ld	a0,80(a0)
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	682080e7          	jalr	1666(ra) # 80001420 <uvmalloc>
    80001da6:	85aa                	mv	a1,a0
    80001da8:	fd79                	bnez	a0,80001d86 <growproc+0x22>
      return -1;
    80001daa:	557d                	li	a0,-1
    80001dac:	bff9                	j	80001d8a <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dae:	00b90633          	add	a2,s2,a1
    80001db2:	6928                	ld	a0,80(a0)
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	624080e7          	jalr	1572(ra) # 800013d8 <uvmdealloc>
    80001dbc:	85aa                	mv	a1,a0
    80001dbe:	b7e1                	j	80001d86 <growproc+0x22>

0000000080001dc0 <fork>:
{
    80001dc0:	7139                	addi	sp,sp,-64
    80001dc2:	fc06                	sd	ra,56(sp)
    80001dc4:	f822                	sd	s0,48(sp)
    80001dc6:	f426                	sd	s1,40(sp)
    80001dc8:	f04a                	sd	s2,32(sp)
    80001dca:	ec4e                	sd	s3,24(sp)
    80001dcc:	e852                	sd	s4,16(sp)
    80001dce:	e456                	sd	s5,8(sp)
    80001dd0:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dd2:	00000097          	auipc	ra,0x0
    80001dd6:	bea080e7          	jalr	-1046(ra) # 800019bc <myproc>
    80001dda:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001ddc:	00000097          	auipc	ra,0x0
    80001de0:	e0c080e7          	jalr	-500(ra) # 80001be8 <allocproc>
    80001de4:	10050c63          	beqz	a0,80001efc <fork+0x13c>
    80001de8:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dea:	048ab603          	ld	a2,72(s5)
    80001dee:	692c                	ld	a1,80(a0)
    80001df0:	050ab503          	ld	a0,80(s5)
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	780080e7          	jalr	1920(ra) # 80001574 <uvmcopy>
    80001dfc:	04054863          	bltz	a0,80001e4c <fork+0x8c>
  np->sz = p->sz;
    80001e00:	048ab783          	ld	a5,72(s5)
    80001e04:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e08:	058ab683          	ld	a3,88(s5)
    80001e0c:	87b6                	mv	a5,a3
    80001e0e:	058a3703          	ld	a4,88(s4)
    80001e12:	12068693          	addi	a3,a3,288
    80001e16:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e1a:	6788                	ld	a0,8(a5)
    80001e1c:	6b8c                	ld	a1,16(a5)
    80001e1e:	6f90                	ld	a2,24(a5)
    80001e20:	01073023          	sd	a6,0(a4)
    80001e24:	e708                	sd	a0,8(a4)
    80001e26:	eb0c                	sd	a1,16(a4)
    80001e28:	ef10                	sd	a2,24(a4)
    80001e2a:	02078793          	addi	a5,a5,32
    80001e2e:	02070713          	addi	a4,a4,32
    80001e32:	fed792e3          	bne	a5,a3,80001e16 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e36:	058a3783          	ld	a5,88(s4)
    80001e3a:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e3e:	0d0a8493          	addi	s1,s5,208
    80001e42:	0d0a0913          	addi	s2,s4,208
    80001e46:	150a8993          	addi	s3,s5,336
    80001e4a:	a00d                	j	80001e6c <fork+0xac>
    freeproc(np);
    80001e4c:	8552                	mv	a0,s4
    80001e4e:	00000097          	auipc	ra,0x0
    80001e52:	d20080e7          	jalr	-736(ra) # 80001b6e <freeproc>
    release(&np->lock);
    80001e56:	8552                	mv	a0,s4
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	e32080e7          	jalr	-462(ra) # 80000c8a <release>
    return -1;
    80001e60:	597d                	li	s2,-1
    80001e62:	a059                	j	80001ee8 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e64:	04a1                	addi	s1,s1,8
    80001e66:	0921                	addi	s2,s2,8
    80001e68:	01348b63          	beq	s1,s3,80001e7e <fork+0xbe>
    if (p->ofile[i])
    80001e6c:	6088                	ld	a0,0(s1)
    80001e6e:	d97d                	beqz	a0,80001e64 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e70:	00003097          	auipc	ra,0x3
    80001e74:	1a6080e7          	jalr	422(ra) # 80005016 <filedup>
    80001e78:	00a93023          	sd	a0,0(s2)
    80001e7c:	b7e5                	j	80001e64 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e7e:	150ab503          	ld	a0,336(s5)
    80001e82:	00002097          	auipc	ra,0x2
    80001e86:	31a080e7          	jalr	794(ra) # 8000419c <idup>
    80001e8a:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e8e:	4641                	li	a2,16
    80001e90:	158a8593          	addi	a1,s5,344
    80001e94:	158a0513          	addi	a0,s4,344
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	f84080e7          	jalr	-124(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001ea0:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001ea4:	8552                	mv	a0,s4
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	de4080e7          	jalr	-540(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001eae:	0000f497          	auipc	s1,0xf
    80001eb2:	c9a48493          	addi	s1,s1,-870 # 80010b48 <wait_lock>
    80001eb6:	8526                	mv	a0,s1
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	d1e080e7          	jalr	-738(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001ec0:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001ec4:	8526                	mv	a0,s1
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	dc4080e7          	jalr	-572(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001ece:	8552                	mv	a0,s4
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	d06080e7          	jalr	-762(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001ed8:	478d                	li	a5,3
    80001eda:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ede:	8552                	mv	a0,s4
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	daa080e7          	jalr	-598(ra) # 80000c8a <release>
}
    80001ee8:	854a                	mv	a0,s2
    80001eea:	70e2                	ld	ra,56(sp)
    80001eec:	7442                	ld	s0,48(sp)
    80001eee:	74a2                	ld	s1,40(sp)
    80001ef0:	7902                	ld	s2,32(sp)
    80001ef2:	69e2                	ld	s3,24(sp)
    80001ef4:	6a42                	ld	s4,16(sp)
    80001ef6:	6aa2                	ld	s5,8(sp)
    80001ef8:	6121                	addi	sp,sp,64
    80001efa:	8082                	ret
    return -1;
    80001efc:	597d                	li	s2,-1
    80001efe:	b7ed                	j	80001ee8 <fork+0x128>

0000000080001f00 <scheduler>:
{
    80001f00:	715d                	addi	sp,sp,-80
    80001f02:	e486                	sd	ra,72(sp)
    80001f04:	e0a2                	sd	s0,64(sp)
    80001f06:	fc26                	sd	s1,56(sp)
    80001f08:	f84a                	sd	s2,48(sp)
    80001f0a:	f44e                	sd	s3,40(sp)
    80001f0c:	f052                	sd	s4,32(sp)
    80001f0e:	ec56                	sd	s5,24(sp)
    80001f10:	e85a                	sd	s6,16(sp)
    80001f12:	e45e                	sd	s7,8(sp)
    80001f14:	e062                	sd	s8,0(sp)
    80001f16:	0880                	addi	s0,sp,80
    80001f18:	8792                	mv	a5,tp
  int id = r_tp();
    80001f1a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f1c:	00779c13          	slli	s8,a5,0x7
    80001f20:	0000f717          	auipc	a4,0xf
    80001f24:	c1070713          	addi	a4,a4,-1008 # 80010b30 <pid_lock>
    80001f28:	9762                	add	a4,a4,s8
    80001f2a:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &highest_priority_process->context);
    80001f2e:	0000f717          	auipc	a4,0xf
    80001f32:	c3a70713          	addi	a4,a4,-966 # 80010b68 <cpus+0x8>
    80001f36:	9c3a                	add	s8,s8,a4
    for (p = proc; p < &proc[NPROC]; p++)
    80001f38:	00016917          	auipc	s2,0x16
    80001f3c:	a2890913          	addi	s2,s2,-1496 # 80017960 <tickslock>
          if (p->new_flag == 1)
    80001f40:	4a05                	li	s4,1
      c->proc = highest_priority_process;
    80001f42:	079e                	slli	a5,a5,0x7
    80001f44:	0000fb17          	auipc	s6,0xf
    80001f48:	becb0b13          	addi	s6,s6,-1044 # 80010b30 <pid_lock>
    80001f4c:	9b3e                	add	s6,s6,a5
    80001f4e:	a2a5                	j	800020b6 <scheduler+0x1b6>
        release(&p->lock);
    80001f50:	8526                	mv	a0,s1
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	d38080e7          	jalr	-712(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f5a:	1a848493          	addi	s1,s1,424
    80001f5e:	03248a63          	beq	s1,s2,80001f92 <scheduler+0x92>
      acquire(&p->lock);
    80001f62:	8526                	mv	a0,s1
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	c72080e7          	jalr	-910(ra) # 80000bd6 <acquire>
      if (p->queue == 0 && p->state == RUNNABLE)
    80001f6c:	1744a783          	lw	a5,372(s1)
    80001f70:	f3e5                	bnez	a5,80001f50 <scheduler+0x50>
    80001f72:	4c9c                	lw	a5,24(s1)
    80001f74:	fd379ee3          	bne	a5,s3,80001f50 <scheduler+0x50>
        release(&p->lock);
    80001f78:	8526                	mv	a0,s1
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	d10080e7          	jalr	-752(ra) # 80000c8a <release>
      int l = highest_priority_process->queue;
    80001f82:	1744a603          	lw	a2,372(s1)
      int flag111 = 0;
    80001f86:	85de                	mv	a1,s7
      for (p = proc; p < &proc[NPROC]; p++)
    80001f88:	0000f797          	auipc	a5,0xf
    80001f8c:	fd878793          	addi	a5,a5,-40 # 80010f60 <proc>
    80001f90:	a0e9                	j	8000205a <scheduler+0x15a>
      for (p = proc; p < &proc[NPROC]; p++)
    80001f92:	0000f497          	auipc	s1,0xf
    80001f96:	fce48493          	addi	s1,s1,-50 # 80010f60 <proc>
    80001f9a:	a811                	j	80001fae <scheduler+0xae>
          release(&p->lock);
    80001f9c:	8526                	mv	a0,s1
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	cec080e7          	jalr	-788(ra) # 80000c8a <release>
      for (p = proc; p < &proc[NPROC]; p++)
    80001fa6:	1a848493          	addi	s1,s1,424
    80001faa:	03248463          	beq	s1,s2,80001fd2 <scheduler+0xd2>
        acquire(&p->lock);
    80001fae:	8526                	mv	a0,s1
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	c26080e7          	jalr	-986(ra) # 80000bd6 <acquire>
        if (p->queue == 1 && p->state == RUNNABLE)
    80001fb8:	1744a783          	lw	a5,372(s1)
    80001fbc:	ff4790e3          	bne	a5,s4,80001f9c <scheduler+0x9c>
    80001fc0:	4c9c                	lw	a5,24(s1)
    80001fc2:	fd379de3          	bne	a5,s3,80001f9c <scheduler+0x9c>
          release(&p->lock);
    80001fc6:	8526                	mv	a0,s1
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	cc2080e7          	jalr	-830(ra) # 80000c8a <release>
      if (flag1 == 0)
    80001fd0:	bf4d                	j	80001f82 <scheduler+0x82>
        for (p = proc; p < &proc[NPROC]; p++)
    80001fd2:	0000f497          	auipc	s1,0xf
    80001fd6:	f8e48493          	addi	s1,s1,-114 # 80010f60 <proc>
    80001fda:	a811                	j	80001fee <scheduler+0xee>
            release(&p->lock);
    80001fdc:	8526                	mv	a0,s1
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	cac080e7          	jalr	-852(ra) # 80000c8a <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80001fe6:	1a848493          	addi	s1,s1,424
    80001fea:	03248463          	beq	s1,s2,80002012 <scheduler+0x112>
          acquire(&p->lock);
    80001fee:	8526                	mv	a0,s1
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	be6080e7          	jalr	-1050(ra) # 80000bd6 <acquire>
          if (p->queue == 2 && p->state == RUNNABLE)
    80001ff8:	1744a783          	lw	a5,372(s1)
    80001ffc:	ff5790e3          	bne	a5,s5,80001fdc <scheduler+0xdc>
    80002000:	4c9c                	lw	a5,24(s1)
    80002002:	fd379de3          	bne	a5,s3,80001fdc <scheduler+0xdc>
            release(&p->lock);
    80002006:	8526                	mv	a0,s1
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	c82080e7          	jalr	-894(ra) # 80000c8a <release>
        if (flag2 == 0)
    80002010:	bf8d                	j	80001f82 <scheduler+0x82>
          for (p = proc; p < &proc[NPROC]; p++)
    80002012:	0000f497          	auipc	s1,0xf
    80002016:	f4e48493          	addi	s1,s1,-178 # 80010f60 <proc>
    8000201a:	a811                	j	8000202e <scheduler+0x12e>
              release(&p->lock);
    8000201c:	8526                	mv	a0,s1
    8000201e:	fffff097          	auipc	ra,0xfffff
    80002022:	c6c080e7          	jalr	-916(ra) # 80000c8a <release>
          for (p = proc; p < &proc[NPROC]; p++)
    80002026:	1a848493          	addi	s1,s1,424
    8000202a:	09248963          	beq	s1,s2,800020bc <scheduler+0x1bc>
            acquire(&p->lock);
    8000202e:	8526                	mv	a0,s1
    80002030:	fffff097          	auipc	ra,0xfffff
    80002034:	ba6080e7          	jalr	-1114(ra) # 80000bd6 <acquire>
            if (p->queue == 3 && p->state == RUNNABLE)
    80002038:	1744a783          	lw	a5,372(s1)
    8000203c:	ff3790e3          	bne	a5,s3,8000201c <scheduler+0x11c>
    80002040:	4c9c                	lw	a5,24(s1)
    80002042:	fd379de3          	bne	a5,s3,8000201c <scheduler+0x11c>
              release(&p->lock);
    80002046:	8526                	mv	a0,s1
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	c42080e7          	jalr	-958(ra) # 80000c8a <release>
              break;
    80002050:	bf0d                	j	80001f82 <scheduler+0x82>
      for (p = proc; p < &proc[NPROC]; p++)
    80002052:	1a878793          	addi	a5,a5,424
    80002056:	03278563          	beq	a5,s2,80002080 <scheduler+0x180>
        if (p->state == RUNNABLE)
    8000205a:	4f98                	lw	a4,24(a5)
    8000205c:	ff371be3          	bne	a4,s3,80002052 <scheduler+0x152>
          if (p->new_flag == 1)
    80002060:	1a47a703          	lw	a4,420(a5)
    80002064:	ff4717e3          	bne	a4,s4,80002052 <scheduler+0x152>
            if (l == m)
    80002068:	1747a683          	lw	a3,372(a5)
    8000206c:	fec693e3          	bne	a3,a2,80002052 <scheduler+0x152>
      for (p = proc; p < &proc[NPROC]; p++)
    80002070:	1a878693          	addi	a3,a5,424
    80002074:	0d268163          	beq	a3,s2,80002136 <scheduler+0x236>
              flag111 = 1;
    80002078:	85ba                	mv	a1,a4
      for (p = proc; p < &proc[NPROC]; p++)
    8000207a:	84be                	mv	s1,a5
    8000207c:	87b6                	mv	a5,a3
    8000207e:	bff1                	j	8000205a <scheduler+0x15a>
      if (flag111 == 0)
    80002080:	c9a9                	beqz	a1,800020d2 <scheduler+0x1d2>
    if (highest_priority_process != 0)
    80002082:	cc8d                	beqz	s1,800020bc <scheduler+0x1bc>
      acquire(&highest_priority_process->lock);
    80002084:	8526                	mv	a0,s1
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	b50080e7          	jalr	-1200(ra) # 80000bd6 <acquire>
      highest_priority_process->state = RUNNING;
    8000208e:	4791                	li	a5,4
    80002090:	cc9c                	sw	a5,24(s1)
      highest_priority_process->wait = 0;
    80002092:	1604ae23          	sw	zero,380(s1)
      c->proc = highest_priority_process;
    80002096:	029b3823          	sd	s1,48(s6)
      swtch(&c->context, &highest_priority_process->context);
    8000209a:	06048593          	addi	a1,s1,96
    8000209e:	8562                	mv	a0,s8
    800020a0:	00001097          	auipc	ra,0x1
    800020a4:	82a080e7          	jalr	-2006(ra) # 800028ca <swtch>
      c->proc = 0;
    800020a8:	020b3823          	sd	zero,48(s6)
      release(&highest_priority_process->lock);
    800020ac:	8526                	mv	a0,s1
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	bdc080e7          	jalr	-1060(ra) # 80000c8a <release>
      if (p->queue == 0 && p->state == RUNNABLE)
    800020b6:	498d                	li	s3,3
      int flag111 = 0;
    800020b8:	4b81                	li	s7,0
          if (p->queue == 2 && p->state == RUNNABLE)
    800020ba:	4a89                	li	s5,2
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020bc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020c0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020c4:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    800020c8:	0000f497          	auipc	s1,0xf
    800020cc:	e9848493          	addi	s1,s1,-360 # 80010f60 <proc>
    800020d0:	bd49                	j	80001f62 <scheduler+0x62>
        for (p = proc; p < &proc[NPROC]; p++)
    800020d2:	0000f797          	auipc	a5,0xf
    800020d6:	e8e78793          	addi	a5,a5,-370 # 80010f60 <proc>
    800020da:	a039                	j	800020e8 <scheduler+0x1e8>
    800020dc:	0007059b          	sext.w	a1,a4
    800020e0:	1a878793          	addi	a5,a5,424
    800020e4:	03278163          	beq	a5,s2,80002106 <scheduler+0x206>
          if (p->state == RUNNABLE)
    800020e8:	4f98                	lw	a4,24(a5)
    800020ea:	ff371be3          	bne	a4,s3,800020e0 <scheduler+0x1e0>
            if (l == m)
    800020ee:	1747a703          	lw	a4,372(a5)
    800020f2:	fec717e3          	bne	a4,a2,800020e0 <scheduler+0x1e0>
              if (max_time <= p->wait)
    800020f6:	17c7a703          	lw	a4,380(a5)
    800020fa:	0007069b          	sext.w	a3,a4
    800020fe:	fcb6dfe3          	bge	a3,a1,800020dc <scheduler+0x1dc>
    80002102:	872e                	mv	a4,a1
    80002104:	bfe1                	j	800020dc <scheduler+0x1dc>
        for (p = proc; p < &proc[NPROC]; p++)
    80002106:	0000f797          	auipc	a5,0xf
    8000210a:	e5a78793          	addi	a5,a5,-422 # 80010f60 <proc>
    8000210e:	a029                	j	80002118 <scheduler+0x218>
    80002110:	1a878793          	addi	a5,a5,424
    80002114:	f72787e3          	beq	a5,s2,80002082 <scheduler+0x182>
          if (p->state == RUNNABLE)
    80002118:	4f98                	lw	a4,24(a5)
    8000211a:	ff371be3          	bne	a4,s3,80002110 <scheduler+0x210>
            if (l == m)
    8000211e:	1744a683          	lw	a3,372(s1)
    80002122:	1747a703          	lw	a4,372(a5)
    80002126:	fee695e3          	bne	a3,a4,80002110 <scheduler+0x210>
              if (p->wait == max_time)
    8000212a:	17c7a703          	lw	a4,380(a5)
    8000212e:	feb711e3          	bne	a4,a1,80002110 <scheduler+0x210>
    80002132:	84be                	mv	s1,a5
    80002134:	bf81                	j	80002084 <scheduler+0x184>
      for (p = proc; p < &proc[NPROC]; p++)
    80002136:	84be                	mv	s1,a5
    80002138:	b7b1                	j	80002084 <scheduler+0x184>

000000008000213a <sched>:
{
    8000213a:	7179                	addi	sp,sp,-48
    8000213c:	f406                	sd	ra,40(sp)
    8000213e:	f022                	sd	s0,32(sp)
    80002140:	ec26                	sd	s1,24(sp)
    80002142:	e84a                	sd	s2,16(sp)
    80002144:	e44e                	sd	s3,8(sp)
    80002146:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002148:	00000097          	auipc	ra,0x0
    8000214c:	874080e7          	jalr	-1932(ra) # 800019bc <myproc>
    80002150:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	a0a080e7          	jalr	-1526(ra) # 80000b5c <holding>
    8000215a:	c93d                	beqz	a0,800021d0 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000215c:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000215e:	2781                	sext.w	a5,a5
    80002160:	079e                	slli	a5,a5,0x7
    80002162:	0000f717          	auipc	a4,0xf
    80002166:	9ce70713          	addi	a4,a4,-1586 # 80010b30 <pid_lock>
    8000216a:	97ba                	add	a5,a5,a4
    8000216c:	0a87a703          	lw	a4,168(a5)
    80002170:	4785                	li	a5,1
    80002172:	06f71763          	bne	a4,a5,800021e0 <sched+0xa6>
  if (p->state == RUNNING)
    80002176:	4c98                	lw	a4,24(s1)
    80002178:	4791                	li	a5,4
    8000217a:	06f70b63          	beq	a4,a5,800021f0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000217e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002182:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002184:	efb5                	bnez	a5,80002200 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002186:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002188:	0000f917          	auipc	s2,0xf
    8000218c:	9a890913          	addi	s2,s2,-1624 # 80010b30 <pid_lock>
    80002190:	2781                	sext.w	a5,a5
    80002192:	079e                	slli	a5,a5,0x7
    80002194:	97ca                	add	a5,a5,s2
    80002196:	0ac7a983          	lw	s3,172(a5)
    8000219a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000219c:	2781                	sext.w	a5,a5
    8000219e:	079e                	slli	a5,a5,0x7
    800021a0:	0000f597          	auipc	a1,0xf
    800021a4:	9c858593          	addi	a1,a1,-1592 # 80010b68 <cpus+0x8>
    800021a8:	95be                	add	a1,a1,a5
    800021aa:	06048513          	addi	a0,s1,96
    800021ae:	00000097          	auipc	ra,0x0
    800021b2:	71c080e7          	jalr	1820(ra) # 800028ca <swtch>
    800021b6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021b8:	2781                	sext.w	a5,a5
    800021ba:	079e                	slli	a5,a5,0x7
    800021bc:	97ca                	add	a5,a5,s2
    800021be:	0b37a623          	sw	s3,172(a5)
}
    800021c2:	70a2                	ld	ra,40(sp)
    800021c4:	7402                	ld	s0,32(sp)
    800021c6:	64e2                	ld	s1,24(sp)
    800021c8:	6942                	ld	s2,16(sp)
    800021ca:	69a2                	ld	s3,8(sp)
    800021cc:	6145                	addi	sp,sp,48
    800021ce:	8082                	ret
    panic("sched p->lock");
    800021d0:	00006517          	auipc	a0,0x6
    800021d4:	05050513          	addi	a0,a0,80 # 80008220 <digits+0x1e0>
    800021d8:	ffffe097          	auipc	ra,0xffffe
    800021dc:	366080e7          	jalr	870(ra) # 8000053e <panic>
    panic("sched locks");
    800021e0:	00006517          	auipc	a0,0x6
    800021e4:	05050513          	addi	a0,a0,80 # 80008230 <digits+0x1f0>
    800021e8:	ffffe097          	auipc	ra,0xffffe
    800021ec:	356080e7          	jalr	854(ra) # 8000053e <panic>
    panic("sched running");
    800021f0:	00006517          	auipc	a0,0x6
    800021f4:	05050513          	addi	a0,a0,80 # 80008240 <digits+0x200>
    800021f8:	ffffe097          	auipc	ra,0xffffe
    800021fc:	346080e7          	jalr	838(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002200:	00006517          	auipc	a0,0x6
    80002204:	05050513          	addi	a0,a0,80 # 80008250 <digits+0x210>
    80002208:	ffffe097          	auipc	ra,0xffffe
    8000220c:	336080e7          	jalr	822(ra) # 8000053e <panic>

0000000080002210 <yield>:
{
    80002210:	1101                	addi	sp,sp,-32
    80002212:	ec06                	sd	ra,24(sp)
    80002214:	e822                	sd	s0,16(sp)
    80002216:	e426                	sd	s1,8(sp)
    80002218:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	7a2080e7          	jalr	1954(ra) # 800019bc <myproc>
    80002222:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	9b2080e7          	jalr	-1614(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    8000222c:	478d                	li	a5,3
    8000222e:	cc9c                	sw	a5,24(s1)
  sched();
    80002230:	00000097          	auipc	ra,0x0
    80002234:	f0a080e7          	jalr	-246(ra) # 8000213a <sched>
  release(&p->lock);
    80002238:	8526                	mv	a0,s1
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	a50080e7          	jalr	-1456(ra) # 80000c8a <release>
}
    80002242:	60e2                	ld	ra,24(sp)
    80002244:	6442                	ld	s0,16(sp)
    80002246:	64a2                	ld	s1,8(sp)
    80002248:	6105                	addi	sp,sp,32
    8000224a:	8082                	ret

000000008000224c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000224c:	7179                	addi	sp,sp,-48
    8000224e:	f406                	sd	ra,40(sp)
    80002250:	f022                	sd	s0,32(sp)
    80002252:	ec26                	sd	s1,24(sp)
    80002254:	e84a                	sd	s2,16(sp)
    80002256:	e44e                	sd	s3,8(sp)
    80002258:	1800                	addi	s0,sp,48
    8000225a:	89aa                	mv	s3,a0
    8000225c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	75e080e7          	jalr	1886(ra) # 800019bc <myproc>
    80002266:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	96e080e7          	jalr	-1682(ra) # 80000bd6 <acquire>
  release(lk);
    80002270:	854a                	mv	a0,s2
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	a18080e7          	jalr	-1512(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    8000227a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000227e:	4789                	li	a5,2
    80002280:	cc9c                	sw	a5,24(s1)

  sched();
    80002282:	00000097          	auipc	ra,0x0
    80002286:	eb8080e7          	jalr	-328(ra) # 8000213a <sched>

  // Tidy up.
  p->chan = 0;
    8000228a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
  acquire(lk);
    80002298:	854a                	mv	a0,s2
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	93c080e7          	jalr	-1732(ra) # 80000bd6 <acquire>
}
    800022a2:	70a2                	ld	ra,40(sp)
    800022a4:	7402                	ld	s0,32(sp)
    800022a6:	64e2                	ld	s1,24(sp)
    800022a8:	6942                	ld	s2,16(sp)
    800022aa:	69a2                	ld	s3,8(sp)
    800022ac:	6145                	addi	sp,sp,48
    800022ae:	8082                	ret

00000000800022b0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800022b0:	7139                	addi	sp,sp,-64
    800022b2:	fc06                	sd	ra,56(sp)
    800022b4:	f822                	sd	s0,48(sp)
    800022b6:	f426                	sd	s1,40(sp)
    800022b8:	f04a                	sd	s2,32(sp)
    800022ba:	ec4e                	sd	s3,24(sp)
    800022bc:	e852                	sd	s4,16(sp)
    800022be:	e456                	sd	s5,8(sp)
    800022c0:	0080                	addi	s0,sp,64
    800022c2:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800022c4:	0000f497          	auipc	s1,0xf
    800022c8:	c9c48493          	addi	s1,s1,-868 # 80010f60 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800022cc:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800022ce:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800022d0:	00015917          	auipc	s2,0x15
    800022d4:	69090913          	addi	s2,s2,1680 # 80017960 <tickslock>
    800022d8:	a811                	j	800022ec <wakeup+0x3c>
      }
      release(&p->lock);
    800022da:	8526                	mv	a0,s1
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	9ae080e7          	jalr	-1618(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022e4:	1a848493          	addi	s1,s1,424
    800022e8:	03248663          	beq	s1,s2,80002314 <wakeup+0x64>
    if (p != myproc())
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	6d0080e7          	jalr	1744(ra) # 800019bc <myproc>
    800022f4:	fea488e3          	beq	s1,a0,800022e4 <wakeup+0x34>
      acquire(&p->lock);
    800022f8:	8526                	mv	a0,s1
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	8dc080e7          	jalr	-1828(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002302:	4c9c                	lw	a5,24(s1)
    80002304:	fd379be3          	bne	a5,s3,800022da <wakeup+0x2a>
    80002308:	709c                	ld	a5,32(s1)
    8000230a:	fd4798e3          	bne	a5,s4,800022da <wakeup+0x2a>
        p->state = RUNNABLE;
    8000230e:	0154ac23          	sw	s5,24(s1)
    80002312:	b7e1                	j	800022da <wakeup+0x2a>
    }
  }
}
    80002314:	70e2                	ld	ra,56(sp)
    80002316:	7442                	ld	s0,48(sp)
    80002318:	74a2                	ld	s1,40(sp)
    8000231a:	7902                	ld	s2,32(sp)
    8000231c:	69e2                	ld	s3,24(sp)
    8000231e:	6a42                	ld	s4,16(sp)
    80002320:	6aa2                	ld	s5,8(sp)
    80002322:	6121                	addi	sp,sp,64
    80002324:	8082                	ret

0000000080002326 <reparent>:
{
    80002326:	7179                	addi	sp,sp,-48
    80002328:	f406                	sd	ra,40(sp)
    8000232a:	f022                	sd	s0,32(sp)
    8000232c:	ec26                	sd	s1,24(sp)
    8000232e:	e84a                	sd	s2,16(sp)
    80002330:	e44e                	sd	s3,8(sp)
    80002332:	e052                	sd	s4,0(sp)
    80002334:	1800                	addi	s0,sp,48
    80002336:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002338:	0000f497          	auipc	s1,0xf
    8000233c:	c2848493          	addi	s1,s1,-984 # 80010f60 <proc>
      pp->parent = initproc;
    80002340:	00006a17          	auipc	s4,0x6
    80002344:	578a0a13          	addi	s4,s4,1400 # 800088b8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002348:	00015997          	auipc	s3,0x15
    8000234c:	61898993          	addi	s3,s3,1560 # 80017960 <tickslock>
    80002350:	a029                	j	8000235a <reparent+0x34>
    80002352:	1a848493          	addi	s1,s1,424
    80002356:	01348d63          	beq	s1,s3,80002370 <reparent+0x4a>
    if (pp->parent == p)
    8000235a:	7c9c                	ld	a5,56(s1)
    8000235c:	ff279be3          	bne	a5,s2,80002352 <reparent+0x2c>
      pp->parent = initproc;
    80002360:	000a3503          	ld	a0,0(s4)
    80002364:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002366:	00000097          	auipc	ra,0x0
    8000236a:	f4a080e7          	jalr	-182(ra) # 800022b0 <wakeup>
    8000236e:	b7d5                	j	80002352 <reparent+0x2c>
}
    80002370:	70a2                	ld	ra,40(sp)
    80002372:	7402                	ld	s0,32(sp)
    80002374:	64e2                	ld	s1,24(sp)
    80002376:	6942                	ld	s2,16(sp)
    80002378:	69a2                	ld	s3,8(sp)
    8000237a:	6a02                	ld	s4,0(sp)
    8000237c:	6145                	addi	sp,sp,48
    8000237e:	8082                	ret

0000000080002380 <exit>:
{
    80002380:	7179                	addi	sp,sp,-48
    80002382:	f406                	sd	ra,40(sp)
    80002384:	f022                	sd	s0,32(sp)
    80002386:	ec26                	sd	s1,24(sp)
    80002388:	e84a                	sd	s2,16(sp)
    8000238a:	e44e                	sd	s3,8(sp)
    8000238c:	e052                	sd	s4,0(sp)
    8000238e:	1800                	addi	s0,sp,48
    80002390:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	62a080e7          	jalr	1578(ra) # 800019bc <myproc>
    8000239a:	89aa                	mv	s3,a0
  if (p == initproc)
    8000239c:	00006797          	auipc	a5,0x6
    800023a0:	51c7b783          	ld	a5,1308(a5) # 800088b8 <initproc>
    800023a4:	0d050493          	addi	s1,a0,208
    800023a8:	15050913          	addi	s2,a0,336
    800023ac:	02a79363          	bne	a5,a0,800023d2 <exit+0x52>
    panic("init exiting");
    800023b0:	00006517          	auipc	a0,0x6
    800023b4:	eb850513          	addi	a0,a0,-328 # 80008268 <digits+0x228>
    800023b8:	ffffe097          	auipc	ra,0xffffe
    800023bc:	186080e7          	jalr	390(ra) # 8000053e <panic>
      fileclose(f);
    800023c0:	00003097          	auipc	ra,0x3
    800023c4:	ca8080e7          	jalr	-856(ra) # 80005068 <fileclose>
      p->ofile[fd] = 0;
    800023c8:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800023cc:	04a1                	addi	s1,s1,8
    800023ce:	01248563          	beq	s1,s2,800023d8 <exit+0x58>
    if (p->ofile[fd])
    800023d2:	6088                	ld	a0,0(s1)
    800023d4:	f575                	bnez	a0,800023c0 <exit+0x40>
    800023d6:	bfdd                	j	800023cc <exit+0x4c>
  begin_op();
    800023d8:	00002097          	auipc	ra,0x2
    800023dc:	7c4080e7          	jalr	1988(ra) # 80004b9c <begin_op>
  iput(p->cwd);
    800023e0:	1509b503          	ld	a0,336(s3)
    800023e4:	00002097          	auipc	ra,0x2
    800023e8:	fb0080e7          	jalr	-80(ra) # 80004394 <iput>
  end_op();
    800023ec:	00003097          	auipc	ra,0x3
    800023f0:	830080e7          	jalr	-2000(ra) # 80004c1c <end_op>
  p->cwd = 0;
    800023f4:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023f8:	0000e497          	auipc	s1,0xe
    800023fc:	75048493          	addi	s1,s1,1872 # 80010b48 <wait_lock>
    80002400:	8526                	mv	a0,s1
    80002402:	ffffe097          	auipc	ra,0xffffe
    80002406:	7d4080e7          	jalr	2004(ra) # 80000bd6 <acquire>
  reparent(p);
    8000240a:	854e                	mv	a0,s3
    8000240c:	00000097          	auipc	ra,0x0
    80002410:	f1a080e7          	jalr	-230(ra) # 80002326 <reparent>
  wakeup(p->parent);
    80002414:	0389b503          	ld	a0,56(s3)
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	e98080e7          	jalr	-360(ra) # 800022b0 <wakeup>
  acquire(&p->lock);
    80002420:	854e                	mv	a0,s3
    80002422:	ffffe097          	auipc	ra,0xffffe
    80002426:	7b4080e7          	jalr	1972(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000242a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000242e:	4795                	li	a5,5
    80002430:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002434:	00006797          	auipc	a5,0x6
    80002438:	48c7a783          	lw	a5,1164(a5) # 800088c0 <ticks>
    8000243c:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	848080e7          	jalr	-1976(ra) # 80000c8a <release>
  sched();
    8000244a:	00000097          	auipc	ra,0x0
    8000244e:	cf0080e7          	jalr	-784(ra) # 8000213a <sched>
  panic("zombie exit");
    80002452:	00006517          	auipc	a0,0x6
    80002456:	e2650513          	addi	a0,a0,-474 # 80008278 <digits+0x238>
    8000245a:	ffffe097          	auipc	ra,0xffffe
    8000245e:	0e4080e7          	jalr	228(ra) # 8000053e <panic>

0000000080002462 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002462:	7179                	addi	sp,sp,-48
    80002464:	f406                	sd	ra,40(sp)
    80002466:	f022                	sd	s0,32(sp)
    80002468:	ec26                	sd	s1,24(sp)
    8000246a:	e84a                	sd	s2,16(sp)
    8000246c:	e44e                	sd	s3,8(sp)
    8000246e:	1800                	addi	s0,sp,48
    80002470:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002472:	0000f497          	auipc	s1,0xf
    80002476:	aee48493          	addi	s1,s1,-1298 # 80010f60 <proc>
    8000247a:	00015997          	auipc	s3,0x15
    8000247e:	4e698993          	addi	s3,s3,1254 # 80017960 <tickslock>
  {
    acquire(&p->lock);
    80002482:	8526                	mv	a0,s1
    80002484:	ffffe097          	auipc	ra,0xffffe
    80002488:	752080e7          	jalr	1874(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    8000248c:	589c                	lw	a5,48(s1)
    8000248e:	01278d63          	beq	a5,s2,800024a8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002492:	8526                	mv	a0,s1
    80002494:	ffffe097          	auipc	ra,0xffffe
    80002498:	7f6080e7          	jalr	2038(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000249c:	1a848493          	addi	s1,s1,424
    800024a0:	ff3491e3          	bne	s1,s3,80002482 <kill+0x20>
  }
  return -1;
    800024a4:	557d                	li	a0,-1
    800024a6:	a829                	j	800024c0 <kill+0x5e>
      p->killed = 1;
    800024a8:	4785                	li	a5,1
    800024aa:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800024ac:	4c98                	lw	a4,24(s1)
    800024ae:	4789                	li	a5,2
    800024b0:	00f70f63          	beq	a4,a5,800024ce <kill+0x6c>
      release(&p->lock);
    800024b4:	8526                	mv	a0,s1
    800024b6:	ffffe097          	auipc	ra,0xffffe
    800024ba:	7d4080e7          	jalr	2004(ra) # 80000c8a <release>
      return 0;
    800024be:	4501                	li	a0,0
}
    800024c0:	70a2                	ld	ra,40(sp)
    800024c2:	7402                	ld	s0,32(sp)
    800024c4:	64e2                	ld	s1,24(sp)
    800024c6:	6942                	ld	s2,16(sp)
    800024c8:	69a2                	ld	s3,8(sp)
    800024ca:	6145                	addi	sp,sp,48
    800024cc:	8082                	ret
        p->state = RUNNABLE;
    800024ce:	478d                	li	a5,3
    800024d0:	cc9c                	sw	a5,24(s1)
    800024d2:	b7cd                	j	800024b4 <kill+0x52>

00000000800024d4 <setkilled>:

void setkilled(struct proc *p)
{
    800024d4:	1101                	addi	sp,sp,-32
    800024d6:	ec06                	sd	ra,24(sp)
    800024d8:	e822                	sd	s0,16(sp)
    800024da:	e426                	sd	s1,8(sp)
    800024dc:	1000                	addi	s0,sp,32
    800024de:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	6f6080e7          	jalr	1782(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800024e8:	4785                	li	a5,1
    800024ea:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800024ec:	8526                	mv	a0,s1
    800024ee:	ffffe097          	auipc	ra,0xffffe
    800024f2:	79c080e7          	jalr	1948(ra) # 80000c8a <release>
}
    800024f6:	60e2                	ld	ra,24(sp)
    800024f8:	6442                	ld	s0,16(sp)
    800024fa:	64a2                	ld	s1,8(sp)
    800024fc:	6105                	addi	sp,sp,32
    800024fe:	8082                	ret

0000000080002500 <killed>:

int killed(struct proc *p)
{
    80002500:	1101                	addi	sp,sp,-32
    80002502:	ec06                	sd	ra,24(sp)
    80002504:	e822                	sd	s0,16(sp)
    80002506:	e426                	sd	s1,8(sp)
    80002508:	e04a                	sd	s2,0(sp)
    8000250a:	1000                	addi	s0,sp,32
    8000250c:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000250e:	ffffe097          	auipc	ra,0xffffe
    80002512:	6c8080e7          	jalr	1736(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002516:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000251a:	8526                	mv	a0,s1
    8000251c:	ffffe097          	auipc	ra,0xffffe
    80002520:	76e080e7          	jalr	1902(ra) # 80000c8a <release>
  return k;
}
    80002524:	854a                	mv	a0,s2
    80002526:	60e2                	ld	ra,24(sp)
    80002528:	6442                	ld	s0,16(sp)
    8000252a:	64a2                	ld	s1,8(sp)
    8000252c:	6902                	ld	s2,0(sp)
    8000252e:	6105                	addi	sp,sp,32
    80002530:	8082                	ret

0000000080002532 <wait>:
{
    80002532:	715d                	addi	sp,sp,-80
    80002534:	e486                	sd	ra,72(sp)
    80002536:	e0a2                	sd	s0,64(sp)
    80002538:	fc26                	sd	s1,56(sp)
    8000253a:	f84a                	sd	s2,48(sp)
    8000253c:	f44e                	sd	s3,40(sp)
    8000253e:	f052                	sd	s4,32(sp)
    80002540:	ec56                	sd	s5,24(sp)
    80002542:	e85a                	sd	s6,16(sp)
    80002544:	e45e                	sd	s7,8(sp)
    80002546:	e062                	sd	s8,0(sp)
    80002548:	0880                	addi	s0,sp,80
    8000254a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	470080e7          	jalr	1136(ra) # 800019bc <myproc>
    80002554:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002556:	0000e517          	auipc	a0,0xe
    8000255a:	5f250513          	addi	a0,a0,1522 # 80010b48 <wait_lock>
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	678080e7          	jalr	1656(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002566:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002568:	4a15                	li	s4,5
        havekids = 1;
    8000256a:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000256c:	00015997          	auipc	s3,0x15
    80002570:	3f498993          	addi	s3,s3,1012 # 80017960 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002574:	0000ec17          	auipc	s8,0xe
    80002578:	5d4c0c13          	addi	s8,s8,1492 # 80010b48 <wait_lock>
    havekids = 0;
    8000257c:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000257e:	0000f497          	auipc	s1,0xf
    80002582:	9e248493          	addi	s1,s1,-1566 # 80010f60 <proc>
    80002586:	a0bd                	j	800025f4 <wait+0xc2>
          pid = pp->pid;
    80002588:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000258c:	000b0e63          	beqz	s6,800025a8 <wait+0x76>
    80002590:	4691                	li	a3,4
    80002592:	02c48613          	addi	a2,s1,44
    80002596:	85da                	mv	a1,s6
    80002598:	05093503          	ld	a0,80(s2)
    8000259c:	fffff097          	auipc	ra,0xfffff
    800025a0:	0dc080e7          	jalr	220(ra) # 80001678 <copyout>
    800025a4:	02054563          	bltz	a0,800025ce <wait+0x9c>
          freeproc(pp);
    800025a8:	8526                	mv	a0,s1
    800025aa:	fffff097          	auipc	ra,0xfffff
    800025ae:	5c4080e7          	jalr	1476(ra) # 80001b6e <freeproc>
          release(&pp->lock);
    800025b2:	8526                	mv	a0,s1
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	6d6080e7          	jalr	1750(ra) # 80000c8a <release>
          release(&wait_lock);
    800025bc:	0000e517          	auipc	a0,0xe
    800025c0:	58c50513          	addi	a0,a0,1420 # 80010b48 <wait_lock>
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	6c6080e7          	jalr	1734(ra) # 80000c8a <release>
          return pid;
    800025cc:	a0b5                	j	80002638 <wait+0x106>
            release(&pp->lock);
    800025ce:	8526                	mv	a0,s1
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	6ba080e7          	jalr	1722(ra) # 80000c8a <release>
            release(&wait_lock);
    800025d8:	0000e517          	auipc	a0,0xe
    800025dc:	57050513          	addi	a0,a0,1392 # 80010b48 <wait_lock>
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	6aa080e7          	jalr	1706(ra) # 80000c8a <release>
            return -1;
    800025e8:	59fd                	li	s3,-1
    800025ea:	a0b9                	j	80002638 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025ec:	1a848493          	addi	s1,s1,424
    800025f0:	03348463          	beq	s1,s3,80002618 <wait+0xe6>
      if (pp->parent == p)
    800025f4:	7c9c                	ld	a5,56(s1)
    800025f6:	ff279be3          	bne	a5,s2,800025ec <wait+0xba>
        acquire(&pp->lock);
    800025fa:	8526                	mv	a0,s1
    800025fc:	ffffe097          	auipc	ra,0xffffe
    80002600:	5da080e7          	jalr	1498(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002604:	4c9c                	lw	a5,24(s1)
    80002606:	f94781e3          	beq	a5,s4,80002588 <wait+0x56>
        release(&pp->lock);
    8000260a:	8526                	mv	a0,s1
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	67e080e7          	jalr	1662(ra) # 80000c8a <release>
        havekids = 1;
    80002614:	8756                	mv	a4,s5
    80002616:	bfd9                	j	800025ec <wait+0xba>
    if (!havekids || killed(p))
    80002618:	c719                	beqz	a4,80002626 <wait+0xf4>
    8000261a:	854a                	mv	a0,s2
    8000261c:	00000097          	auipc	ra,0x0
    80002620:	ee4080e7          	jalr	-284(ra) # 80002500 <killed>
    80002624:	c51d                	beqz	a0,80002652 <wait+0x120>
      release(&wait_lock);
    80002626:	0000e517          	auipc	a0,0xe
    8000262a:	52250513          	addi	a0,a0,1314 # 80010b48 <wait_lock>
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	65c080e7          	jalr	1628(ra) # 80000c8a <release>
      return -1;
    80002636:	59fd                	li	s3,-1
}
    80002638:	854e                	mv	a0,s3
    8000263a:	60a6                	ld	ra,72(sp)
    8000263c:	6406                	ld	s0,64(sp)
    8000263e:	74e2                	ld	s1,56(sp)
    80002640:	7942                	ld	s2,48(sp)
    80002642:	79a2                	ld	s3,40(sp)
    80002644:	7a02                	ld	s4,32(sp)
    80002646:	6ae2                	ld	s5,24(sp)
    80002648:	6b42                	ld	s6,16(sp)
    8000264a:	6ba2                	ld	s7,8(sp)
    8000264c:	6c02                	ld	s8,0(sp)
    8000264e:	6161                	addi	sp,sp,80
    80002650:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002652:	85e2                	mv	a1,s8
    80002654:	854a                	mv	a0,s2
    80002656:	00000097          	auipc	ra,0x0
    8000265a:	bf6080e7          	jalr	-1034(ra) # 8000224c <sleep>
    havekids = 0;
    8000265e:	bf39                	j	8000257c <wait+0x4a>

0000000080002660 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002660:	7179                	addi	sp,sp,-48
    80002662:	f406                	sd	ra,40(sp)
    80002664:	f022                	sd	s0,32(sp)
    80002666:	ec26                	sd	s1,24(sp)
    80002668:	e84a                	sd	s2,16(sp)
    8000266a:	e44e                	sd	s3,8(sp)
    8000266c:	e052                	sd	s4,0(sp)
    8000266e:	1800                	addi	s0,sp,48
    80002670:	84aa                	mv	s1,a0
    80002672:	892e                	mv	s2,a1
    80002674:	89b2                	mv	s3,a2
    80002676:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002678:	fffff097          	auipc	ra,0xfffff
    8000267c:	344080e7          	jalr	836(ra) # 800019bc <myproc>
  if (user_dst)
    80002680:	c08d                	beqz	s1,800026a2 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002682:	86d2                	mv	a3,s4
    80002684:	864e                	mv	a2,s3
    80002686:	85ca                	mv	a1,s2
    80002688:	6928                	ld	a0,80(a0)
    8000268a:	fffff097          	auipc	ra,0xfffff
    8000268e:	fee080e7          	jalr	-18(ra) # 80001678 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002692:	70a2                	ld	ra,40(sp)
    80002694:	7402                	ld	s0,32(sp)
    80002696:	64e2                	ld	s1,24(sp)
    80002698:	6942                	ld	s2,16(sp)
    8000269a:	69a2                	ld	s3,8(sp)
    8000269c:	6a02                	ld	s4,0(sp)
    8000269e:	6145                	addi	sp,sp,48
    800026a0:	8082                	ret
    memmove((char *)dst, src, len);
    800026a2:	000a061b          	sext.w	a2,s4
    800026a6:	85ce                	mv	a1,s3
    800026a8:	854a                	mv	a0,s2
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	684080e7          	jalr	1668(ra) # 80000d2e <memmove>
    return 0;
    800026b2:	8526                	mv	a0,s1
    800026b4:	bff9                	j	80002692 <either_copyout+0x32>

00000000800026b6 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026b6:	7179                	addi	sp,sp,-48
    800026b8:	f406                	sd	ra,40(sp)
    800026ba:	f022                	sd	s0,32(sp)
    800026bc:	ec26                	sd	s1,24(sp)
    800026be:	e84a                	sd	s2,16(sp)
    800026c0:	e44e                	sd	s3,8(sp)
    800026c2:	e052                	sd	s4,0(sp)
    800026c4:	1800                	addi	s0,sp,48
    800026c6:	892a                	mv	s2,a0
    800026c8:	84ae                	mv	s1,a1
    800026ca:	89b2                	mv	s3,a2
    800026cc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026ce:	fffff097          	auipc	ra,0xfffff
    800026d2:	2ee080e7          	jalr	750(ra) # 800019bc <myproc>
  if (user_src)
    800026d6:	c08d                	beqz	s1,800026f8 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800026d8:	86d2                	mv	a3,s4
    800026da:	864e                	mv	a2,s3
    800026dc:	85ca                	mv	a1,s2
    800026de:	6928                	ld	a0,80(a0)
    800026e0:	fffff097          	auipc	ra,0xfffff
    800026e4:	024080e7          	jalr	36(ra) # 80001704 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800026e8:	70a2                	ld	ra,40(sp)
    800026ea:	7402                	ld	s0,32(sp)
    800026ec:	64e2                	ld	s1,24(sp)
    800026ee:	6942                	ld	s2,16(sp)
    800026f0:	69a2                	ld	s3,8(sp)
    800026f2:	6a02                	ld	s4,0(sp)
    800026f4:	6145                	addi	sp,sp,48
    800026f6:	8082                	ret
    memmove(dst, (char *)src, len);
    800026f8:	000a061b          	sext.w	a2,s4
    800026fc:	85ce                	mv	a1,s3
    800026fe:	854a                	mv	a0,s2
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	62e080e7          	jalr	1582(ra) # 80000d2e <memmove>
    return 0;
    80002708:	8526                	mv	a0,s1
    8000270a:	bff9                	j	800026e8 <either_copyin+0x32>

000000008000270c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000270c:	1141                	addi	sp,sp,-16
    8000270e:	e422                	sd	s0,8(sp)
    80002710:	0800                	addi	s0,sp,16
    80002712:	04000793          	li	a5,64
  //     [ZOMBIE] "zombie"};
  struct proc *p;
  // char *state;

  // printf("\n");
  for (p = proc; p < &proc[NPROC]; p++)
    80002716:	17fd                	addi	a5,a5,-1
    80002718:	fffd                	bnez	a5,80002716 <procdump+0xa>
      // printf("%d %s %d %d\n", p->pid, p->name, p->queue, ticks);
      // printf("%d %d %d", ticks,p->pid,p->queue);
      // printf("\n");
    }
  }
}
    8000271a:	6422                	ld	s0,8(sp)
    8000271c:	0141                	addi	sp,sp,16
    8000271e:	8082                	ret

0000000080002720 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002720:	711d                	addi	sp,sp,-96
    80002722:	ec86                	sd	ra,88(sp)
    80002724:	e8a2                	sd	s0,80(sp)
    80002726:	e4a6                	sd	s1,72(sp)
    80002728:	e0ca                	sd	s2,64(sp)
    8000272a:	fc4e                	sd	s3,56(sp)
    8000272c:	f852                	sd	s4,48(sp)
    8000272e:	f456                	sd	s5,40(sp)
    80002730:	f05a                	sd	s6,32(sp)
    80002732:	ec5e                	sd	s7,24(sp)
    80002734:	e862                	sd	s8,16(sp)
    80002736:	e466                	sd	s9,8(sp)
    80002738:	e06a                	sd	s10,0(sp)
    8000273a:	1080                	addi	s0,sp,96
    8000273c:	8b2a                	mv	s6,a0
    8000273e:	8bae                	mv	s7,a1
    80002740:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002742:	fffff097          	auipc	ra,0xfffff
    80002746:	27a080e7          	jalr	634(ra) # 800019bc <myproc>
    8000274a:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000274c:	0000e517          	auipc	a0,0xe
    80002750:	3fc50513          	addi	a0,a0,1020 # 80010b48 <wait_lock>
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	482080e7          	jalr	1154(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000275c:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000275e:	4a15                	li	s4,5
        havekids = 1;
    80002760:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002762:	00015997          	auipc	s3,0x15
    80002766:	1fe98993          	addi	s3,s3,510 # 80017960 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000276a:	0000ed17          	auipc	s10,0xe
    8000276e:	3ded0d13          	addi	s10,s10,990 # 80010b48 <wait_lock>
    havekids = 0;
    80002772:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002774:	0000e497          	auipc	s1,0xe
    80002778:	7ec48493          	addi	s1,s1,2028 # 80010f60 <proc>
    8000277c:	a059                	j	80002802 <waitx+0xe2>
          pid = np->pid;
    8000277e:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002782:	1684a703          	lw	a4,360(s1)
    80002786:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000278a:	16c4a783          	lw	a5,364(s1)
    8000278e:	9f3d                	addw	a4,a4,a5
    80002790:	1704a783          	lw	a5,368(s1)
    80002794:	9f99                	subw	a5,a5,a4
    80002796:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7f83b070>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000279a:	000b0e63          	beqz	s6,800027b6 <waitx+0x96>
    8000279e:	4691                	li	a3,4
    800027a0:	02c48613          	addi	a2,s1,44
    800027a4:	85da                	mv	a1,s6
    800027a6:	05093503          	ld	a0,80(s2)
    800027aa:	fffff097          	auipc	ra,0xfffff
    800027ae:	ece080e7          	jalr	-306(ra) # 80001678 <copyout>
    800027b2:	02054563          	bltz	a0,800027dc <waitx+0xbc>
          freeproc(np);
    800027b6:	8526                	mv	a0,s1
    800027b8:	fffff097          	auipc	ra,0xfffff
    800027bc:	3b6080e7          	jalr	950(ra) # 80001b6e <freeproc>
          release(&np->lock);
    800027c0:	8526                	mv	a0,s1
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	4c8080e7          	jalr	1224(ra) # 80000c8a <release>
          release(&wait_lock);
    800027ca:	0000e517          	auipc	a0,0xe
    800027ce:	37e50513          	addi	a0,a0,894 # 80010b48 <wait_lock>
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	4b8080e7          	jalr	1208(ra) # 80000c8a <release>
          return pid;
    800027da:	a09d                	j	80002840 <waitx+0x120>
            release(&np->lock);
    800027dc:	8526                	mv	a0,s1
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	4ac080e7          	jalr	1196(ra) # 80000c8a <release>
            release(&wait_lock);
    800027e6:	0000e517          	auipc	a0,0xe
    800027ea:	36250513          	addi	a0,a0,866 # 80010b48 <wait_lock>
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	49c080e7          	jalr	1180(ra) # 80000c8a <release>
            return -1;
    800027f6:	59fd                	li	s3,-1
    800027f8:	a0a1                	j	80002840 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800027fa:	1a848493          	addi	s1,s1,424
    800027fe:	03348463          	beq	s1,s3,80002826 <waitx+0x106>
      if (np->parent == p)
    80002802:	7c9c                	ld	a5,56(s1)
    80002804:	ff279be3          	bne	a5,s2,800027fa <waitx+0xda>
        acquire(&np->lock);
    80002808:	8526                	mv	a0,s1
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	3cc080e7          	jalr	972(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    80002812:	4c9c                	lw	a5,24(s1)
    80002814:	f74785e3          	beq	a5,s4,8000277e <waitx+0x5e>
        release(&np->lock);
    80002818:	8526                	mv	a0,s1
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	470080e7          	jalr	1136(ra) # 80000c8a <release>
        havekids = 1;
    80002822:	8756                	mv	a4,s5
    80002824:	bfd9                	j	800027fa <waitx+0xda>
    if (!havekids || p->killed)
    80002826:	c701                	beqz	a4,8000282e <waitx+0x10e>
    80002828:	02892783          	lw	a5,40(s2)
    8000282c:	cb8d                	beqz	a5,8000285e <waitx+0x13e>
      release(&wait_lock);
    8000282e:	0000e517          	auipc	a0,0xe
    80002832:	31a50513          	addi	a0,a0,794 # 80010b48 <wait_lock>
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	454080e7          	jalr	1108(ra) # 80000c8a <release>
      return -1;
    8000283e:	59fd                	li	s3,-1
  }
}
    80002840:	854e                	mv	a0,s3
    80002842:	60e6                	ld	ra,88(sp)
    80002844:	6446                	ld	s0,80(sp)
    80002846:	64a6                	ld	s1,72(sp)
    80002848:	6906                	ld	s2,64(sp)
    8000284a:	79e2                	ld	s3,56(sp)
    8000284c:	7a42                	ld	s4,48(sp)
    8000284e:	7aa2                	ld	s5,40(sp)
    80002850:	7b02                	ld	s6,32(sp)
    80002852:	6be2                	ld	s7,24(sp)
    80002854:	6c42                	ld	s8,16(sp)
    80002856:	6ca2                	ld	s9,8(sp)
    80002858:	6d02                	ld	s10,0(sp)
    8000285a:	6125                	addi	sp,sp,96
    8000285c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000285e:	85ea                	mv	a1,s10
    80002860:	854a                	mv	a0,s2
    80002862:	00000097          	auipc	ra,0x0
    80002866:	9ea080e7          	jalr	-1558(ra) # 8000224c <sleep>
    havekids = 0;
    8000286a:	b721                	j	80002772 <waitx+0x52>

000000008000286c <update_time>:

void update_time()
{
    8000286c:	7179                	addi	sp,sp,-48
    8000286e:	f406                	sd	ra,40(sp)
    80002870:	f022                	sd	s0,32(sp)
    80002872:	ec26                	sd	s1,24(sp)
    80002874:	e84a                	sd	s2,16(sp)
    80002876:	e44e                	sd	s3,8(sp)
    80002878:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    8000287a:	0000e497          	auipc	s1,0xe
    8000287e:	6e648493          	addi	s1,s1,1766 # 80010f60 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002882:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002884:	00015917          	auipc	s2,0x15
    80002888:	0dc90913          	addi	s2,s2,220 # 80017960 <tickslock>
    8000288c:	a811                	j	800028a0 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    8000288e:	8526                	mv	a0,s1
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	3fa080e7          	jalr	1018(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002898:	1a848493          	addi	s1,s1,424
    8000289c:	03248063          	beq	s1,s2,800028bc <update_time+0x50>
    acquire(&p->lock);
    800028a0:	8526                	mv	a0,s1
    800028a2:	ffffe097          	auipc	ra,0xffffe
    800028a6:	334080e7          	jalr	820(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    800028aa:	4c9c                	lw	a5,24(s1)
    800028ac:	ff3791e3          	bne	a5,s3,8000288e <update_time+0x22>
      p->rtime++;
    800028b0:	1684a783          	lw	a5,360(s1)
    800028b4:	2785                	addiw	a5,a5,1
    800028b6:	16f4a423          	sw	a5,360(s1)
    800028ba:	bfd1                	j	8000288e <update_time+0x22>
  }
    800028bc:	70a2                	ld	ra,40(sp)
    800028be:	7402                	ld	s0,32(sp)
    800028c0:	64e2                	ld	s1,24(sp)
    800028c2:	6942                	ld	s2,16(sp)
    800028c4:	69a2                	ld	s3,8(sp)
    800028c6:	6145                	addi	sp,sp,48
    800028c8:	8082                	ret

00000000800028ca <swtch>:
    800028ca:	00153023          	sd	ra,0(a0)
    800028ce:	00253423          	sd	sp,8(a0)
    800028d2:	e900                	sd	s0,16(a0)
    800028d4:	ed04                	sd	s1,24(a0)
    800028d6:	03253023          	sd	s2,32(a0)
    800028da:	03353423          	sd	s3,40(a0)
    800028de:	03453823          	sd	s4,48(a0)
    800028e2:	03553c23          	sd	s5,56(a0)
    800028e6:	05653023          	sd	s6,64(a0)
    800028ea:	05753423          	sd	s7,72(a0)
    800028ee:	05853823          	sd	s8,80(a0)
    800028f2:	05953c23          	sd	s9,88(a0)
    800028f6:	07a53023          	sd	s10,96(a0)
    800028fa:	07b53423          	sd	s11,104(a0)
    800028fe:	0005b083          	ld	ra,0(a1)
    80002902:	0085b103          	ld	sp,8(a1)
    80002906:	6980                	ld	s0,16(a1)
    80002908:	6d84                	ld	s1,24(a1)
    8000290a:	0205b903          	ld	s2,32(a1)
    8000290e:	0285b983          	ld	s3,40(a1)
    80002912:	0305ba03          	ld	s4,48(a1)
    80002916:	0385ba83          	ld	s5,56(a1)
    8000291a:	0405bb03          	ld	s6,64(a1)
    8000291e:	0485bb83          	ld	s7,72(a1)
    80002922:	0505bc03          	ld	s8,80(a1)
    80002926:	0585bc83          	ld	s9,88(a1)
    8000292a:	0605bd03          	ld	s10,96(a1)
    8000292e:	0685bd83          	ld	s11,104(a1)
    80002932:	8082                	ret

0000000080002934 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002934:	1141                	addi	sp,sp,-16
    80002936:	e406                	sd	ra,8(sp)
    80002938:	e022                	sd	s0,0(sp)
    8000293a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000293c:	00006597          	auipc	a1,0x6
    80002940:	94c58593          	addi	a1,a1,-1716 # 80008288 <digits+0x248>
    80002944:	00015517          	auipc	a0,0x15
    80002948:	01c50513          	addi	a0,a0,28 # 80017960 <tickslock>
    8000294c:	ffffe097          	auipc	ra,0xffffe
    80002950:	1fa080e7          	jalr	506(ra) # 80000b46 <initlock>
}
    80002954:	60a2                	ld	ra,8(sp)
    80002956:	6402                	ld	s0,0(sp)
    80002958:	0141                	addi	sp,sp,16
    8000295a:	8082                	ret

000000008000295c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    8000295c:	1141                	addi	sp,sp,-16
    8000295e:	e422                	sd	s0,8(sp)
    80002960:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002962:	00004797          	auipc	a5,0x4
    80002966:	d5e78793          	addi	a5,a5,-674 # 800066c0 <kernelvec>
    8000296a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000296e:	6422                	ld	s0,8(sp)
    80002970:	0141                	addi	sp,sp,16
    80002972:	8082                	ret

0000000080002974 <min>:
//
// handle an interrupt, exception, or system call from user space.
// called from trampoline.S
//
int min(int a, int b)
{
    80002974:	1141                	addi	sp,sp,-16
    80002976:	e422                	sd	s0,8(sp)
    80002978:	0800                	addi	s0,sp,16
  }
  else
  {
    return b;
  }
}
    8000297a:	87aa                	mv	a5,a0
    8000297c:	00a5d363          	bge	a1,a0,80002982 <min+0xe>
    80002980:	87ae                	mv	a5,a1
    80002982:	0007851b          	sext.w	a0,a5
    80002986:	6422                	ld	s0,8(sp)
    80002988:	0141                	addi	sp,sp,16
    8000298a:	8082                	ret

000000008000298c <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    8000298c:	1141                	addi	sp,sp,-16
    8000298e:	e406                	sd	ra,8(sp)
    80002990:	e022                	sd	s0,0(sp)
    80002992:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002994:	fffff097          	auipc	ra,0xfffff
    80002998:	028080e7          	jalr	40(ra) # 800019bc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000299c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029a0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029a2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800029a6:	00004617          	auipc	a2,0x4
    800029aa:	65a60613          	addi	a2,a2,1626 # 80007000 <_trampoline>
    800029ae:	00004697          	auipc	a3,0x4
    800029b2:	65268693          	addi	a3,a3,1618 # 80007000 <_trampoline>
    800029b6:	8e91                	sub	a3,a3,a2
    800029b8:	040007b7          	lui	a5,0x4000
    800029bc:	17fd                	addi	a5,a5,-1
    800029be:	07b2                	slli	a5,a5,0xc
    800029c0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029c2:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029c6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029c8:	180026f3          	csrr	a3,satp
    800029cc:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029ce:	6d38                	ld	a4,88(a0)
    800029d0:	6134                	ld	a3,64(a0)
    800029d2:	6585                	lui	a1,0x1
    800029d4:	96ae                	add	a3,a3,a1
    800029d6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029d8:	6d38                	ld	a4,88(a0)
    800029da:	00000697          	auipc	a3,0x0
    800029de:	13e68693          	addi	a3,a3,318 # 80002b18 <usertrap>
    800029e2:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    800029e4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029e6:	8692                	mv	a3,tp
    800029e8:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ea:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029ee:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029f2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029f6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029fa:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029fc:	6f18                	ld	a4,24(a4)
    800029fe:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a02:	6928                	ld	a0,80(a0)
    80002a04:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002a06:	00004717          	auipc	a4,0x4
    80002a0a:	69670713          	addi	a4,a4,1686 # 8000709c <userret>
    80002a0e:	8f11                	sub	a4,a4,a2
    80002a10:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002a12:	577d                	li	a4,-1
    80002a14:	177e                	slli	a4,a4,0x3f
    80002a16:	8d59                	or	a0,a0,a4
    80002a18:	9782                	jalr	a5
}
    80002a1a:	60a2                	ld	ra,8(sp)
    80002a1c:	6402                	ld	s0,0(sp)
    80002a1e:	0141                	addi	sp,sp,16
    80002a20:	8082                	ret

0000000080002a22 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002a22:	1101                	addi	sp,sp,-32
    80002a24:	ec06                	sd	ra,24(sp)
    80002a26:	e822                	sd	s0,16(sp)
    80002a28:	e426                	sd	s1,8(sp)
    80002a2a:	e04a                	sd	s2,0(sp)
    80002a2c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a2e:	00015917          	auipc	s2,0x15
    80002a32:	f3290913          	addi	s2,s2,-206 # 80017960 <tickslock>
    80002a36:	854a                	mv	a0,s2
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	19e080e7          	jalr	414(ra) # 80000bd6 <acquire>
  ticks++;
    80002a40:	00006497          	auipc	s1,0x6
    80002a44:	e8048493          	addi	s1,s1,-384 # 800088c0 <ticks>
    80002a48:	409c                	lw	a5,0(s1)
    80002a4a:	2785                	addiw	a5,a5,1
    80002a4c:	c09c                	sw	a5,0(s1)
  update_time();
    80002a4e:	00000097          	auipc	ra,0x0
    80002a52:	e1e080e7          	jalr	-482(ra) # 8000286c <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002a56:	8526                	mv	a0,s1
    80002a58:	00000097          	auipc	ra,0x0
    80002a5c:	858080e7          	jalr	-1960(ra) # 800022b0 <wakeup>
  release(&tickslock);
    80002a60:	854a                	mv	a0,s2
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	228080e7          	jalr	552(ra) # 80000c8a <release>
}
    80002a6a:	60e2                	ld	ra,24(sp)
    80002a6c:	6442                	ld	s0,16(sp)
    80002a6e:	64a2                	ld	s1,8(sp)
    80002a70:	6902                	ld	s2,0(sp)
    80002a72:	6105                	addi	sp,sp,32
    80002a74:	8082                	ret

0000000080002a76 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002a76:	1101                	addi	sp,sp,-32
    80002a78:	ec06                	sd	ra,24(sp)
    80002a7a:	e822                	sd	s0,16(sp)
    80002a7c:	e426                	sd	s1,8(sp)
    80002a7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a80:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002a84:	00074d63          	bltz	a4,80002a9e <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002a88:	57fd                	li	a5,-1
    80002a8a:	17fe                	slli	a5,a5,0x3f
    80002a8c:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002a8e:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002a90:	06f70363          	beq	a4,a5,80002af6 <devintr+0x80>
  }
}
    80002a94:	60e2                	ld	ra,24(sp)
    80002a96:	6442                	ld	s0,16(sp)
    80002a98:	64a2                	ld	s1,8(sp)
    80002a9a:	6105                	addi	sp,sp,32
    80002a9c:	8082                	ret
      (scause & 0xff) == 9)
    80002a9e:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002aa2:	46a5                	li	a3,9
    80002aa4:	fed792e3          	bne	a5,a3,80002a88 <devintr+0x12>
    int irq = plic_claim();
    80002aa8:	00004097          	auipc	ra,0x4
    80002aac:	d20080e7          	jalr	-736(ra) # 800067c8 <plic_claim>
    80002ab0:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002ab2:	47a9                	li	a5,10
    80002ab4:	02f50763          	beq	a0,a5,80002ae2 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002ab8:	4785                	li	a5,1
    80002aba:	02f50963          	beq	a0,a5,80002aec <devintr+0x76>
    return 1;
    80002abe:	4505                	li	a0,1
    else if (irq)
    80002ac0:	d8f1                	beqz	s1,80002a94 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ac2:	85a6                	mv	a1,s1
    80002ac4:	00005517          	auipc	a0,0x5
    80002ac8:	7cc50513          	addi	a0,a0,1996 # 80008290 <digits+0x250>
    80002acc:	ffffe097          	auipc	ra,0xffffe
    80002ad0:	abc080e7          	jalr	-1348(ra) # 80000588 <printf>
      plic_complete(irq);
    80002ad4:	8526                	mv	a0,s1
    80002ad6:	00004097          	auipc	ra,0x4
    80002ada:	d16080e7          	jalr	-746(ra) # 800067ec <plic_complete>
    return 1;
    80002ade:	4505                	li	a0,1
    80002ae0:	bf55                	j	80002a94 <devintr+0x1e>
      uartintr();
    80002ae2:	ffffe097          	auipc	ra,0xffffe
    80002ae6:	eb8080e7          	jalr	-328(ra) # 8000099a <uartintr>
    80002aea:	b7ed                	j	80002ad4 <devintr+0x5e>
      virtio_disk_intr();
    80002aec:	00004097          	auipc	ra,0x4
    80002af0:	1cc080e7          	jalr	460(ra) # 80006cb8 <virtio_disk_intr>
    80002af4:	b7c5                	j	80002ad4 <devintr+0x5e>
    if (cpuid() == 0)
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	e9a080e7          	jalr	-358(ra) # 80001990 <cpuid>
    80002afe:	c901                	beqz	a0,80002b0e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b00:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b04:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b06:	14479073          	csrw	sip,a5
    return 2;
    80002b0a:	4509                	li	a0,2
    80002b0c:	b761                	j	80002a94 <devintr+0x1e>
      clockintr();
    80002b0e:	00000097          	auipc	ra,0x0
    80002b12:	f14080e7          	jalr	-236(ra) # 80002a22 <clockintr>
    80002b16:	b7ed                	j	80002b00 <devintr+0x8a>

0000000080002b18 <usertrap>:
{
    80002b18:	715d                	addi	sp,sp,-80
    80002b1a:	e486                	sd	ra,72(sp)
    80002b1c:	e0a2                	sd	s0,64(sp)
    80002b1e:	fc26                	sd	s1,56(sp)
    80002b20:	f84a                	sd	s2,48(sp)
    80002b22:	f44e                	sd	s3,40(sp)
    80002b24:	f052                	sd	s4,32(sp)
    80002b26:	ec56                	sd	s5,24(sp)
    80002b28:	e85a                	sd	s6,16(sp)
    80002b2a:	e45e                	sd	s7,8(sp)
    80002b2c:	e062                	sd	s8,0(sp)
    80002b2e:	0880                	addi	s0,sp,80
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b30:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002b34:	1007f793          	andi	a5,a5,256
    80002b38:	e3b1                	bnez	a5,80002b7c <usertrap+0x64>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b3a:	00004797          	auipc	a5,0x4
    80002b3e:	b8678793          	addi	a5,a5,-1146 # 800066c0 <kernelvec>
    80002b42:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b46:	fffff097          	auipc	ra,0xfffff
    80002b4a:	e76080e7          	jalr	-394(ra) # 800019bc <myproc>
    80002b4e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b50:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b52:	14102773          	csrr	a4,sepc
    80002b56:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b58:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002b5c:	47a1                	li	a5,8
    80002b5e:	02f70763          	beq	a4,a5,80002b8c <usertrap+0x74>
  else if ((which_dev = devintr()) != 0)
    80002b62:	00000097          	auipc	ra,0x0
    80002b66:	f14080e7          	jalr	-236(ra) # 80002a76 <devintr>
    80002b6a:	892a                	mv	s2,a0
    80002b6c:	c941                	beqz	a0,80002bfc <usertrap+0xe4>
  if (killed(p))
    80002b6e:	8526                	mv	a0,s1
    80002b70:	00000097          	auipc	ra,0x0
    80002b74:	990080e7          	jalr	-1648(ra) # 80002500 <killed>
    80002b78:	c929                	beqz	a0,80002bca <usertrap+0xb2>
    80002b7a:	a099                	j	80002bc0 <usertrap+0xa8>
    panic("usertrap: not from user mode");
    80002b7c:	00005517          	auipc	a0,0x5
    80002b80:	73450513          	addi	a0,a0,1844 # 800082b0 <digits+0x270>
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	9ba080e7          	jalr	-1606(ra) # 8000053e <panic>
    if (killed(p))
    80002b8c:	00000097          	auipc	ra,0x0
    80002b90:	974080e7          	jalr	-1676(ra) # 80002500 <killed>
    80002b94:	ed31                	bnez	a0,80002bf0 <usertrap+0xd8>
    p->trapframe->epc += 4;
    80002b96:	6cb8                	ld	a4,88(s1)
    80002b98:	6f1c                	ld	a5,24(a4)
    80002b9a:	0791                	addi	a5,a5,4
    80002b9c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b9e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ba2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ba6:	10079073          	csrw	sstatus,a5
    syscall();
    80002baa:	00001097          	auipc	ra,0x1
    80002bae:	9aa080e7          	jalr	-1622(ra) # 80003554 <syscall>
  if (killed(p))
    80002bb2:	8526                	mv	a0,s1
    80002bb4:	00000097          	auipc	ra,0x0
    80002bb8:	94c080e7          	jalr	-1716(ra) # 80002500 <killed>
    80002bbc:	c911                	beqz	a0,80002bd0 <usertrap+0xb8>
    80002bbe:	4901                	li	s2,0
    exit(-1);
    80002bc0:	557d                	li	a0,-1
    80002bc2:	fffff097          	auipc	ra,0xfffff
    80002bc6:	7be080e7          	jalr	1982(ra) # 80002380 <exit>
  if (which_dev == 2)
    80002bca:	4789                	li	a5,2
    80002bcc:	06f90563          	beq	s2,a5,80002c36 <usertrap+0x11e>
  usertrapret();
    80002bd0:	00000097          	auipc	ra,0x0
    80002bd4:	dbc080e7          	jalr	-580(ra) # 8000298c <usertrapret>
}
    80002bd8:	60a6                	ld	ra,72(sp)
    80002bda:	6406                	ld	s0,64(sp)
    80002bdc:	74e2                	ld	s1,56(sp)
    80002bde:	7942                	ld	s2,48(sp)
    80002be0:	79a2                	ld	s3,40(sp)
    80002be2:	7a02                	ld	s4,32(sp)
    80002be4:	6ae2                	ld	s5,24(sp)
    80002be6:	6b42                	ld	s6,16(sp)
    80002be8:	6ba2                	ld	s7,8(sp)
    80002bea:	6c02                	ld	s8,0(sp)
    80002bec:	6161                	addi	sp,sp,80
    80002bee:	8082                	ret
      exit(-1);
    80002bf0:	557d                	li	a0,-1
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	78e080e7          	jalr	1934(ra) # 80002380 <exit>
    80002bfa:	bf71                	j	80002b96 <usertrap+0x7e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bfc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c00:	5890                	lw	a2,48(s1)
    80002c02:	00005517          	auipc	a0,0x5
    80002c06:	6ce50513          	addi	a0,a0,1742 # 800082d0 <digits+0x290>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	97e080e7          	jalr	-1666(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c12:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c16:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c1a:	00005517          	auipc	a0,0x5
    80002c1e:	6e650513          	addi	a0,a0,1766 # 80008300 <digits+0x2c0>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	966080e7          	jalr	-1690(ra) # 80000588 <printf>
    setkilled(p);
    80002c2a:	8526                	mv	a0,s1
    80002c2c:	00000097          	auipc	ra,0x0
    80002c30:	8a8080e7          	jalr	-1880(ra) # 800024d4 <setkilled>
    80002c34:	bfbd                	j	80002bb2 <usertrap+0x9a>
    printf("%d %d %d\n", ticks, p->pid, p->queue);
    80002c36:	1744a683          	lw	a3,372(s1)
    80002c3a:	5890                	lw	a2,48(s1)
    80002c3c:	00006597          	auipc	a1,0x6
    80002c40:	c845a583          	lw	a1,-892(a1) # 800088c0 <ticks>
    80002c44:	00005517          	auipc	a0,0x5
    80002c48:	6dc50513          	addi	a0,a0,1756 # 80008320 <digits+0x2e0>
    80002c4c:	ffffe097          	auipc	ra,0xffffe
    80002c50:	93c080e7          	jalr	-1732(ra) # 80000588 <printf>
    myproc()->passed_ticks++;
    80002c54:	fffff097          	auipc	ra,0xfffff
    80002c58:	d68080e7          	jalr	-664(ra) # 800019bc <myproc>
    80002c5c:	19052703          	lw	a4,400(a0)
    80002c60:	2705                	addiw	a4,a4,1
    80002c62:	18e52823          	sw	a4,400(a0)
    if (myproc()->passed_ticks % myproc()->no_of_ticks == 0)
    80002c66:	fffff097          	auipc	ra,0xfffff
    80002c6a:	d56080e7          	jalr	-682(ra) # 800019bc <myproc>
    80002c6e:	19052903          	lw	s2,400(a0)
    80002c72:	fffff097          	auipc	ra,0xfffff
    80002c76:	d4a080e7          	jalr	-694(ra) # 800019bc <myproc>
    80002c7a:	18052783          	lw	a5,384(a0)
    80002c7e:	02f9693b          	remw	s2,s2,a5
    80002c82:	00090d63          	beqz	s2,80002c9c <usertrap+0x184>
  if (killed(p))
    80002c86:	0000e497          	auipc	s1,0xe
    80002c8a:	2da48493          	addi	s1,s1,730 # 80010f60 <proc>
      if (p->state == RUNNABLE)
    80002c8e:	498d                	li	s3,3
      else if (p->state == RUNNING)
    80002c90:	4a11                	li	s4,4
    for (p = proc; p < &proc[NPROC]; p++)
    80002c92:	00015917          	auipc	s2,0x15
    80002c96:	cce90913          	addi	s2,s2,-818 # 80017960 <tickslock>
    80002c9a:	a861                	j	80002d32 <usertrap+0x21a>
      if (myproc()->flag_check_handler == 0)
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	d20080e7          	jalr	-736(ra) # 800019bc <myproc>
    80002ca4:	1a052783          	lw	a5,416(a0)
    80002ca8:	fff9                	bnez	a5,80002c86 <usertrap+0x16e>
        myproc()->flag_check_handler = 1;
    80002caa:	fffff097          	auipc	ra,0xfffff
    80002cae:	d12080e7          	jalr	-750(ra) # 800019bc <myproc>
    80002cb2:	4785                	li	a5,1
    80002cb4:	1af52023          	sw	a5,416(a0)
        arr_of_trapframes_storing_past[myproc()->pid] = kalloc();
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	d04080e7          	jalr	-764(ra) # 800019bc <myproc>
    80002cc0:	03052903          	lw	s2,48(a0)
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	e22080e7          	jalr	-478(ra) # 80000ae6 <kalloc>
    80002ccc:	00015997          	auipc	s3,0x15
    80002cd0:	cac98993          	addi	s3,s3,-852 # 80017978 <arr_of_trapframes_storing_past>
    80002cd4:	00391793          	slli	a5,s2,0x3
    80002cd8:	97ce                	add	a5,a5,s3
    80002cda:	e388                	sd	a0,0(a5)
        memmove(arr_of_trapframes_storing_past[myproc()->pid], myproc()->trapframe, PGSIZE);
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	ce0080e7          	jalr	-800(ra) # 800019bc <myproc>
    80002ce4:	591c                	lw	a5,48(a0)
    80002ce6:	078e                	slli	a5,a5,0x3
    80002ce8:	99be                	add	s3,s3,a5
    80002cea:	0009b903          	ld	s2,0(s3)
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	cce080e7          	jalr	-818(ra) # 800019bc <myproc>
    80002cf6:	6605                	lui	a2,0x1
    80002cf8:	6d2c                	ld	a1,88(a0)
    80002cfa:	854a                	mv	a0,s2
    80002cfc:	ffffe097          	auipc	ra,0xffffe
    80002d00:	032080e7          	jalr	50(ra) # 80000d2e <memmove>
        p->trapframe->epc = myproc()->handler;
    80002d04:	fffff097          	auipc	ra,0xfffff
    80002d08:	cb8080e7          	jalr	-840(ra) # 800019bc <myproc>
    80002d0c:	6cbc                	ld	a5,88(s1)
    80002d0e:	18853703          	ld	a4,392(a0)
    80002d12:	ef98                	sd	a4,24(a5)
    80002d14:	bf8d                	j	80002c86 <usertrap+0x16e>
        p->wait++;
    80002d16:	17c4a783          	lw	a5,380(s1)
    80002d1a:	2785                	addiw	a5,a5,1
    80002d1c:	16f4ae23          	sw	a5,380(s1)
      release(&p->lock);
    80002d20:	8526                	mv	a0,s1
    80002d22:	ffffe097          	auipc	ra,0xffffe
    80002d26:	f68080e7          	jalr	-152(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002d2a:	1a848493          	addi	s1,s1,424
    80002d2e:	03248263          	beq	s1,s2,80002d52 <usertrap+0x23a>
      acquire(&p->lock);
    80002d32:	8526                	mv	a0,s1
    80002d34:	ffffe097          	auipc	ra,0xffffe
    80002d38:	ea2080e7          	jalr	-350(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80002d3c:	4c9c                	lw	a5,24(s1)
    80002d3e:	fd378ce3          	beq	a5,s3,80002d16 <usertrap+0x1fe>
      else if (p->state == RUNNING)
    80002d42:	fd479fe3          	bne	a5,s4,80002d20 <usertrap+0x208>
        p->ticks_when_switch++;
    80002d46:	1784a783          	lw	a5,376(s1)
    80002d4a:	2785                	addiw	a5,a5,1
    80002d4c:	16f4ac23          	sw	a5,376(s1)
    80002d50:	bfc1                	j	80002d20 <usertrap+0x208>
    for (p = proc; p < &proc[NPROC]; p++)
    80002d52:	0000e497          	auipc	s1,0xe
    80002d56:	20e48493          	addi	s1,s1,526 # 80010f60 <proc>
      if (p->state == RUNNABLE)
    80002d5a:	498d                	li	s3,3
        if ((p->wait >= 30) && p->queue > 0)
    80002d5c:	4a75                	li	s4,29
          if (p->pid >= 9)
    80002d5e:	4aa1                	li	s5,8
            printf("%d %d %d after promotion\n", ticks, p->pid, p->queue);
    80002d60:	00006b17          	auipc	s6,0x6
    80002d64:	b60b0b13          	addi	s6,s6,-1184 # 800088c0 <ticks>
    80002d68:	00005c17          	auipc	s8,0x5
    80002d6c:	5c8c0c13          	addi	s8,s8,1480 # 80008330 <digits+0x2f0>
            printf("%d %d %d\n", ticks - 1,p->pid, p->queue);
    80002d70:	00005b97          	auipc	s7,0x5
    80002d74:	5b0b8b93          	addi	s7,s7,1456 # 80008320 <digits+0x2e0>
    for (p = proc; p < &proc[NPROC]; p++)
    80002d78:	00015917          	auipc	s2,0x15
    80002d7c:	be890913          	addi	s2,s2,-1048 # 80017960 <tickslock>
    80002d80:	a80d                	j	80002db2 <usertrap+0x29a>
            printf("%d %d %d\n", ticks - 1,p->pid, p->queue);
    80002d82:	000b2583          	lw	a1,0(s6)
    80002d86:	35fd                	addiw	a1,a1,-1
    80002d88:	855e                	mv	a0,s7
    80002d8a:	ffffd097          	auipc	ra,0xffffd
    80002d8e:	7fe080e7          	jalr	2046(ra) # 80000588 <printf>
    80002d92:	a099                	j	80002dd8 <usertrap+0x2c0>
          p->new_flag = 0;
    80002d94:	1a04a223          	sw	zero,420(s1)
          p->ticks_when_switch = 0;
    80002d98:	1604ac23          	sw	zero,376(s1)
          p->wait = 0;
    80002d9c:	1604ae23          	sw	zero,380(s1)
      release(&p->lock);
    80002da0:	8526                	mv	a0,s1
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	ee8080e7          	jalr	-280(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002daa:	1a848493          	addi	s1,s1,424
    80002dae:	05248763          	beq	s1,s2,80002dfc <usertrap+0x2e4>
      acquire(&p->lock);
    80002db2:	8526                	mv	a0,s1
    80002db4:	ffffe097          	auipc	ra,0xffffe
    80002db8:	e22080e7          	jalr	-478(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80002dbc:	4c9c                	lw	a5,24(s1)
    80002dbe:	ff3791e3          	bne	a5,s3,80002da0 <usertrap+0x288>
        if ((p->wait >= 30) && p->queue > 0)
    80002dc2:	17c4a783          	lw	a5,380(s1)
    80002dc6:	fcfa5de3          	bge	s4,a5,80002da0 <usertrap+0x288>
    80002dca:	1744a683          	lw	a3,372(s1)
    80002dce:	fcd059e3          	blez	a3,80002da0 <usertrap+0x288>
          if (p->pid >= 9)
    80002dd2:	5890                	lw	a2,48(s1)
    80002dd4:	facac7e3          	blt	s5,a2,80002d82 <usertrap+0x26a>
          p->queue--;
    80002dd8:	1744a783          	lw	a5,372(s1)
    80002ddc:	37fd                	addiw	a5,a5,-1
    80002dde:	0007869b          	sext.w	a3,a5
    80002de2:	16f4aa23          	sw	a5,372(s1)
          if (p->pid >= 9)
    80002de6:	5890                	lw	a2,48(s1)
    80002de8:	facad6e3          	bge	s5,a2,80002d94 <usertrap+0x27c>
            printf("%d %d %d after promotion\n", ticks, p->pid, p->queue);
    80002dec:	000b2583          	lw	a1,0(s6)
    80002df0:	8562                	mv	a0,s8
    80002df2:	ffffd097          	auipc	ra,0xffffd
    80002df6:	796080e7          	jalr	1942(ra) # 80000588 <printf>
    80002dfa:	bf69                	j	80002d94 <usertrap+0x27c>
    int current_level = myproc()->queue;
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	bc0080e7          	jalr	-1088(ra) # 800019bc <myproc>
    80002e04:	17452b03          	lw	s6,372(a0)
    for (int i = 0; i < current_level; i++)
    80002e08:	4a01                	li	s4,0
        if (p->state == RUNNABLE && p->queue == i)
    80002e0a:	498d                	li	s3,3
          myproc()->new_flag = 1;
    80002e0c:	4a85                	li	s5,1
      for (p = proc; p < &proc[NPROC]; p++)
    80002e0e:	00015917          	auipc	s2,0x15
    80002e12:	b5290913          	addi	s2,s2,-1198 # 80017960 <tickslock>
    for (int i = 0; i < current_level; i++)
    80002e16:	09604b63          	bgtz	s6,80002eac <usertrap+0x394>
    int queu_of_myproc = myproc()->queue;
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	ba2080e7          	jalr	-1118(ra) # 800019bc <myproc>
    80002e22:	17452783          	lw	a5,372(a0)
    if (queu_of_myproc == 0)
    80002e26:	cbc1                	beqz	a5,80002eb6 <usertrap+0x39e>
    else if (queu_of_myproc == 1)
    80002e28:	4705                	li	a4,1
    80002e2a:	12e78263          	beq	a5,a4,80002f4e <usertrap+0x436>
    else if (queu_of_myproc == 2)
    80002e2e:	4709                	li	a4,2
    80002e30:	1ae78b63          	beq	a5,a4,80002fe6 <usertrap+0x4ce>
    else if (queu_of_myproc == 3)
    80002e34:	470d                	li	a4,3
    80002e36:	d8e79de3          	bne	a5,a4,80002bd0 <usertrap+0xb8>
      if (myproc()->ticks_when_switch == 15)
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	b82080e7          	jalr	-1150(ra) # 800019bc <myproc>
    80002e42:	17852703          	lw	a4,376(a0)
    80002e46:	47bd                	li	a5,15
    80002e48:	d8f714e3          	bne	a4,a5,80002bd0 <usertrap+0xb8>
        myproc()->new_flag = 0;
    80002e4c:	fffff097          	auipc	ra,0xfffff
    80002e50:	b70080e7          	jalr	-1168(ra) # 800019bc <myproc>
    80002e54:	1a052223          	sw	zero,420(a0)
        myproc()->wait = 0;
    80002e58:	fffff097          	auipc	ra,0xfffff
    80002e5c:	b64080e7          	jalr	-1180(ra) # 800019bc <myproc>
    80002e60:	16052e23          	sw	zero,380(a0)
        myproc()->ticks_when_switch = 0;
    80002e64:	fffff097          	auipc	ra,0xfffff
    80002e68:	b58080e7          	jalr	-1192(ra) # 800019bc <myproc>
    80002e6c:	16052c23          	sw	zero,376(a0)
        yield();
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	3a0080e7          	jalr	928(ra) # 80002210 <yield>
    80002e78:	bba1                	j	80002bd0 <usertrap+0xb8>
      for (p = proc; p < &proc[NPROC]; p++)
    80002e7a:	1a848493          	addi	s1,s1,424
    80002e7e:	03248463          	beq	s1,s2,80002ea6 <usertrap+0x38e>
        if (p->state == RUNNABLE && p->queue == i)
    80002e82:	4c9c                	lw	a5,24(s1)
    80002e84:	ff379be3          	bne	a5,s3,80002e7a <usertrap+0x362>
    80002e88:	1744a783          	lw	a5,372(s1)
    80002e8c:	ff4797e3          	bne	a5,s4,80002e7a <usertrap+0x362>
          myproc()->new_flag = 1;
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	b2c080e7          	jalr	-1236(ra) # 800019bc <myproc>
    80002e98:	1b552223          	sw	s5,420(a0)
          yield();
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	374080e7          	jalr	884(ra) # 80002210 <yield>
    80002ea4:	bfd9                	j	80002e7a <usertrap+0x362>
    for (int i = 0; i < current_level; i++)
    80002ea6:	2a05                	addiw	s4,s4,1
    80002ea8:	f74b09e3          	beq	s6,s4,80002e1a <usertrap+0x302>
      for (p = proc; p < &proc[NPROC]; p++)
    80002eac:	0000e497          	auipc	s1,0xe
    80002eb0:	0b448493          	addi	s1,s1,180 # 80010f60 <proc>
    80002eb4:	b7f9                	j	80002e82 <usertrap+0x36a>
      if (myproc()->ticks_when_switch == 1)
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	b06080e7          	jalr	-1274(ra) # 800019bc <myproc>
    80002ebe:	17852703          	lw	a4,376(a0)
    80002ec2:	4785                	li	a5,1
    80002ec4:	d0f716e3          	bne	a4,a5,80002bd0 <usertrap+0xb8>
        myproc()->queue++;
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	af4080e7          	jalr	-1292(ra) # 800019bc <myproc>
    80002ed0:	17452703          	lw	a4,372(a0)
    80002ed4:	2705                	addiw	a4,a4,1
    80002ed6:	16e52a23          	sw	a4,372(a0)
        if (myproc()->pid >= 9)
    80002eda:	fffff097          	auipc	ra,0xfffff
    80002ede:	ae2080e7          	jalr	-1310(ra) # 800019bc <myproc>
    80002ee2:	5918                	lw	a4,48(a0)
    80002ee4:	47a1                	li	a5,8
    80002ee6:	02e7c963          	blt	a5,a4,80002f18 <usertrap+0x400>
        myproc()->ticks_when_switch = 0;
    80002eea:	fffff097          	auipc	ra,0xfffff
    80002eee:	ad2080e7          	jalr	-1326(ra) # 800019bc <myproc>
    80002ef2:	16052c23          	sw	zero,376(a0)
        myproc()->wait = 0;
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	ac6080e7          	jalr	-1338(ra) # 800019bc <myproc>
    80002efe:	16052e23          	sw	zero,380(a0)
        myproc()->new_flag = 0;
    80002f02:	fffff097          	auipc	ra,0xfffff
    80002f06:	aba080e7          	jalr	-1350(ra) # 800019bc <myproc>
    80002f0a:	1a052223          	sw	zero,420(a0)
        yield();
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	302080e7          	jalr	770(ra) # 80002210 <yield>
    80002f16:	b96d                	j	80002bd0 <usertrap+0xb8>
          printf("%d %d %d after demotion \n", ticks, myproc()->pid, myproc()->queue);
    80002f18:	00006497          	auipc	s1,0x6
    80002f1c:	9a84a483          	lw	s1,-1624(s1) # 800088c0 <ticks>
    80002f20:	fffff097          	auipc	ra,0xfffff
    80002f24:	a9c080e7          	jalr	-1380(ra) # 800019bc <myproc>
    80002f28:	03052903          	lw	s2,48(a0)
    80002f2c:	fffff097          	auipc	ra,0xfffff
    80002f30:	a90080e7          	jalr	-1392(ra) # 800019bc <myproc>
    80002f34:	17452683          	lw	a3,372(a0)
    80002f38:	864a                	mv	a2,s2
    80002f3a:	85a6                	mv	a1,s1
    80002f3c:	00005517          	auipc	a0,0x5
    80002f40:	41450513          	addi	a0,a0,1044 # 80008350 <digits+0x310>
    80002f44:	ffffd097          	auipc	ra,0xffffd
    80002f48:	644080e7          	jalr	1604(ra) # 80000588 <printf>
    80002f4c:	bf79                	j	80002eea <usertrap+0x3d2>
      if (myproc()->ticks_when_switch == 3)
    80002f4e:	fffff097          	auipc	ra,0xfffff
    80002f52:	a6e080e7          	jalr	-1426(ra) # 800019bc <myproc>
    80002f56:	17852703          	lw	a4,376(a0)
    80002f5a:	478d                	li	a5,3
    80002f5c:	c6f71ae3          	bne	a4,a5,80002bd0 <usertrap+0xb8>
        myproc()->queue++;
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	a5c080e7          	jalr	-1444(ra) # 800019bc <myproc>
    80002f68:	17452703          	lw	a4,372(a0)
    80002f6c:	2705                	addiw	a4,a4,1
    80002f6e:	16e52a23          	sw	a4,372(a0)
        if (myproc()->pid >= 9)
    80002f72:	fffff097          	auipc	ra,0xfffff
    80002f76:	a4a080e7          	jalr	-1462(ra) # 800019bc <myproc>
    80002f7a:	5918                	lw	a4,48(a0)
    80002f7c:	47a1                	li	a5,8
    80002f7e:	02e7c963          	blt	a5,a4,80002fb0 <usertrap+0x498>
        myproc()->ticks_when_switch = 0;
    80002f82:	fffff097          	auipc	ra,0xfffff
    80002f86:	a3a080e7          	jalr	-1478(ra) # 800019bc <myproc>
    80002f8a:	16052c23          	sw	zero,376(a0)
        myproc()->wait = 0;
    80002f8e:	fffff097          	auipc	ra,0xfffff
    80002f92:	a2e080e7          	jalr	-1490(ra) # 800019bc <myproc>
    80002f96:	16052e23          	sw	zero,380(a0)
        myproc()->new_flag = 0;
    80002f9a:	fffff097          	auipc	ra,0xfffff
    80002f9e:	a22080e7          	jalr	-1502(ra) # 800019bc <myproc>
    80002fa2:	1a052223          	sw	zero,420(a0)
        yield();
    80002fa6:	fffff097          	auipc	ra,0xfffff
    80002faa:	26a080e7          	jalr	618(ra) # 80002210 <yield>
    80002fae:	b10d                	j	80002bd0 <usertrap+0xb8>
          printf("%d %d %d after demotion \n", ticks, myproc()->pid, myproc()->queue);
    80002fb0:	00006497          	auipc	s1,0x6
    80002fb4:	9104a483          	lw	s1,-1776(s1) # 800088c0 <ticks>
    80002fb8:	fffff097          	auipc	ra,0xfffff
    80002fbc:	a04080e7          	jalr	-1532(ra) # 800019bc <myproc>
    80002fc0:	03052903          	lw	s2,48(a0)
    80002fc4:	fffff097          	auipc	ra,0xfffff
    80002fc8:	9f8080e7          	jalr	-1544(ra) # 800019bc <myproc>
    80002fcc:	17452683          	lw	a3,372(a0)
    80002fd0:	864a                	mv	a2,s2
    80002fd2:	85a6                	mv	a1,s1
    80002fd4:	00005517          	auipc	a0,0x5
    80002fd8:	37c50513          	addi	a0,a0,892 # 80008350 <digits+0x310>
    80002fdc:	ffffd097          	auipc	ra,0xffffd
    80002fe0:	5ac080e7          	jalr	1452(ra) # 80000588 <printf>
    80002fe4:	bf79                	j	80002f82 <usertrap+0x46a>
      if (myproc()->ticks_when_switch == 9)
    80002fe6:	fffff097          	auipc	ra,0xfffff
    80002fea:	9d6080e7          	jalr	-1578(ra) # 800019bc <myproc>
    80002fee:	17852703          	lw	a4,376(a0)
    80002ff2:	47a5                	li	a5,9
    80002ff4:	bcf71ee3          	bne	a4,a5,80002bd0 <usertrap+0xb8>
        myproc()->queue++;
    80002ff8:	fffff097          	auipc	ra,0xfffff
    80002ffc:	9c4080e7          	jalr	-1596(ra) # 800019bc <myproc>
    80003000:	17452703          	lw	a4,372(a0)
    80003004:	2705                	addiw	a4,a4,1
    80003006:	16e52a23          	sw	a4,372(a0)
        if (myproc()->pid >= 9)
    8000300a:	fffff097          	auipc	ra,0xfffff
    8000300e:	9b2080e7          	jalr	-1614(ra) # 800019bc <myproc>
    80003012:	5918                	lw	a4,48(a0)
    80003014:	47a1                	li	a5,8
    80003016:	02e7c963          	blt	a5,a4,80003048 <usertrap+0x530>
        myproc()->ticks_when_switch = 0;
    8000301a:	fffff097          	auipc	ra,0xfffff
    8000301e:	9a2080e7          	jalr	-1630(ra) # 800019bc <myproc>
    80003022:	16052c23          	sw	zero,376(a0)
        myproc()->wait = 0;
    80003026:	fffff097          	auipc	ra,0xfffff
    8000302a:	996080e7          	jalr	-1642(ra) # 800019bc <myproc>
    8000302e:	16052e23          	sw	zero,380(a0)
        myproc()->new_flag = 0;
    80003032:	fffff097          	auipc	ra,0xfffff
    80003036:	98a080e7          	jalr	-1654(ra) # 800019bc <myproc>
    8000303a:	1a052223          	sw	zero,420(a0)
        yield();
    8000303e:	fffff097          	auipc	ra,0xfffff
    80003042:	1d2080e7          	jalr	466(ra) # 80002210 <yield>
    80003046:	b669                	j	80002bd0 <usertrap+0xb8>
          printf("%d %d %d after demotion \n", ticks, myproc()->pid, myproc()->queue);
    80003048:	00006497          	auipc	s1,0x6
    8000304c:	8784a483          	lw	s1,-1928(s1) # 800088c0 <ticks>
    80003050:	fffff097          	auipc	ra,0xfffff
    80003054:	96c080e7          	jalr	-1684(ra) # 800019bc <myproc>
    80003058:	03052903          	lw	s2,48(a0)
    8000305c:	fffff097          	auipc	ra,0xfffff
    80003060:	960080e7          	jalr	-1696(ra) # 800019bc <myproc>
    80003064:	17452683          	lw	a3,372(a0)
    80003068:	864a                	mv	a2,s2
    8000306a:	85a6                	mv	a1,s1
    8000306c:	00005517          	auipc	a0,0x5
    80003070:	2e450513          	addi	a0,a0,740 # 80008350 <digits+0x310>
    80003074:	ffffd097          	auipc	ra,0xffffd
    80003078:	514080e7          	jalr	1300(ra) # 80000588 <printf>
    8000307c:	bf79                	j	8000301a <usertrap+0x502>

000000008000307e <kerneltrap>:
{
    8000307e:	715d                	addi	sp,sp,-80
    80003080:	e486                	sd	ra,72(sp)
    80003082:	e0a2                	sd	s0,64(sp)
    80003084:	fc26                	sd	s1,56(sp)
    80003086:	f84a                	sd	s2,48(sp)
    80003088:	f44e                	sd	s3,40(sp)
    8000308a:	f052                	sd	s4,32(sp)
    8000308c:	ec56                	sd	s5,24(sp)
    8000308e:	e85a                	sd	s6,16(sp)
    80003090:	e45e                	sd	s7,8(sp)
    80003092:	e062                	sd	s8,0(sp)
    80003094:	0880                	addi	s0,sp,80
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003096:	14102b73          	csrr	s6,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000309a:	10002af3          	csrr	s5,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000309e:	142024f3          	csrr	s1,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    800030a2:	100af793          	andi	a5,s5,256
    800030a6:	cf8d                	beqz	a5,800030e0 <kerneltrap+0x62>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030a8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800030ac:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    800030ae:	e3a9                	bnez	a5,800030f0 <kerneltrap+0x72>
  if ((which_dev = devintr()) == 0)
    800030b0:	00000097          	auipc	ra,0x0
    800030b4:	9c6080e7          	jalr	-1594(ra) # 80002a76 <devintr>
    800030b8:	c521                	beqz	a0,80003100 <kerneltrap+0x82>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800030ba:	4789                	li	a5,2
    800030bc:	06f50f63          	beq	a0,a5,8000313a <kerneltrap+0xbc>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030c0:	141b1073          	csrw	sepc,s6
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030c4:	100a9073          	csrw	sstatus,s5
}
    800030c8:	60a6                	ld	ra,72(sp)
    800030ca:	6406                	ld	s0,64(sp)
    800030cc:	74e2                	ld	s1,56(sp)
    800030ce:	7942                	ld	s2,48(sp)
    800030d0:	79a2                	ld	s3,40(sp)
    800030d2:	7a02                	ld	s4,32(sp)
    800030d4:	6ae2                	ld	s5,24(sp)
    800030d6:	6b42                	ld	s6,16(sp)
    800030d8:	6ba2                	ld	s7,8(sp)
    800030da:	6c02                	ld	s8,0(sp)
    800030dc:	6161                	addi	sp,sp,80
    800030de:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800030e0:	00005517          	auipc	a0,0x5
    800030e4:	29050513          	addi	a0,a0,656 # 80008370 <digits+0x330>
    800030e8:	ffffd097          	auipc	ra,0xffffd
    800030ec:	456080e7          	jalr	1110(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800030f0:	00005517          	auipc	a0,0x5
    800030f4:	2a850513          	addi	a0,a0,680 # 80008398 <digits+0x358>
    800030f8:	ffffd097          	auipc	ra,0xffffd
    800030fc:	446080e7          	jalr	1094(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003100:	85a6                	mv	a1,s1
    80003102:	00005517          	auipc	a0,0x5
    80003106:	2b650513          	addi	a0,a0,694 # 800083b8 <digits+0x378>
    8000310a:	ffffd097          	auipc	ra,0xffffd
    8000310e:	47e080e7          	jalr	1150(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003112:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003116:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000311a:	00005517          	auipc	a0,0x5
    8000311e:	2ae50513          	addi	a0,a0,686 # 800083c8 <digits+0x388>
    80003122:	ffffd097          	auipc	ra,0xffffd
    80003126:	466080e7          	jalr	1126(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000312a:	00005517          	auipc	a0,0x5
    8000312e:	2b650513          	addi	a0,a0,694 # 800083e0 <digits+0x3a0>
    80003132:	ffffd097          	auipc	ra,0xffffd
    80003136:	40c080e7          	jalr	1036(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000313a:	fffff097          	auipc	ra,0xfffff
    8000313e:	882080e7          	jalr	-1918(ra) # 800019bc <myproc>
    80003142:	dd3d                	beqz	a0,800030c0 <kerneltrap+0x42>
    80003144:	fffff097          	auipc	ra,0xfffff
    80003148:	878080e7          	jalr	-1928(ra) # 800019bc <myproc>
    8000314c:	4d18                	lw	a4,24(a0)
    8000314e:	4791                	li	a5,4
    80003150:	f6f718e3          	bne	a4,a5,800030c0 <kerneltrap+0x42>
    for (p = proc; p < &proc[NPROC]; p++)
    80003154:	0000e497          	auipc	s1,0xe
    80003158:	e0c48493          	addi	s1,s1,-500 # 80010f60 <proc>
      if (p->state == RUNNABLE)
    8000315c:	498d                	li	s3,3
      else if (p->state == RUNNING)
    8000315e:	4a11                	li	s4,4
    for (p = proc; p < &proc[NPROC]; p++)
    80003160:	00015917          	auipc	s2,0x15
    80003164:	80090913          	addi	s2,s2,-2048 # 80017960 <tickslock>
    80003168:	a839                	j	80003186 <kerneltrap+0x108>
        p->wait++;
    8000316a:	17c4a783          	lw	a5,380(s1)
    8000316e:	2785                	addiw	a5,a5,1
    80003170:	16f4ae23          	sw	a5,380(s1)
      release(&p->lock);
    80003174:	8526                	mv	a0,s1
    80003176:	ffffe097          	auipc	ra,0xffffe
    8000317a:	b14080e7          	jalr	-1260(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000317e:	1a848493          	addi	s1,s1,424
    80003182:	03248263          	beq	s1,s2,800031a6 <kerneltrap+0x128>
      acquire(&p->lock);
    80003186:	8526                	mv	a0,s1
    80003188:	ffffe097          	auipc	ra,0xffffe
    8000318c:	a4e080e7          	jalr	-1458(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80003190:	4c9c                	lw	a5,24(s1)
    80003192:	fd378ce3          	beq	a5,s3,8000316a <kerneltrap+0xec>
      else if (p->state == RUNNING)
    80003196:	fd479fe3          	bne	a5,s4,80003174 <kerneltrap+0xf6>
        p->ticks_when_switch++;
    8000319a:	1784a783          	lw	a5,376(s1)
    8000319e:	2785                	addiw	a5,a5,1
    800031a0:	16f4ac23          	sw	a5,376(s1)
    800031a4:	bfc1                	j	80003174 <kerneltrap+0xf6>
    for (p = proc; p < &proc[NPROC]; p++)
    800031a6:	0000e497          	auipc	s1,0xe
    800031aa:	dba48493          	addi	s1,s1,-582 # 80010f60 <proc>
      if (p->state == RUNNABLE)
    800031ae:	498d                	li	s3,3
        if ((p->wait >= 30) && p->queue > 0)
    800031b0:	4a75                	li	s4,29
    for (p = proc; p < &proc[NPROC]; p++)
    800031b2:	00014917          	auipc	s2,0x14
    800031b6:	7ae90913          	addi	s2,s2,1966 # 80017960 <tickslock>
    800031ba:	a811                	j	800031ce <kerneltrap+0x150>
      release(&p->lock);
    800031bc:	8526                	mv	a0,s1
    800031be:	ffffe097          	auipc	ra,0xffffe
    800031c2:	acc080e7          	jalr	-1332(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800031c6:	1a848493          	addi	s1,s1,424
    800031ca:	05248263          	beq	s1,s2,8000320e <kerneltrap+0x190>
      acquire(&p->lock);
    800031ce:	8526                	mv	a0,s1
    800031d0:	ffffe097          	auipc	ra,0xffffe
    800031d4:	a06080e7          	jalr	-1530(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    800031d8:	4c9c                	lw	a5,24(s1)
    800031da:	ff3791e3          	bne	a5,s3,800031bc <kerneltrap+0x13e>
        if ((p->wait >= 30) && p->queue > 0)
    800031de:	17c4a783          	lw	a5,380(s1)
    800031e2:	fcfa5de3          	bge	s4,a5,800031bc <kerneltrap+0x13e>
    800031e6:	1744a783          	lw	a5,372(s1)
    800031ea:	fcf059e3          	blez	a5,800031bc <kerneltrap+0x13e>
          if (myproc()->pid >= 9)
    800031ee:	ffffe097          	auipc	ra,0xffffe
    800031f2:	7ce080e7          	jalr	1998(ra) # 800019bc <myproc>
          p->queue--;
    800031f6:	1744a783          	lw	a5,372(s1)
    800031fa:	37fd                	addiw	a5,a5,-1
    800031fc:	16f4aa23          	sw	a5,372(s1)
          p->new_flag = 0;
    80003200:	1a04a223          	sw	zero,420(s1)
          p->ticks_when_switch = 0;
    80003204:	1604ac23          	sw	zero,376(s1)
          p->wait = 0;
    80003208:	1604ae23          	sw	zero,380(s1)
    8000320c:	bf45                	j	800031bc <kerneltrap+0x13e>
    int current_level = myproc()->queue;
    8000320e:	ffffe097          	auipc	ra,0xffffe
    80003212:	7ae080e7          	jalr	1966(ra) # 800019bc <myproc>
    80003216:	17452c03          	lw	s8,372(a0)
    for (int i = 0; i < current_level; i++)
    8000321a:	4a01                	li	s4,0
        if (p->state == RUNNABLE && p->queue == i)
    8000321c:	498d                	li	s3,3
          myproc()->new_flag = 1;
    8000321e:	4b85                	li	s7,1
      for (p = proc; p < &proc[NPROC]; p++)
    80003220:	00014917          	auipc	s2,0x14
    80003224:	74090913          	addi	s2,s2,1856 # 80017960 <tickslock>
    for (int i = 0; i < current_level; i++)
    80003228:	09804b63          	bgtz	s8,800032be <kerneltrap+0x240>
    int queu_of_myproc = myproc()->queue;
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	790080e7          	jalr	1936(ra) # 800019bc <myproc>
    80003234:	17452783          	lw	a5,372(a0)
    if (queu_of_myproc == 0)
    80003238:	cbc1                	beqz	a5,800032c8 <kerneltrap+0x24a>
    else if (queu_of_myproc == 1)
    8000323a:	4705                	li	a4,1
    8000323c:	0ee78363          	beq	a5,a4,80003322 <kerneltrap+0x2a4>
    else if (queu_of_myproc == 2)
    80003240:	4709                	li	a4,2
    80003242:	12e78d63          	beq	a5,a4,8000337c <kerneltrap+0x2fe>
    else if (queu_of_myproc == 3)
    80003246:	470d                	li	a4,3
    80003248:	e6e79ce3          	bne	a5,a4,800030c0 <kerneltrap+0x42>
      if (myproc()->ticks_when_switch == 15)
    8000324c:	ffffe097          	auipc	ra,0xffffe
    80003250:	770080e7          	jalr	1904(ra) # 800019bc <myproc>
    80003254:	17852703          	lw	a4,376(a0)
    80003258:	47bd                	li	a5,15
    8000325a:	e6f713e3          	bne	a4,a5,800030c0 <kerneltrap+0x42>
        myproc()->new_flag = 0;
    8000325e:	ffffe097          	auipc	ra,0xffffe
    80003262:	75e080e7          	jalr	1886(ra) # 800019bc <myproc>
    80003266:	1a052223          	sw	zero,420(a0)
        myproc()->wait = 0;
    8000326a:	ffffe097          	auipc	ra,0xffffe
    8000326e:	752080e7          	jalr	1874(ra) # 800019bc <myproc>
    80003272:	16052e23          	sw	zero,380(a0)
        myproc()->ticks_when_switch = 0;
    80003276:	ffffe097          	auipc	ra,0xffffe
    8000327a:	746080e7          	jalr	1862(ra) # 800019bc <myproc>
    8000327e:	16052c23          	sw	zero,376(a0)
        yield();
    80003282:	fffff097          	auipc	ra,0xfffff
    80003286:	f8e080e7          	jalr	-114(ra) # 80002210 <yield>
    8000328a:	bd1d                	j	800030c0 <kerneltrap+0x42>
      for (p = proc; p < &proc[NPROC]; p++)
    8000328c:	1a848493          	addi	s1,s1,424
    80003290:	03248463          	beq	s1,s2,800032b8 <kerneltrap+0x23a>
        if (p->state == RUNNABLE && p->queue == i)
    80003294:	4c9c                	lw	a5,24(s1)
    80003296:	ff379be3          	bne	a5,s3,8000328c <kerneltrap+0x20e>
    8000329a:	1744a783          	lw	a5,372(s1)
    8000329e:	ff4797e3          	bne	a5,s4,8000328c <kerneltrap+0x20e>
          myproc()->new_flag = 1;
    800032a2:	ffffe097          	auipc	ra,0xffffe
    800032a6:	71a080e7          	jalr	1818(ra) # 800019bc <myproc>
    800032aa:	1b752223          	sw	s7,420(a0)
          yield();
    800032ae:	fffff097          	auipc	ra,0xfffff
    800032b2:	f62080e7          	jalr	-158(ra) # 80002210 <yield>
    800032b6:	bfd9                	j	8000328c <kerneltrap+0x20e>
    for (int i = 0; i < current_level; i++)
    800032b8:	2a05                	addiw	s4,s4,1
    800032ba:	f74c09e3          	beq	s8,s4,8000322c <kerneltrap+0x1ae>
      for (p = proc; p < &proc[NPROC]; p++)
    800032be:	0000e497          	auipc	s1,0xe
    800032c2:	ca248493          	addi	s1,s1,-862 # 80010f60 <proc>
    800032c6:	b7f9                	j	80003294 <kerneltrap+0x216>
      if (myproc()->ticks_when_switch == 1)
    800032c8:	ffffe097          	auipc	ra,0xffffe
    800032cc:	6f4080e7          	jalr	1780(ra) # 800019bc <myproc>
    800032d0:	17852703          	lw	a4,376(a0)
    800032d4:	4785                	li	a5,1
    800032d6:	def715e3          	bne	a4,a5,800030c0 <kerneltrap+0x42>
        myproc()->queue++;
    800032da:	ffffe097          	auipc	ra,0xffffe
    800032de:	6e2080e7          	jalr	1762(ra) # 800019bc <myproc>
    800032e2:	17452703          	lw	a4,372(a0)
    800032e6:	2705                	addiw	a4,a4,1
    800032e8:	16e52a23          	sw	a4,372(a0)
        if (myproc()->pid >= 9)
    800032ec:	ffffe097          	auipc	ra,0xffffe
    800032f0:	6d0080e7          	jalr	1744(ra) # 800019bc <myproc>
        myproc()->ticks_when_switch = 0;
    800032f4:	ffffe097          	auipc	ra,0xffffe
    800032f8:	6c8080e7          	jalr	1736(ra) # 800019bc <myproc>
    800032fc:	16052c23          	sw	zero,376(a0)
        myproc()->wait = 0;
    80003300:	ffffe097          	auipc	ra,0xffffe
    80003304:	6bc080e7          	jalr	1724(ra) # 800019bc <myproc>
    80003308:	16052e23          	sw	zero,380(a0)
        myproc()->new_flag = 0;
    8000330c:	ffffe097          	auipc	ra,0xffffe
    80003310:	6b0080e7          	jalr	1712(ra) # 800019bc <myproc>
    80003314:	1a052223          	sw	zero,420(a0)
        yield();
    80003318:	fffff097          	auipc	ra,0xfffff
    8000331c:	ef8080e7          	jalr	-264(ra) # 80002210 <yield>
    80003320:	b345                	j	800030c0 <kerneltrap+0x42>
      if (myproc()->ticks_when_switch == 3)
    80003322:	ffffe097          	auipc	ra,0xffffe
    80003326:	69a080e7          	jalr	1690(ra) # 800019bc <myproc>
    8000332a:	17852703          	lw	a4,376(a0)
    8000332e:	478d                	li	a5,3
    80003330:	d8f718e3          	bne	a4,a5,800030c0 <kerneltrap+0x42>
        myproc()->queue++;
    80003334:	ffffe097          	auipc	ra,0xffffe
    80003338:	688080e7          	jalr	1672(ra) # 800019bc <myproc>
    8000333c:	17452703          	lw	a4,372(a0)
    80003340:	2705                	addiw	a4,a4,1
    80003342:	16e52a23          	sw	a4,372(a0)
        if (myproc()->pid >= 9)
    80003346:	ffffe097          	auipc	ra,0xffffe
    8000334a:	676080e7          	jalr	1654(ra) # 800019bc <myproc>
        myproc()->ticks_when_switch = 0;
    8000334e:	ffffe097          	auipc	ra,0xffffe
    80003352:	66e080e7          	jalr	1646(ra) # 800019bc <myproc>
    80003356:	16052c23          	sw	zero,376(a0)
        myproc()->wait = 0;
    8000335a:	ffffe097          	auipc	ra,0xffffe
    8000335e:	662080e7          	jalr	1634(ra) # 800019bc <myproc>
    80003362:	16052e23          	sw	zero,380(a0)
        myproc()->new_flag = 0;
    80003366:	ffffe097          	auipc	ra,0xffffe
    8000336a:	656080e7          	jalr	1622(ra) # 800019bc <myproc>
    8000336e:	1a052223          	sw	zero,420(a0)
        yield();
    80003372:	fffff097          	auipc	ra,0xfffff
    80003376:	e9e080e7          	jalr	-354(ra) # 80002210 <yield>
    8000337a:	b399                	j	800030c0 <kerneltrap+0x42>
      if (myproc()->ticks_when_switch == 9)
    8000337c:	ffffe097          	auipc	ra,0xffffe
    80003380:	640080e7          	jalr	1600(ra) # 800019bc <myproc>
    80003384:	17852703          	lw	a4,376(a0)
    80003388:	47a5                	li	a5,9
    8000338a:	d2f71be3          	bne	a4,a5,800030c0 <kerneltrap+0x42>
        myproc()->queue++;
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	62e080e7          	jalr	1582(ra) # 800019bc <myproc>
    80003396:	17452703          	lw	a4,372(a0)
    8000339a:	2705                	addiw	a4,a4,1
    8000339c:	16e52a23          	sw	a4,372(a0)
        if (myproc()->pid >= 9)
    800033a0:	ffffe097          	auipc	ra,0xffffe
    800033a4:	61c080e7          	jalr	1564(ra) # 800019bc <myproc>
        myproc()->ticks_when_switch = 0;
    800033a8:	ffffe097          	auipc	ra,0xffffe
    800033ac:	614080e7          	jalr	1556(ra) # 800019bc <myproc>
    800033b0:	16052c23          	sw	zero,376(a0)
        myproc()->wait = 0;
    800033b4:	ffffe097          	auipc	ra,0xffffe
    800033b8:	608080e7          	jalr	1544(ra) # 800019bc <myproc>
    800033bc:	16052e23          	sw	zero,380(a0)
        myproc()->new_flag = 0;
    800033c0:	ffffe097          	auipc	ra,0xffffe
    800033c4:	5fc080e7          	jalr	1532(ra) # 800019bc <myproc>
    800033c8:	1a052223          	sw	zero,420(a0)
        yield();
    800033cc:	fffff097          	auipc	ra,0xfffff
    800033d0:	e44080e7          	jalr	-444(ra) # 80002210 <yield>
    800033d4:	b1f5                	j	800030c0 <kerneltrap+0x42>

00000000800033d6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800033d6:	1101                	addi	sp,sp,-32
    800033d8:	ec06                	sd	ra,24(sp)
    800033da:	e822                	sd	s0,16(sp)
    800033dc:	e426                	sd	s1,8(sp)
    800033de:	1000                	addi	s0,sp,32
    800033e0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800033e2:	ffffe097          	auipc	ra,0xffffe
    800033e6:	5da080e7          	jalr	1498(ra) # 800019bc <myproc>
  switch (n) {
    800033ea:	4795                	li	a5,5
    800033ec:	0497e163          	bltu	a5,s1,8000342e <argraw+0x58>
    800033f0:	048a                	slli	s1,s1,0x2
    800033f2:	00005717          	auipc	a4,0x5
    800033f6:	02670713          	addi	a4,a4,38 # 80008418 <digits+0x3d8>
    800033fa:	94ba                	add	s1,s1,a4
    800033fc:	409c                	lw	a5,0(s1)
    800033fe:	97ba                	add	a5,a5,a4
    80003400:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003402:	6d3c                	ld	a5,88(a0)
    80003404:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003406:	60e2                	ld	ra,24(sp)
    80003408:	6442                	ld	s0,16(sp)
    8000340a:	64a2                	ld	s1,8(sp)
    8000340c:	6105                	addi	sp,sp,32
    8000340e:	8082                	ret
    return p->trapframe->a1;
    80003410:	6d3c                	ld	a5,88(a0)
    80003412:	7fa8                	ld	a0,120(a5)
    80003414:	bfcd                	j	80003406 <argraw+0x30>
    return p->trapframe->a2;
    80003416:	6d3c                	ld	a5,88(a0)
    80003418:	63c8                	ld	a0,128(a5)
    8000341a:	b7f5                	j	80003406 <argraw+0x30>
    return p->trapframe->a3;
    8000341c:	6d3c                	ld	a5,88(a0)
    8000341e:	67c8                	ld	a0,136(a5)
    80003420:	b7dd                	j	80003406 <argraw+0x30>
    return p->trapframe->a4;
    80003422:	6d3c                	ld	a5,88(a0)
    80003424:	6bc8                	ld	a0,144(a5)
    80003426:	b7c5                	j	80003406 <argraw+0x30>
    return p->trapframe->a5;
    80003428:	6d3c                	ld	a5,88(a0)
    8000342a:	6fc8                	ld	a0,152(a5)
    8000342c:	bfe9                	j	80003406 <argraw+0x30>
  panic("argraw");
    8000342e:	00005517          	auipc	a0,0x5
    80003432:	fc250513          	addi	a0,a0,-62 # 800083f0 <digits+0x3b0>
    80003436:	ffffd097          	auipc	ra,0xffffd
    8000343a:	108080e7          	jalr	264(ra) # 8000053e <panic>

000000008000343e <fetchaddr>:
{
    8000343e:	1101                	addi	sp,sp,-32
    80003440:	ec06                	sd	ra,24(sp)
    80003442:	e822                	sd	s0,16(sp)
    80003444:	e426                	sd	s1,8(sp)
    80003446:	e04a                	sd	s2,0(sp)
    80003448:	1000                	addi	s0,sp,32
    8000344a:	84aa                	mv	s1,a0
    8000344c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000344e:	ffffe097          	auipc	ra,0xffffe
    80003452:	56e080e7          	jalr	1390(ra) # 800019bc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003456:	653c                	ld	a5,72(a0)
    80003458:	02f4f863          	bgeu	s1,a5,80003488 <fetchaddr+0x4a>
    8000345c:	00848713          	addi	a4,s1,8
    80003460:	02e7e663          	bltu	a5,a4,8000348c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003464:	46a1                	li	a3,8
    80003466:	8626                	mv	a2,s1
    80003468:	85ca                	mv	a1,s2
    8000346a:	6928                	ld	a0,80(a0)
    8000346c:	ffffe097          	auipc	ra,0xffffe
    80003470:	298080e7          	jalr	664(ra) # 80001704 <copyin>
    80003474:	00a03533          	snez	a0,a0
    80003478:	40a00533          	neg	a0,a0
}
    8000347c:	60e2                	ld	ra,24(sp)
    8000347e:	6442                	ld	s0,16(sp)
    80003480:	64a2                	ld	s1,8(sp)
    80003482:	6902                	ld	s2,0(sp)
    80003484:	6105                	addi	sp,sp,32
    80003486:	8082                	ret
    return -1;
    80003488:	557d                	li	a0,-1
    8000348a:	bfcd                	j	8000347c <fetchaddr+0x3e>
    8000348c:	557d                	li	a0,-1
    8000348e:	b7fd                	j	8000347c <fetchaddr+0x3e>

0000000080003490 <fetchstr>:
{
    80003490:	7179                	addi	sp,sp,-48
    80003492:	f406                	sd	ra,40(sp)
    80003494:	f022                	sd	s0,32(sp)
    80003496:	ec26                	sd	s1,24(sp)
    80003498:	e84a                	sd	s2,16(sp)
    8000349a:	e44e                	sd	s3,8(sp)
    8000349c:	1800                	addi	s0,sp,48
    8000349e:	892a                	mv	s2,a0
    800034a0:	84ae                	mv	s1,a1
    800034a2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800034a4:	ffffe097          	auipc	ra,0xffffe
    800034a8:	518080e7          	jalr	1304(ra) # 800019bc <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800034ac:	86ce                	mv	a3,s3
    800034ae:	864a                	mv	a2,s2
    800034b0:	85a6                	mv	a1,s1
    800034b2:	6928                	ld	a0,80(a0)
    800034b4:	ffffe097          	auipc	ra,0xffffe
    800034b8:	2de080e7          	jalr	734(ra) # 80001792 <copyinstr>
    800034bc:	00054e63          	bltz	a0,800034d8 <fetchstr+0x48>
  return strlen(buf);
    800034c0:	8526                	mv	a0,s1
    800034c2:	ffffe097          	auipc	ra,0xffffe
    800034c6:	98c080e7          	jalr	-1652(ra) # 80000e4e <strlen>
}
    800034ca:	70a2                	ld	ra,40(sp)
    800034cc:	7402                	ld	s0,32(sp)
    800034ce:	64e2                	ld	s1,24(sp)
    800034d0:	6942                	ld	s2,16(sp)
    800034d2:	69a2                	ld	s3,8(sp)
    800034d4:	6145                	addi	sp,sp,48
    800034d6:	8082                	ret
    return -1;
    800034d8:	557d                	li	a0,-1
    800034da:	bfc5                	j	800034ca <fetchstr+0x3a>

00000000800034dc <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800034dc:	1101                	addi	sp,sp,-32
    800034de:	ec06                	sd	ra,24(sp)
    800034e0:	e822                	sd	s0,16(sp)
    800034e2:	e426                	sd	s1,8(sp)
    800034e4:	1000                	addi	s0,sp,32
    800034e6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800034e8:	00000097          	auipc	ra,0x0
    800034ec:	eee080e7          	jalr	-274(ra) # 800033d6 <argraw>
    800034f0:	c088                	sw	a0,0(s1)
}
    800034f2:	60e2                	ld	ra,24(sp)
    800034f4:	6442                	ld	s0,16(sp)
    800034f6:	64a2                	ld	s1,8(sp)
    800034f8:	6105                	addi	sp,sp,32
    800034fa:	8082                	ret

00000000800034fc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800034fc:	1101                	addi	sp,sp,-32
    800034fe:	ec06                	sd	ra,24(sp)
    80003500:	e822                	sd	s0,16(sp)
    80003502:	e426                	sd	s1,8(sp)
    80003504:	1000                	addi	s0,sp,32
    80003506:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003508:	00000097          	auipc	ra,0x0
    8000350c:	ece080e7          	jalr	-306(ra) # 800033d6 <argraw>
    80003510:	e088                	sd	a0,0(s1)
}
    80003512:	60e2                	ld	ra,24(sp)
    80003514:	6442                	ld	s0,16(sp)
    80003516:	64a2                	ld	s1,8(sp)
    80003518:	6105                	addi	sp,sp,32
    8000351a:	8082                	ret

000000008000351c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000351c:	7179                	addi	sp,sp,-48
    8000351e:	f406                	sd	ra,40(sp)
    80003520:	f022                	sd	s0,32(sp)
    80003522:	ec26                	sd	s1,24(sp)
    80003524:	e84a                	sd	s2,16(sp)
    80003526:	1800                	addi	s0,sp,48
    80003528:	84ae                	mv	s1,a1
    8000352a:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    8000352c:	fd840593          	addi	a1,s0,-40
    80003530:	00000097          	auipc	ra,0x0
    80003534:	fcc080e7          	jalr	-52(ra) # 800034fc <argaddr>
  return fetchstr(addr, buf, max);
    80003538:	864a                	mv	a2,s2
    8000353a:	85a6                	mv	a1,s1
    8000353c:	fd843503          	ld	a0,-40(s0)
    80003540:	00000097          	auipc	ra,0x0
    80003544:	f50080e7          	jalr	-176(ra) # 80003490 <fetchstr>
}
    80003548:	70a2                	ld	ra,40(sp)
    8000354a:	7402                	ld	s0,32(sp)
    8000354c:	64e2                	ld	s1,24(sp)
    8000354e:	6942                	ld	s2,16(sp)
    80003550:	6145                	addi	sp,sp,48
    80003552:	8082                	ret

0000000080003554 <syscall>:
[SYS_sigreturn] sys_sigreturn,
};

void
syscall(void)
{
    80003554:	1101                	addi	sp,sp,-32
    80003556:	ec06                	sd	ra,24(sp)
    80003558:	e822                	sd	s0,16(sp)
    8000355a:	e426                	sd	s1,8(sp)
    8000355c:	e04a                	sd	s2,0(sp)
    8000355e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003560:	ffffe097          	auipc	ra,0xffffe
    80003564:	45c080e7          	jalr	1116(ra) # 800019bc <myproc>
    80003568:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000356a:	05853903          	ld	s2,88(a0)
    8000356e:	0a893783          	ld	a5,168(s2)
    80003572:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003576:	37fd                	addiw	a5,a5,-1
    80003578:	4761                	li	a4,24
    8000357a:	00f76f63          	bltu	a4,a5,80003598 <syscall+0x44>
    8000357e:	00369713          	slli	a4,a3,0x3
    80003582:	00005797          	auipc	a5,0x5
    80003586:	eae78793          	addi	a5,a5,-338 # 80008430 <syscalls>
    8000358a:	97ba                	add	a5,a5,a4
    8000358c:	639c                	ld	a5,0(a5)
    8000358e:	c789                	beqz	a5,80003598 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003590:	9782                	jalr	a5
    80003592:	06a93823          	sd	a0,112(s2)
    80003596:	a839                	j	800035b4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003598:	15848613          	addi	a2,s1,344
    8000359c:	588c                	lw	a1,48(s1)
    8000359e:	00005517          	auipc	a0,0x5
    800035a2:	e5a50513          	addi	a0,a0,-422 # 800083f8 <digits+0x3b8>
    800035a6:	ffffd097          	auipc	ra,0xffffd
    800035aa:	fe2080e7          	jalr	-30(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800035ae:	6cbc                	ld	a5,88(s1)
    800035b0:	577d                	li	a4,-1
    800035b2:	fbb8                	sd	a4,112(a5)
  }
}
    800035b4:	60e2                	ld	ra,24(sp)
    800035b6:	6442                	ld	s0,16(sp)
    800035b8:	64a2                	ld	s1,8(sp)
    800035ba:	6902                	ld	s2,0(sp)
    800035bc:	6105                	addi	sp,sp,32
    800035be:	8082                	ret

00000000800035c0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"
extern int getread_count;
uint64
sys_exit(void)
{
    800035c0:	1101                	addi	sp,sp,-32
    800035c2:	ec06                	sd	ra,24(sp)
    800035c4:	e822                	sd	s0,16(sp)
    800035c6:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800035c8:	fec40593          	addi	a1,s0,-20
    800035cc:	4501                	li	a0,0
    800035ce:	00000097          	auipc	ra,0x0
    800035d2:	f0e080e7          	jalr	-242(ra) # 800034dc <argint>
  exit(n);
    800035d6:	fec42503          	lw	a0,-20(s0)
    800035da:	fffff097          	auipc	ra,0xfffff
    800035de:	da6080e7          	jalr	-602(ra) # 80002380 <exit>
  return 0; // not reached
}
    800035e2:	4501                	li	a0,0
    800035e4:	60e2                	ld	ra,24(sp)
    800035e6:	6442                	ld	s0,16(sp)
    800035e8:	6105                	addi	sp,sp,32
    800035ea:	8082                	ret

00000000800035ec <sys_getreadcount>:
uint64
sys_getreadcount(void)
{
    800035ec:	1141                	addi	sp,sp,-16
    800035ee:	e422                	sd	s0,8(sp)
    800035f0:	0800                	addi	s0,sp,16
  return getread_count;
}
    800035f2:	00005517          	auipc	a0,0x5
    800035f6:	2b652503          	lw	a0,694(a0) # 800088a8 <getread_count>
    800035fa:	6422                	ld	s0,8(sp)
    800035fc:	0141                	addi	sp,sp,16
    800035fe:	8082                	ret

0000000080003600 <sys_getpid>:
uint64
sys_getpid(void)
{
    80003600:	1141                	addi	sp,sp,-16
    80003602:	e406                	sd	ra,8(sp)
    80003604:	e022                	sd	s0,0(sp)
    80003606:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003608:	ffffe097          	auipc	ra,0xffffe
    8000360c:	3b4080e7          	jalr	948(ra) # 800019bc <myproc>
}
    80003610:	5908                	lw	a0,48(a0)
    80003612:	60a2                	ld	ra,8(sp)
    80003614:	6402                	ld	s0,0(sp)
    80003616:	0141                	addi	sp,sp,16
    80003618:	8082                	ret

000000008000361a <sys_fork>:

uint64
sys_fork(void)
{
    8000361a:	1141                	addi	sp,sp,-16
    8000361c:	e406                	sd	ra,8(sp)
    8000361e:	e022                	sd	s0,0(sp)
    80003620:	0800                	addi	s0,sp,16
  return fork();
    80003622:	ffffe097          	auipc	ra,0xffffe
    80003626:	79e080e7          	jalr	1950(ra) # 80001dc0 <fork>
}
    8000362a:	60a2                	ld	ra,8(sp)
    8000362c:	6402                	ld	s0,0(sp)
    8000362e:	0141                	addi	sp,sp,16
    80003630:	8082                	ret

0000000080003632 <sys_wait>:

uint64
sys_wait(void)
{
    80003632:	1101                	addi	sp,sp,-32
    80003634:	ec06                	sd	ra,24(sp)
    80003636:	e822                	sd	s0,16(sp)
    80003638:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000363a:	fe840593          	addi	a1,s0,-24
    8000363e:	4501                	li	a0,0
    80003640:	00000097          	auipc	ra,0x0
    80003644:	ebc080e7          	jalr	-324(ra) # 800034fc <argaddr>
  return wait(p);
    80003648:	fe843503          	ld	a0,-24(s0)
    8000364c:	fffff097          	auipc	ra,0xfffff
    80003650:	ee6080e7          	jalr	-282(ra) # 80002532 <wait>
}
    80003654:	60e2                	ld	ra,24(sp)
    80003656:	6442                	ld	s0,16(sp)
    80003658:	6105                	addi	sp,sp,32
    8000365a:	8082                	ret

000000008000365c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000365c:	7179                	addi	sp,sp,-48
    8000365e:	f406                	sd	ra,40(sp)
    80003660:	f022                	sd	s0,32(sp)
    80003662:	ec26                	sd	s1,24(sp)
    80003664:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003666:	fdc40593          	addi	a1,s0,-36
    8000366a:	4501                	li	a0,0
    8000366c:	00000097          	auipc	ra,0x0
    80003670:	e70080e7          	jalr	-400(ra) # 800034dc <argint>
  addr = myproc()->sz;
    80003674:	ffffe097          	auipc	ra,0xffffe
    80003678:	348080e7          	jalr	840(ra) # 800019bc <myproc>
    8000367c:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    8000367e:	fdc42503          	lw	a0,-36(s0)
    80003682:	ffffe097          	auipc	ra,0xffffe
    80003686:	6e2080e7          	jalr	1762(ra) # 80001d64 <growproc>
    8000368a:	00054863          	bltz	a0,8000369a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000368e:	8526                	mv	a0,s1
    80003690:	70a2                	ld	ra,40(sp)
    80003692:	7402                	ld	s0,32(sp)
    80003694:	64e2                	ld	s1,24(sp)
    80003696:	6145                	addi	sp,sp,48
    80003698:	8082                	ret
    return -1;
    8000369a:	54fd                	li	s1,-1
    8000369c:	bfcd                	j	8000368e <sys_sbrk+0x32>

000000008000369e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000369e:	7139                	addi	sp,sp,-64
    800036a0:	fc06                	sd	ra,56(sp)
    800036a2:	f822                	sd	s0,48(sp)
    800036a4:	f426                	sd	s1,40(sp)
    800036a6:	f04a                	sd	s2,32(sp)
    800036a8:	ec4e                	sd	s3,24(sp)
    800036aa:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800036ac:	fcc40593          	addi	a1,s0,-52
    800036b0:	4501                	li	a0,0
    800036b2:	00000097          	auipc	ra,0x0
    800036b6:	e2a080e7          	jalr	-470(ra) # 800034dc <argint>
  acquire(&tickslock);
    800036ba:	00014517          	auipc	a0,0x14
    800036be:	2a650513          	addi	a0,a0,678 # 80017960 <tickslock>
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	514080e7          	jalr	1300(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    800036ca:	00005917          	auipc	s2,0x5
    800036ce:	1f692903          	lw	s2,502(s2) # 800088c0 <ticks>
  while (ticks - ticks0 < n)
    800036d2:	fcc42783          	lw	a5,-52(s0)
    800036d6:	cf9d                	beqz	a5,80003714 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800036d8:	00014997          	auipc	s3,0x14
    800036dc:	28898993          	addi	s3,s3,648 # 80017960 <tickslock>
    800036e0:	00005497          	auipc	s1,0x5
    800036e4:	1e048493          	addi	s1,s1,480 # 800088c0 <ticks>
    if (killed(myproc()))
    800036e8:	ffffe097          	auipc	ra,0xffffe
    800036ec:	2d4080e7          	jalr	724(ra) # 800019bc <myproc>
    800036f0:	fffff097          	auipc	ra,0xfffff
    800036f4:	e10080e7          	jalr	-496(ra) # 80002500 <killed>
    800036f8:	ed15                	bnez	a0,80003734 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800036fa:	85ce                	mv	a1,s3
    800036fc:	8526                	mv	a0,s1
    800036fe:	fffff097          	auipc	ra,0xfffff
    80003702:	b4e080e7          	jalr	-1202(ra) # 8000224c <sleep>
  while (ticks - ticks0 < n)
    80003706:	409c                	lw	a5,0(s1)
    80003708:	412787bb          	subw	a5,a5,s2
    8000370c:	fcc42703          	lw	a4,-52(s0)
    80003710:	fce7ece3          	bltu	a5,a4,800036e8 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003714:	00014517          	auipc	a0,0x14
    80003718:	24c50513          	addi	a0,a0,588 # 80017960 <tickslock>
    8000371c:	ffffd097          	auipc	ra,0xffffd
    80003720:	56e080e7          	jalr	1390(ra) # 80000c8a <release>
  return 0;
    80003724:	4501                	li	a0,0
}
    80003726:	70e2                	ld	ra,56(sp)
    80003728:	7442                	ld	s0,48(sp)
    8000372a:	74a2                	ld	s1,40(sp)
    8000372c:	7902                	ld	s2,32(sp)
    8000372e:	69e2                	ld	s3,24(sp)
    80003730:	6121                	addi	sp,sp,64
    80003732:	8082                	ret
      release(&tickslock);
    80003734:	00014517          	auipc	a0,0x14
    80003738:	22c50513          	addi	a0,a0,556 # 80017960 <tickslock>
    8000373c:	ffffd097          	auipc	ra,0xffffd
    80003740:	54e080e7          	jalr	1358(ra) # 80000c8a <release>
      return -1;
    80003744:	557d                	li	a0,-1
    80003746:	b7c5                	j	80003726 <sys_sleep+0x88>

0000000080003748 <sys_kill>:
// {
//   return getre
// }
uint64
sys_kill(void)
{
    80003748:	1101                	addi	sp,sp,-32
    8000374a:	ec06                	sd	ra,24(sp)
    8000374c:	e822                	sd	s0,16(sp)
    8000374e:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003750:	fec40593          	addi	a1,s0,-20
    80003754:	4501                	li	a0,0
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	d86080e7          	jalr	-634(ra) # 800034dc <argint>
  return kill(pid);
    8000375e:	fec42503          	lw	a0,-20(s0)
    80003762:	fffff097          	auipc	ra,0xfffff
    80003766:	d00080e7          	jalr	-768(ra) # 80002462 <kill>
}
    8000376a:	60e2                	ld	ra,24(sp)
    8000376c:	6442                	ld	s0,16(sp)
    8000376e:	6105                	addi	sp,sp,32
    80003770:	8082                	ret

0000000080003772 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003772:	1101                	addi	sp,sp,-32
    80003774:	ec06                	sd	ra,24(sp)
    80003776:	e822                	sd	s0,16(sp)
    80003778:	e426                	sd	s1,8(sp)
    8000377a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000377c:	00014517          	auipc	a0,0x14
    80003780:	1e450513          	addi	a0,a0,484 # 80017960 <tickslock>
    80003784:	ffffd097          	auipc	ra,0xffffd
    80003788:	452080e7          	jalr	1106(ra) # 80000bd6 <acquire>
  xticks = ticks;
    8000378c:	00005497          	auipc	s1,0x5
    80003790:	1344a483          	lw	s1,308(s1) # 800088c0 <ticks>
  release(&tickslock);
    80003794:	00014517          	auipc	a0,0x14
    80003798:	1cc50513          	addi	a0,a0,460 # 80017960 <tickslock>
    8000379c:	ffffd097          	auipc	ra,0xffffd
    800037a0:	4ee080e7          	jalr	1262(ra) # 80000c8a <release>
  return xticks;
}
    800037a4:	02049513          	slli	a0,s1,0x20
    800037a8:	9101                	srli	a0,a0,0x20
    800037aa:	60e2                	ld	ra,24(sp)
    800037ac:	6442                	ld	s0,16(sp)
    800037ae:	64a2                	ld	s1,8(sp)
    800037b0:	6105                	addi	sp,sp,32
    800037b2:	8082                	ret

00000000800037b4 <sys_waitx>:

uint64
sys_waitx(void)
{
    800037b4:	7139                	addi	sp,sp,-64
    800037b6:	fc06                	sd	ra,56(sp)
    800037b8:	f822                	sd	s0,48(sp)
    800037ba:	f426                	sd	s1,40(sp)
    800037bc:	f04a                	sd	s2,32(sp)
    800037be:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800037c0:	fd840593          	addi	a1,s0,-40
    800037c4:	4501                	li	a0,0
    800037c6:	00000097          	auipc	ra,0x0
    800037ca:	d36080e7          	jalr	-714(ra) # 800034fc <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800037ce:	fd040593          	addi	a1,s0,-48
    800037d2:	4505                	li	a0,1
    800037d4:	00000097          	auipc	ra,0x0
    800037d8:	d28080e7          	jalr	-728(ra) # 800034fc <argaddr>
  argaddr(2, &addr2);
    800037dc:	fc840593          	addi	a1,s0,-56
    800037e0:	4509                	li	a0,2
    800037e2:	00000097          	auipc	ra,0x0
    800037e6:	d1a080e7          	jalr	-742(ra) # 800034fc <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800037ea:	fc040613          	addi	a2,s0,-64
    800037ee:	fc440593          	addi	a1,s0,-60
    800037f2:	fd843503          	ld	a0,-40(s0)
    800037f6:	fffff097          	auipc	ra,0xfffff
    800037fa:	f2a080e7          	jalr	-214(ra) # 80002720 <waitx>
    800037fe:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003800:	ffffe097          	auipc	ra,0xffffe
    80003804:	1bc080e7          	jalr	444(ra) # 800019bc <myproc>
    80003808:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000380a:	4691                	li	a3,4
    8000380c:	fc440613          	addi	a2,s0,-60
    80003810:	fd043583          	ld	a1,-48(s0)
    80003814:	6928                	ld	a0,80(a0)
    80003816:	ffffe097          	auipc	ra,0xffffe
    8000381a:	e62080e7          	jalr	-414(ra) # 80001678 <copyout>
    return -1;
    8000381e:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003820:	00054f63          	bltz	a0,8000383e <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003824:	4691                	li	a3,4
    80003826:	fc040613          	addi	a2,s0,-64
    8000382a:	fc843583          	ld	a1,-56(s0)
    8000382e:	68a8                	ld	a0,80(s1)
    80003830:	ffffe097          	auipc	ra,0xffffe
    80003834:	e48080e7          	jalr	-440(ra) # 80001678 <copyout>
    80003838:	00054a63          	bltz	a0,8000384c <sys_waitx+0x98>
    return -1;
  return ret;
    8000383c:	87ca                	mv	a5,s2
}
    8000383e:	853e                	mv	a0,a5
    80003840:	70e2                	ld	ra,56(sp)
    80003842:	7442                	ld	s0,48(sp)
    80003844:	74a2                	ld	s1,40(sp)
    80003846:	7902                	ld	s2,32(sp)
    80003848:	6121                	addi	sp,sp,64
    8000384a:	8082                	ret
    return -1;
    8000384c:	57fd                	li	a5,-1
    8000384e:	bfc5                	j	8000383e <sys_waitx+0x8a>

0000000080003850 <sys_sigalarm>:
extern ptrtotrapframe arr_of_trapframes_storing_past[1000010];

uint64 sys_sigalarm(void)
{
    80003850:	7179                	addi	sp,sp,-48
    80003852:	f406                	sd	ra,40(sp)
    80003854:	f022                	sd	s0,32(sp)
    80003856:	ec26                	sd	s1,24(sp)
    80003858:	1800                	addi	s0,sp,48
  uint64 address_of_handler;
  uint64 no_of_ticks;

  argaddr(0, &no_of_ticks);
    8000385a:	fd040593          	addi	a1,s0,-48
    8000385e:	4501                	li	a0,0
    80003860:	00000097          	auipc	ra,0x0
    80003864:	c9c080e7          	jalr	-868(ra) # 800034fc <argaddr>
  argaddr(1, &address_of_handler);
    80003868:	fd840593          	addi	a1,s0,-40
    8000386c:	4505                	li	a0,1
    8000386e:	00000097          	auipc	ra,0x0
    80003872:	c8e080e7          	jalr	-882(ra) # 800034fc <argaddr>
  // address_of_handler = argc
  myproc()->no_of_ticks = no_of_ticks;
    80003876:	fd043483          	ld	s1,-48(s0)
    8000387a:	ffffe097          	auipc	ra,0xffffe
    8000387e:	142080e7          	jalr	322(ra) # 800019bc <myproc>
    80003882:	18952023          	sw	s1,384(a0)
  myproc()->handler = address_of_handler;
    80003886:	ffffe097          	auipc	ra,0xffffe
    8000388a:	136080e7          	jalr	310(ra) # 800019bc <myproc>
    8000388e:	fd843783          	ld	a5,-40(s0)
    80003892:	18f53423          	sd	a5,392(a0)
  return 0; 
}
    80003896:	4501                	li	a0,0
    80003898:	70a2                	ld	ra,40(sp)
    8000389a:	7402                	ld	s0,32(sp)
    8000389c:	64e2                	ld	s1,24(sp)
    8000389e:	6145                	addi	sp,sp,48
    800038a0:	8082                	ret

00000000800038a2 <sys_sigreturn>:
uint64 sys_sigreturn(void)
{
    800038a2:	1101                	addi	sp,sp,-32
    800038a4:	ec06                	sd	ra,24(sp)
    800038a6:	e822                	sd	s0,16(sp)
    800038a8:	e426                	sd	s1,8(sp)
    800038aa:	e04a                	sd	s2,0(sp)
    800038ac:	1000                	addi	s0,sp,32
  memmove(myproc()->trapframe,arr_of_trapframes_storing_past[myproc()->pid], PGSIZE);
    800038ae:	ffffe097          	auipc	ra,0xffffe
    800038b2:	10e080e7          	jalr	270(ra) # 800019bc <myproc>
    800038b6:	05853903          	ld	s2,88(a0)
    800038ba:	ffffe097          	auipc	ra,0xffffe
    800038be:	102080e7          	jalr	258(ra) # 800019bc <myproc>
    800038c2:	00014497          	auipc	s1,0x14
    800038c6:	0b648493          	addi	s1,s1,182 # 80017978 <arr_of_trapframes_storing_past>
    800038ca:	591c                	lw	a5,48(a0)
    800038cc:	078e                	slli	a5,a5,0x3
    800038ce:	97a6                	add	a5,a5,s1
    800038d0:	6605                	lui	a2,0x1
    800038d2:	638c                	ld	a1,0(a5)
    800038d4:	854a                	mv	a0,s2
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	458080e7          	jalr	1112(ra) # 80000d2e <memmove>
  kfree(arr_of_trapframes_storing_past[myproc()->pid]);
    800038de:	ffffe097          	auipc	ra,0xffffe
    800038e2:	0de080e7          	jalr	222(ra) # 800019bc <myproc>
    800038e6:	591c                	lw	a5,48(a0)
    800038e8:	078e                	slli	a5,a5,0x3
    800038ea:	94be                	add	s1,s1,a5
    800038ec:	6088                	ld	a0,0(s1)
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	0fc080e7          	jalr	252(ra) # 800009ea <kfree>
  myproc()->flag_check_handler = 0; 
    800038f6:	ffffe097          	auipc	ra,0xffffe
    800038fa:	0c6080e7          	jalr	198(ra) # 800019bc <myproc>
    800038fe:	1a052023          	sw	zero,416(a0)
  myproc()->passed_ticks =  0; 
    80003902:	ffffe097          	auipc	ra,0xffffe
    80003906:	0ba080e7          	jalr	186(ra) # 800019bc <myproc>
    8000390a:	18052823          	sw	zero,400(a0)
  myproc()->past_trap_frame = 0; 
    8000390e:	ffffe097          	auipc	ra,0xffffe
    80003912:	0ae080e7          	jalr	174(ra) # 800019bc <myproc>
    80003916:	18053c23          	sd	zero,408(a0)
  
  return myproc()->trapframe->a0; 
    8000391a:	ffffe097          	auipc	ra,0xffffe
    8000391e:	0a2080e7          	jalr	162(ra) # 800019bc <myproc>
    80003922:	6d3c                	ld	a5,88(a0)
  // return 0;
    80003924:	7ba8                	ld	a0,112(a5)
    80003926:	60e2                	ld	ra,24(sp)
    80003928:	6442                	ld	s0,16(sp)
    8000392a:	64a2                	ld	s1,8(sp)
    8000392c:	6902                	ld	s2,0(sp)
    8000392e:	6105                	addi	sp,sp,32
    80003930:	8082                	ret

0000000080003932 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003932:	7179                	addi	sp,sp,-48
    80003934:	f406                	sd	ra,40(sp)
    80003936:	f022                	sd	s0,32(sp)
    80003938:	ec26                	sd	s1,24(sp)
    8000393a:	e84a                	sd	s2,16(sp)
    8000393c:	e44e                	sd	s3,8(sp)
    8000393e:	e052                	sd	s4,0(sp)
    80003940:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003942:	00005597          	auipc	a1,0x5
    80003946:	bbe58593          	addi	a1,a1,-1090 # 80008500 <syscalls+0xd0>
    8000394a:	007b5517          	auipc	a0,0x7b5
    8000394e:	27e50513          	addi	a0,a0,638 # 807b8bc8 <bcache>
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	1f4080e7          	jalr	500(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000395a:	007bd797          	auipc	a5,0x7bd
    8000395e:	26e78793          	addi	a5,a5,622 # 807c0bc8 <bcache+0x8000>
    80003962:	007bd717          	auipc	a4,0x7bd
    80003966:	4ce70713          	addi	a4,a4,1230 # 807c0e30 <bcache+0x8268>
    8000396a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000396e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003972:	007b5497          	auipc	s1,0x7b5
    80003976:	26e48493          	addi	s1,s1,622 # 807b8be0 <bcache+0x18>
    b->next = bcache.head.next;
    8000397a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000397c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000397e:	00005a17          	auipc	s4,0x5
    80003982:	b8aa0a13          	addi	s4,s4,-1142 # 80008508 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003986:	2b893783          	ld	a5,696(s2)
    8000398a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000398c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003990:	85d2                	mv	a1,s4
    80003992:	01048513          	addi	a0,s1,16
    80003996:	00001097          	auipc	ra,0x1
    8000399a:	4c4080e7          	jalr	1220(ra) # 80004e5a <initsleeplock>
    bcache.head.next->prev = b;
    8000399e:	2b893783          	ld	a5,696(s2)
    800039a2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800039a4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800039a8:	45848493          	addi	s1,s1,1112
    800039ac:	fd349de3          	bne	s1,s3,80003986 <binit+0x54>
  }
}
    800039b0:	70a2                	ld	ra,40(sp)
    800039b2:	7402                	ld	s0,32(sp)
    800039b4:	64e2                	ld	s1,24(sp)
    800039b6:	6942                	ld	s2,16(sp)
    800039b8:	69a2                	ld	s3,8(sp)
    800039ba:	6a02                	ld	s4,0(sp)
    800039bc:	6145                	addi	sp,sp,48
    800039be:	8082                	ret

00000000800039c0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800039c0:	7179                	addi	sp,sp,-48
    800039c2:	f406                	sd	ra,40(sp)
    800039c4:	f022                	sd	s0,32(sp)
    800039c6:	ec26                	sd	s1,24(sp)
    800039c8:	e84a                	sd	s2,16(sp)
    800039ca:	e44e                	sd	s3,8(sp)
    800039cc:	1800                	addi	s0,sp,48
    800039ce:	892a                	mv	s2,a0
    800039d0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800039d2:	007b5517          	auipc	a0,0x7b5
    800039d6:	1f650513          	addi	a0,a0,502 # 807b8bc8 <bcache>
    800039da:	ffffd097          	auipc	ra,0xffffd
    800039de:	1fc080e7          	jalr	508(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800039e2:	007bd497          	auipc	s1,0x7bd
    800039e6:	49e4b483          	ld	s1,1182(s1) # 807c0e80 <bcache+0x82b8>
    800039ea:	007bd797          	auipc	a5,0x7bd
    800039ee:	44678793          	addi	a5,a5,1094 # 807c0e30 <bcache+0x8268>
    800039f2:	02f48f63          	beq	s1,a5,80003a30 <bread+0x70>
    800039f6:	873e                	mv	a4,a5
    800039f8:	a021                	j	80003a00 <bread+0x40>
    800039fa:	68a4                	ld	s1,80(s1)
    800039fc:	02e48a63          	beq	s1,a4,80003a30 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003a00:	449c                	lw	a5,8(s1)
    80003a02:	ff279ce3          	bne	a5,s2,800039fa <bread+0x3a>
    80003a06:	44dc                	lw	a5,12(s1)
    80003a08:	ff3799e3          	bne	a5,s3,800039fa <bread+0x3a>
      b->refcnt++;
    80003a0c:	40bc                	lw	a5,64(s1)
    80003a0e:	2785                	addiw	a5,a5,1
    80003a10:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003a12:	007b5517          	auipc	a0,0x7b5
    80003a16:	1b650513          	addi	a0,a0,438 # 807b8bc8 <bcache>
    80003a1a:	ffffd097          	auipc	ra,0xffffd
    80003a1e:	270080e7          	jalr	624(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003a22:	01048513          	addi	a0,s1,16
    80003a26:	00001097          	auipc	ra,0x1
    80003a2a:	46e080e7          	jalr	1134(ra) # 80004e94 <acquiresleep>
      return b;
    80003a2e:	a8b9                	j	80003a8c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003a30:	007bd497          	auipc	s1,0x7bd
    80003a34:	4484b483          	ld	s1,1096(s1) # 807c0e78 <bcache+0x82b0>
    80003a38:	007bd797          	auipc	a5,0x7bd
    80003a3c:	3f878793          	addi	a5,a5,1016 # 807c0e30 <bcache+0x8268>
    80003a40:	00f48863          	beq	s1,a5,80003a50 <bread+0x90>
    80003a44:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003a46:	40bc                	lw	a5,64(s1)
    80003a48:	cf81                	beqz	a5,80003a60 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003a4a:	64a4                	ld	s1,72(s1)
    80003a4c:	fee49de3          	bne	s1,a4,80003a46 <bread+0x86>
  panic("bget: no buffers");
    80003a50:	00005517          	auipc	a0,0x5
    80003a54:	ac050513          	addi	a0,a0,-1344 # 80008510 <syscalls+0xe0>
    80003a58:	ffffd097          	auipc	ra,0xffffd
    80003a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>
      b->dev = dev;
    80003a60:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003a64:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003a68:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003a6c:	4785                	li	a5,1
    80003a6e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003a70:	007b5517          	auipc	a0,0x7b5
    80003a74:	15850513          	addi	a0,a0,344 # 807b8bc8 <bcache>
    80003a78:	ffffd097          	auipc	ra,0xffffd
    80003a7c:	212080e7          	jalr	530(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003a80:	01048513          	addi	a0,s1,16
    80003a84:	00001097          	auipc	ra,0x1
    80003a88:	410080e7          	jalr	1040(ra) # 80004e94 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003a8c:	409c                	lw	a5,0(s1)
    80003a8e:	cb89                	beqz	a5,80003aa0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003a90:	8526                	mv	a0,s1
    80003a92:	70a2                	ld	ra,40(sp)
    80003a94:	7402                	ld	s0,32(sp)
    80003a96:	64e2                	ld	s1,24(sp)
    80003a98:	6942                	ld	s2,16(sp)
    80003a9a:	69a2                	ld	s3,8(sp)
    80003a9c:	6145                	addi	sp,sp,48
    80003a9e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003aa0:	4581                	li	a1,0
    80003aa2:	8526                	mv	a0,s1
    80003aa4:	00003097          	auipc	ra,0x3
    80003aa8:	fe0080e7          	jalr	-32(ra) # 80006a84 <virtio_disk_rw>
    b->valid = 1;
    80003aac:	4785                	li	a5,1
    80003aae:	c09c                	sw	a5,0(s1)
  return b;
    80003ab0:	b7c5                	j	80003a90 <bread+0xd0>

0000000080003ab2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003ab2:	1101                	addi	sp,sp,-32
    80003ab4:	ec06                	sd	ra,24(sp)
    80003ab6:	e822                	sd	s0,16(sp)
    80003ab8:	e426                	sd	s1,8(sp)
    80003aba:	1000                	addi	s0,sp,32
    80003abc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003abe:	0541                	addi	a0,a0,16
    80003ac0:	00001097          	auipc	ra,0x1
    80003ac4:	46e080e7          	jalr	1134(ra) # 80004f2e <holdingsleep>
    80003ac8:	cd01                	beqz	a0,80003ae0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003aca:	4585                	li	a1,1
    80003acc:	8526                	mv	a0,s1
    80003ace:	00003097          	auipc	ra,0x3
    80003ad2:	fb6080e7          	jalr	-74(ra) # 80006a84 <virtio_disk_rw>
}
    80003ad6:	60e2                	ld	ra,24(sp)
    80003ad8:	6442                	ld	s0,16(sp)
    80003ada:	64a2                	ld	s1,8(sp)
    80003adc:	6105                	addi	sp,sp,32
    80003ade:	8082                	ret
    panic("bwrite");
    80003ae0:	00005517          	auipc	a0,0x5
    80003ae4:	a4850513          	addi	a0,a0,-1464 # 80008528 <syscalls+0xf8>
    80003ae8:	ffffd097          	auipc	ra,0xffffd
    80003aec:	a56080e7          	jalr	-1450(ra) # 8000053e <panic>

0000000080003af0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003af0:	1101                	addi	sp,sp,-32
    80003af2:	ec06                	sd	ra,24(sp)
    80003af4:	e822                	sd	s0,16(sp)
    80003af6:	e426                	sd	s1,8(sp)
    80003af8:	e04a                	sd	s2,0(sp)
    80003afa:	1000                	addi	s0,sp,32
    80003afc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003afe:	01050913          	addi	s2,a0,16
    80003b02:	854a                	mv	a0,s2
    80003b04:	00001097          	auipc	ra,0x1
    80003b08:	42a080e7          	jalr	1066(ra) # 80004f2e <holdingsleep>
    80003b0c:	c92d                	beqz	a0,80003b7e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003b0e:	854a                	mv	a0,s2
    80003b10:	00001097          	auipc	ra,0x1
    80003b14:	3da080e7          	jalr	986(ra) # 80004eea <releasesleep>

  acquire(&bcache.lock);
    80003b18:	007b5517          	auipc	a0,0x7b5
    80003b1c:	0b050513          	addi	a0,a0,176 # 807b8bc8 <bcache>
    80003b20:	ffffd097          	auipc	ra,0xffffd
    80003b24:	0b6080e7          	jalr	182(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003b28:	40bc                	lw	a5,64(s1)
    80003b2a:	37fd                	addiw	a5,a5,-1
    80003b2c:	0007871b          	sext.w	a4,a5
    80003b30:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003b32:	eb05                	bnez	a4,80003b62 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003b34:	68bc                	ld	a5,80(s1)
    80003b36:	64b8                	ld	a4,72(s1)
    80003b38:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003b3a:	64bc                	ld	a5,72(s1)
    80003b3c:	68b8                	ld	a4,80(s1)
    80003b3e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003b40:	007bd797          	auipc	a5,0x7bd
    80003b44:	08878793          	addi	a5,a5,136 # 807c0bc8 <bcache+0x8000>
    80003b48:	2b87b703          	ld	a4,696(a5)
    80003b4c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003b4e:	007bd717          	auipc	a4,0x7bd
    80003b52:	2e270713          	addi	a4,a4,738 # 807c0e30 <bcache+0x8268>
    80003b56:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003b58:	2b87b703          	ld	a4,696(a5)
    80003b5c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003b5e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003b62:	007b5517          	auipc	a0,0x7b5
    80003b66:	06650513          	addi	a0,a0,102 # 807b8bc8 <bcache>
    80003b6a:	ffffd097          	auipc	ra,0xffffd
    80003b6e:	120080e7          	jalr	288(ra) # 80000c8a <release>
}
    80003b72:	60e2                	ld	ra,24(sp)
    80003b74:	6442                	ld	s0,16(sp)
    80003b76:	64a2                	ld	s1,8(sp)
    80003b78:	6902                	ld	s2,0(sp)
    80003b7a:	6105                	addi	sp,sp,32
    80003b7c:	8082                	ret
    panic("brelse");
    80003b7e:	00005517          	auipc	a0,0x5
    80003b82:	9b250513          	addi	a0,a0,-1614 # 80008530 <syscalls+0x100>
    80003b86:	ffffd097          	auipc	ra,0xffffd
    80003b8a:	9b8080e7          	jalr	-1608(ra) # 8000053e <panic>

0000000080003b8e <bpin>:

void
bpin(struct buf *b) {
    80003b8e:	1101                	addi	sp,sp,-32
    80003b90:	ec06                	sd	ra,24(sp)
    80003b92:	e822                	sd	s0,16(sp)
    80003b94:	e426                	sd	s1,8(sp)
    80003b96:	1000                	addi	s0,sp,32
    80003b98:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003b9a:	007b5517          	auipc	a0,0x7b5
    80003b9e:	02e50513          	addi	a0,a0,46 # 807b8bc8 <bcache>
    80003ba2:	ffffd097          	auipc	ra,0xffffd
    80003ba6:	034080e7          	jalr	52(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003baa:	40bc                	lw	a5,64(s1)
    80003bac:	2785                	addiw	a5,a5,1
    80003bae:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003bb0:	007b5517          	auipc	a0,0x7b5
    80003bb4:	01850513          	addi	a0,a0,24 # 807b8bc8 <bcache>
    80003bb8:	ffffd097          	auipc	ra,0xffffd
    80003bbc:	0d2080e7          	jalr	210(ra) # 80000c8a <release>
}
    80003bc0:	60e2                	ld	ra,24(sp)
    80003bc2:	6442                	ld	s0,16(sp)
    80003bc4:	64a2                	ld	s1,8(sp)
    80003bc6:	6105                	addi	sp,sp,32
    80003bc8:	8082                	ret

0000000080003bca <bunpin>:

void
bunpin(struct buf *b) {
    80003bca:	1101                	addi	sp,sp,-32
    80003bcc:	ec06                	sd	ra,24(sp)
    80003bce:	e822                	sd	s0,16(sp)
    80003bd0:	e426                	sd	s1,8(sp)
    80003bd2:	1000                	addi	s0,sp,32
    80003bd4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003bd6:	007b5517          	auipc	a0,0x7b5
    80003bda:	ff250513          	addi	a0,a0,-14 # 807b8bc8 <bcache>
    80003bde:	ffffd097          	auipc	ra,0xffffd
    80003be2:	ff8080e7          	jalr	-8(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003be6:	40bc                	lw	a5,64(s1)
    80003be8:	37fd                	addiw	a5,a5,-1
    80003bea:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003bec:	007b5517          	auipc	a0,0x7b5
    80003bf0:	fdc50513          	addi	a0,a0,-36 # 807b8bc8 <bcache>
    80003bf4:	ffffd097          	auipc	ra,0xffffd
    80003bf8:	096080e7          	jalr	150(ra) # 80000c8a <release>
}
    80003bfc:	60e2                	ld	ra,24(sp)
    80003bfe:	6442                	ld	s0,16(sp)
    80003c00:	64a2                	ld	s1,8(sp)
    80003c02:	6105                	addi	sp,sp,32
    80003c04:	8082                	ret

0000000080003c06 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003c06:	1101                	addi	sp,sp,-32
    80003c08:	ec06                	sd	ra,24(sp)
    80003c0a:	e822                	sd	s0,16(sp)
    80003c0c:	e426                	sd	s1,8(sp)
    80003c0e:	e04a                	sd	s2,0(sp)
    80003c10:	1000                	addi	s0,sp,32
    80003c12:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003c14:	00d5d59b          	srliw	a1,a1,0xd
    80003c18:	007bd797          	auipc	a5,0x7bd
    80003c1c:	68c7a783          	lw	a5,1676(a5) # 807c12a4 <sb+0x1c>
    80003c20:	9dbd                	addw	a1,a1,a5
    80003c22:	00000097          	auipc	ra,0x0
    80003c26:	d9e080e7          	jalr	-610(ra) # 800039c0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003c2a:	0074f713          	andi	a4,s1,7
    80003c2e:	4785                	li	a5,1
    80003c30:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003c34:	14ce                	slli	s1,s1,0x33
    80003c36:	90d9                	srli	s1,s1,0x36
    80003c38:	00950733          	add	a4,a0,s1
    80003c3c:	05874703          	lbu	a4,88(a4)
    80003c40:	00e7f6b3          	and	a3,a5,a4
    80003c44:	c69d                	beqz	a3,80003c72 <bfree+0x6c>
    80003c46:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003c48:	94aa                	add	s1,s1,a0
    80003c4a:	fff7c793          	not	a5,a5
    80003c4e:	8ff9                	and	a5,a5,a4
    80003c50:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003c54:	00001097          	auipc	ra,0x1
    80003c58:	120080e7          	jalr	288(ra) # 80004d74 <log_write>
  brelse(bp);
    80003c5c:	854a                	mv	a0,s2
    80003c5e:	00000097          	auipc	ra,0x0
    80003c62:	e92080e7          	jalr	-366(ra) # 80003af0 <brelse>
}
    80003c66:	60e2                	ld	ra,24(sp)
    80003c68:	6442                	ld	s0,16(sp)
    80003c6a:	64a2                	ld	s1,8(sp)
    80003c6c:	6902                	ld	s2,0(sp)
    80003c6e:	6105                	addi	sp,sp,32
    80003c70:	8082                	ret
    panic("freeing free block");
    80003c72:	00005517          	auipc	a0,0x5
    80003c76:	8c650513          	addi	a0,a0,-1850 # 80008538 <syscalls+0x108>
    80003c7a:	ffffd097          	auipc	ra,0xffffd
    80003c7e:	8c4080e7          	jalr	-1852(ra) # 8000053e <panic>

0000000080003c82 <balloc>:
{
    80003c82:	711d                	addi	sp,sp,-96
    80003c84:	ec86                	sd	ra,88(sp)
    80003c86:	e8a2                	sd	s0,80(sp)
    80003c88:	e4a6                	sd	s1,72(sp)
    80003c8a:	e0ca                	sd	s2,64(sp)
    80003c8c:	fc4e                	sd	s3,56(sp)
    80003c8e:	f852                	sd	s4,48(sp)
    80003c90:	f456                	sd	s5,40(sp)
    80003c92:	f05a                	sd	s6,32(sp)
    80003c94:	ec5e                	sd	s7,24(sp)
    80003c96:	e862                	sd	s8,16(sp)
    80003c98:	e466                	sd	s9,8(sp)
    80003c9a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003c9c:	007bd797          	auipc	a5,0x7bd
    80003ca0:	5f07a783          	lw	a5,1520(a5) # 807c128c <sb+0x4>
    80003ca4:	10078163          	beqz	a5,80003da6 <balloc+0x124>
    80003ca8:	8baa                	mv	s7,a0
    80003caa:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003cac:	007bdb17          	auipc	s6,0x7bd
    80003cb0:	5dcb0b13          	addi	s6,s6,1500 # 807c1288 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003cb4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003cb6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003cb8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003cba:	6c89                	lui	s9,0x2
    80003cbc:	a061                	j	80003d44 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003cbe:	974a                	add	a4,a4,s2
    80003cc0:	8fd5                	or	a5,a5,a3
    80003cc2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003cc6:	854a                	mv	a0,s2
    80003cc8:	00001097          	auipc	ra,0x1
    80003ccc:	0ac080e7          	jalr	172(ra) # 80004d74 <log_write>
        brelse(bp);
    80003cd0:	854a                	mv	a0,s2
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	e1e080e7          	jalr	-482(ra) # 80003af0 <brelse>
  bp = bread(dev, bno);
    80003cda:	85a6                	mv	a1,s1
    80003cdc:	855e                	mv	a0,s7
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	ce2080e7          	jalr	-798(ra) # 800039c0 <bread>
    80003ce6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003ce8:	40000613          	li	a2,1024
    80003cec:	4581                	li	a1,0
    80003cee:	05850513          	addi	a0,a0,88
    80003cf2:	ffffd097          	auipc	ra,0xffffd
    80003cf6:	fe0080e7          	jalr	-32(ra) # 80000cd2 <memset>
  log_write(bp);
    80003cfa:	854a                	mv	a0,s2
    80003cfc:	00001097          	auipc	ra,0x1
    80003d00:	078080e7          	jalr	120(ra) # 80004d74 <log_write>
  brelse(bp);
    80003d04:	854a                	mv	a0,s2
    80003d06:	00000097          	auipc	ra,0x0
    80003d0a:	dea080e7          	jalr	-534(ra) # 80003af0 <brelse>
}
    80003d0e:	8526                	mv	a0,s1
    80003d10:	60e6                	ld	ra,88(sp)
    80003d12:	6446                	ld	s0,80(sp)
    80003d14:	64a6                	ld	s1,72(sp)
    80003d16:	6906                	ld	s2,64(sp)
    80003d18:	79e2                	ld	s3,56(sp)
    80003d1a:	7a42                	ld	s4,48(sp)
    80003d1c:	7aa2                	ld	s5,40(sp)
    80003d1e:	7b02                	ld	s6,32(sp)
    80003d20:	6be2                	ld	s7,24(sp)
    80003d22:	6c42                	ld	s8,16(sp)
    80003d24:	6ca2                	ld	s9,8(sp)
    80003d26:	6125                	addi	sp,sp,96
    80003d28:	8082                	ret
    brelse(bp);
    80003d2a:	854a                	mv	a0,s2
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	dc4080e7          	jalr	-572(ra) # 80003af0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003d34:	015c87bb          	addw	a5,s9,s5
    80003d38:	00078a9b          	sext.w	s5,a5
    80003d3c:	004b2703          	lw	a4,4(s6)
    80003d40:	06eaf363          	bgeu	s5,a4,80003da6 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003d44:	41fad79b          	sraiw	a5,s5,0x1f
    80003d48:	0137d79b          	srliw	a5,a5,0x13
    80003d4c:	015787bb          	addw	a5,a5,s5
    80003d50:	40d7d79b          	sraiw	a5,a5,0xd
    80003d54:	01cb2583          	lw	a1,28(s6)
    80003d58:	9dbd                	addw	a1,a1,a5
    80003d5a:	855e                	mv	a0,s7
    80003d5c:	00000097          	auipc	ra,0x0
    80003d60:	c64080e7          	jalr	-924(ra) # 800039c0 <bread>
    80003d64:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d66:	004b2503          	lw	a0,4(s6)
    80003d6a:	000a849b          	sext.w	s1,s5
    80003d6e:	8662                	mv	a2,s8
    80003d70:	faa4fde3          	bgeu	s1,a0,80003d2a <balloc+0xa8>
      m = 1 << (bi % 8);
    80003d74:	41f6579b          	sraiw	a5,a2,0x1f
    80003d78:	01d7d69b          	srliw	a3,a5,0x1d
    80003d7c:	00c6873b          	addw	a4,a3,a2
    80003d80:	00777793          	andi	a5,a4,7
    80003d84:	9f95                	subw	a5,a5,a3
    80003d86:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003d8a:	4037571b          	sraiw	a4,a4,0x3
    80003d8e:	00e906b3          	add	a3,s2,a4
    80003d92:	0586c683          	lbu	a3,88(a3)
    80003d96:	00d7f5b3          	and	a1,a5,a3
    80003d9a:	d195                	beqz	a1,80003cbe <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d9c:	2605                	addiw	a2,a2,1
    80003d9e:	2485                	addiw	s1,s1,1
    80003da0:	fd4618e3          	bne	a2,s4,80003d70 <balloc+0xee>
    80003da4:	b759                	j	80003d2a <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003da6:	00004517          	auipc	a0,0x4
    80003daa:	7aa50513          	addi	a0,a0,1962 # 80008550 <syscalls+0x120>
    80003dae:	ffffc097          	auipc	ra,0xffffc
    80003db2:	7da080e7          	jalr	2010(ra) # 80000588 <printf>
  return 0;
    80003db6:	4481                	li	s1,0
    80003db8:	bf99                	j	80003d0e <balloc+0x8c>

0000000080003dba <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003dba:	7179                	addi	sp,sp,-48
    80003dbc:	f406                	sd	ra,40(sp)
    80003dbe:	f022                	sd	s0,32(sp)
    80003dc0:	ec26                	sd	s1,24(sp)
    80003dc2:	e84a                	sd	s2,16(sp)
    80003dc4:	e44e                	sd	s3,8(sp)
    80003dc6:	e052                	sd	s4,0(sp)
    80003dc8:	1800                	addi	s0,sp,48
    80003dca:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003dcc:	47ad                	li	a5,11
    80003dce:	02b7e763          	bltu	a5,a1,80003dfc <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003dd2:	02059493          	slli	s1,a1,0x20
    80003dd6:	9081                	srli	s1,s1,0x20
    80003dd8:	048a                	slli	s1,s1,0x2
    80003dda:	94aa                	add	s1,s1,a0
    80003ddc:	0504a903          	lw	s2,80(s1)
    80003de0:	06091e63          	bnez	s2,80003e5c <bmap+0xa2>
      addr = balloc(ip->dev);
    80003de4:	4108                	lw	a0,0(a0)
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	e9c080e7          	jalr	-356(ra) # 80003c82 <balloc>
    80003dee:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003df2:	06090563          	beqz	s2,80003e5c <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003df6:	0524a823          	sw	s2,80(s1)
    80003dfa:	a08d                	j	80003e5c <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003dfc:	ff45849b          	addiw	s1,a1,-12
    80003e00:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003e04:	0ff00793          	li	a5,255
    80003e08:	08e7e563          	bltu	a5,a4,80003e92 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003e0c:	08052903          	lw	s2,128(a0)
    80003e10:	00091d63          	bnez	s2,80003e2a <bmap+0x70>
      addr = balloc(ip->dev);
    80003e14:	4108                	lw	a0,0(a0)
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	e6c080e7          	jalr	-404(ra) # 80003c82 <balloc>
    80003e1e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003e22:	02090d63          	beqz	s2,80003e5c <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003e26:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003e2a:	85ca                	mv	a1,s2
    80003e2c:	0009a503          	lw	a0,0(s3)
    80003e30:	00000097          	auipc	ra,0x0
    80003e34:	b90080e7          	jalr	-1136(ra) # 800039c0 <bread>
    80003e38:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003e3a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003e3e:	02049593          	slli	a1,s1,0x20
    80003e42:	9181                	srli	a1,a1,0x20
    80003e44:	058a                	slli	a1,a1,0x2
    80003e46:	00b784b3          	add	s1,a5,a1
    80003e4a:	0004a903          	lw	s2,0(s1)
    80003e4e:	02090063          	beqz	s2,80003e6e <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003e52:	8552                	mv	a0,s4
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	c9c080e7          	jalr	-868(ra) # 80003af0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003e5c:	854a                	mv	a0,s2
    80003e5e:	70a2                	ld	ra,40(sp)
    80003e60:	7402                	ld	s0,32(sp)
    80003e62:	64e2                	ld	s1,24(sp)
    80003e64:	6942                	ld	s2,16(sp)
    80003e66:	69a2                	ld	s3,8(sp)
    80003e68:	6a02                	ld	s4,0(sp)
    80003e6a:	6145                	addi	sp,sp,48
    80003e6c:	8082                	ret
      addr = balloc(ip->dev);
    80003e6e:	0009a503          	lw	a0,0(s3)
    80003e72:	00000097          	auipc	ra,0x0
    80003e76:	e10080e7          	jalr	-496(ra) # 80003c82 <balloc>
    80003e7a:	0005091b          	sext.w	s2,a0
      if(addr){
    80003e7e:	fc090ae3          	beqz	s2,80003e52 <bmap+0x98>
        a[bn] = addr;
    80003e82:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003e86:	8552                	mv	a0,s4
    80003e88:	00001097          	auipc	ra,0x1
    80003e8c:	eec080e7          	jalr	-276(ra) # 80004d74 <log_write>
    80003e90:	b7c9                	j	80003e52 <bmap+0x98>
  panic("bmap: out of range");
    80003e92:	00004517          	auipc	a0,0x4
    80003e96:	6d650513          	addi	a0,a0,1750 # 80008568 <syscalls+0x138>
    80003e9a:	ffffc097          	auipc	ra,0xffffc
    80003e9e:	6a4080e7          	jalr	1700(ra) # 8000053e <panic>

0000000080003ea2 <iget>:
{
    80003ea2:	7179                	addi	sp,sp,-48
    80003ea4:	f406                	sd	ra,40(sp)
    80003ea6:	f022                	sd	s0,32(sp)
    80003ea8:	ec26                	sd	s1,24(sp)
    80003eaa:	e84a                	sd	s2,16(sp)
    80003eac:	e44e                	sd	s3,8(sp)
    80003eae:	e052                	sd	s4,0(sp)
    80003eb0:	1800                	addi	s0,sp,48
    80003eb2:	89aa                	mv	s3,a0
    80003eb4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003eb6:	007bd517          	auipc	a0,0x7bd
    80003eba:	3f250513          	addi	a0,a0,1010 # 807c12a8 <itable>
    80003ebe:	ffffd097          	auipc	ra,0xffffd
    80003ec2:	d18080e7          	jalr	-744(ra) # 80000bd6 <acquire>
  empty = 0;
    80003ec6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ec8:	007bd497          	auipc	s1,0x7bd
    80003ecc:	3f848493          	addi	s1,s1,1016 # 807c12c0 <itable+0x18>
    80003ed0:	007bf697          	auipc	a3,0x7bf
    80003ed4:	e8068693          	addi	a3,a3,-384 # 807c2d50 <log>
    80003ed8:	a039                	j	80003ee6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003eda:	02090b63          	beqz	s2,80003f10 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ede:	08848493          	addi	s1,s1,136
    80003ee2:	02d48a63          	beq	s1,a3,80003f16 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003ee6:	449c                	lw	a5,8(s1)
    80003ee8:	fef059e3          	blez	a5,80003eda <iget+0x38>
    80003eec:	4098                	lw	a4,0(s1)
    80003eee:	ff3716e3          	bne	a4,s3,80003eda <iget+0x38>
    80003ef2:	40d8                	lw	a4,4(s1)
    80003ef4:	ff4713e3          	bne	a4,s4,80003eda <iget+0x38>
      ip->ref++;
    80003ef8:	2785                	addiw	a5,a5,1
    80003efa:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003efc:	007bd517          	auipc	a0,0x7bd
    80003f00:	3ac50513          	addi	a0,a0,940 # 807c12a8 <itable>
    80003f04:	ffffd097          	auipc	ra,0xffffd
    80003f08:	d86080e7          	jalr	-634(ra) # 80000c8a <release>
      return ip;
    80003f0c:	8926                	mv	s2,s1
    80003f0e:	a03d                	j	80003f3c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003f10:	f7f9                	bnez	a5,80003ede <iget+0x3c>
    80003f12:	8926                	mv	s2,s1
    80003f14:	b7e9                	j	80003ede <iget+0x3c>
  if(empty == 0)
    80003f16:	02090c63          	beqz	s2,80003f4e <iget+0xac>
  ip->dev = dev;
    80003f1a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003f1e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003f22:	4785                	li	a5,1
    80003f24:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003f28:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003f2c:	007bd517          	auipc	a0,0x7bd
    80003f30:	37c50513          	addi	a0,a0,892 # 807c12a8 <itable>
    80003f34:	ffffd097          	auipc	ra,0xffffd
    80003f38:	d56080e7          	jalr	-682(ra) # 80000c8a <release>
}
    80003f3c:	854a                	mv	a0,s2
    80003f3e:	70a2                	ld	ra,40(sp)
    80003f40:	7402                	ld	s0,32(sp)
    80003f42:	64e2                	ld	s1,24(sp)
    80003f44:	6942                	ld	s2,16(sp)
    80003f46:	69a2                	ld	s3,8(sp)
    80003f48:	6a02                	ld	s4,0(sp)
    80003f4a:	6145                	addi	sp,sp,48
    80003f4c:	8082                	ret
    panic("iget: no inodes");
    80003f4e:	00004517          	auipc	a0,0x4
    80003f52:	63250513          	addi	a0,a0,1586 # 80008580 <syscalls+0x150>
    80003f56:	ffffc097          	auipc	ra,0xffffc
    80003f5a:	5e8080e7          	jalr	1512(ra) # 8000053e <panic>

0000000080003f5e <fsinit>:
fsinit(int dev) {
    80003f5e:	7179                	addi	sp,sp,-48
    80003f60:	f406                	sd	ra,40(sp)
    80003f62:	f022                	sd	s0,32(sp)
    80003f64:	ec26                	sd	s1,24(sp)
    80003f66:	e84a                	sd	s2,16(sp)
    80003f68:	e44e                	sd	s3,8(sp)
    80003f6a:	1800                	addi	s0,sp,48
    80003f6c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003f6e:	4585                	li	a1,1
    80003f70:	00000097          	auipc	ra,0x0
    80003f74:	a50080e7          	jalr	-1456(ra) # 800039c0 <bread>
    80003f78:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003f7a:	007bd997          	auipc	s3,0x7bd
    80003f7e:	30e98993          	addi	s3,s3,782 # 807c1288 <sb>
    80003f82:	02000613          	li	a2,32
    80003f86:	05850593          	addi	a1,a0,88
    80003f8a:	854e                	mv	a0,s3
    80003f8c:	ffffd097          	auipc	ra,0xffffd
    80003f90:	da2080e7          	jalr	-606(ra) # 80000d2e <memmove>
  brelse(bp);
    80003f94:	8526                	mv	a0,s1
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	b5a080e7          	jalr	-1190(ra) # 80003af0 <brelse>
  if(sb.magic != FSMAGIC)
    80003f9e:	0009a703          	lw	a4,0(s3)
    80003fa2:	102037b7          	lui	a5,0x10203
    80003fa6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003faa:	02f71263          	bne	a4,a5,80003fce <fsinit+0x70>
  initlog(dev, &sb);
    80003fae:	007bd597          	auipc	a1,0x7bd
    80003fb2:	2da58593          	addi	a1,a1,730 # 807c1288 <sb>
    80003fb6:	854a                	mv	a0,s2
    80003fb8:	00001097          	auipc	ra,0x1
    80003fbc:	b40080e7          	jalr	-1216(ra) # 80004af8 <initlog>
}
    80003fc0:	70a2                	ld	ra,40(sp)
    80003fc2:	7402                	ld	s0,32(sp)
    80003fc4:	64e2                	ld	s1,24(sp)
    80003fc6:	6942                	ld	s2,16(sp)
    80003fc8:	69a2                	ld	s3,8(sp)
    80003fca:	6145                	addi	sp,sp,48
    80003fcc:	8082                	ret
    panic("invalid file system");
    80003fce:	00004517          	auipc	a0,0x4
    80003fd2:	5c250513          	addi	a0,a0,1474 # 80008590 <syscalls+0x160>
    80003fd6:	ffffc097          	auipc	ra,0xffffc
    80003fda:	568080e7          	jalr	1384(ra) # 8000053e <panic>

0000000080003fde <iinit>:
{
    80003fde:	7179                	addi	sp,sp,-48
    80003fe0:	f406                	sd	ra,40(sp)
    80003fe2:	f022                	sd	s0,32(sp)
    80003fe4:	ec26                	sd	s1,24(sp)
    80003fe6:	e84a                	sd	s2,16(sp)
    80003fe8:	e44e                	sd	s3,8(sp)
    80003fea:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003fec:	00004597          	auipc	a1,0x4
    80003ff0:	5bc58593          	addi	a1,a1,1468 # 800085a8 <syscalls+0x178>
    80003ff4:	007bd517          	auipc	a0,0x7bd
    80003ff8:	2b450513          	addi	a0,a0,692 # 807c12a8 <itable>
    80003ffc:	ffffd097          	auipc	ra,0xffffd
    80004000:	b4a080e7          	jalr	-1206(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80004004:	007bd497          	auipc	s1,0x7bd
    80004008:	2cc48493          	addi	s1,s1,716 # 807c12d0 <itable+0x28>
    8000400c:	007bf997          	auipc	s3,0x7bf
    80004010:	d5498993          	addi	s3,s3,-684 # 807c2d60 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004014:	00004917          	auipc	s2,0x4
    80004018:	59c90913          	addi	s2,s2,1436 # 800085b0 <syscalls+0x180>
    8000401c:	85ca                	mv	a1,s2
    8000401e:	8526                	mv	a0,s1
    80004020:	00001097          	auipc	ra,0x1
    80004024:	e3a080e7          	jalr	-454(ra) # 80004e5a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004028:	08848493          	addi	s1,s1,136
    8000402c:	ff3498e3          	bne	s1,s3,8000401c <iinit+0x3e>
}
    80004030:	70a2                	ld	ra,40(sp)
    80004032:	7402                	ld	s0,32(sp)
    80004034:	64e2                	ld	s1,24(sp)
    80004036:	6942                	ld	s2,16(sp)
    80004038:	69a2                	ld	s3,8(sp)
    8000403a:	6145                	addi	sp,sp,48
    8000403c:	8082                	ret

000000008000403e <ialloc>:
{
    8000403e:	715d                	addi	sp,sp,-80
    80004040:	e486                	sd	ra,72(sp)
    80004042:	e0a2                	sd	s0,64(sp)
    80004044:	fc26                	sd	s1,56(sp)
    80004046:	f84a                	sd	s2,48(sp)
    80004048:	f44e                	sd	s3,40(sp)
    8000404a:	f052                	sd	s4,32(sp)
    8000404c:	ec56                	sd	s5,24(sp)
    8000404e:	e85a                	sd	s6,16(sp)
    80004050:	e45e                	sd	s7,8(sp)
    80004052:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004054:	007bd717          	auipc	a4,0x7bd
    80004058:	24072703          	lw	a4,576(a4) # 807c1294 <sb+0xc>
    8000405c:	4785                	li	a5,1
    8000405e:	04e7fa63          	bgeu	a5,a4,800040b2 <ialloc+0x74>
    80004062:	8aaa                	mv	s5,a0
    80004064:	8bae                	mv	s7,a1
    80004066:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004068:	007bda17          	auipc	s4,0x7bd
    8000406c:	220a0a13          	addi	s4,s4,544 # 807c1288 <sb>
    80004070:	00048b1b          	sext.w	s6,s1
    80004074:	0044d793          	srli	a5,s1,0x4
    80004078:	018a2583          	lw	a1,24(s4)
    8000407c:	9dbd                	addw	a1,a1,a5
    8000407e:	8556                	mv	a0,s5
    80004080:	00000097          	auipc	ra,0x0
    80004084:	940080e7          	jalr	-1728(ra) # 800039c0 <bread>
    80004088:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000408a:	05850993          	addi	s3,a0,88
    8000408e:	00f4f793          	andi	a5,s1,15
    80004092:	079a                	slli	a5,a5,0x6
    80004094:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004096:	00099783          	lh	a5,0(s3)
    8000409a:	c3a1                	beqz	a5,800040da <ialloc+0x9c>
    brelse(bp);
    8000409c:	00000097          	auipc	ra,0x0
    800040a0:	a54080e7          	jalr	-1452(ra) # 80003af0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800040a4:	0485                	addi	s1,s1,1
    800040a6:	00ca2703          	lw	a4,12(s4)
    800040aa:	0004879b          	sext.w	a5,s1
    800040ae:	fce7e1e3          	bltu	a5,a4,80004070 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800040b2:	00004517          	auipc	a0,0x4
    800040b6:	50650513          	addi	a0,a0,1286 # 800085b8 <syscalls+0x188>
    800040ba:	ffffc097          	auipc	ra,0xffffc
    800040be:	4ce080e7          	jalr	1230(ra) # 80000588 <printf>
  return 0;
    800040c2:	4501                	li	a0,0
}
    800040c4:	60a6                	ld	ra,72(sp)
    800040c6:	6406                	ld	s0,64(sp)
    800040c8:	74e2                	ld	s1,56(sp)
    800040ca:	7942                	ld	s2,48(sp)
    800040cc:	79a2                	ld	s3,40(sp)
    800040ce:	7a02                	ld	s4,32(sp)
    800040d0:	6ae2                	ld	s5,24(sp)
    800040d2:	6b42                	ld	s6,16(sp)
    800040d4:	6ba2                	ld	s7,8(sp)
    800040d6:	6161                	addi	sp,sp,80
    800040d8:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800040da:	04000613          	li	a2,64
    800040de:	4581                	li	a1,0
    800040e0:	854e                	mv	a0,s3
    800040e2:	ffffd097          	auipc	ra,0xffffd
    800040e6:	bf0080e7          	jalr	-1040(ra) # 80000cd2 <memset>
      dip->type = type;
    800040ea:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800040ee:	854a                	mv	a0,s2
    800040f0:	00001097          	auipc	ra,0x1
    800040f4:	c84080e7          	jalr	-892(ra) # 80004d74 <log_write>
      brelse(bp);
    800040f8:	854a                	mv	a0,s2
    800040fa:	00000097          	auipc	ra,0x0
    800040fe:	9f6080e7          	jalr	-1546(ra) # 80003af0 <brelse>
      return iget(dev, inum);
    80004102:	85da                	mv	a1,s6
    80004104:	8556                	mv	a0,s5
    80004106:	00000097          	auipc	ra,0x0
    8000410a:	d9c080e7          	jalr	-612(ra) # 80003ea2 <iget>
    8000410e:	bf5d                	j	800040c4 <ialloc+0x86>

0000000080004110 <iupdate>:
{
    80004110:	1101                	addi	sp,sp,-32
    80004112:	ec06                	sd	ra,24(sp)
    80004114:	e822                	sd	s0,16(sp)
    80004116:	e426                	sd	s1,8(sp)
    80004118:	e04a                	sd	s2,0(sp)
    8000411a:	1000                	addi	s0,sp,32
    8000411c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000411e:	415c                	lw	a5,4(a0)
    80004120:	0047d79b          	srliw	a5,a5,0x4
    80004124:	007bd597          	auipc	a1,0x7bd
    80004128:	17c5a583          	lw	a1,380(a1) # 807c12a0 <sb+0x18>
    8000412c:	9dbd                	addw	a1,a1,a5
    8000412e:	4108                	lw	a0,0(a0)
    80004130:	00000097          	auipc	ra,0x0
    80004134:	890080e7          	jalr	-1904(ra) # 800039c0 <bread>
    80004138:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000413a:	05850793          	addi	a5,a0,88
    8000413e:	40c8                	lw	a0,4(s1)
    80004140:	893d                	andi	a0,a0,15
    80004142:	051a                	slli	a0,a0,0x6
    80004144:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004146:	04449703          	lh	a4,68(s1)
    8000414a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000414e:	04649703          	lh	a4,70(s1)
    80004152:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004156:	04849703          	lh	a4,72(s1)
    8000415a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000415e:	04a49703          	lh	a4,74(s1)
    80004162:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004166:	44f8                	lw	a4,76(s1)
    80004168:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000416a:	03400613          	li	a2,52
    8000416e:	05048593          	addi	a1,s1,80
    80004172:	0531                	addi	a0,a0,12
    80004174:	ffffd097          	auipc	ra,0xffffd
    80004178:	bba080e7          	jalr	-1094(ra) # 80000d2e <memmove>
  log_write(bp);
    8000417c:	854a                	mv	a0,s2
    8000417e:	00001097          	auipc	ra,0x1
    80004182:	bf6080e7          	jalr	-1034(ra) # 80004d74 <log_write>
  brelse(bp);
    80004186:	854a                	mv	a0,s2
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	968080e7          	jalr	-1688(ra) # 80003af0 <brelse>
}
    80004190:	60e2                	ld	ra,24(sp)
    80004192:	6442                	ld	s0,16(sp)
    80004194:	64a2                	ld	s1,8(sp)
    80004196:	6902                	ld	s2,0(sp)
    80004198:	6105                	addi	sp,sp,32
    8000419a:	8082                	ret

000000008000419c <idup>:
{
    8000419c:	1101                	addi	sp,sp,-32
    8000419e:	ec06                	sd	ra,24(sp)
    800041a0:	e822                	sd	s0,16(sp)
    800041a2:	e426                	sd	s1,8(sp)
    800041a4:	1000                	addi	s0,sp,32
    800041a6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800041a8:	007bd517          	auipc	a0,0x7bd
    800041ac:	10050513          	addi	a0,a0,256 # 807c12a8 <itable>
    800041b0:	ffffd097          	auipc	ra,0xffffd
    800041b4:	a26080e7          	jalr	-1498(ra) # 80000bd6 <acquire>
  ip->ref++;
    800041b8:	449c                	lw	a5,8(s1)
    800041ba:	2785                	addiw	a5,a5,1
    800041bc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800041be:	007bd517          	auipc	a0,0x7bd
    800041c2:	0ea50513          	addi	a0,a0,234 # 807c12a8 <itable>
    800041c6:	ffffd097          	auipc	ra,0xffffd
    800041ca:	ac4080e7          	jalr	-1340(ra) # 80000c8a <release>
}
    800041ce:	8526                	mv	a0,s1
    800041d0:	60e2                	ld	ra,24(sp)
    800041d2:	6442                	ld	s0,16(sp)
    800041d4:	64a2                	ld	s1,8(sp)
    800041d6:	6105                	addi	sp,sp,32
    800041d8:	8082                	ret

00000000800041da <ilock>:
{
    800041da:	1101                	addi	sp,sp,-32
    800041dc:	ec06                	sd	ra,24(sp)
    800041de:	e822                	sd	s0,16(sp)
    800041e0:	e426                	sd	s1,8(sp)
    800041e2:	e04a                	sd	s2,0(sp)
    800041e4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800041e6:	c115                	beqz	a0,8000420a <ilock+0x30>
    800041e8:	84aa                	mv	s1,a0
    800041ea:	451c                	lw	a5,8(a0)
    800041ec:	00f05f63          	blez	a5,8000420a <ilock+0x30>
  acquiresleep(&ip->lock);
    800041f0:	0541                	addi	a0,a0,16
    800041f2:	00001097          	auipc	ra,0x1
    800041f6:	ca2080e7          	jalr	-862(ra) # 80004e94 <acquiresleep>
  if(ip->valid == 0){
    800041fa:	40bc                	lw	a5,64(s1)
    800041fc:	cf99                	beqz	a5,8000421a <ilock+0x40>
}
    800041fe:	60e2                	ld	ra,24(sp)
    80004200:	6442                	ld	s0,16(sp)
    80004202:	64a2                	ld	s1,8(sp)
    80004204:	6902                	ld	s2,0(sp)
    80004206:	6105                	addi	sp,sp,32
    80004208:	8082                	ret
    panic("ilock");
    8000420a:	00004517          	auipc	a0,0x4
    8000420e:	3c650513          	addi	a0,a0,966 # 800085d0 <syscalls+0x1a0>
    80004212:	ffffc097          	auipc	ra,0xffffc
    80004216:	32c080e7          	jalr	812(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000421a:	40dc                	lw	a5,4(s1)
    8000421c:	0047d79b          	srliw	a5,a5,0x4
    80004220:	007bd597          	auipc	a1,0x7bd
    80004224:	0805a583          	lw	a1,128(a1) # 807c12a0 <sb+0x18>
    80004228:	9dbd                	addw	a1,a1,a5
    8000422a:	4088                	lw	a0,0(s1)
    8000422c:	fffff097          	auipc	ra,0xfffff
    80004230:	794080e7          	jalr	1940(ra) # 800039c0 <bread>
    80004234:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004236:	05850593          	addi	a1,a0,88
    8000423a:	40dc                	lw	a5,4(s1)
    8000423c:	8bbd                	andi	a5,a5,15
    8000423e:	079a                	slli	a5,a5,0x6
    80004240:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004242:	00059783          	lh	a5,0(a1)
    80004246:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000424a:	00259783          	lh	a5,2(a1)
    8000424e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004252:	00459783          	lh	a5,4(a1)
    80004256:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000425a:	00659783          	lh	a5,6(a1)
    8000425e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004262:	459c                	lw	a5,8(a1)
    80004264:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004266:	03400613          	li	a2,52
    8000426a:	05b1                	addi	a1,a1,12
    8000426c:	05048513          	addi	a0,s1,80
    80004270:	ffffd097          	auipc	ra,0xffffd
    80004274:	abe080e7          	jalr	-1346(ra) # 80000d2e <memmove>
    brelse(bp);
    80004278:	854a                	mv	a0,s2
    8000427a:	00000097          	auipc	ra,0x0
    8000427e:	876080e7          	jalr	-1930(ra) # 80003af0 <brelse>
    ip->valid = 1;
    80004282:	4785                	li	a5,1
    80004284:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004286:	04449783          	lh	a5,68(s1)
    8000428a:	fbb5                	bnez	a5,800041fe <ilock+0x24>
      panic("ilock: no type");
    8000428c:	00004517          	auipc	a0,0x4
    80004290:	34c50513          	addi	a0,a0,844 # 800085d8 <syscalls+0x1a8>
    80004294:	ffffc097          	auipc	ra,0xffffc
    80004298:	2aa080e7          	jalr	682(ra) # 8000053e <panic>

000000008000429c <iunlock>:
{
    8000429c:	1101                	addi	sp,sp,-32
    8000429e:	ec06                	sd	ra,24(sp)
    800042a0:	e822                	sd	s0,16(sp)
    800042a2:	e426                	sd	s1,8(sp)
    800042a4:	e04a                	sd	s2,0(sp)
    800042a6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800042a8:	c905                	beqz	a0,800042d8 <iunlock+0x3c>
    800042aa:	84aa                	mv	s1,a0
    800042ac:	01050913          	addi	s2,a0,16
    800042b0:	854a                	mv	a0,s2
    800042b2:	00001097          	auipc	ra,0x1
    800042b6:	c7c080e7          	jalr	-900(ra) # 80004f2e <holdingsleep>
    800042ba:	cd19                	beqz	a0,800042d8 <iunlock+0x3c>
    800042bc:	449c                	lw	a5,8(s1)
    800042be:	00f05d63          	blez	a5,800042d8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800042c2:	854a                	mv	a0,s2
    800042c4:	00001097          	auipc	ra,0x1
    800042c8:	c26080e7          	jalr	-986(ra) # 80004eea <releasesleep>
}
    800042cc:	60e2                	ld	ra,24(sp)
    800042ce:	6442                	ld	s0,16(sp)
    800042d0:	64a2                	ld	s1,8(sp)
    800042d2:	6902                	ld	s2,0(sp)
    800042d4:	6105                	addi	sp,sp,32
    800042d6:	8082                	ret
    panic("iunlock");
    800042d8:	00004517          	auipc	a0,0x4
    800042dc:	31050513          	addi	a0,a0,784 # 800085e8 <syscalls+0x1b8>
    800042e0:	ffffc097          	auipc	ra,0xffffc
    800042e4:	25e080e7          	jalr	606(ra) # 8000053e <panic>

00000000800042e8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800042e8:	7179                	addi	sp,sp,-48
    800042ea:	f406                	sd	ra,40(sp)
    800042ec:	f022                	sd	s0,32(sp)
    800042ee:	ec26                	sd	s1,24(sp)
    800042f0:	e84a                	sd	s2,16(sp)
    800042f2:	e44e                	sd	s3,8(sp)
    800042f4:	e052                	sd	s4,0(sp)
    800042f6:	1800                	addi	s0,sp,48
    800042f8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800042fa:	05050493          	addi	s1,a0,80
    800042fe:	08050913          	addi	s2,a0,128
    80004302:	a021                	j	8000430a <itrunc+0x22>
    80004304:	0491                	addi	s1,s1,4
    80004306:	01248d63          	beq	s1,s2,80004320 <itrunc+0x38>
    if(ip->addrs[i]){
    8000430a:	408c                	lw	a1,0(s1)
    8000430c:	dde5                	beqz	a1,80004304 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000430e:	0009a503          	lw	a0,0(s3)
    80004312:	00000097          	auipc	ra,0x0
    80004316:	8f4080e7          	jalr	-1804(ra) # 80003c06 <bfree>
      ip->addrs[i] = 0;
    8000431a:	0004a023          	sw	zero,0(s1)
    8000431e:	b7dd                	j	80004304 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004320:	0809a583          	lw	a1,128(s3)
    80004324:	e185                	bnez	a1,80004344 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004326:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000432a:	854e                	mv	a0,s3
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	de4080e7          	jalr	-540(ra) # 80004110 <iupdate>
}
    80004334:	70a2                	ld	ra,40(sp)
    80004336:	7402                	ld	s0,32(sp)
    80004338:	64e2                	ld	s1,24(sp)
    8000433a:	6942                	ld	s2,16(sp)
    8000433c:	69a2                	ld	s3,8(sp)
    8000433e:	6a02                	ld	s4,0(sp)
    80004340:	6145                	addi	sp,sp,48
    80004342:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004344:	0009a503          	lw	a0,0(s3)
    80004348:	fffff097          	auipc	ra,0xfffff
    8000434c:	678080e7          	jalr	1656(ra) # 800039c0 <bread>
    80004350:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004352:	05850493          	addi	s1,a0,88
    80004356:	45850913          	addi	s2,a0,1112
    8000435a:	a021                	j	80004362 <itrunc+0x7a>
    8000435c:	0491                	addi	s1,s1,4
    8000435e:	01248b63          	beq	s1,s2,80004374 <itrunc+0x8c>
      if(a[j])
    80004362:	408c                	lw	a1,0(s1)
    80004364:	dde5                	beqz	a1,8000435c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004366:	0009a503          	lw	a0,0(s3)
    8000436a:	00000097          	auipc	ra,0x0
    8000436e:	89c080e7          	jalr	-1892(ra) # 80003c06 <bfree>
    80004372:	b7ed                	j	8000435c <itrunc+0x74>
    brelse(bp);
    80004374:	8552                	mv	a0,s4
    80004376:	fffff097          	auipc	ra,0xfffff
    8000437a:	77a080e7          	jalr	1914(ra) # 80003af0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000437e:	0809a583          	lw	a1,128(s3)
    80004382:	0009a503          	lw	a0,0(s3)
    80004386:	00000097          	auipc	ra,0x0
    8000438a:	880080e7          	jalr	-1920(ra) # 80003c06 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000438e:	0809a023          	sw	zero,128(s3)
    80004392:	bf51                	j	80004326 <itrunc+0x3e>

0000000080004394 <iput>:
{
    80004394:	1101                	addi	sp,sp,-32
    80004396:	ec06                	sd	ra,24(sp)
    80004398:	e822                	sd	s0,16(sp)
    8000439a:	e426                	sd	s1,8(sp)
    8000439c:	e04a                	sd	s2,0(sp)
    8000439e:	1000                	addi	s0,sp,32
    800043a0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800043a2:	007bd517          	auipc	a0,0x7bd
    800043a6:	f0650513          	addi	a0,a0,-250 # 807c12a8 <itable>
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	82c080e7          	jalr	-2004(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800043b2:	4498                	lw	a4,8(s1)
    800043b4:	4785                	li	a5,1
    800043b6:	02f70363          	beq	a4,a5,800043dc <iput+0x48>
  ip->ref--;
    800043ba:	449c                	lw	a5,8(s1)
    800043bc:	37fd                	addiw	a5,a5,-1
    800043be:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800043c0:	007bd517          	auipc	a0,0x7bd
    800043c4:	ee850513          	addi	a0,a0,-280 # 807c12a8 <itable>
    800043c8:	ffffd097          	auipc	ra,0xffffd
    800043cc:	8c2080e7          	jalr	-1854(ra) # 80000c8a <release>
}
    800043d0:	60e2                	ld	ra,24(sp)
    800043d2:	6442                	ld	s0,16(sp)
    800043d4:	64a2                	ld	s1,8(sp)
    800043d6:	6902                	ld	s2,0(sp)
    800043d8:	6105                	addi	sp,sp,32
    800043da:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800043dc:	40bc                	lw	a5,64(s1)
    800043de:	dff1                	beqz	a5,800043ba <iput+0x26>
    800043e0:	04a49783          	lh	a5,74(s1)
    800043e4:	fbf9                	bnez	a5,800043ba <iput+0x26>
    acquiresleep(&ip->lock);
    800043e6:	01048913          	addi	s2,s1,16
    800043ea:	854a                	mv	a0,s2
    800043ec:	00001097          	auipc	ra,0x1
    800043f0:	aa8080e7          	jalr	-1368(ra) # 80004e94 <acquiresleep>
    release(&itable.lock);
    800043f4:	007bd517          	auipc	a0,0x7bd
    800043f8:	eb450513          	addi	a0,a0,-332 # 807c12a8 <itable>
    800043fc:	ffffd097          	auipc	ra,0xffffd
    80004400:	88e080e7          	jalr	-1906(ra) # 80000c8a <release>
    itrunc(ip);
    80004404:	8526                	mv	a0,s1
    80004406:	00000097          	auipc	ra,0x0
    8000440a:	ee2080e7          	jalr	-286(ra) # 800042e8 <itrunc>
    ip->type = 0;
    8000440e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004412:	8526                	mv	a0,s1
    80004414:	00000097          	auipc	ra,0x0
    80004418:	cfc080e7          	jalr	-772(ra) # 80004110 <iupdate>
    ip->valid = 0;
    8000441c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004420:	854a                	mv	a0,s2
    80004422:	00001097          	auipc	ra,0x1
    80004426:	ac8080e7          	jalr	-1336(ra) # 80004eea <releasesleep>
    acquire(&itable.lock);
    8000442a:	007bd517          	auipc	a0,0x7bd
    8000442e:	e7e50513          	addi	a0,a0,-386 # 807c12a8 <itable>
    80004432:	ffffc097          	auipc	ra,0xffffc
    80004436:	7a4080e7          	jalr	1956(ra) # 80000bd6 <acquire>
    8000443a:	b741                	j	800043ba <iput+0x26>

000000008000443c <iunlockput>:
{
    8000443c:	1101                	addi	sp,sp,-32
    8000443e:	ec06                	sd	ra,24(sp)
    80004440:	e822                	sd	s0,16(sp)
    80004442:	e426                	sd	s1,8(sp)
    80004444:	1000                	addi	s0,sp,32
    80004446:	84aa                	mv	s1,a0
  iunlock(ip);
    80004448:	00000097          	auipc	ra,0x0
    8000444c:	e54080e7          	jalr	-428(ra) # 8000429c <iunlock>
  iput(ip);
    80004450:	8526                	mv	a0,s1
    80004452:	00000097          	auipc	ra,0x0
    80004456:	f42080e7          	jalr	-190(ra) # 80004394 <iput>
}
    8000445a:	60e2                	ld	ra,24(sp)
    8000445c:	6442                	ld	s0,16(sp)
    8000445e:	64a2                	ld	s1,8(sp)
    80004460:	6105                	addi	sp,sp,32
    80004462:	8082                	ret

0000000080004464 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004464:	1141                	addi	sp,sp,-16
    80004466:	e422                	sd	s0,8(sp)
    80004468:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000446a:	411c                	lw	a5,0(a0)
    8000446c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000446e:	415c                	lw	a5,4(a0)
    80004470:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004472:	04451783          	lh	a5,68(a0)
    80004476:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000447a:	04a51783          	lh	a5,74(a0)
    8000447e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004482:	04c56783          	lwu	a5,76(a0)
    80004486:	e99c                	sd	a5,16(a1)
}
    80004488:	6422                	ld	s0,8(sp)
    8000448a:	0141                	addi	sp,sp,16
    8000448c:	8082                	ret

000000008000448e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000448e:	457c                	lw	a5,76(a0)
    80004490:	0ed7e963          	bltu	a5,a3,80004582 <readi+0xf4>
{
    80004494:	7159                	addi	sp,sp,-112
    80004496:	f486                	sd	ra,104(sp)
    80004498:	f0a2                	sd	s0,96(sp)
    8000449a:	eca6                	sd	s1,88(sp)
    8000449c:	e8ca                	sd	s2,80(sp)
    8000449e:	e4ce                	sd	s3,72(sp)
    800044a0:	e0d2                	sd	s4,64(sp)
    800044a2:	fc56                	sd	s5,56(sp)
    800044a4:	f85a                	sd	s6,48(sp)
    800044a6:	f45e                	sd	s7,40(sp)
    800044a8:	f062                	sd	s8,32(sp)
    800044aa:	ec66                	sd	s9,24(sp)
    800044ac:	e86a                	sd	s10,16(sp)
    800044ae:	e46e                	sd	s11,8(sp)
    800044b0:	1880                	addi	s0,sp,112
    800044b2:	8b2a                	mv	s6,a0
    800044b4:	8bae                	mv	s7,a1
    800044b6:	8a32                	mv	s4,a2
    800044b8:	84b6                	mv	s1,a3
    800044ba:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800044bc:	9f35                	addw	a4,a4,a3
    return 0;
    800044be:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800044c0:	0ad76063          	bltu	a4,a3,80004560 <readi+0xd2>
  if(off + n > ip->size)
    800044c4:	00e7f463          	bgeu	a5,a4,800044cc <readi+0x3e>
    n = ip->size - off;
    800044c8:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800044cc:	0a0a8963          	beqz	s5,8000457e <readi+0xf0>
    800044d0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800044d2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800044d6:	5c7d                	li	s8,-1
    800044d8:	a82d                	j	80004512 <readi+0x84>
    800044da:	020d1d93          	slli	s11,s10,0x20
    800044de:	020ddd93          	srli	s11,s11,0x20
    800044e2:	05890793          	addi	a5,s2,88
    800044e6:	86ee                	mv	a3,s11
    800044e8:	963e                	add	a2,a2,a5
    800044ea:	85d2                	mv	a1,s4
    800044ec:	855e                	mv	a0,s7
    800044ee:	ffffe097          	auipc	ra,0xffffe
    800044f2:	172080e7          	jalr	370(ra) # 80002660 <either_copyout>
    800044f6:	05850d63          	beq	a0,s8,80004550 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800044fa:	854a                	mv	a0,s2
    800044fc:	fffff097          	auipc	ra,0xfffff
    80004500:	5f4080e7          	jalr	1524(ra) # 80003af0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004504:	013d09bb          	addw	s3,s10,s3
    80004508:	009d04bb          	addw	s1,s10,s1
    8000450c:	9a6e                	add	s4,s4,s11
    8000450e:	0559f763          	bgeu	s3,s5,8000455c <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004512:	00a4d59b          	srliw	a1,s1,0xa
    80004516:	855a                	mv	a0,s6
    80004518:	00000097          	auipc	ra,0x0
    8000451c:	8a2080e7          	jalr	-1886(ra) # 80003dba <bmap>
    80004520:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004524:	cd85                	beqz	a1,8000455c <readi+0xce>
    bp = bread(ip->dev, addr);
    80004526:	000b2503          	lw	a0,0(s6)
    8000452a:	fffff097          	auipc	ra,0xfffff
    8000452e:	496080e7          	jalr	1174(ra) # 800039c0 <bread>
    80004532:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004534:	3ff4f613          	andi	a2,s1,1023
    80004538:	40cc87bb          	subw	a5,s9,a2
    8000453c:	413a873b          	subw	a4,s5,s3
    80004540:	8d3e                	mv	s10,a5
    80004542:	2781                	sext.w	a5,a5
    80004544:	0007069b          	sext.w	a3,a4
    80004548:	f8f6f9e3          	bgeu	a3,a5,800044da <readi+0x4c>
    8000454c:	8d3a                	mv	s10,a4
    8000454e:	b771                	j	800044da <readi+0x4c>
      brelse(bp);
    80004550:	854a                	mv	a0,s2
    80004552:	fffff097          	auipc	ra,0xfffff
    80004556:	59e080e7          	jalr	1438(ra) # 80003af0 <brelse>
      tot = -1;
    8000455a:	59fd                	li	s3,-1
  }
  return tot;
    8000455c:	0009851b          	sext.w	a0,s3
}
    80004560:	70a6                	ld	ra,104(sp)
    80004562:	7406                	ld	s0,96(sp)
    80004564:	64e6                	ld	s1,88(sp)
    80004566:	6946                	ld	s2,80(sp)
    80004568:	69a6                	ld	s3,72(sp)
    8000456a:	6a06                	ld	s4,64(sp)
    8000456c:	7ae2                	ld	s5,56(sp)
    8000456e:	7b42                	ld	s6,48(sp)
    80004570:	7ba2                	ld	s7,40(sp)
    80004572:	7c02                	ld	s8,32(sp)
    80004574:	6ce2                	ld	s9,24(sp)
    80004576:	6d42                	ld	s10,16(sp)
    80004578:	6da2                	ld	s11,8(sp)
    8000457a:	6165                	addi	sp,sp,112
    8000457c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000457e:	89d6                	mv	s3,s5
    80004580:	bff1                	j	8000455c <readi+0xce>
    return 0;
    80004582:	4501                	li	a0,0
}
    80004584:	8082                	ret

0000000080004586 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004586:	457c                	lw	a5,76(a0)
    80004588:	10d7e863          	bltu	a5,a3,80004698 <writei+0x112>
{
    8000458c:	7159                	addi	sp,sp,-112
    8000458e:	f486                	sd	ra,104(sp)
    80004590:	f0a2                	sd	s0,96(sp)
    80004592:	eca6                	sd	s1,88(sp)
    80004594:	e8ca                	sd	s2,80(sp)
    80004596:	e4ce                	sd	s3,72(sp)
    80004598:	e0d2                	sd	s4,64(sp)
    8000459a:	fc56                	sd	s5,56(sp)
    8000459c:	f85a                	sd	s6,48(sp)
    8000459e:	f45e                	sd	s7,40(sp)
    800045a0:	f062                	sd	s8,32(sp)
    800045a2:	ec66                	sd	s9,24(sp)
    800045a4:	e86a                	sd	s10,16(sp)
    800045a6:	e46e                	sd	s11,8(sp)
    800045a8:	1880                	addi	s0,sp,112
    800045aa:	8aaa                	mv	s5,a0
    800045ac:	8bae                	mv	s7,a1
    800045ae:	8a32                	mv	s4,a2
    800045b0:	8936                	mv	s2,a3
    800045b2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800045b4:	00e687bb          	addw	a5,a3,a4
    800045b8:	0ed7e263          	bltu	a5,a3,8000469c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800045bc:	00043737          	lui	a4,0x43
    800045c0:	0ef76063          	bltu	a4,a5,800046a0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800045c4:	0c0b0863          	beqz	s6,80004694 <writei+0x10e>
    800045c8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800045ca:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800045ce:	5c7d                	li	s8,-1
    800045d0:	a091                	j	80004614 <writei+0x8e>
    800045d2:	020d1d93          	slli	s11,s10,0x20
    800045d6:	020ddd93          	srli	s11,s11,0x20
    800045da:	05848793          	addi	a5,s1,88
    800045de:	86ee                	mv	a3,s11
    800045e0:	8652                	mv	a2,s4
    800045e2:	85de                	mv	a1,s7
    800045e4:	953e                	add	a0,a0,a5
    800045e6:	ffffe097          	auipc	ra,0xffffe
    800045ea:	0d0080e7          	jalr	208(ra) # 800026b6 <either_copyin>
    800045ee:	07850263          	beq	a0,s8,80004652 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800045f2:	8526                	mv	a0,s1
    800045f4:	00000097          	auipc	ra,0x0
    800045f8:	780080e7          	jalr	1920(ra) # 80004d74 <log_write>
    brelse(bp);
    800045fc:	8526                	mv	a0,s1
    800045fe:	fffff097          	auipc	ra,0xfffff
    80004602:	4f2080e7          	jalr	1266(ra) # 80003af0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004606:	013d09bb          	addw	s3,s10,s3
    8000460a:	012d093b          	addw	s2,s10,s2
    8000460e:	9a6e                	add	s4,s4,s11
    80004610:	0569f663          	bgeu	s3,s6,8000465c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004614:	00a9559b          	srliw	a1,s2,0xa
    80004618:	8556                	mv	a0,s5
    8000461a:	fffff097          	auipc	ra,0xfffff
    8000461e:	7a0080e7          	jalr	1952(ra) # 80003dba <bmap>
    80004622:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004626:	c99d                	beqz	a1,8000465c <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004628:	000aa503          	lw	a0,0(s5)
    8000462c:	fffff097          	auipc	ra,0xfffff
    80004630:	394080e7          	jalr	916(ra) # 800039c0 <bread>
    80004634:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004636:	3ff97513          	andi	a0,s2,1023
    8000463a:	40ac87bb          	subw	a5,s9,a0
    8000463e:	413b073b          	subw	a4,s6,s3
    80004642:	8d3e                	mv	s10,a5
    80004644:	2781                	sext.w	a5,a5
    80004646:	0007069b          	sext.w	a3,a4
    8000464a:	f8f6f4e3          	bgeu	a3,a5,800045d2 <writei+0x4c>
    8000464e:	8d3a                	mv	s10,a4
    80004650:	b749                	j	800045d2 <writei+0x4c>
      brelse(bp);
    80004652:	8526                	mv	a0,s1
    80004654:	fffff097          	auipc	ra,0xfffff
    80004658:	49c080e7          	jalr	1180(ra) # 80003af0 <brelse>
  }

  if(off > ip->size)
    8000465c:	04caa783          	lw	a5,76(s5)
    80004660:	0127f463          	bgeu	a5,s2,80004668 <writei+0xe2>
    ip->size = off;
    80004664:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004668:	8556                	mv	a0,s5
    8000466a:	00000097          	auipc	ra,0x0
    8000466e:	aa6080e7          	jalr	-1370(ra) # 80004110 <iupdate>

  return tot;
    80004672:	0009851b          	sext.w	a0,s3
}
    80004676:	70a6                	ld	ra,104(sp)
    80004678:	7406                	ld	s0,96(sp)
    8000467a:	64e6                	ld	s1,88(sp)
    8000467c:	6946                	ld	s2,80(sp)
    8000467e:	69a6                	ld	s3,72(sp)
    80004680:	6a06                	ld	s4,64(sp)
    80004682:	7ae2                	ld	s5,56(sp)
    80004684:	7b42                	ld	s6,48(sp)
    80004686:	7ba2                	ld	s7,40(sp)
    80004688:	7c02                	ld	s8,32(sp)
    8000468a:	6ce2                	ld	s9,24(sp)
    8000468c:	6d42                	ld	s10,16(sp)
    8000468e:	6da2                	ld	s11,8(sp)
    80004690:	6165                	addi	sp,sp,112
    80004692:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004694:	89da                	mv	s3,s6
    80004696:	bfc9                	j	80004668 <writei+0xe2>
    return -1;
    80004698:	557d                	li	a0,-1
}
    8000469a:	8082                	ret
    return -1;
    8000469c:	557d                	li	a0,-1
    8000469e:	bfe1                	j	80004676 <writei+0xf0>
    return -1;
    800046a0:	557d                	li	a0,-1
    800046a2:	bfd1                	j	80004676 <writei+0xf0>

00000000800046a4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800046a4:	1141                	addi	sp,sp,-16
    800046a6:	e406                	sd	ra,8(sp)
    800046a8:	e022                	sd	s0,0(sp)
    800046aa:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800046ac:	4639                	li	a2,14
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	6f4080e7          	jalr	1780(ra) # 80000da2 <strncmp>
}
    800046b6:	60a2                	ld	ra,8(sp)
    800046b8:	6402                	ld	s0,0(sp)
    800046ba:	0141                	addi	sp,sp,16
    800046bc:	8082                	ret

00000000800046be <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800046be:	7139                	addi	sp,sp,-64
    800046c0:	fc06                	sd	ra,56(sp)
    800046c2:	f822                	sd	s0,48(sp)
    800046c4:	f426                	sd	s1,40(sp)
    800046c6:	f04a                	sd	s2,32(sp)
    800046c8:	ec4e                	sd	s3,24(sp)
    800046ca:	e852                	sd	s4,16(sp)
    800046cc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800046ce:	04451703          	lh	a4,68(a0)
    800046d2:	4785                	li	a5,1
    800046d4:	00f71a63          	bne	a4,a5,800046e8 <dirlookup+0x2a>
    800046d8:	892a                	mv	s2,a0
    800046da:	89ae                	mv	s3,a1
    800046dc:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800046de:	457c                	lw	a5,76(a0)
    800046e0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800046e2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046e4:	e79d                	bnez	a5,80004712 <dirlookup+0x54>
    800046e6:	a8a5                	j	8000475e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800046e8:	00004517          	auipc	a0,0x4
    800046ec:	f0850513          	addi	a0,a0,-248 # 800085f0 <syscalls+0x1c0>
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	e4e080e7          	jalr	-434(ra) # 8000053e <panic>
      panic("dirlookup read");
    800046f8:	00004517          	auipc	a0,0x4
    800046fc:	f1050513          	addi	a0,a0,-240 # 80008608 <syscalls+0x1d8>
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	e3e080e7          	jalr	-450(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004708:	24c1                	addiw	s1,s1,16
    8000470a:	04c92783          	lw	a5,76(s2)
    8000470e:	04f4f763          	bgeu	s1,a5,8000475c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004712:	4741                	li	a4,16
    80004714:	86a6                	mv	a3,s1
    80004716:	fc040613          	addi	a2,s0,-64
    8000471a:	4581                	li	a1,0
    8000471c:	854a                	mv	a0,s2
    8000471e:	00000097          	auipc	ra,0x0
    80004722:	d70080e7          	jalr	-656(ra) # 8000448e <readi>
    80004726:	47c1                	li	a5,16
    80004728:	fcf518e3          	bne	a0,a5,800046f8 <dirlookup+0x3a>
    if(de.inum == 0)
    8000472c:	fc045783          	lhu	a5,-64(s0)
    80004730:	dfe1                	beqz	a5,80004708 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004732:	fc240593          	addi	a1,s0,-62
    80004736:	854e                	mv	a0,s3
    80004738:	00000097          	auipc	ra,0x0
    8000473c:	f6c080e7          	jalr	-148(ra) # 800046a4 <namecmp>
    80004740:	f561                	bnez	a0,80004708 <dirlookup+0x4a>
      if(poff)
    80004742:	000a0463          	beqz	s4,8000474a <dirlookup+0x8c>
        *poff = off;
    80004746:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000474a:	fc045583          	lhu	a1,-64(s0)
    8000474e:	00092503          	lw	a0,0(s2)
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	750080e7          	jalr	1872(ra) # 80003ea2 <iget>
    8000475a:	a011                	j	8000475e <dirlookup+0xa0>
  return 0;
    8000475c:	4501                	li	a0,0
}
    8000475e:	70e2                	ld	ra,56(sp)
    80004760:	7442                	ld	s0,48(sp)
    80004762:	74a2                	ld	s1,40(sp)
    80004764:	7902                	ld	s2,32(sp)
    80004766:	69e2                	ld	s3,24(sp)
    80004768:	6a42                	ld	s4,16(sp)
    8000476a:	6121                	addi	sp,sp,64
    8000476c:	8082                	ret

000000008000476e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000476e:	711d                	addi	sp,sp,-96
    80004770:	ec86                	sd	ra,88(sp)
    80004772:	e8a2                	sd	s0,80(sp)
    80004774:	e4a6                	sd	s1,72(sp)
    80004776:	e0ca                	sd	s2,64(sp)
    80004778:	fc4e                	sd	s3,56(sp)
    8000477a:	f852                	sd	s4,48(sp)
    8000477c:	f456                	sd	s5,40(sp)
    8000477e:	f05a                	sd	s6,32(sp)
    80004780:	ec5e                	sd	s7,24(sp)
    80004782:	e862                	sd	s8,16(sp)
    80004784:	e466                	sd	s9,8(sp)
    80004786:	1080                	addi	s0,sp,96
    80004788:	84aa                	mv	s1,a0
    8000478a:	8aae                	mv	s5,a1
    8000478c:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000478e:	00054703          	lbu	a4,0(a0)
    80004792:	02f00793          	li	a5,47
    80004796:	02f70363          	beq	a4,a5,800047bc <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000479a:	ffffd097          	auipc	ra,0xffffd
    8000479e:	222080e7          	jalr	546(ra) # 800019bc <myproc>
    800047a2:	15053503          	ld	a0,336(a0)
    800047a6:	00000097          	auipc	ra,0x0
    800047aa:	9f6080e7          	jalr	-1546(ra) # 8000419c <idup>
    800047ae:	89aa                	mv	s3,a0
  while(*path == '/')
    800047b0:	02f00913          	li	s2,47
  len = path - s;
    800047b4:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800047b6:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800047b8:	4b85                	li	s7,1
    800047ba:	a865                	j	80004872 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800047bc:	4585                	li	a1,1
    800047be:	4505                	li	a0,1
    800047c0:	fffff097          	auipc	ra,0xfffff
    800047c4:	6e2080e7          	jalr	1762(ra) # 80003ea2 <iget>
    800047c8:	89aa                	mv	s3,a0
    800047ca:	b7dd                	j	800047b0 <namex+0x42>
      iunlockput(ip);
    800047cc:	854e                	mv	a0,s3
    800047ce:	00000097          	auipc	ra,0x0
    800047d2:	c6e080e7          	jalr	-914(ra) # 8000443c <iunlockput>
      return 0;
    800047d6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800047d8:	854e                	mv	a0,s3
    800047da:	60e6                	ld	ra,88(sp)
    800047dc:	6446                	ld	s0,80(sp)
    800047de:	64a6                	ld	s1,72(sp)
    800047e0:	6906                	ld	s2,64(sp)
    800047e2:	79e2                	ld	s3,56(sp)
    800047e4:	7a42                	ld	s4,48(sp)
    800047e6:	7aa2                	ld	s5,40(sp)
    800047e8:	7b02                	ld	s6,32(sp)
    800047ea:	6be2                	ld	s7,24(sp)
    800047ec:	6c42                	ld	s8,16(sp)
    800047ee:	6ca2                	ld	s9,8(sp)
    800047f0:	6125                	addi	sp,sp,96
    800047f2:	8082                	ret
      iunlock(ip);
    800047f4:	854e                	mv	a0,s3
    800047f6:	00000097          	auipc	ra,0x0
    800047fa:	aa6080e7          	jalr	-1370(ra) # 8000429c <iunlock>
      return ip;
    800047fe:	bfe9                	j	800047d8 <namex+0x6a>
      iunlockput(ip);
    80004800:	854e                	mv	a0,s3
    80004802:	00000097          	auipc	ra,0x0
    80004806:	c3a080e7          	jalr	-966(ra) # 8000443c <iunlockput>
      return 0;
    8000480a:	89e6                	mv	s3,s9
    8000480c:	b7f1                	j	800047d8 <namex+0x6a>
  len = path - s;
    8000480e:	40b48633          	sub	a2,s1,a1
    80004812:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004816:	099c5463          	bge	s8,s9,8000489e <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000481a:	4639                	li	a2,14
    8000481c:	8552                	mv	a0,s4
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	510080e7          	jalr	1296(ra) # 80000d2e <memmove>
  while(*path == '/')
    80004826:	0004c783          	lbu	a5,0(s1)
    8000482a:	01279763          	bne	a5,s2,80004838 <namex+0xca>
    path++;
    8000482e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004830:	0004c783          	lbu	a5,0(s1)
    80004834:	ff278de3          	beq	a5,s2,8000482e <namex+0xc0>
    ilock(ip);
    80004838:	854e                	mv	a0,s3
    8000483a:	00000097          	auipc	ra,0x0
    8000483e:	9a0080e7          	jalr	-1632(ra) # 800041da <ilock>
    if(ip->type != T_DIR){
    80004842:	04499783          	lh	a5,68(s3)
    80004846:	f97793e3          	bne	a5,s7,800047cc <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000484a:	000a8563          	beqz	s5,80004854 <namex+0xe6>
    8000484e:	0004c783          	lbu	a5,0(s1)
    80004852:	d3cd                	beqz	a5,800047f4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004854:	865a                	mv	a2,s6
    80004856:	85d2                	mv	a1,s4
    80004858:	854e                	mv	a0,s3
    8000485a:	00000097          	auipc	ra,0x0
    8000485e:	e64080e7          	jalr	-412(ra) # 800046be <dirlookup>
    80004862:	8caa                	mv	s9,a0
    80004864:	dd51                	beqz	a0,80004800 <namex+0x92>
    iunlockput(ip);
    80004866:	854e                	mv	a0,s3
    80004868:	00000097          	auipc	ra,0x0
    8000486c:	bd4080e7          	jalr	-1068(ra) # 8000443c <iunlockput>
    ip = next;
    80004870:	89e6                	mv	s3,s9
  while(*path == '/')
    80004872:	0004c783          	lbu	a5,0(s1)
    80004876:	05279763          	bne	a5,s2,800048c4 <namex+0x156>
    path++;
    8000487a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000487c:	0004c783          	lbu	a5,0(s1)
    80004880:	ff278de3          	beq	a5,s2,8000487a <namex+0x10c>
  if(*path == 0)
    80004884:	c79d                	beqz	a5,800048b2 <namex+0x144>
    path++;
    80004886:	85a6                	mv	a1,s1
  len = path - s;
    80004888:	8cda                	mv	s9,s6
    8000488a:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000488c:	01278963          	beq	a5,s2,8000489e <namex+0x130>
    80004890:	dfbd                	beqz	a5,8000480e <namex+0xa0>
    path++;
    80004892:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004894:	0004c783          	lbu	a5,0(s1)
    80004898:	ff279ce3          	bne	a5,s2,80004890 <namex+0x122>
    8000489c:	bf8d                	j	8000480e <namex+0xa0>
    memmove(name, s, len);
    8000489e:	2601                	sext.w	a2,a2
    800048a0:	8552                	mv	a0,s4
    800048a2:	ffffc097          	auipc	ra,0xffffc
    800048a6:	48c080e7          	jalr	1164(ra) # 80000d2e <memmove>
    name[len] = 0;
    800048aa:	9cd2                	add	s9,s9,s4
    800048ac:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800048b0:	bf9d                	j	80004826 <namex+0xb8>
  if(nameiparent){
    800048b2:	f20a83e3          	beqz	s5,800047d8 <namex+0x6a>
    iput(ip);
    800048b6:	854e                	mv	a0,s3
    800048b8:	00000097          	auipc	ra,0x0
    800048bc:	adc080e7          	jalr	-1316(ra) # 80004394 <iput>
    return 0;
    800048c0:	4981                	li	s3,0
    800048c2:	bf19                	j	800047d8 <namex+0x6a>
  if(*path == 0)
    800048c4:	d7fd                	beqz	a5,800048b2 <namex+0x144>
  while(*path != '/' && *path != 0)
    800048c6:	0004c783          	lbu	a5,0(s1)
    800048ca:	85a6                	mv	a1,s1
    800048cc:	b7d1                	j	80004890 <namex+0x122>

00000000800048ce <dirlink>:
{
    800048ce:	7139                	addi	sp,sp,-64
    800048d0:	fc06                	sd	ra,56(sp)
    800048d2:	f822                	sd	s0,48(sp)
    800048d4:	f426                	sd	s1,40(sp)
    800048d6:	f04a                	sd	s2,32(sp)
    800048d8:	ec4e                	sd	s3,24(sp)
    800048da:	e852                	sd	s4,16(sp)
    800048dc:	0080                	addi	s0,sp,64
    800048de:	892a                	mv	s2,a0
    800048e0:	8a2e                	mv	s4,a1
    800048e2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800048e4:	4601                	li	a2,0
    800048e6:	00000097          	auipc	ra,0x0
    800048ea:	dd8080e7          	jalr	-552(ra) # 800046be <dirlookup>
    800048ee:	e93d                	bnez	a0,80004964 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800048f0:	04c92483          	lw	s1,76(s2)
    800048f4:	c49d                	beqz	s1,80004922 <dirlink+0x54>
    800048f6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048f8:	4741                	li	a4,16
    800048fa:	86a6                	mv	a3,s1
    800048fc:	fc040613          	addi	a2,s0,-64
    80004900:	4581                	li	a1,0
    80004902:	854a                	mv	a0,s2
    80004904:	00000097          	auipc	ra,0x0
    80004908:	b8a080e7          	jalr	-1142(ra) # 8000448e <readi>
    8000490c:	47c1                	li	a5,16
    8000490e:	06f51163          	bne	a0,a5,80004970 <dirlink+0xa2>
    if(de.inum == 0)
    80004912:	fc045783          	lhu	a5,-64(s0)
    80004916:	c791                	beqz	a5,80004922 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004918:	24c1                	addiw	s1,s1,16
    8000491a:	04c92783          	lw	a5,76(s2)
    8000491e:	fcf4ede3          	bltu	s1,a5,800048f8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004922:	4639                	li	a2,14
    80004924:	85d2                	mv	a1,s4
    80004926:	fc240513          	addi	a0,s0,-62
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	4b4080e7          	jalr	1204(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004932:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004936:	4741                	li	a4,16
    80004938:	86a6                	mv	a3,s1
    8000493a:	fc040613          	addi	a2,s0,-64
    8000493e:	4581                	li	a1,0
    80004940:	854a                	mv	a0,s2
    80004942:	00000097          	auipc	ra,0x0
    80004946:	c44080e7          	jalr	-956(ra) # 80004586 <writei>
    8000494a:	1541                	addi	a0,a0,-16
    8000494c:	00a03533          	snez	a0,a0
    80004950:	40a00533          	neg	a0,a0
}
    80004954:	70e2                	ld	ra,56(sp)
    80004956:	7442                	ld	s0,48(sp)
    80004958:	74a2                	ld	s1,40(sp)
    8000495a:	7902                	ld	s2,32(sp)
    8000495c:	69e2                	ld	s3,24(sp)
    8000495e:	6a42                	ld	s4,16(sp)
    80004960:	6121                	addi	sp,sp,64
    80004962:	8082                	ret
    iput(ip);
    80004964:	00000097          	auipc	ra,0x0
    80004968:	a30080e7          	jalr	-1488(ra) # 80004394 <iput>
    return -1;
    8000496c:	557d                	li	a0,-1
    8000496e:	b7dd                	j	80004954 <dirlink+0x86>
      panic("dirlink read");
    80004970:	00004517          	auipc	a0,0x4
    80004974:	ca850513          	addi	a0,a0,-856 # 80008618 <syscalls+0x1e8>
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	bc6080e7          	jalr	-1082(ra) # 8000053e <panic>

0000000080004980 <namei>:

struct inode*
namei(char *path)
{
    80004980:	1101                	addi	sp,sp,-32
    80004982:	ec06                	sd	ra,24(sp)
    80004984:	e822                	sd	s0,16(sp)
    80004986:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004988:	fe040613          	addi	a2,s0,-32
    8000498c:	4581                	li	a1,0
    8000498e:	00000097          	auipc	ra,0x0
    80004992:	de0080e7          	jalr	-544(ra) # 8000476e <namex>
}
    80004996:	60e2                	ld	ra,24(sp)
    80004998:	6442                	ld	s0,16(sp)
    8000499a:	6105                	addi	sp,sp,32
    8000499c:	8082                	ret

000000008000499e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000499e:	1141                	addi	sp,sp,-16
    800049a0:	e406                	sd	ra,8(sp)
    800049a2:	e022                	sd	s0,0(sp)
    800049a4:	0800                	addi	s0,sp,16
    800049a6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800049a8:	4585                	li	a1,1
    800049aa:	00000097          	auipc	ra,0x0
    800049ae:	dc4080e7          	jalr	-572(ra) # 8000476e <namex>
}
    800049b2:	60a2                	ld	ra,8(sp)
    800049b4:	6402                	ld	s0,0(sp)
    800049b6:	0141                	addi	sp,sp,16
    800049b8:	8082                	ret

00000000800049ba <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800049ba:	1101                	addi	sp,sp,-32
    800049bc:	ec06                	sd	ra,24(sp)
    800049be:	e822                	sd	s0,16(sp)
    800049c0:	e426                	sd	s1,8(sp)
    800049c2:	e04a                	sd	s2,0(sp)
    800049c4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800049c6:	007be917          	auipc	s2,0x7be
    800049ca:	38a90913          	addi	s2,s2,906 # 807c2d50 <log>
    800049ce:	01892583          	lw	a1,24(s2)
    800049d2:	02892503          	lw	a0,40(s2)
    800049d6:	fffff097          	auipc	ra,0xfffff
    800049da:	fea080e7          	jalr	-22(ra) # 800039c0 <bread>
    800049de:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800049e0:	02c92683          	lw	a3,44(s2)
    800049e4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800049e6:	02d05763          	blez	a3,80004a14 <write_head+0x5a>
    800049ea:	007be797          	auipc	a5,0x7be
    800049ee:	39678793          	addi	a5,a5,918 # 807c2d80 <log+0x30>
    800049f2:	05c50713          	addi	a4,a0,92
    800049f6:	36fd                	addiw	a3,a3,-1
    800049f8:	1682                	slli	a3,a3,0x20
    800049fa:	9281                	srli	a3,a3,0x20
    800049fc:	068a                	slli	a3,a3,0x2
    800049fe:	007be617          	auipc	a2,0x7be
    80004a02:	38660613          	addi	a2,a2,902 # 807c2d84 <log+0x34>
    80004a06:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004a08:	4390                	lw	a2,0(a5)
    80004a0a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004a0c:	0791                	addi	a5,a5,4
    80004a0e:	0711                	addi	a4,a4,4
    80004a10:	fed79ce3          	bne	a5,a3,80004a08 <write_head+0x4e>
  }
  bwrite(buf);
    80004a14:	8526                	mv	a0,s1
    80004a16:	fffff097          	auipc	ra,0xfffff
    80004a1a:	09c080e7          	jalr	156(ra) # 80003ab2 <bwrite>
  brelse(buf);
    80004a1e:	8526                	mv	a0,s1
    80004a20:	fffff097          	auipc	ra,0xfffff
    80004a24:	0d0080e7          	jalr	208(ra) # 80003af0 <brelse>
}
    80004a28:	60e2                	ld	ra,24(sp)
    80004a2a:	6442                	ld	s0,16(sp)
    80004a2c:	64a2                	ld	s1,8(sp)
    80004a2e:	6902                	ld	s2,0(sp)
    80004a30:	6105                	addi	sp,sp,32
    80004a32:	8082                	ret

0000000080004a34 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a34:	007be797          	auipc	a5,0x7be
    80004a38:	3487a783          	lw	a5,840(a5) # 807c2d7c <log+0x2c>
    80004a3c:	0af05d63          	blez	a5,80004af6 <install_trans+0xc2>
{
    80004a40:	7139                	addi	sp,sp,-64
    80004a42:	fc06                	sd	ra,56(sp)
    80004a44:	f822                	sd	s0,48(sp)
    80004a46:	f426                	sd	s1,40(sp)
    80004a48:	f04a                	sd	s2,32(sp)
    80004a4a:	ec4e                	sd	s3,24(sp)
    80004a4c:	e852                	sd	s4,16(sp)
    80004a4e:	e456                	sd	s5,8(sp)
    80004a50:	e05a                	sd	s6,0(sp)
    80004a52:	0080                	addi	s0,sp,64
    80004a54:	8b2a                	mv	s6,a0
    80004a56:	007bea97          	auipc	s5,0x7be
    80004a5a:	32aa8a93          	addi	s5,s5,810 # 807c2d80 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a5e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004a60:	007be997          	auipc	s3,0x7be
    80004a64:	2f098993          	addi	s3,s3,752 # 807c2d50 <log>
    80004a68:	a00d                	j	80004a8a <install_trans+0x56>
    brelse(lbuf);
    80004a6a:	854a                	mv	a0,s2
    80004a6c:	fffff097          	auipc	ra,0xfffff
    80004a70:	084080e7          	jalr	132(ra) # 80003af0 <brelse>
    brelse(dbuf);
    80004a74:	8526                	mv	a0,s1
    80004a76:	fffff097          	auipc	ra,0xfffff
    80004a7a:	07a080e7          	jalr	122(ra) # 80003af0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a7e:	2a05                	addiw	s4,s4,1
    80004a80:	0a91                	addi	s5,s5,4
    80004a82:	02c9a783          	lw	a5,44(s3)
    80004a86:	04fa5e63          	bge	s4,a5,80004ae2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004a8a:	0189a583          	lw	a1,24(s3)
    80004a8e:	014585bb          	addw	a1,a1,s4
    80004a92:	2585                	addiw	a1,a1,1
    80004a94:	0289a503          	lw	a0,40(s3)
    80004a98:	fffff097          	auipc	ra,0xfffff
    80004a9c:	f28080e7          	jalr	-216(ra) # 800039c0 <bread>
    80004aa0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004aa2:	000aa583          	lw	a1,0(s5)
    80004aa6:	0289a503          	lw	a0,40(s3)
    80004aaa:	fffff097          	auipc	ra,0xfffff
    80004aae:	f16080e7          	jalr	-234(ra) # 800039c0 <bread>
    80004ab2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004ab4:	40000613          	li	a2,1024
    80004ab8:	05890593          	addi	a1,s2,88
    80004abc:	05850513          	addi	a0,a0,88
    80004ac0:	ffffc097          	auipc	ra,0xffffc
    80004ac4:	26e080e7          	jalr	622(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004ac8:	8526                	mv	a0,s1
    80004aca:	fffff097          	auipc	ra,0xfffff
    80004ace:	fe8080e7          	jalr	-24(ra) # 80003ab2 <bwrite>
    if(recovering == 0)
    80004ad2:	f80b1ce3          	bnez	s6,80004a6a <install_trans+0x36>
      bunpin(dbuf);
    80004ad6:	8526                	mv	a0,s1
    80004ad8:	fffff097          	auipc	ra,0xfffff
    80004adc:	0f2080e7          	jalr	242(ra) # 80003bca <bunpin>
    80004ae0:	b769                	j	80004a6a <install_trans+0x36>
}
    80004ae2:	70e2                	ld	ra,56(sp)
    80004ae4:	7442                	ld	s0,48(sp)
    80004ae6:	74a2                	ld	s1,40(sp)
    80004ae8:	7902                	ld	s2,32(sp)
    80004aea:	69e2                	ld	s3,24(sp)
    80004aec:	6a42                	ld	s4,16(sp)
    80004aee:	6aa2                	ld	s5,8(sp)
    80004af0:	6b02                	ld	s6,0(sp)
    80004af2:	6121                	addi	sp,sp,64
    80004af4:	8082                	ret
    80004af6:	8082                	ret

0000000080004af8 <initlog>:
{
    80004af8:	7179                	addi	sp,sp,-48
    80004afa:	f406                	sd	ra,40(sp)
    80004afc:	f022                	sd	s0,32(sp)
    80004afe:	ec26                	sd	s1,24(sp)
    80004b00:	e84a                	sd	s2,16(sp)
    80004b02:	e44e                	sd	s3,8(sp)
    80004b04:	1800                	addi	s0,sp,48
    80004b06:	892a                	mv	s2,a0
    80004b08:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004b0a:	007be497          	auipc	s1,0x7be
    80004b0e:	24648493          	addi	s1,s1,582 # 807c2d50 <log>
    80004b12:	00004597          	auipc	a1,0x4
    80004b16:	b1658593          	addi	a1,a1,-1258 # 80008628 <syscalls+0x1f8>
    80004b1a:	8526                	mv	a0,s1
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	02a080e7          	jalr	42(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004b24:	0149a583          	lw	a1,20(s3)
    80004b28:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004b2a:	0109a783          	lw	a5,16(s3)
    80004b2e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004b30:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004b34:	854a                	mv	a0,s2
    80004b36:	fffff097          	auipc	ra,0xfffff
    80004b3a:	e8a080e7          	jalr	-374(ra) # 800039c0 <bread>
  log.lh.n = lh->n;
    80004b3e:	4d34                	lw	a3,88(a0)
    80004b40:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004b42:	02d05563          	blez	a3,80004b6c <initlog+0x74>
    80004b46:	05c50793          	addi	a5,a0,92
    80004b4a:	007be717          	auipc	a4,0x7be
    80004b4e:	23670713          	addi	a4,a4,566 # 807c2d80 <log+0x30>
    80004b52:	36fd                	addiw	a3,a3,-1
    80004b54:	1682                	slli	a3,a3,0x20
    80004b56:	9281                	srli	a3,a3,0x20
    80004b58:	068a                	slli	a3,a3,0x2
    80004b5a:	06050613          	addi	a2,a0,96
    80004b5e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004b60:	4390                	lw	a2,0(a5)
    80004b62:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004b64:	0791                	addi	a5,a5,4
    80004b66:	0711                	addi	a4,a4,4
    80004b68:	fed79ce3          	bne	a5,a3,80004b60 <initlog+0x68>
  brelse(buf);
    80004b6c:	fffff097          	auipc	ra,0xfffff
    80004b70:	f84080e7          	jalr	-124(ra) # 80003af0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004b74:	4505                	li	a0,1
    80004b76:	00000097          	auipc	ra,0x0
    80004b7a:	ebe080e7          	jalr	-322(ra) # 80004a34 <install_trans>
  log.lh.n = 0;
    80004b7e:	007be797          	auipc	a5,0x7be
    80004b82:	1e07af23          	sw	zero,510(a5) # 807c2d7c <log+0x2c>
  write_head(); // clear the log
    80004b86:	00000097          	auipc	ra,0x0
    80004b8a:	e34080e7          	jalr	-460(ra) # 800049ba <write_head>
}
    80004b8e:	70a2                	ld	ra,40(sp)
    80004b90:	7402                	ld	s0,32(sp)
    80004b92:	64e2                	ld	s1,24(sp)
    80004b94:	6942                	ld	s2,16(sp)
    80004b96:	69a2                	ld	s3,8(sp)
    80004b98:	6145                	addi	sp,sp,48
    80004b9a:	8082                	ret

0000000080004b9c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004b9c:	1101                	addi	sp,sp,-32
    80004b9e:	ec06                	sd	ra,24(sp)
    80004ba0:	e822                	sd	s0,16(sp)
    80004ba2:	e426                	sd	s1,8(sp)
    80004ba4:	e04a                	sd	s2,0(sp)
    80004ba6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004ba8:	007be517          	auipc	a0,0x7be
    80004bac:	1a850513          	addi	a0,a0,424 # 807c2d50 <log>
    80004bb0:	ffffc097          	auipc	ra,0xffffc
    80004bb4:	026080e7          	jalr	38(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004bb8:	007be497          	auipc	s1,0x7be
    80004bbc:	19848493          	addi	s1,s1,408 # 807c2d50 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004bc0:	4979                	li	s2,30
    80004bc2:	a039                	j	80004bd0 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004bc4:	85a6                	mv	a1,s1
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	ffffd097          	auipc	ra,0xffffd
    80004bcc:	684080e7          	jalr	1668(ra) # 8000224c <sleep>
    if(log.committing){
    80004bd0:	50dc                	lw	a5,36(s1)
    80004bd2:	fbed                	bnez	a5,80004bc4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004bd4:	509c                	lw	a5,32(s1)
    80004bd6:	0017871b          	addiw	a4,a5,1
    80004bda:	0007069b          	sext.w	a3,a4
    80004bde:	0027179b          	slliw	a5,a4,0x2
    80004be2:	9fb9                	addw	a5,a5,a4
    80004be4:	0017979b          	slliw	a5,a5,0x1
    80004be8:	54d8                	lw	a4,44(s1)
    80004bea:	9fb9                	addw	a5,a5,a4
    80004bec:	00f95963          	bge	s2,a5,80004bfe <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004bf0:	85a6                	mv	a1,s1
    80004bf2:	8526                	mv	a0,s1
    80004bf4:	ffffd097          	auipc	ra,0xffffd
    80004bf8:	658080e7          	jalr	1624(ra) # 8000224c <sleep>
    80004bfc:	bfd1                	j	80004bd0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004bfe:	007be517          	auipc	a0,0x7be
    80004c02:	15250513          	addi	a0,a0,338 # 807c2d50 <log>
    80004c06:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	082080e7          	jalr	130(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004c10:	60e2                	ld	ra,24(sp)
    80004c12:	6442                	ld	s0,16(sp)
    80004c14:	64a2                	ld	s1,8(sp)
    80004c16:	6902                	ld	s2,0(sp)
    80004c18:	6105                	addi	sp,sp,32
    80004c1a:	8082                	ret

0000000080004c1c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004c1c:	7139                	addi	sp,sp,-64
    80004c1e:	fc06                	sd	ra,56(sp)
    80004c20:	f822                	sd	s0,48(sp)
    80004c22:	f426                	sd	s1,40(sp)
    80004c24:	f04a                	sd	s2,32(sp)
    80004c26:	ec4e                	sd	s3,24(sp)
    80004c28:	e852                	sd	s4,16(sp)
    80004c2a:	e456                	sd	s5,8(sp)
    80004c2c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004c2e:	007be497          	auipc	s1,0x7be
    80004c32:	12248493          	addi	s1,s1,290 # 807c2d50 <log>
    80004c36:	8526                	mv	a0,s1
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	f9e080e7          	jalr	-98(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004c40:	509c                	lw	a5,32(s1)
    80004c42:	37fd                	addiw	a5,a5,-1
    80004c44:	0007891b          	sext.w	s2,a5
    80004c48:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004c4a:	50dc                	lw	a5,36(s1)
    80004c4c:	e7b9                	bnez	a5,80004c9a <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004c4e:	04091e63          	bnez	s2,80004caa <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004c52:	007be497          	auipc	s1,0x7be
    80004c56:	0fe48493          	addi	s1,s1,254 # 807c2d50 <log>
    80004c5a:	4785                	li	a5,1
    80004c5c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004c5e:	8526                	mv	a0,s1
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004c68:	54dc                	lw	a5,44(s1)
    80004c6a:	06f04763          	bgtz	a5,80004cd8 <end_op+0xbc>
    acquire(&log.lock);
    80004c6e:	007be497          	auipc	s1,0x7be
    80004c72:	0e248493          	addi	s1,s1,226 # 807c2d50 <log>
    80004c76:	8526                	mv	a0,s1
    80004c78:	ffffc097          	auipc	ra,0xffffc
    80004c7c:	f5e080e7          	jalr	-162(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004c80:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004c84:	8526                	mv	a0,s1
    80004c86:	ffffd097          	auipc	ra,0xffffd
    80004c8a:	62a080e7          	jalr	1578(ra) # 800022b0 <wakeup>
    release(&log.lock);
    80004c8e:	8526                	mv	a0,s1
    80004c90:	ffffc097          	auipc	ra,0xffffc
    80004c94:	ffa080e7          	jalr	-6(ra) # 80000c8a <release>
}
    80004c98:	a03d                	j	80004cc6 <end_op+0xaa>
    panic("log.committing");
    80004c9a:	00004517          	auipc	a0,0x4
    80004c9e:	99650513          	addi	a0,a0,-1642 # 80008630 <syscalls+0x200>
    80004ca2:	ffffc097          	auipc	ra,0xffffc
    80004ca6:	89c080e7          	jalr	-1892(ra) # 8000053e <panic>
    wakeup(&log);
    80004caa:	007be497          	auipc	s1,0x7be
    80004cae:	0a648493          	addi	s1,s1,166 # 807c2d50 <log>
    80004cb2:	8526                	mv	a0,s1
    80004cb4:	ffffd097          	auipc	ra,0xffffd
    80004cb8:	5fc080e7          	jalr	1532(ra) # 800022b0 <wakeup>
  release(&log.lock);
    80004cbc:	8526                	mv	a0,s1
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	fcc080e7          	jalr	-52(ra) # 80000c8a <release>
}
    80004cc6:	70e2                	ld	ra,56(sp)
    80004cc8:	7442                	ld	s0,48(sp)
    80004cca:	74a2                	ld	s1,40(sp)
    80004ccc:	7902                	ld	s2,32(sp)
    80004cce:	69e2                	ld	s3,24(sp)
    80004cd0:	6a42                	ld	s4,16(sp)
    80004cd2:	6aa2                	ld	s5,8(sp)
    80004cd4:	6121                	addi	sp,sp,64
    80004cd6:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004cd8:	007bea97          	auipc	s5,0x7be
    80004cdc:	0a8a8a93          	addi	s5,s5,168 # 807c2d80 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004ce0:	007bea17          	auipc	s4,0x7be
    80004ce4:	070a0a13          	addi	s4,s4,112 # 807c2d50 <log>
    80004ce8:	018a2583          	lw	a1,24(s4)
    80004cec:	012585bb          	addw	a1,a1,s2
    80004cf0:	2585                	addiw	a1,a1,1
    80004cf2:	028a2503          	lw	a0,40(s4)
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	cca080e7          	jalr	-822(ra) # 800039c0 <bread>
    80004cfe:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004d00:	000aa583          	lw	a1,0(s5)
    80004d04:	028a2503          	lw	a0,40(s4)
    80004d08:	fffff097          	auipc	ra,0xfffff
    80004d0c:	cb8080e7          	jalr	-840(ra) # 800039c0 <bread>
    80004d10:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004d12:	40000613          	li	a2,1024
    80004d16:	05850593          	addi	a1,a0,88
    80004d1a:	05848513          	addi	a0,s1,88
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	010080e7          	jalr	16(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004d26:	8526                	mv	a0,s1
    80004d28:	fffff097          	auipc	ra,0xfffff
    80004d2c:	d8a080e7          	jalr	-630(ra) # 80003ab2 <bwrite>
    brelse(from);
    80004d30:	854e                	mv	a0,s3
    80004d32:	fffff097          	auipc	ra,0xfffff
    80004d36:	dbe080e7          	jalr	-578(ra) # 80003af0 <brelse>
    brelse(to);
    80004d3a:	8526                	mv	a0,s1
    80004d3c:	fffff097          	auipc	ra,0xfffff
    80004d40:	db4080e7          	jalr	-588(ra) # 80003af0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d44:	2905                	addiw	s2,s2,1
    80004d46:	0a91                	addi	s5,s5,4
    80004d48:	02ca2783          	lw	a5,44(s4)
    80004d4c:	f8f94ee3          	blt	s2,a5,80004ce8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004d50:	00000097          	auipc	ra,0x0
    80004d54:	c6a080e7          	jalr	-918(ra) # 800049ba <write_head>
    install_trans(0); // Now install writes to home locations
    80004d58:	4501                	li	a0,0
    80004d5a:	00000097          	auipc	ra,0x0
    80004d5e:	cda080e7          	jalr	-806(ra) # 80004a34 <install_trans>
    log.lh.n = 0;
    80004d62:	007be797          	auipc	a5,0x7be
    80004d66:	0007ad23          	sw	zero,26(a5) # 807c2d7c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004d6a:	00000097          	auipc	ra,0x0
    80004d6e:	c50080e7          	jalr	-944(ra) # 800049ba <write_head>
    80004d72:	bdf5                	j	80004c6e <end_op+0x52>

0000000080004d74 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004d74:	1101                	addi	sp,sp,-32
    80004d76:	ec06                	sd	ra,24(sp)
    80004d78:	e822                	sd	s0,16(sp)
    80004d7a:	e426                	sd	s1,8(sp)
    80004d7c:	e04a                	sd	s2,0(sp)
    80004d7e:	1000                	addi	s0,sp,32
    80004d80:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004d82:	007be917          	auipc	s2,0x7be
    80004d86:	fce90913          	addi	s2,s2,-50 # 807c2d50 <log>
    80004d8a:	854a                	mv	a0,s2
    80004d8c:	ffffc097          	auipc	ra,0xffffc
    80004d90:	e4a080e7          	jalr	-438(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004d94:	02c92603          	lw	a2,44(s2)
    80004d98:	47f5                	li	a5,29
    80004d9a:	06c7c563          	blt	a5,a2,80004e04 <log_write+0x90>
    80004d9e:	007be797          	auipc	a5,0x7be
    80004da2:	fce7a783          	lw	a5,-50(a5) # 807c2d6c <log+0x1c>
    80004da6:	37fd                	addiw	a5,a5,-1
    80004da8:	04f65e63          	bge	a2,a5,80004e04 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004dac:	007be797          	auipc	a5,0x7be
    80004db0:	fc47a783          	lw	a5,-60(a5) # 807c2d70 <log+0x20>
    80004db4:	06f05063          	blez	a5,80004e14 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004db8:	4781                	li	a5,0
    80004dba:	06c05563          	blez	a2,80004e24 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004dbe:	44cc                	lw	a1,12(s1)
    80004dc0:	007be717          	auipc	a4,0x7be
    80004dc4:	fc070713          	addi	a4,a4,-64 # 807c2d80 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004dc8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004dca:	4314                	lw	a3,0(a4)
    80004dcc:	04b68c63          	beq	a3,a1,80004e24 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004dd0:	2785                	addiw	a5,a5,1
    80004dd2:	0711                	addi	a4,a4,4
    80004dd4:	fef61be3          	bne	a2,a5,80004dca <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004dd8:	0621                	addi	a2,a2,8
    80004dda:	060a                	slli	a2,a2,0x2
    80004ddc:	007be797          	auipc	a5,0x7be
    80004de0:	f7478793          	addi	a5,a5,-140 # 807c2d50 <log>
    80004de4:	963e                	add	a2,a2,a5
    80004de6:	44dc                	lw	a5,12(s1)
    80004de8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004dea:	8526                	mv	a0,s1
    80004dec:	fffff097          	auipc	ra,0xfffff
    80004df0:	da2080e7          	jalr	-606(ra) # 80003b8e <bpin>
    log.lh.n++;
    80004df4:	007be717          	auipc	a4,0x7be
    80004df8:	f5c70713          	addi	a4,a4,-164 # 807c2d50 <log>
    80004dfc:	575c                	lw	a5,44(a4)
    80004dfe:	2785                	addiw	a5,a5,1
    80004e00:	d75c                	sw	a5,44(a4)
    80004e02:	a835                	j	80004e3e <log_write+0xca>
    panic("too big a transaction");
    80004e04:	00004517          	auipc	a0,0x4
    80004e08:	83c50513          	addi	a0,a0,-1988 # 80008640 <syscalls+0x210>
    80004e0c:	ffffb097          	auipc	ra,0xffffb
    80004e10:	732080e7          	jalr	1842(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004e14:	00004517          	auipc	a0,0x4
    80004e18:	84450513          	addi	a0,a0,-1980 # 80008658 <syscalls+0x228>
    80004e1c:	ffffb097          	auipc	ra,0xffffb
    80004e20:	722080e7          	jalr	1826(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004e24:	00878713          	addi	a4,a5,8
    80004e28:	00271693          	slli	a3,a4,0x2
    80004e2c:	007be717          	auipc	a4,0x7be
    80004e30:	f2470713          	addi	a4,a4,-220 # 807c2d50 <log>
    80004e34:	9736                	add	a4,a4,a3
    80004e36:	44d4                	lw	a3,12(s1)
    80004e38:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004e3a:	faf608e3          	beq	a2,a5,80004dea <log_write+0x76>
  }
  release(&log.lock);
    80004e3e:	007be517          	auipc	a0,0x7be
    80004e42:	f1250513          	addi	a0,a0,-238 # 807c2d50 <log>
    80004e46:	ffffc097          	auipc	ra,0xffffc
    80004e4a:	e44080e7          	jalr	-444(ra) # 80000c8a <release>
}
    80004e4e:	60e2                	ld	ra,24(sp)
    80004e50:	6442                	ld	s0,16(sp)
    80004e52:	64a2                	ld	s1,8(sp)
    80004e54:	6902                	ld	s2,0(sp)
    80004e56:	6105                	addi	sp,sp,32
    80004e58:	8082                	ret

0000000080004e5a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004e5a:	1101                	addi	sp,sp,-32
    80004e5c:	ec06                	sd	ra,24(sp)
    80004e5e:	e822                	sd	s0,16(sp)
    80004e60:	e426                	sd	s1,8(sp)
    80004e62:	e04a                	sd	s2,0(sp)
    80004e64:	1000                	addi	s0,sp,32
    80004e66:	84aa                	mv	s1,a0
    80004e68:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004e6a:	00004597          	auipc	a1,0x4
    80004e6e:	80e58593          	addi	a1,a1,-2034 # 80008678 <syscalls+0x248>
    80004e72:	0521                	addi	a0,a0,8
    80004e74:	ffffc097          	auipc	ra,0xffffc
    80004e78:	cd2080e7          	jalr	-814(ra) # 80000b46 <initlock>
  lk->name = name;
    80004e7c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004e80:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004e84:	0204a423          	sw	zero,40(s1)
}
    80004e88:	60e2                	ld	ra,24(sp)
    80004e8a:	6442                	ld	s0,16(sp)
    80004e8c:	64a2                	ld	s1,8(sp)
    80004e8e:	6902                	ld	s2,0(sp)
    80004e90:	6105                	addi	sp,sp,32
    80004e92:	8082                	ret

0000000080004e94 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004e94:	1101                	addi	sp,sp,-32
    80004e96:	ec06                	sd	ra,24(sp)
    80004e98:	e822                	sd	s0,16(sp)
    80004e9a:	e426                	sd	s1,8(sp)
    80004e9c:	e04a                	sd	s2,0(sp)
    80004e9e:	1000                	addi	s0,sp,32
    80004ea0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ea2:	00850913          	addi	s2,a0,8
    80004ea6:	854a                	mv	a0,s2
    80004ea8:	ffffc097          	auipc	ra,0xffffc
    80004eac:	d2e080e7          	jalr	-722(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004eb0:	409c                	lw	a5,0(s1)
    80004eb2:	cb89                	beqz	a5,80004ec4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004eb4:	85ca                	mv	a1,s2
    80004eb6:	8526                	mv	a0,s1
    80004eb8:	ffffd097          	auipc	ra,0xffffd
    80004ebc:	394080e7          	jalr	916(ra) # 8000224c <sleep>
  while (lk->locked) {
    80004ec0:	409c                	lw	a5,0(s1)
    80004ec2:	fbed                	bnez	a5,80004eb4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004ec4:	4785                	li	a5,1
    80004ec6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004ec8:	ffffd097          	auipc	ra,0xffffd
    80004ecc:	af4080e7          	jalr	-1292(ra) # 800019bc <myproc>
    80004ed0:	591c                	lw	a5,48(a0)
    80004ed2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004ed4:	854a                	mv	a0,s2
    80004ed6:	ffffc097          	auipc	ra,0xffffc
    80004eda:	db4080e7          	jalr	-588(ra) # 80000c8a <release>
}
    80004ede:	60e2                	ld	ra,24(sp)
    80004ee0:	6442                	ld	s0,16(sp)
    80004ee2:	64a2                	ld	s1,8(sp)
    80004ee4:	6902                	ld	s2,0(sp)
    80004ee6:	6105                	addi	sp,sp,32
    80004ee8:	8082                	ret

0000000080004eea <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004eea:	1101                	addi	sp,sp,-32
    80004eec:	ec06                	sd	ra,24(sp)
    80004eee:	e822                	sd	s0,16(sp)
    80004ef0:	e426                	sd	s1,8(sp)
    80004ef2:	e04a                	sd	s2,0(sp)
    80004ef4:	1000                	addi	s0,sp,32
    80004ef6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ef8:	00850913          	addi	s2,a0,8
    80004efc:	854a                	mv	a0,s2
    80004efe:	ffffc097          	auipc	ra,0xffffc
    80004f02:	cd8080e7          	jalr	-808(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004f06:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f0a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004f0e:	8526                	mv	a0,s1
    80004f10:	ffffd097          	auipc	ra,0xffffd
    80004f14:	3a0080e7          	jalr	928(ra) # 800022b0 <wakeup>
  release(&lk->lk);
    80004f18:	854a                	mv	a0,s2
    80004f1a:	ffffc097          	auipc	ra,0xffffc
    80004f1e:	d70080e7          	jalr	-656(ra) # 80000c8a <release>
}
    80004f22:	60e2                	ld	ra,24(sp)
    80004f24:	6442                	ld	s0,16(sp)
    80004f26:	64a2                	ld	s1,8(sp)
    80004f28:	6902                	ld	s2,0(sp)
    80004f2a:	6105                	addi	sp,sp,32
    80004f2c:	8082                	ret

0000000080004f2e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004f2e:	7179                	addi	sp,sp,-48
    80004f30:	f406                	sd	ra,40(sp)
    80004f32:	f022                	sd	s0,32(sp)
    80004f34:	ec26                	sd	s1,24(sp)
    80004f36:	e84a                	sd	s2,16(sp)
    80004f38:	e44e                	sd	s3,8(sp)
    80004f3a:	1800                	addi	s0,sp,48
    80004f3c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004f3e:	00850913          	addi	s2,a0,8
    80004f42:	854a                	mv	a0,s2
    80004f44:	ffffc097          	auipc	ra,0xffffc
    80004f48:	c92080e7          	jalr	-878(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004f4c:	409c                	lw	a5,0(s1)
    80004f4e:	ef99                	bnez	a5,80004f6c <holdingsleep+0x3e>
    80004f50:	4481                	li	s1,0
  release(&lk->lk);
    80004f52:	854a                	mv	a0,s2
    80004f54:	ffffc097          	auipc	ra,0xffffc
    80004f58:	d36080e7          	jalr	-714(ra) # 80000c8a <release>
  return r;
}
    80004f5c:	8526                	mv	a0,s1
    80004f5e:	70a2                	ld	ra,40(sp)
    80004f60:	7402                	ld	s0,32(sp)
    80004f62:	64e2                	ld	s1,24(sp)
    80004f64:	6942                	ld	s2,16(sp)
    80004f66:	69a2                	ld	s3,8(sp)
    80004f68:	6145                	addi	sp,sp,48
    80004f6a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004f6c:	0284a983          	lw	s3,40(s1)
    80004f70:	ffffd097          	auipc	ra,0xffffd
    80004f74:	a4c080e7          	jalr	-1460(ra) # 800019bc <myproc>
    80004f78:	5904                	lw	s1,48(a0)
    80004f7a:	413484b3          	sub	s1,s1,s3
    80004f7e:	0014b493          	seqz	s1,s1
    80004f82:	bfc1                	j	80004f52 <holdingsleep+0x24>

0000000080004f84 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004f84:	1141                	addi	sp,sp,-16
    80004f86:	e406                	sd	ra,8(sp)
    80004f88:	e022                	sd	s0,0(sp)
    80004f8a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004f8c:	00003597          	auipc	a1,0x3
    80004f90:	6fc58593          	addi	a1,a1,1788 # 80008688 <syscalls+0x258>
    80004f94:	007be517          	auipc	a0,0x7be
    80004f98:	f0450513          	addi	a0,a0,-252 # 807c2e98 <ftable>
    80004f9c:	ffffc097          	auipc	ra,0xffffc
    80004fa0:	baa080e7          	jalr	-1110(ra) # 80000b46 <initlock>
}
    80004fa4:	60a2                	ld	ra,8(sp)
    80004fa6:	6402                	ld	s0,0(sp)
    80004fa8:	0141                	addi	sp,sp,16
    80004faa:	8082                	ret

0000000080004fac <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004fac:	1101                	addi	sp,sp,-32
    80004fae:	ec06                	sd	ra,24(sp)
    80004fb0:	e822                	sd	s0,16(sp)
    80004fb2:	e426                	sd	s1,8(sp)
    80004fb4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004fb6:	007be517          	auipc	a0,0x7be
    80004fba:	ee250513          	addi	a0,a0,-286 # 807c2e98 <ftable>
    80004fbe:	ffffc097          	auipc	ra,0xffffc
    80004fc2:	c18080e7          	jalr	-1000(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004fc6:	007be497          	auipc	s1,0x7be
    80004fca:	eea48493          	addi	s1,s1,-278 # 807c2eb0 <ftable+0x18>
    80004fce:	007bf717          	auipc	a4,0x7bf
    80004fd2:	e8270713          	addi	a4,a4,-382 # 807c3e50 <disk>
    if(f->ref == 0){
    80004fd6:	40dc                	lw	a5,4(s1)
    80004fd8:	cf99                	beqz	a5,80004ff6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004fda:	02848493          	addi	s1,s1,40
    80004fde:	fee49ce3          	bne	s1,a4,80004fd6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004fe2:	007be517          	auipc	a0,0x7be
    80004fe6:	eb650513          	addi	a0,a0,-330 # 807c2e98 <ftable>
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	ca0080e7          	jalr	-864(ra) # 80000c8a <release>
  return 0;
    80004ff2:	4481                	li	s1,0
    80004ff4:	a819                	j	8000500a <filealloc+0x5e>
      f->ref = 1;
    80004ff6:	4785                	li	a5,1
    80004ff8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004ffa:	007be517          	auipc	a0,0x7be
    80004ffe:	e9e50513          	addi	a0,a0,-354 # 807c2e98 <ftable>
    80005002:	ffffc097          	auipc	ra,0xffffc
    80005006:	c88080e7          	jalr	-888(ra) # 80000c8a <release>
}
    8000500a:	8526                	mv	a0,s1
    8000500c:	60e2                	ld	ra,24(sp)
    8000500e:	6442                	ld	s0,16(sp)
    80005010:	64a2                	ld	s1,8(sp)
    80005012:	6105                	addi	sp,sp,32
    80005014:	8082                	ret

0000000080005016 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005016:	1101                	addi	sp,sp,-32
    80005018:	ec06                	sd	ra,24(sp)
    8000501a:	e822                	sd	s0,16(sp)
    8000501c:	e426                	sd	s1,8(sp)
    8000501e:	1000                	addi	s0,sp,32
    80005020:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005022:	007be517          	auipc	a0,0x7be
    80005026:	e7650513          	addi	a0,a0,-394 # 807c2e98 <ftable>
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	bac080e7          	jalr	-1108(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80005032:	40dc                	lw	a5,4(s1)
    80005034:	02f05263          	blez	a5,80005058 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005038:	2785                	addiw	a5,a5,1
    8000503a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000503c:	007be517          	auipc	a0,0x7be
    80005040:	e5c50513          	addi	a0,a0,-420 # 807c2e98 <ftable>
    80005044:	ffffc097          	auipc	ra,0xffffc
    80005048:	c46080e7          	jalr	-954(ra) # 80000c8a <release>
  return f;
}
    8000504c:	8526                	mv	a0,s1
    8000504e:	60e2                	ld	ra,24(sp)
    80005050:	6442                	ld	s0,16(sp)
    80005052:	64a2                	ld	s1,8(sp)
    80005054:	6105                	addi	sp,sp,32
    80005056:	8082                	ret
    panic("filedup");
    80005058:	00003517          	auipc	a0,0x3
    8000505c:	63850513          	addi	a0,a0,1592 # 80008690 <syscalls+0x260>
    80005060:	ffffb097          	auipc	ra,0xffffb
    80005064:	4de080e7          	jalr	1246(ra) # 8000053e <panic>

0000000080005068 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005068:	7139                	addi	sp,sp,-64
    8000506a:	fc06                	sd	ra,56(sp)
    8000506c:	f822                	sd	s0,48(sp)
    8000506e:	f426                	sd	s1,40(sp)
    80005070:	f04a                	sd	s2,32(sp)
    80005072:	ec4e                	sd	s3,24(sp)
    80005074:	e852                	sd	s4,16(sp)
    80005076:	e456                	sd	s5,8(sp)
    80005078:	0080                	addi	s0,sp,64
    8000507a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000507c:	007be517          	auipc	a0,0x7be
    80005080:	e1c50513          	addi	a0,a0,-484 # 807c2e98 <ftable>
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	b52080e7          	jalr	-1198(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000508c:	40dc                	lw	a5,4(s1)
    8000508e:	06f05163          	blez	a5,800050f0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005092:	37fd                	addiw	a5,a5,-1
    80005094:	0007871b          	sext.w	a4,a5
    80005098:	c0dc                	sw	a5,4(s1)
    8000509a:	06e04363          	bgtz	a4,80005100 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000509e:	0004a903          	lw	s2,0(s1)
    800050a2:	0094ca83          	lbu	s5,9(s1)
    800050a6:	0104ba03          	ld	s4,16(s1)
    800050aa:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800050ae:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800050b2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800050b6:	007be517          	auipc	a0,0x7be
    800050ba:	de250513          	addi	a0,a0,-542 # 807c2e98 <ftable>
    800050be:	ffffc097          	auipc	ra,0xffffc
    800050c2:	bcc080e7          	jalr	-1076(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800050c6:	4785                	li	a5,1
    800050c8:	04f90d63          	beq	s2,a5,80005122 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800050cc:	3979                	addiw	s2,s2,-2
    800050ce:	4785                	li	a5,1
    800050d0:	0527e063          	bltu	a5,s2,80005110 <fileclose+0xa8>
    begin_op();
    800050d4:	00000097          	auipc	ra,0x0
    800050d8:	ac8080e7          	jalr	-1336(ra) # 80004b9c <begin_op>
    iput(ff.ip);
    800050dc:	854e                	mv	a0,s3
    800050de:	fffff097          	auipc	ra,0xfffff
    800050e2:	2b6080e7          	jalr	694(ra) # 80004394 <iput>
    end_op();
    800050e6:	00000097          	auipc	ra,0x0
    800050ea:	b36080e7          	jalr	-1226(ra) # 80004c1c <end_op>
    800050ee:	a00d                	j	80005110 <fileclose+0xa8>
    panic("fileclose");
    800050f0:	00003517          	auipc	a0,0x3
    800050f4:	5a850513          	addi	a0,a0,1448 # 80008698 <syscalls+0x268>
    800050f8:	ffffb097          	auipc	ra,0xffffb
    800050fc:	446080e7          	jalr	1094(ra) # 8000053e <panic>
    release(&ftable.lock);
    80005100:	007be517          	auipc	a0,0x7be
    80005104:	d9850513          	addi	a0,a0,-616 # 807c2e98 <ftable>
    80005108:	ffffc097          	auipc	ra,0xffffc
    8000510c:	b82080e7          	jalr	-1150(ra) # 80000c8a <release>
  }
}
    80005110:	70e2                	ld	ra,56(sp)
    80005112:	7442                	ld	s0,48(sp)
    80005114:	74a2                	ld	s1,40(sp)
    80005116:	7902                	ld	s2,32(sp)
    80005118:	69e2                	ld	s3,24(sp)
    8000511a:	6a42                	ld	s4,16(sp)
    8000511c:	6aa2                	ld	s5,8(sp)
    8000511e:	6121                	addi	sp,sp,64
    80005120:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005122:	85d6                	mv	a1,s5
    80005124:	8552                	mv	a0,s4
    80005126:	00000097          	auipc	ra,0x0
    8000512a:	34c080e7          	jalr	844(ra) # 80005472 <pipeclose>
    8000512e:	b7cd                	j	80005110 <fileclose+0xa8>

0000000080005130 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005130:	715d                	addi	sp,sp,-80
    80005132:	e486                	sd	ra,72(sp)
    80005134:	e0a2                	sd	s0,64(sp)
    80005136:	fc26                	sd	s1,56(sp)
    80005138:	f84a                	sd	s2,48(sp)
    8000513a:	f44e                	sd	s3,40(sp)
    8000513c:	0880                	addi	s0,sp,80
    8000513e:	84aa                	mv	s1,a0
    80005140:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005142:	ffffd097          	auipc	ra,0xffffd
    80005146:	87a080e7          	jalr	-1926(ra) # 800019bc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000514a:	409c                	lw	a5,0(s1)
    8000514c:	37f9                	addiw	a5,a5,-2
    8000514e:	4705                	li	a4,1
    80005150:	04f76763          	bltu	a4,a5,8000519e <filestat+0x6e>
    80005154:	892a                	mv	s2,a0
    ilock(f->ip);
    80005156:	6c88                	ld	a0,24(s1)
    80005158:	fffff097          	auipc	ra,0xfffff
    8000515c:	082080e7          	jalr	130(ra) # 800041da <ilock>
    stati(f->ip, &st);
    80005160:	fb840593          	addi	a1,s0,-72
    80005164:	6c88                	ld	a0,24(s1)
    80005166:	fffff097          	auipc	ra,0xfffff
    8000516a:	2fe080e7          	jalr	766(ra) # 80004464 <stati>
    iunlock(f->ip);
    8000516e:	6c88                	ld	a0,24(s1)
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	12c080e7          	jalr	300(ra) # 8000429c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005178:	46e1                	li	a3,24
    8000517a:	fb840613          	addi	a2,s0,-72
    8000517e:	85ce                	mv	a1,s3
    80005180:	05093503          	ld	a0,80(s2)
    80005184:	ffffc097          	auipc	ra,0xffffc
    80005188:	4f4080e7          	jalr	1268(ra) # 80001678 <copyout>
    8000518c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005190:	60a6                	ld	ra,72(sp)
    80005192:	6406                	ld	s0,64(sp)
    80005194:	74e2                	ld	s1,56(sp)
    80005196:	7942                	ld	s2,48(sp)
    80005198:	79a2                	ld	s3,40(sp)
    8000519a:	6161                	addi	sp,sp,80
    8000519c:	8082                	ret
  return -1;
    8000519e:	557d                	li	a0,-1
    800051a0:	bfc5                	j	80005190 <filestat+0x60>

00000000800051a2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800051a2:	7179                	addi	sp,sp,-48
    800051a4:	f406                	sd	ra,40(sp)
    800051a6:	f022                	sd	s0,32(sp)
    800051a8:	ec26                	sd	s1,24(sp)
    800051aa:	e84a                	sd	s2,16(sp)
    800051ac:	e44e                	sd	s3,8(sp)
    800051ae:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800051b0:	00854783          	lbu	a5,8(a0)
    800051b4:	c3d5                	beqz	a5,80005258 <fileread+0xb6>
    800051b6:	84aa                	mv	s1,a0
    800051b8:	89ae                	mv	s3,a1
    800051ba:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800051bc:	411c                	lw	a5,0(a0)
    800051be:	4705                	li	a4,1
    800051c0:	04e78963          	beq	a5,a4,80005212 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800051c4:	470d                	li	a4,3
    800051c6:	04e78d63          	beq	a5,a4,80005220 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800051ca:	4709                	li	a4,2
    800051cc:	06e79e63          	bne	a5,a4,80005248 <fileread+0xa6>
    ilock(f->ip);
    800051d0:	6d08                	ld	a0,24(a0)
    800051d2:	fffff097          	auipc	ra,0xfffff
    800051d6:	008080e7          	jalr	8(ra) # 800041da <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800051da:	874a                	mv	a4,s2
    800051dc:	5094                	lw	a3,32(s1)
    800051de:	864e                	mv	a2,s3
    800051e0:	4585                	li	a1,1
    800051e2:	6c88                	ld	a0,24(s1)
    800051e4:	fffff097          	auipc	ra,0xfffff
    800051e8:	2aa080e7          	jalr	682(ra) # 8000448e <readi>
    800051ec:	892a                	mv	s2,a0
    800051ee:	00a05563          	blez	a0,800051f8 <fileread+0x56>
      f->off += r;
    800051f2:	509c                	lw	a5,32(s1)
    800051f4:	9fa9                	addw	a5,a5,a0
    800051f6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800051f8:	6c88                	ld	a0,24(s1)
    800051fa:	fffff097          	auipc	ra,0xfffff
    800051fe:	0a2080e7          	jalr	162(ra) # 8000429c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005202:	854a                	mv	a0,s2
    80005204:	70a2                	ld	ra,40(sp)
    80005206:	7402                	ld	s0,32(sp)
    80005208:	64e2                	ld	s1,24(sp)
    8000520a:	6942                	ld	s2,16(sp)
    8000520c:	69a2                	ld	s3,8(sp)
    8000520e:	6145                	addi	sp,sp,48
    80005210:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005212:	6908                	ld	a0,16(a0)
    80005214:	00000097          	auipc	ra,0x0
    80005218:	3c6080e7          	jalr	966(ra) # 800055da <piperead>
    8000521c:	892a                	mv	s2,a0
    8000521e:	b7d5                	j	80005202 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005220:	02451783          	lh	a5,36(a0)
    80005224:	03079693          	slli	a3,a5,0x30
    80005228:	92c1                	srli	a3,a3,0x30
    8000522a:	4725                	li	a4,9
    8000522c:	02d76863          	bltu	a4,a3,8000525c <fileread+0xba>
    80005230:	0792                	slli	a5,a5,0x4
    80005232:	007be717          	auipc	a4,0x7be
    80005236:	bc670713          	addi	a4,a4,-1082 # 807c2df8 <devsw>
    8000523a:	97ba                	add	a5,a5,a4
    8000523c:	639c                	ld	a5,0(a5)
    8000523e:	c38d                	beqz	a5,80005260 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005240:	4505                	li	a0,1
    80005242:	9782                	jalr	a5
    80005244:	892a                	mv	s2,a0
    80005246:	bf75                	j	80005202 <fileread+0x60>
    panic("fileread");
    80005248:	00003517          	auipc	a0,0x3
    8000524c:	46050513          	addi	a0,a0,1120 # 800086a8 <syscalls+0x278>
    80005250:	ffffb097          	auipc	ra,0xffffb
    80005254:	2ee080e7          	jalr	750(ra) # 8000053e <panic>
    return -1;
    80005258:	597d                	li	s2,-1
    8000525a:	b765                	j	80005202 <fileread+0x60>
      return -1;
    8000525c:	597d                	li	s2,-1
    8000525e:	b755                	j	80005202 <fileread+0x60>
    80005260:	597d                	li	s2,-1
    80005262:	b745                	j	80005202 <fileread+0x60>

0000000080005264 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005264:	715d                	addi	sp,sp,-80
    80005266:	e486                	sd	ra,72(sp)
    80005268:	e0a2                	sd	s0,64(sp)
    8000526a:	fc26                	sd	s1,56(sp)
    8000526c:	f84a                	sd	s2,48(sp)
    8000526e:	f44e                	sd	s3,40(sp)
    80005270:	f052                	sd	s4,32(sp)
    80005272:	ec56                	sd	s5,24(sp)
    80005274:	e85a                	sd	s6,16(sp)
    80005276:	e45e                	sd	s7,8(sp)
    80005278:	e062                	sd	s8,0(sp)
    8000527a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000527c:	00954783          	lbu	a5,9(a0)
    80005280:	10078663          	beqz	a5,8000538c <filewrite+0x128>
    80005284:	892a                	mv	s2,a0
    80005286:	8aae                	mv	s5,a1
    80005288:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000528a:	411c                	lw	a5,0(a0)
    8000528c:	4705                	li	a4,1
    8000528e:	02e78263          	beq	a5,a4,800052b2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005292:	470d                	li	a4,3
    80005294:	02e78663          	beq	a5,a4,800052c0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005298:	4709                	li	a4,2
    8000529a:	0ee79163          	bne	a5,a4,8000537c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000529e:	0ac05d63          	blez	a2,80005358 <filewrite+0xf4>
    int i = 0;
    800052a2:	4981                	li	s3,0
    800052a4:	6b05                	lui	s6,0x1
    800052a6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800052aa:	6b85                	lui	s7,0x1
    800052ac:	c00b8b9b          	addiw	s7,s7,-1024
    800052b0:	a861                	j	80005348 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800052b2:	6908                	ld	a0,16(a0)
    800052b4:	00000097          	auipc	ra,0x0
    800052b8:	22e080e7          	jalr	558(ra) # 800054e2 <pipewrite>
    800052bc:	8a2a                	mv	s4,a0
    800052be:	a045                	j	8000535e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800052c0:	02451783          	lh	a5,36(a0)
    800052c4:	03079693          	slli	a3,a5,0x30
    800052c8:	92c1                	srli	a3,a3,0x30
    800052ca:	4725                	li	a4,9
    800052cc:	0cd76263          	bltu	a4,a3,80005390 <filewrite+0x12c>
    800052d0:	0792                	slli	a5,a5,0x4
    800052d2:	007be717          	auipc	a4,0x7be
    800052d6:	b2670713          	addi	a4,a4,-1242 # 807c2df8 <devsw>
    800052da:	97ba                	add	a5,a5,a4
    800052dc:	679c                	ld	a5,8(a5)
    800052de:	cbdd                	beqz	a5,80005394 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800052e0:	4505                	li	a0,1
    800052e2:	9782                	jalr	a5
    800052e4:	8a2a                	mv	s4,a0
    800052e6:	a8a5                	j	8000535e <filewrite+0xfa>
    800052e8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800052ec:	00000097          	auipc	ra,0x0
    800052f0:	8b0080e7          	jalr	-1872(ra) # 80004b9c <begin_op>
      ilock(f->ip);
    800052f4:	01893503          	ld	a0,24(s2)
    800052f8:	fffff097          	auipc	ra,0xfffff
    800052fc:	ee2080e7          	jalr	-286(ra) # 800041da <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005300:	8762                	mv	a4,s8
    80005302:	02092683          	lw	a3,32(s2)
    80005306:	01598633          	add	a2,s3,s5
    8000530a:	4585                	li	a1,1
    8000530c:	01893503          	ld	a0,24(s2)
    80005310:	fffff097          	auipc	ra,0xfffff
    80005314:	276080e7          	jalr	630(ra) # 80004586 <writei>
    80005318:	84aa                	mv	s1,a0
    8000531a:	00a05763          	blez	a0,80005328 <filewrite+0xc4>
        f->off += r;
    8000531e:	02092783          	lw	a5,32(s2)
    80005322:	9fa9                	addw	a5,a5,a0
    80005324:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005328:	01893503          	ld	a0,24(s2)
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	f70080e7          	jalr	-144(ra) # 8000429c <iunlock>
      end_op();
    80005334:	00000097          	auipc	ra,0x0
    80005338:	8e8080e7          	jalr	-1816(ra) # 80004c1c <end_op>

      if(r != n1){
    8000533c:	009c1f63          	bne	s8,s1,8000535a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005340:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005344:	0149db63          	bge	s3,s4,8000535a <filewrite+0xf6>
      int n1 = n - i;
    80005348:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000534c:	84be                	mv	s1,a5
    8000534e:	2781                	sext.w	a5,a5
    80005350:	f8fb5ce3          	bge	s6,a5,800052e8 <filewrite+0x84>
    80005354:	84de                	mv	s1,s7
    80005356:	bf49                	j	800052e8 <filewrite+0x84>
    int i = 0;
    80005358:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000535a:	013a1f63          	bne	s4,s3,80005378 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000535e:	8552                	mv	a0,s4
    80005360:	60a6                	ld	ra,72(sp)
    80005362:	6406                	ld	s0,64(sp)
    80005364:	74e2                	ld	s1,56(sp)
    80005366:	7942                	ld	s2,48(sp)
    80005368:	79a2                	ld	s3,40(sp)
    8000536a:	7a02                	ld	s4,32(sp)
    8000536c:	6ae2                	ld	s5,24(sp)
    8000536e:	6b42                	ld	s6,16(sp)
    80005370:	6ba2                	ld	s7,8(sp)
    80005372:	6c02                	ld	s8,0(sp)
    80005374:	6161                	addi	sp,sp,80
    80005376:	8082                	ret
    ret = (i == n ? n : -1);
    80005378:	5a7d                	li	s4,-1
    8000537a:	b7d5                	j	8000535e <filewrite+0xfa>
    panic("filewrite");
    8000537c:	00003517          	auipc	a0,0x3
    80005380:	33c50513          	addi	a0,a0,828 # 800086b8 <syscalls+0x288>
    80005384:	ffffb097          	auipc	ra,0xffffb
    80005388:	1ba080e7          	jalr	442(ra) # 8000053e <panic>
    return -1;
    8000538c:	5a7d                	li	s4,-1
    8000538e:	bfc1                	j	8000535e <filewrite+0xfa>
      return -1;
    80005390:	5a7d                	li	s4,-1
    80005392:	b7f1                	j	8000535e <filewrite+0xfa>
    80005394:	5a7d                	li	s4,-1
    80005396:	b7e1                	j	8000535e <filewrite+0xfa>

0000000080005398 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005398:	7179                	addi	sp,sp,-48
    8000539a:	f406                	sd	ra,40(sp)
    8000539c:	f022                	sd	s0,32(sp)
    8000539e:	ec26                	sd	s1,24(sp)
    800053a0:	e84a                	sd	s2,16(sp)
    800053a2:	e44e                	sd	s3,8(sp)
    800053a4:	e052                	sd	s4,0(sp)
    800053a6:	1800                	addi	s0,sp,48
    800053a8:	84aa                	mv	s1,a0
    800053aa:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800053ac:	0005b023          	sd	zero,0(a1)
    800053b0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800053b4:	00000097          	auipc	ra,0x0
    800053b8:	bf8080e7          	jalr	-1032(ra) # 80004fac <filealloc>
    800053bc:	e088                	sd	a0,0(s1)
    800053be:	c551                	beqz	a0,8000544a <pipealloc+0xb2>
    800053c0:	00000097          	auipc	ra,0x0
    800053c4:	bec080e7          	jalr	-1044(ra) # 80004fac <filealloc>
    800053c8:	00aa3023          	sd	a0,0(s4)
    800053cc:	c92d                	beqz	a0,8000543e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800053ce:	ffffb097          	auipc	ra,0xffffb
    800053d2:	718080e7          	jalr	1816(ra) # 80000ae6 <kalloc>
    800053d6:	892a                	mv	s2,a0
    800053d8:	c125                	beqz	a0,80005438 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800053da:	4985                	li	s3,1
    800053dc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800053e0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800053e4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800053e8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800053ec:	00003597          	auipc	a1,0x3
    800053f0:	2dc58593          	addi	a1,a1,732 # 800086c8 <syscalls+0x298>
    800053f4:	ffffb097          	auipc	ra,0xffffb
    800053f8:	752080e7          	jalr	1874(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800053fc:	609c                	ld	a5,0(s1)
    800053fe:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005402:	609c                	ld	a5,0(s1)
    80005404:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005408:	609c                	ld	a5,0(s1)
    8000540a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000540e:	609c                	ld	a5,0(s1)
    80005410:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005414:	000a3783          	ld	a5,0(s4)
    80005418:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000541c:	000a3783          	ld	a5,0(s4)
    80005420:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005424:	000a3783          	ld	a5,0(s4)
    80005428:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000542c:	000a3783          	ld	a5,0(s4)
    80005430:	0127b823          	sd	s2,16(a5)
  return 0;
    80005434:	4501                	li	a0,0
    80005436:	a025                	j	8000545e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005438:	6088                	ld	a0,0(s1)
    8000543a:	e501                	bnez	a0,80005442 <pipealloc+0xaa>
    8000543c:	a039                	j	8000544a <pipealloc+0xb2>
    8000543e:	6088                	ld	a0,0(s1)
    80005440:	c51d                	beqz	a0,8000546e <pipealloc+0xd6>
    fileclose(*f0);
    80005442:	00000097          	auipc	ra,0x0
    80005446:	c26080e7          	jalr	-986(ra) # 80005068 <fileclose>
  if(*f1)
    8000544a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000544e:	557d                	li	a0,-1
  if(*f1)
    80005450:	c799                	beqz	a5,8000545e <pipealloc+0xc6>
    fileclose(*f1);
    80005452:	853e                	mv	a0,a5
    80005454:	00000097          	auipc	ra,0x0
    80005458:	c14080e7          	jalr	-1004(ra) # 80005068 <fileclose>
  return -1;
    8000545c:	557d                	li	a0,-1
}
    8000545e:	70a2                	ld	ra,40(sp)
    80005460:	7402                	ld	s0,32(sp)
    80005462:	64e2                	ld	s1,24(sp)
    80005464:	6942                	ld	s2,16(sp)
    80005466:	69a2                	ld	s3,8(sp)
    80005468:	6a02                	ld	s4,0(sp)
    8000546a:	6145                	addi	sp,sp,48
    8000546c:	8082                	ret
  return -1;
    8000546e:	557d                	li	a0,-1
    80005470:	b7fd                	j	8000545e <pipealloc+0xc6>

0000000080005472 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005472:	1101                	addi	sp,sp,-32
    80005474:	ec06                	sd	ra,24(sp)
    80005476:	e822                	sd	s0,16(sp)
    80005478:	e426                	sd	s1,8(sp)
    8000547a:	e04a                	sd	s2,0(sp)
    8000547c:	1000                	addi	s0,sp,32
    8000547e:	84aa                	mv	s1,a0
    80005480:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005482:	ffffb097          	auipc	ra,0xffffb
    80005486:	754080e7          	jalr	1876(ra) # 80000bd6 <acquire>
  if(writable){
    8000548a:	02090d63          	beqz	s2,800054c4 <pipeclose+0x52>
    pi->writeopen = 0;
    8000548e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005492:	21848513          	addi	a0,s1,536
    80005496:	ffffd097          	auipc	ra,0xffffd
    8000549a:	e1a080e7          	jalr	-486(ra) # 800022b0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000549e:	2204b783          	ld	a5,544(s1)
    800054a2:	eb95                	bnez	a5,800054d6 <pipeclose+0x64>
    release(&pi->lock);
    800054a4:	8526                	mv	a0,s1
    800054a6:	ffffb097          	auipc	ra,0xffffb
    800054aa:	7e4080e7          	jalr	2020(ra) # 80000c8a <release>
    kfree((char*)pi);
    800054ae:	8526                	mv	a0,s1
    800054b0:	ffffb097          	auipc	ra,0xffffb
    800054b4:	53a080e7          	jalr	1338(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    800054b8:	60e2                	ld	ra,24(sp)
    800054ba:	6442                	ld	s0,16(sp)
    800054bc:	64a2                	ld	s1,8(sp)
    800054be:	6902                	ld	s2,0(sp)
    800054c0:	6105                	addi	sp,sp,32
    800054c2:	8082                	ret
    pi->readopen = 0;
    800054c4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800054c8:	21c48513          	addi	a0,s1,540
    800054cc:	ffffd097          	auipc	ra,0xffffd
    800054d0:	de4080e7          	jalr	-540(ra) # 800022b0 <wakeup>
    800054d4:	b7e9                	j	8000549e <pipeclose+0x2c>
    release(&pi->lock);
    800054d6:	8526                	mv	a0,s1
    800054d8:	ffffb097          	auipc	ra,0xffffb
    800054dc:	7b2080e7          	jalr	1970(ra) # 80000c8a <release>
}
    800054e0:	bfe1                	j	800054b8 <pipeclose+0x46>

00000000800054e2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800054e2:	711d                	addi	sp,sp,-96
    800054e4:	ec86                	sd	ra,88(sp)
    800054e6:	e8a2                	sd	s0,80(sp)
    800054e8:	e4a6                	sd	s1,72(sp)
    800054ea:	e0ca                	sd	s2,64(sp)
    800054ec:	fc4e                	sd	s3,56(sp)
    800054ee:	f852                	sd	s4,48(sp)
    800054f0:	f456                	sd	s5,40(sp)
    800054f2:	f05a                	sd	s6,32(sp)
    800054f4:	ec5e                	sd	s7,24(sp)
    800054f6:	e862                	sd	s8,16(sp)
    800054f8:	1080                	addi	s0,sp,96
    800054fa:	84aa                	mv	s1,a0
    800054fc:	8aae                	mv	s5,a1
    800054fe:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005500:	ffffc097          	auipc	ra,0xffffc
    80005504:	4bc080e7          	jalr	1212(ra) # 800019bc <myproc>
    80005508:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffb097          	auipc	ra,0xffffb
    80005510:	6ca080e7          	jalr	1738(ra) # 80000bd6 <acquire>
  while(i < n){
    80005514:	0b405663          	blez	s4,800055c0 <pipewrite+0xde>
  int i = 0;
    80005518:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000551a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000551c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005520:	21c48b93          	addi	s7,s1,540
    80005524:	a089                	j	80005566 <pipewrite+0x84>
      release(&pi->lock);
    80005526:	8526                	mv	a0,s1
    80005528:	ffffb097          	auipc	ra,0xffffb
    8000552c:	762080e7          	jalr	1890(ra) # 80000c8a <release>
      return -1;
    80005530:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005532:	854a                	mv	a0,s2
    80005534:	60e6                	ld	ra,88(sp)
    80005536:	6446                	ld	s0,80(sp)
    80005538:	64a6                	ld	s1,72(sp)
    8000553a:	6906                	ld	s2,64(sp)
    8000553c:	79e2                	ld	s3,56(sp)
    8000553e:	7a42                	ld	s4,48(sp)
    80005540:	7aa2                	ld	s5,40(sp)
    80005542:	7b02                	ld	s6,32(sp)
    80005544:	6be2                	ld	s7,24(sp)
    80005546:	6c42                	ld	s8,16(sp)
    80005548:	6125                	addi	sp,sp,96
    8000554a:	8082                	ret
      wakeup(&pi->nread);
    8000554c:	8562                	mv	a0,s8
    8000554e:	ffffd097          	auipc	ra,0xffffd
    80005552:	d62080e7          	jalr	-670(ra) # 800022b0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005556:	85a6                	mv	a1,s1
    80005558:	855e                	mv	a0,s7
    8000555a:	ffffd097          	auipc	ra,0xffffd
    8000555e:	cf2080e7          	jalr	-782(ra) # 8000224c <sleep>
  while(i < n){
    80005562:	07495063          	bge	s2,s4,800055c2 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005566:	2204a783          	lw	a5,544(s1)
    8000556a:	dfd5                	beqz	a5,80005526 <pipewrite+0x44>
    8000556c:	854e                	mv	a0,s3
    8000556e:	ffffd097          	auipc	ra,0xffffd
    80005572:	f92080e7          	jalr	-110(ra) # 80002500 <killed>
    80005576:	f945                	bnez	a0,80005526 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005578:	2184a783          	lw	a5,536(s1)
    8000557c:	21c4a703          	lw	a4,540(s1)
    80005580:	2007879b          	addiw	a5,a5,512
    80005584:	fcf704e3          	beq	a4,a5,8000554c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005588:	4685                	li	a3,1
    8000558a:	01590633          	add	a2,s2,s5
    8000558e:	faf40593          	addi	a1,s0,-81
    80005592:	0509b503          	ld	a0,80(s3)
    80005596:	ffffc097          	auipc	ra,0xffffc
    8000559a:	16e080e7          	jalr	366(ra) # 80001704 <copyin>
    8000559e:	03650263          	beq	a0,s6,800055c2 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800055a2:	21c4a783          	lw	a5,540(s1)
    800055a6:	0017871b          	addiw	a4,a5,1
    800055aa:	20e4ae23          	sw	a4,540(s1)
    800055ae:	1ff7f793          	andi	a5,a5,511
    800055b2:	97a6                	add	a5,a5,s1
    800055b4:	faf44703          	lbu	a4,-81(s0)
    800055b8:	00e78c23          	sb	a4,24(a5)
      i++;
    800055bc:	2905                	addiw	s2,s2,1
    800055be:	b755                	j	80005562 <pipewrite+0x80>
  int i = 0;
    800055c0:	4901                	li	s2,0
  wakeup(&pi->nread);
    800055c2:	21848513          	addi	a0,s1,536
    800055c6:	ffffd097          	auipc	ra,0xffffd
    800055ca:	cea080e7          	jalr	-790(ra) # 800022b0 <wakeup>
  release(&pi->lock);
    800055ce:	8526                	mv	a0,s1
    800055d0:	ffffb097          	auipc	ra,0xffffb
    800055d4:	6ba080e7          	jalr	1722(ra) # 80000c8a <release>
  return i;
    800055d8:	bfa9                	j	80005532 <pipewrite+0x50>

00000000800055da <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800055da:	715d                	addi	sp,sp,-80
    800055dc:	e486                	sd	ra,72(sp)
    800055de:	e0a2                	sd	s0,64(sp)
    800055e0:	fc26                	sd	s1,56(sp)
    800055e2:	f84a                	sd	s2,48(sp)
    800055e4:	f44e                	sd	s3,40(sp)
    800055e6:	f052                	sd	s4,32(sp)
    800055e8:	ec56                	sd	s5,24(sp)
    800055ea:	e85a                	sd	s6,16(sp)
    800055ec:	0880                	addi	s0,sp,80
    800055ee:	84aa                	mv	s1,a0
    800055f0:	892e                	mv	s2,a1
    800055f2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800055f4:	ffffc097          	auipc	ra,0xffffc
    800055f8:	3c8080e7          	jalr	968(ra) # 800019bc <myproc>
    800055fc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800055fe:	8526                	mv	a0,s1
    80005600:	ffffb097          	auipc	ra,0xffffb
    80005604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005608:	2184a703          	lw	a4,536(s1)
    8000560c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005610:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005614:	02f71763          	bne	a4,a5,80005642 <piperead+0x68>
    80005618:	2244a783          	lw	a5,548(s1)
    8000561c:	c39d                	beqz	a5,80005642 <piperead+0x68>
    if(killed(pr)){
    8000561e:	8552                	mv	a0,s4
    80005620:	ffffd097          	auipc	ra,0xffffd
    80005624:	ee0080e7          	jalr	-288(ra) # 80002500 <killed>
    80005628:	e941                	bnez	a0,800056b8 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000562a:	85a6                	mv	a1,s1
    8000562c:	854e                	mv	a0,s3
    8000562e:	ffffd097          	auipc	ra,0xffffd
    80005632:	c1e080e7          	jalr	-994(ra) # 8000224c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005636:	2184a703          	lw	a4,536(s1)
    8000563a:	21c4a783          	lw	a5,540(s1)
    8000563e:	fcf70de3          	beq	a4,a5,80005618 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005642:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005644:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005646:	05505363          	blez	s5,8000568c <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    8000564a:	2184a783          	lw	a5,536(s1)
    8000564e:	21c4a703          	lw	a4,540(s1)
    80005652:	02f70d63          	beq	a4,a5,8000568c <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005656:	0017871b          	addiw	a4,a5,1
    8000565a:	20e4ac23          	sw	a4,536(s1)
    8000565e:	1ff7f793          	andi	a5,a5,511
    80005662:	97a6                	add	a5,a5,s1
    80005664:	0187c783          	lbu	a5,24(a5)
    80005668:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000566c:	4685                	li	a3,1
    8000566e:	fbf40613          	addi	a2,s0,-65
    80005672:	85ca                	mv	a1,s2
    80005674:	050a3503          	ld	a0,80(s4)
    80005678:	ffffc097          	auipc	ra,0xffffc
    8000567c:	000080e7          	jalr	ra # 80001678 <copyout>
    80005680:	01650663          	beq	a0,s6,8000568c <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005684:	2985                	addiw	s3,s3,1
    80005686:	0905                	addi	s2,s2,1
    80005688:	fd3a91e3          	bne	s5,s3,8000564a <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000568c:	21c48513          	addi	a0,s1,540
    80005690:	ffffd097          	auipc	ra,0xffffd
    80005694:	c20080e7          	jalr	-992(ra) # 800022b0 <wakeup>
  release(&pi->lock);
    80005698:	8526                	mv	a0,s1
    8000569a:	ffffb097          	auipc	ra,0xffffb
    8000569e:	5f0080e7          	jalr	1520(ra) # 80000c8a <release>
  return i;
}
    800056a2:	854e                	mv	a0,s3
    800056a4:	60a6                	ld	ra,72(sp)
    800056a6:	6406                	ld	s0,64(sp)
    800056a8:	74e2                	ld	s1,56(sp)
    800056aa:	7942                	ld	s2,48(sp)
    800056ac:	79a2                	ld	s3,40(sp)
    800056ae:	7a02                	ld	s4,32(sp)
    800056b0:	6ae2                	ld	s5,24(sp)
    800056b2:	6b42                	ld	s6,16(sp)
    800056b4:	6161                	addi	sp,sp,80
    800056b6:	8082                	ret
      release(&pi->lock);
    800056b8:	8526                	mv	a0,s1
    800056ba:	ffffb097          	auipc	ra,0xffffb
    800056be:	5d0080e7          	jalr	1488(ra) # 80000c8a <release>
      return -1;
    800056c2:	59fd                	li	s3,-1
    800056c4:	bff9                	j	800056a2 <piperead+0xc8>

00000000800056c6 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800056c6:	1141                	addi	sp,sp,-16
    800056c8:	e422                	sd	s0,8(sp)
    800056ca:	0800                	addi	s0,sp,16
    800056cc:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800056ce:	8905                	andi	a0,a0,1
    800056d0:	c111                	beqz	a0,800056d4 <flags2perm+0xe>
      perm = PTE_X;
    800056d2:	4521                	li	a0,8
    if(flags & 0x2)
    800056d4:	8b89                	andi	a5,a5,2
    800056d6:	c399                	beqz	a5,800056dc <flags2perm+0x16>
      perm |= PTE_W;
    800056d8:	00456513          	ori	a0,a0,4
    return perm;
}
    800056dc:	6422                	ld	s0,8(sp)
    800056de:	0141                	addi	sp,sp,16
    800056e0:	8082                	ret

00000000800056e2 <exec>:

int
exec(char *path, char **argv)
{
    800056e2:	de010113          	addi	sp,sp,-544
    800056e6:	20113c23          	sd	ra,536(sp)
    800056ea:	20813823          	sd	s0,528(sp)
    800056ee:	20913423          	sd	s1,520(sp)
    800056f2:	21213023          	sd	s2,512(sp)
    800056f6:	ffce                	sd	s3,504(sp)
    800056f8:	fbd2                	sd	s4,496(sp)
    800056fa:	f7d6                	sd	s5,488(sp)
    800056fc:	f3da                	sd	s6,480(sp)
    800056fe:	efde                	sd	s7,472(sp)
    80005700:	ebe2                	sd	s8,464(sp)
    80005702:	e7e6                	sd	s9,456(sp)
    80005704:	e3ea                	sd	s10,448(sp)
    80005706:	ff6e                	sd	s11,440(sp)
    80005708:	1400                	addi	s0,sp,544
    8000570a:	892a                	mv	s2,a0
    8000570c:	dea43423          	sd	a0,-536(s0)
    80005710:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005714:	ffffc097          	auipc	ra,0xffffc
    80005718:	2a8080e7          	jalr	680(ra) # 800019bc <myproc>
    8000571c:	84aa                	mv	s1,a0

  begin_op();
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	47e080e7          	jalr	1150(ra) # 80004b9c <begin_op>

  if((ip = namei(path)) == 0){
    80005726:	854a                	mv	a0,s2
    80005728:	fffff097          	auipc	ra,0xfffff
    8000572c:	258080e7          	jalr	600(ra) # 80004980 <namei>
    80005730:	c93d                	beqz	a0,800057a6 <exec+0xc4>
    80005732:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	aa6080e7          	jalr	-1370(ra) # 800041da <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000573c:	04000713          	li	a4,64
    80005740:	4681                	li	a3,0
    80005742:	e5040613          	addi	a2,s0,-432
    80005746:	4581                	li	a1,0
    80005748:	8556                	mv	a0,s5
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	d44080e7          	jalr	-700(ra) # 8000448e <readi>
    80005752:	04000793          	li	a5,64
    80005756:	00f51a63          	bne	a0,a5,8000576a <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000575a:	e5042703          	lw	a4,-432(s0)
    8000575e:	464c47b7          	lui	a5,0x464c4
    80005762:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005766:	04f70663          	beq	a4,a5,800057b2 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000576a:	8556                	mv	a0,s5
    8000576c:	fffff097          	auipc	ra,0xfffff
    80005770:	cd0080e7          	jalr	-816(ra) # 8000443c <iunlockput>
    end_op();
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	4a8080e7          	jalr	1192(ra) # 80004c1c <end_op>
  }
  return -1;
    8000577c:	557d                	li	a0,-1
}
    8000577e:	21813083          	ld	ra,536(sp)
    80005782:	21013403          	ld	s0,528(sp)
    80005786:	20813483          	ld	s1,520(sp)
    8000578a:	20013903          	ld	s2,512(sp)
    8000578e:	79fe                	ld	s3,504(sp)
    80005790:	7a5e                	ld	s4,496(sp)
    80005792:	7abe                	ld	s5,488(sp)
    80005794:	7b1e                	ld	s6,480(sp)
    80005796:	6bfe                	ld	s7,472(sp)
    80005798:	6c5e                	ld	s8,464(sp)
    8000579a:	6cbe                	ld	s9,456(sp)
    8000579c:	6d1e                	ld	s10,448(sp)
    8000579e:	7dfa                	ld	s11,440(sp)
    800057a0:	22010113          	addi	sp,sp,544
    800057a4:	8082                	ret
    end_op();
    800057a6:	fffff097          	auipc	ra,0xfffff
    800057aa:	476080e7          	jalr	1142(ra) # 80004c1c <end_op>
    return -1;
    800057ae:	557d                	li	a0,-1
    800057b0:	b7f9                	j	8000577e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800057b2:	8526                	mv	a0,s1
    800057b4:	ffffc097          	auipc	ra,0xffffc
    800057b8:	2cc080e7          	jalr	716(ra) # 80001a80 <proc_pagetable>
    800057bc:	8b2a                	mv	s6,a0
    800057be:	d555                	beqz	a0,8000576a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057c0:	e7042783          	lw	a5,-400(s0)
    800057c4:	e8845703          	lhu	a4,-376(s0)
    800057c8:	c735                	beqz	a4,80005834 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800057ca:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057cc:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800057d0:	6a05                	lui	s4,0x1
    800057d2:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800057d6:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800057da:	6d85                	lui	s11,0x1
    800057dc:	7d7d                	lui	s10,0xfffff
    800057de:	a481                	j	80005a1e <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800057e0:	00003517          	auipc	a0,0x3
    800057e4:	ef050513          	addi	a0,a0,-272 # 800086d0 <syscalls+0x2a0>
    800057e8:	ffffb097          	auipc	ra,0xffffb
    800057ec:	d56080e7          	jalr	-682(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800057f0:	874a                	mv	a4,s2
    800057f2:	009c86bb          	addw	a3,s9,s1
    800057f6:	4581                	li	a1,0
    800057f8:	8556                	mv	a0,s5
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	c94080e7          	jalr	-876(ra) # 8000448e <readi>
    80005802:	2501                	sext.w	a0,a0
    80005804:	1aa91a63          	bne	s2,a0,800059b8 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80005808:	009d84bb          	addw	s1,s11,s1
    8000580c:	013d09bb          	addw	s3,s10,s3
    80005810:	1f74f763          	bgeu	s1,s7,800059fe <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80005814:	02049593          	slli	a1,s1,0x20
    80005818:	9181                	srli	a1,a1,0x20
    8000581a:	95e2                	add	a1,a1,s8
    8000581c:	855a                	mv	a0,s6
    8000581e:	ffffc097          	auipc	ra,0xffffc
    80005822:	84e080e7          	jalr	-1970(ra) # 8000106c <walkaddr>
    80005826:	862a                	mv	a2,a0
    if(pa == 0)
    80005828:	dd45                	beqz	a0,800057e0 <exec+0xfe>
      n = PGSIZE;
    8000582a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000582c:	fd49f2e3          	bgeu	s3,s4,800057f0 <exec+0x10e>
      n = sz - i;
    80005830:	894e                	mv	s2,s3
    80005832:	bf7d                	j	800057f0 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005834:	4901                	li	s2,0
  iunlockput(ip);
    80005836:	8556                	mv	a0,s5
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	c04080e7          	jalr	-1020(ra) # 8000443c <iunlockput>
  end_op();
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	3dc080e7          	jalr	988(ra) # 80004c1c <end_op>
  p = myproc();
    80005848:	ffffc097          	auipc	ra,0xffffc
    8000584c:	174080e7          	jalr	372(ra) # 800019bc <myproc>
    80005850:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005852:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005856:	6785                	lui	a5,0x1
    80005858:	17fd                	addi	a5,a5,-1
    8000585a:	993e                	add	s2,s2,a5
    8000585c:	77fd                	lui	a5,0xfffff
    8000585e:	00f977b3          	and	a5,s2,a5
    80005862:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005866:	4691                	li	a3,4
    80005868:	6609                	lui	a2,0x2
    8000586a:	963e                	add	a2,a2,a5
    8000586c:	85be                	mv	a1,a5
    8000586e:	855a                	mv	a0,s6
    80005870:	ffffc097          	auipc	ra,0xffffc
    80005874:	bb0080e7          	jalr	-1104(ra) # 80001420 <uvmalloc>
    80005878:	8c2a                	mv	s8,a0
  ip = 0;
    8000587a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000587c:	12050e63          	beqz	a0,800059b8 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005880:	75f9                	lui	a1,0xffffe
    80005882:	95aa                	add	a1,a1,a0
    80005884:	855a                	mv	a0,s6
    80005886:	ffffc097          	auipc	ra,0xffffc
    8000588a:	dc0080e7          	jalr	-576(ra) # 80001646 <uvmclear>
  stackbase = sp - PGSIZE;
    8000588e:	7afd                	lui	s5,0xfffff
    80005890:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005892:	df043783          	ld	a5,-528(s0)
    80005896:	6388                	ld	a0,0(a5)
    80005898:	c925                	beqz	a0,80005908 <exec+0x226>
    8000589a:	e9040993          	addi	s3,s0,-368
    8000589e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800058a2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800058a4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800058a6:	ffffb097          	auipc	ra,0xffffb
    800058aa:	5a8080e7          	jalr	1448(ra) # 80000e4e <strlen>
    800058ae:	0015079b          	addiw	a5,a0,1
    800058b2:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800058b6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800058ba:	13596663          	bltu	s2,s5,800059e6 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800058be:	df043d83          	ld	s11,-528(s0)
    800058c2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800058c6:	8552                	mv	a0,s4
    800058c8:	ffffb097          	auipc	ra,0xffffb
    800058cc:	586080e7          	jalr	1414(ra) # 80000e4e <strlen>
    800058d0:	0015069b          	addiw	a3,a0,1
    800058d4:	8652                	mv	a2,s4
    800058d6:	85ca                	mv	a1,s2
    800058d8:	855a                	mv	a0,s6
    800058da:	ffffc097          	auipc	ra,0xffffc
    800058de:	d9e080e7          	jalr	-610(ra) # 80001678 <copyout>
    800058e2:	10054663          	bltz	a0,800059ee <exec+0x30c>
    ustack[argc] = sp;
    800058e6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800058ea:	0485                	addi	s1,s1,1
    800058ec:	008d8793          	addi	a5,s11,8
    800058f0:	def43823          	sd	a5,-528(s0)
    800058f4:	008db503          	ld	a0,8(s11)
    800058f8:	c911                	beqz	a0,8000590c <exec+0x22a>
    if(argc >= MAXARG)
    800058fa:	09a1                	addi	s3,s3,8
    800058fc:	fb3c95e3          	bne	s9,s3,800058a6 <exec+0x1c4>
  sz = sz1;
    80005900:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005904:	4a81                	li	s5,0
    80005906:	a84d                	j	800059b8 <exec+0x2d6>
  sp = sz;
    80005908:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000590a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000590c:	00349793          	slli	a5,s1,0x3
    80005910:	f9040713          	addi	a4,s0,-112
    80005914:	97ba                	add	a5,a5,a4
    80005916:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7f83af70>
  sp -= (argc+1) * sizeof(uint64);
    8000591a:	00148693          	addi	a3,s1,1
    8000591e:	068e                	slli	a3,a3,0x3
    80005920:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005924:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005928:	01597663          	bgeu	s2,s5,80005934 <exec+0x252>
  sz = sz1;
    8000592c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005930:	4a81                	li	s5,0
    80005932:	a059                	j	800059b8 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005934:	e9040613          	addi	a2,s0,-368
    80005938:	85ca                	mv	a1,s2
    8000593a:	855a                	mv	a0,s6
    8000593c:	ffffc097          	auipc	ra,0xffffc
    80005940:	d3c080e7          	jalr	-708(ra) # 80001678 <copyout>
    80005944:	0a054963          	bltz	a0,800059f6 <exec+0x314>
  p->trapframe->a1 = sp;
    80005948:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    8000594c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005950:	de843783          	ld	a5,-536(s0)
    80005954:	0007c703          	lbu	a4,0(a5)
    80005958:	cf11                	beqz	a4,80005974 <exec+0x292>
    8000595a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000595c:	02f00693          	li	a3,47
    80005960:	a039                	j	8000596e <exec+0x28c>
      last = s+1;
    80005962:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005966:	0785                	addi	a5,a5,1
    80005968:	fff7c703          	lbu	a4,-1(a5)
    8000596c:	c701                	beqz	a4,80005974 <exec+0x292>
    if(*s == '/')
    8000596e:	fed71ce3          	bne	a4,a3,80005966 <exec+0x284>
    80005972:	bfc5                	j	80005962 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80005974:	4641                	li	a2,16
    80005976:	de843583          	ld	a1,-536(s0)
    8000597a:	158b8513          	addi	a0,s7,344
    8000597e:	ffffb097          	auipc	ra,0xffffb
    80005982:	49e080e7          	jalr	1182(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005986:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000598a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000598e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005992:	058bb783          	ld	a5,88(s7)
    80005996:	e6843703          	ld	a4,-408(s0)
    8000599a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000599c:	058bb783          	ld	a5,88(s7)
    800059a0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800059a4:	85ea                	mv	a1,s10
    800059a6:	ffffc097          	auipc	ra,0xffffc
    800059aa:	176080e7          	jalr	374(ra) # 80001b1c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800059ae:	0004851b          	sext.w	a0,s1
    800059b2:	b3f1                	j	8000577e <exec+0x9c>
    800059b4:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800059b8:	df843583          	ld	a1,-520(s0)
    800059bc:	855a                	mv	a0,s6
    800059be:	ffffc097          	auipc	ra,0xffffc
    800059c2:	15e080e7          	jalr	350(ra) # 80001b1c <proc_freepagetable>
  if(ip){
    800059c6:	da0a92e3          	bnez	s5,8000576a <exec+0x88>
  return -1;
    800059ca:	557d                	li	a0,-1
    800059cc:	bb4d                	j	8000577e <exec+0x9c>
    800059ce:	df243c23          	sd	s2,-520(s0)
    800059d2:	b7dd                	j	800059b8 <exec+0x2d6>
    800059d4:	df243c23          	sd	s2,-520(s0)
    800059d8:	b7c5                	j	800059b8 <exec+0x2d6>
    800059da:	df243c23          	sd	s2,-520(s0)
    800059de:	bfe9                	j	800059b8 <exec+0x2d6>
    800059e0:	df243c23          	sd	s2,-520(s0)
    800059e4:	bfd1                	j	800059b8 <exec+0x2d6>
  sz = sz1;
    800059e6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800059ea:	4a81                	li	s5,0
    800059ec:	b7f1                	j	800059b8 <exec+0x2d6>
  sz = sz1;
    800059ee:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800059f2:	4a81                	li	s5,0
    800059f4:	b7d1                	j	800059b8 <exec+0x2d6>
  sz = sz1;
    800059f6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800059fa:	4a81                	li	s5,0
    800059fc:	bf75                	j	800059b8 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800059fe:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a02:	e0843783          	ld	a5,-504(s0)
    80005a06:	0017869b          	addiw	a3,a5,1
    80005a0a:	e0d43423          	sd	a3,-504(s0)
    80005a0e:	e0043783          	ld	a5,-512(s0)
    80005a12:	0387879b          	addiw	a5,a5,56
    80005a16:	e8845703          	lhu	a4,-376(s0)
    80005a1a:	e0e6dee3          	bge	a3,a4,80005836 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005a1e:	2781                	sext.w	a5,a5
    80005a20:	e0f43023          	sd	a5,-512(s0)
    80005a24:	03800713          	li	a4,56
    80005a28:	86be                	mv	a3,a5
    80005a2a:	e1840613          	addi	a2,s0,-488
    80005a2e:	4581                	li	a1,0
    80005a30:	8556                	mv	a0,s5
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	a5c080e7          	jalr	-1444(ra) # 8000448e <readi>
    80005a3a:	03800793          	li	a5,56
    80005a3e:	f6f51be3          	bne	a0,a5,800059b4 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005a42:	e1842783          	lw	a5,-488(s0)
    80005a46:	4705                	li	a4,1
    80005a48:	fae79de3          	bne	a5,a4,80005a02 <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005a4c:	e4043483          	ld	s1,-448(s0)
    80005a50:	e3843783          	ld	a5,-456(s0)
    80005a54:	f6f4ede3          	bltu	s1,a5,800059ce <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005a58:	e2843783          	ld	a5,-472(s0)
    80005a5c:	94be                	add	s1,s1,a5
    80005a5e:	f6f4ebe3          	bltu	s1,a5,800059d4 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80005a62:	de043703          	ld	a4,-544(s0)
    80005a66:	8ff9                	and	a5,a5,a4
    80005a68:	fbad                	bnez	a5,800059da <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005a6a:	e1c42503          	lw	a0,-484(s0)
    80005a6e:	00000097          	auipc	ra,0x0
    80005a72:	c58080e7          	jalr	-936(ra) # 800056c6 <flags2perm>
    80005a76:	86aa                	mv	a3,a0
    80005a78:	8626                	mv	a2,s1
    80005a7a:	85ca                	mv	a1,s2
    80005a7c:	855a                	mv	a0,s6
    80005a7e:	ffffc097          	auipc	ra,0xffffc
    80005a82:	9a2080e7          	jalr	-1630(ra) # 80001420 <uvmalloc>
    80005a86:	dea43c23          	sd	a0,-520(s0)
    80005a8a:	d939                	beqz	a0,800059e0 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005a8c:	e2843c03          	ld	s8,-472(s0)
    80005a90:	e2042c83          	lw	s9,-480(s0)
    80005a94:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005a98:	f60b83e3          	beqz	s7,800059fe <exec+0x31c>
    80005a9c:	89de                	mv	s3,s7
    80005a9e:	4481                	li	s1,0
    80005aa0:	bb95                	j	80005814 <exec+0x132>

0000000080005aa2 <argfd>:
extern int getread_count; 
// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005aa2:	7179                	addi	sp,sp,-48
    80005aa4:	f406                	sd	ra,40(sp)
    80005aa6:	f022                	sd	s0,32(sp)
    80005aa8:	ec26                	sd	s1,24(sp)
    80005aaa:	e84a                	sd	s2,16(sp)
    80005aac:	1800                	addi	s0,sp,48
    80005aae:	892e                	mv	s2,a1
    80005ab0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005ab2:	fdc40593          	addi	a1,s0,-36
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	a26080e7          	jalr	-1498(ra) # 800034dc <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005abe:	fdc42703          	lw	a4,-36(s0)
    80005ac2:	47bd                	li	a5,15
    80005ac4:	02e7eb63          	bltu	a5,a4,80005afa <argfd+0x58>
    80005ac8:	ffffc097          	auipc	ra,0xffffc
    80005acc:	ef4080e7          	jalr	-268(ra) # 800019bc <myproc>
    80005ad0:	fdc42703          	lw	a4,-36(s0)
    80005ad4:	01a70793          	addi	a5,a4,26
    80005ad8:	078e                	slli	a5,a5,0x3
    80005ada:	953e                	add	a0,a0,a5
    80005adc:	611c                	ld	a5,0(a0)
    80005ade:	c385                	beqz	a5,80005afe <argfd+0x5c>
    return -1;
  if(pfd)
    80005ae0:	00090463          	beqz	s2,80005ae8 <argfd+0x46>
    *pfd = fd;
    80005ae4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005ae8:	4501                	li	a0,0
  if(pf)
    80005aea:	c091                	beqz	s1,80005aee <argfd+0x4c>
    *pf = f;
    80005aec:	e09c                	sd	a5,0(s1)
}
    80005aee:	70a2                	ld	ra,40(sp)
    80005af0:	7402                	ld	s0,32(sp)
    80005af2:	64e2                	ld	s1,24(sp)
    80005af4:	6942                	ld	s2,16(sp)
    80005af6:	6145                	addi	sp,sp,48
    80005af8:	8082                	ret
    return -1;
    80005afa:	557d                	li	a0,-1
    80005afc:	bfcd                	j	80005aee <argfd+0x4c>
    80005afe:	557d                	li	a0,-1
    80005b00:	b7fd                	j	80005aee <argfd+0x4c>

0000000080005b02 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005b02:	1101                	addi	sp,sp,-32
    80005b04:	ec06                	sd	ra,24(sp)
    80005b06:	e822                	sd	s0,16(sp)
    80005b08:	e426                	sd	s1,8(sp)
    80005b0a:	1000                	addi	s0,sp,32
    80005b0c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005b0e:	ffffc097          	auipc	ra,0xffffc
    80005b12:	eae080e7          	jalr	-338(ra) # 800019bc <myproc>
    80005b16:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005b18:	0d050793          	addi	a5,a0,208
    80005b1c:	4501                	li	a0,0
    80005b1e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005b20:	6398                	ld	a4,0(a5)
    80005b22:	cb19                	beqz	a4,80005b38 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005b24:	2505                	addiw	a0,a0,1
    80005b26:	07a1                	addi	a5,a5,8
    80005b28:	fed51ce3          	bne	a0,a3,80005b20 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005b2c:	557d                	li	a0,-1
}
    80005b2e:	60e2                	ld	ra,24(sp)
    80005b30:	6442                	ld	s0,16(sp)
    80005b32:	64a2                	ld	s1,8(sp)
    80005b34:	6105                	addi	sp,sp,32
    80005b36:	8082                	ret
      p->ofile[fd] = f;
    80005b38:	01a50793          	addi	a5,a0,26
    80005b3c:	078e                	slli	a5,a5,0x3
    80005b3e:	963e                	add	a2,a2,a5
    80005b40:	e204                	sd	s1,0(a2)
      return fd;
    80005b42:	b7f5                	j	80005b2e <fdalloc+0x2c>

0000000080005b44 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005b44:	715d                	addi	sp,sp,-80
    80005b46:	e486                	sd	ra,72(sp)
    80005b48:	e0a2                	sd	s0,64(sp)
    80005b4a:	fc26                	sd	s1,56(sp)
    80005b4c:	f84a                	sd	s2,48(sp)
    80005b4e:	f44e                	sd	s3,40(sp)
    80005b50:	f052                	sd	s4,32(sp)
    80005b52:	ec56                	sd	s5,24(sp)
    80005b54:	e85a                	sd	s6,16(sp)
    80005b56:	0880                	addi	s0,sp,80
    80005b58:	8b2e                	mv	s6,a1
    80005b5a:	89b2                	mv	s3,a2
    80005b5c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005b5e:	fb040593          	addi	a1,s0,-80
    80005b62:	fffff097          	auipc	ra,0xfffff
    80005b66:	e3c080e7          	jalr	-452(ra) # 8000499e <nameiparent>
    80005b6a:	84aa                	mv	s1,a0
    80005b6c:	14050f63          	beqz	a0,80005cca <create+0x186>
    return 0;

  ilock(dp);
    80005b70:	ffffe097          	auipc	ra,0xffffe
    80005b74:	66a080e7          	jalr	1642(ra) # 800041da <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005b78:	4601                	li	a2,0
    80005b7a:	fb040593          	addi	a1,s0,-80
    80005b7e:	8526                	mv	a0,s1
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	b3e080e7          	jalr	-1218(ra) # 800046be <dirlookup>
    80005b88:	8aaa                	mv	s5,a0
    80005b8a:	c931                	beqz	a0,80005bde <create+0x9a>
    iunlockput(dp);
    80005b8c:	8526                	mv	a0,s1
    80005b8e:	fffff097          	auipc	ra,0xfffff
    80005b92:	8ae080e7          	jalr	-1874(ra) # 8000443c <iunlockput>
    ilock(ip);
    80005b96:	8556                	mv	a0,s5
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	642080e7          	jalr	1602(ra) # 800041da <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005ba0:	000b059b          	sext.w	a1,s6
    80005ba4:	4789                	li	a5,2
    80005ba6:	02f59563          	bne	a1,a5,80005bd0 <create+0x8c>
    80005baa:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7f83b0b4>
    80005bae:	37f9                	addiw	a5,a5,-2
    80005bb0:	17c2                	slli	a5,a5,0x30
    80005bb2:	93c1                	srli	a5,a5,0x30
    80005bb4:	4705                	li	a4,1
    80005bb6:	00f76d63          	bltu	a4,a5,80005bd0 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005bba:	8556                	mv	a0,s5
    80005bbc:	60a6                	ld	ra,72(sp)
    80005bbe:	6406                	ld	s0,64(sp)
    80005bc0:	74e2                	ld	s1,56(sp)
    80005bc2:	7942                	ld	s2,48(sp)
    80005bc4:	79a2                	ld	s3,40(sp)
    80005bc6:	7a02                	ld	s4,32(sp)
    80005bc8:	6ae2                	ld	s5,24(sp)
    80005bca:	6b42                	ld	s6,16(sp)
    80005bcc:	6161                	addi	sp,sp,80
    80005bce:	8082                	ret
    iunlockput(ip);
    80005bd0:	8556                	mv	a0,s5
    80005bd2:	fffff097          	auipc	ra,0xfffff
    80005bd6:	86a080e7          	jalr	-1942(ra) # 8000443c <iunlockput>
    return 0;
    80005bda:	4a81                	li	s5,0
    80005bdc:	bff9                	j	80005bba <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005bde:	85da                	mv	a1,s6
    80005be0:	4088                	lw	a0,0(s1)
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	45c080e7          	jalr	1116(ra) # 8000403e <ialloc>
    80005bea:	8a2a                	mv	s4,a0
    80005bec:	c539                	beqz	a0,80005c3a <create+0xf6>
  ilock(ip);
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	5ec080e7          	jalr	1516(ra) # 800041da <ilock>
  ip->major = major;
    80005bf6:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005bfa:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005bfe:	4905                	li	s2,1
    80005c00:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005c04:	8552                	mv	a0,s4
    80005c06:	ffffe097          	auipc	ra,0xffffe
    80005c0a:	50a080e7          	jalr	1290(ra) # 80004110 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005c0e:	000b059b          	sext.w	a1,s6
    80005c12:	03258b63          	beq	a1,s2,80005c48 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005c16:	004a2603          	lw	a2,4(s4)
    80005c1a:	fb040593          	addi	a1,s0,-80
    80005c1e:	8526                	mv	a0,s1
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	cae080e7          	jalr	-850(ra) # 800048ce <dirlink>
    80005c28:	06054f63          	bltz	a0,80005ca6 <create+0x162>
  iunlockput(dp);
    80005c2c:	8526                	mv	a0,s1
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	80e080e7          	jalr	-2034(ra) # 8000443c <iunlockput>
  return ip;
    80005c36:	8ad2                	mv	s5,s4
    80005c38:	b749                	j	80005bba <create+0x76>
    iunlockput(dp);
    80005c3a:	8526                	mv	a0,s1
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	800080e7          	jalr	-2048(ra) # 8000443c <iunlockput>
    return 0;
    80005c44:	8ad2                	mv	s5,s4
    80005c46:	bf95                	j	80005bba <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005c48:	004a2603          	lw	a2,4(s4)
    80005c4c:	00003597          	auipc	a1,0x3
    80005c50:	aa458593          	addi	a1,a1,-1372 # 800086f0 <syscalls+0x2c0>
    80005c54:	8552                	mv	a0,s4
    80005c56:	fffff097          	auipc	ra,0xfffff
    80005c5a:	c78080e7          	jalr	-904(ra) # 800048ce <dirlink>
    80005c5e:	04054463          	bltz	a0,80005ca6 <create+0x162>
    80005c62:	40d0                	lw	a2,4(s1)
    80005c64:	00003597          	auipc	a1,0x3
    80005c68:	a9458593          	addi	a1,a1,-1388 # 800086f8 <syscalls+0x2c8>
    80005c6c:	8552                	mv	a0,s4
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	c60080e7          	jalr	-928(ra) # 800048ce <dirlink>
    80005c76:	02054863          	bltz	a0,80005ca6 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005c7a:	004a2603          	lw	a2,4(s4)
    80005c7e:	fb040593          	addi	a1,s0,-80
    80005c82:	8526                	mv	a0,s1
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	c4a080e7          	jalr	-950(ra) # 800048ce <dirlink>
    80005c8c:	00054d63          	bltz	a0,80005ca6 <create+0x162>
    dp->nlink++;  // for ".."
    80005c90:	04a4d783          	lhu	a5,74(s1)
    80005c94:	2785                	addiw	a5,a5,1
    80005c96:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c9a:	8526                	mv	a0,s1
    80005c9c:	ffffe097          	auipc	ra,0xffffe
    80005ca0:	474080e7          	jalr	1140(ra) # 80004110 <iupdate>
    80005ca4:	b761                	j	80005c2c <create+0xe8>
  ip->nlink = 0;
    80005ca6:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005caa:	8552                	mv	a0,s4
    80005cac:	ffffe097          	auipc	ra,0xffffe
    80005cb0:	464080e7          	jalr	1124(ra) # 80004110 <iupdate>
  iunlockput(ip);
    80005cb4:	8552                	mv	a0,s4
    80005cb6:	ffffe097          	auipc	ra,0xffffe
    80005cba:	786080e7          	jalr	1926(ra) # 8000443c <iunlockput>
  iunlockput(dp);
    80005cbe:	8526                	mv	a0,s1
    80005cc0:	ffffe097          	auipc	ra,0xffffe
    80005cc4:	77c080e7          	jalr	1916(ra) # 8000443c <iunlockput>
  return 0;
    80005cc8:	bdcd                	j	80005bba <create+0x76>
    return 0;
    80005cca:	8aaa                	mv	s5,a0
    80005ccc:	b5fd                	j	80005bba <create+0x76>

0000000080005cce <sys_dup>:
{
    80005cce:	7179                	addi	sp,sp,-48
    80005cd0:	f406                	sd	ra,40(sp)
    80005cd2:	f022                	sd	s0,32(sp)
    80005cd4:	ec26                	sd	s1,24(sp)
    80005cd6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005cd8:	fd840613          	addi	a2,s0,-40
    80005cdc:	4581                	li	a1,0
    80005cde:	4501                	li	a0,0
    80005ce0:	00000097          	auipc	ra,0x0
    80005ce4:	dc2080e7          	jalr	-574(ra) # 80005aa2 <argfd>
    return -1;
    80005ce8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005cea:	02054363          	bltz	a0,80005d10 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005cee:	fd843503          	ld	a0,-40(s0)
    80005cf2:	00000097          	auipc	ra,0x0
    80005cf6:	e10080e7          	jalr	-496(ra) # 80005b02 <fdalloc>
    80005cfa:	84aa                	mv	s1,a0
    return -1;
    80005cfc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005cfe:	00054963          	bltz	a0,80005d10 <sys_dup+0x42>
  filedup(f);
    80005d02:	fd843503          	ld	a0,-40(s0)
    80005d06:	fffff097          	auipc	ra,0xfffff
    80005d0a:	310080e7          	jalr	784(ra) # 80005016 <filedup>
  return fd;
    80005d0e:	87a6                	mv	a5,s1
}
    80005d10:	853e                	mv	a0,a5
    80005d12:	70a2                	ld	ra,40(sp)
    80005d14:	7402                	ld	s0,32(sp)
    80005d16:	64e2                	ld	s1,24(sp)
    80005d18:	6145                	addi	sp,sp,48
    80005d1a:	8082                	ret

0000000080005d1c <sys_read>:
{
    80005d1c:	7179                	addi	sp,sp,-48
    80005d1e:	f406                	sd	ra,40(sp)
    80005d20:	f022                	sd	s0,32(sp)
    80005d22:	1800                	addi	s0,sp,48
  getread_count++;
    80005d24:	00003717          	auipc	a4,0x3
    80005d28:	b8470713          	addi	a4,a4,-1148 # 800088a8 <getread_count>
    80005d2c:	431c                	lw	a5,0(a4)
    80005d2e:	2785                	addiw	a5,a5,1
    80005d30:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    80005d32:	fd840593          	addi	a1,s0,-40
    80005d36:	4505                	li	a0,1
    80005d38:	ffffd097          	auipc	ra,0xffffd
    80005d3c:	7c4080e7          	jalr	1988(ra) # 800034fc <argaddr>
  argint(2, &n);
    80005d40:	fe440593          	addi	a1,s0,-28
    80005d44:	4509                	li	a0,2
    80005d46:	ffffd097          	auipc	ra,0xffffd
    80005d4a:	796080e7          	jalr	1942(ra) # 800034dc <argint>
  if(argfd(0, 0, &f) < 0)
    80005d4e:	fe840613          	addi	a2,s0,-24
    80005d52:	4581                	li	a1,0
    80005d54:	4501                	li	a0,0
    80005d56:	00000097          	auipc	ra,0x0
    80005d5a:	d4c080e7          	jalr	-692(ra) # 80005aa2 <argfd>
    80005d5e:	87aa                	mv	a5,a0
    return -1;
    80005d60:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005d62:	0007cc63          	bltz	a5,80005d7a <sys_read+0x5e>
  return fileread(f, p, n);
    80005d66:	fe442603          	lw	a2,-28(s0)
    80005d6a:	fd843583          	ld	a1,-40(s0)
    80005d6e:	fe843503          	ld	a0,-24(s0)
    80005d72:	fffff097          	auipc	ra,0xfffff
    80005d76:	430080e7          	jalr	1072(ra) # 800051a2 <fileread>
}
    80005d7a:	70a2                	ld	ra,40(sp)
    80005d7c:	7402                	ld	s0,32(sp)
    80005d7e:	6145                	addi	sp,sp,48
    80005d80:	8082                	ret

0000000080005d82 <sys_write>:
{
    80005d82:	7179                	addi	sp,sp,-48
    80005d84:	f406                	sd	ra,40(sp)
    80005d86:	f022                	sd	s0,32(sp)
    80005d88:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005d8a:	fd840593          	addi	a1,s0,-40
    80005d8e:	4505                	li	a0,1
    80005d90:	ffffd097          	auipc	ra,0xffffd
    80005d94:	76c080e7          	jalr	1900(ra) # 800034fc <argaddr>
  argint(2, &n);
    80005d98:	fe440593          	addi	a1,s0,-28
    80005d9c:	4509                	li	a0,2
    80005d9e:	ffffd097          	auipc	ra,0xffffd
    80005da2:	73e080e7          	jalr	1854(ra) # 800034dc <argint>
  if(argfd(0, 0, &f) < 0)
    80005da6:	fe840613          	addi	a2,s0,-24
    80005daa:	4581                	li	a1,0
    80005dac:	4501                	li	a0,0
    80005dae:	00000097          	auipc	ra,0x0
    80005db2:	cf4080e7          	jalr	-780(ra) # 80005aa2 <argfd>
    80005db6:	87aa                	mv	a5,a0
    return -1;
    80005db8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005dba:	0007cc63          	bltz	a5,80005dd2 <sys_write+0x50>
  return filewrite(f, p, n);
    80005dbe:	fe442603          	lw	a2,-28(s0)
    80005dc2:	fd843583          	ld	a1,-40(s0)
    80005dc6:	fe843503          	ld	a0,-24(s0)
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	49a080e7          	jalr	1178(ra) # 80005264 <filewrite>
}
    80005dd2:	70a2                	ld	ra,40(sp)
    80005dd4:	7402                	ld	s0,32(sp)
    80005dd6:	6145                	addi	sp,sp,48
    80005dd8:	8082                	ret

0000000080005dda <sys_close>:
{
    80005dda:	1101                	addi	sp,sp,-32
    80005ddc:	ec06                	sd	ra,24(sp)
    80005dde:	e822                	sd	s0,16(sp)
    80005de0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005de2:	fe040613          	addi	a2,s0,-32
    80005de6:	fec40593          	addi	a1,s0,-20
    80005dea:	4501                	li	a0,0
    80005dec:	00000097          	auipc	ra,0x0
    80005df0:	cb6080e7          	jalr	-842(ra) # 80005aa2 <argfd>
    return -1;
    80005df4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005df6:	02054463          	bltz	a0,80005e1e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005dfa:	ffffc097          	auipc	ra,0xffffc
    80005dfe:	bc2080e7          	jalr	-1086(ra) # 800019bc <myproc>
    80005e02:	fec42783          	lw	a5,-20(s0)
    80005e06:	07e9                	addi	a5,a5,26
    80005e08:	078e                	slli	a5,a5,0x3
    80005e0a:	97aa                	add	a5,a5,a0
    80005e0c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005e10:	fe043503          	ld	a0,-32(s0)
    80005e14:	fffff097          	auipc	ra,0xfffff
    80005e18:	254080e7          	jalr	596(ra) # 80005068 <fileclose>
  return 0;
    80005e1c:	4781                	li	a5,0
}
    80005e1e:	853e                	mv	a0,a5
    80005e20:	60e2                	ld	ra,24(sp)
    80005e22:	6442                	ld	s0,16(sp)
    80005e24:	6105                	addi	sp,sp,32
    80005e26:	8082                	ret

0000000080005e28 <sys_fstat>:
{
    80005e28:	1101                	addi	sp,sp,-32
    80005e2a:	ec06                	sd	ra,24(sp)
    80005e2c:	e822                	sd	s0,16(sp)
    80005e2e:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005e30:	fe040593          	addi	a1,s0,-32
    80005e34:	4505                	li	a0,1
    80005e36:	ffffd097          	auipc	ra,0xffffd
    80005e3a:	6c6080e7          	jalr	1734(ra) # 800034fc <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005e3e:	fe840613          	addi	a2,s0,-24
    80005e42:	4581                	li	a1,0
    80005e44:	4501                	li	a0,0
    80005e46:	00000097          	auipc	ra,0x0
    80005e4a:	c5c080e7          	jalr	-932(ra) # 80005aa2 <argfd>
    80005e4e:	87aa                	mv	a5,a0
    return -1;
    80005e50:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005e52:	0007ca63          	bltz	a5,80005e66 <sys_fstat+0x3e>
  return filestat(f, st);
    80005e56:	fe043583          	ld	a1,-32(s0)
    80005e5a:	fe843503          	ld	a0,-24(s0)
    80005e5e:	fffff097          	auipc	ra,0xfffff
    80005e62:	2d2080e7          	jalr	722(ra) # 80005130 <filestat>
}
    80005e66:	60e2                	ld	ra,24(sp)
    80005e68:	6442                	ld	s0,16(sp)
    80005e6a:	6105                	addi	sp,sp,32
    80005e6c:	8082                	ret

0000000080005e6e <sys_link>:
{
    80005e6e:	7169                	addi	sp,sp,-304
    80005e70:	f606                	sd	ra,296(sp)
    80005e72:	f222                	sd	s0,288(sp)
    80005e74:	ee26                	sd	s1,280(sp)
    80005e76:	ea4a                	sd	s2,272(sp)
    80005e78:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005e7a:	08000613          	li	a2,128
    80005e7e:	ed040593          	addi	a1,s0,-304
    80005e82:	4501                	li	a0,0
    80005e84:	ffffd097          	auipc	ra,0xffffd
    80005e88:	698080e7          	jalr	1688(ra) # 8000351c <argstr>
    return -1;
    80005e8c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005e8e:	10054e63          	bltz	a0,80005faa <sys_link+0x13c>
    80005e92:	08000613          	li	a2,128
    80005e96:	f5040593          	addi	a1,s0,-176
    80005e9a:	4505                	li	a0,1
    80005e9c:	ffffd097          	auipc	ra,0xffffd
    80005ea0:	680080e7          	jalr	1664(ra) # 8000351c <argstr>
    return -1;
    80005ea4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ea6:	10054263          	bltz	a0,80005faa <sys_link+0x13c>
  begin_op();
    80005eaa:	fffff097          	auipc	ra,0xfffff
    80005eae:	cf2080e7          	jalr	-782(ra) # 80004b9c <begin_op>
  if((ip = namei(old)) == 0){
    80005eb2:	ed040513          	addi	a0,s0,-304
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	aca080e7          	jalr	-1334(ra) # 80004980 <namei>
    80005ebe:	84aa                	mv	s1,a0
    80005ec0:	c551                	beqz	a0,80005f4c <sys_link+0xde>
  ilock(ip);
    80005ec2:	ffffe097          	auipc	ra,0xffffe
    80005ec6:	318080e7          	jalr	792(ra) # 800041da <ilock>
  if(ip->type == T_DIR){
    80005eca:	04449703          	lh	a4,68(s1)
    80005ece:	4785                	li	a5,1
    80005ed0:	08f70463          	beq	a4,a5,80005f58 <sys_link+0xea>
  ip->nlink++;
    80005ed4:	04a4d783          	lhu	a5,74(s1)
    80005ed8:	2785                	addiw	a5,a5,1
    80005eda:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ede:	8526                	mv	a0,s1
    80005ee0:	ffffe097          	auipc	ra,0xffffe
    80005ee4:	230080e7          	jalr	560(ra) # 80004110 <iupdate>
  iunlock(ip);
    80005ee8:	8526                	mv	a0,s1
    80005eea:	ffffe097          	auipc	ra,0xffffe
    80005eee:	3b2080e7          	jalr	946(ra) # 8000429c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005ef2:	fd040593          	addi	a1,s0,-48
    80005ef6:	f5040513          	addi	a0,s0,-176
    80005efa:	fffff097          	auipc	ra,0xfffff
    80005efe:	aa4080e7          	jalr	-1372(ra) # 8000499e <nameiparent>
    80005f02:	892a                	mv	s2,a0
    80005f04:	c935                	beqz	a0,80005f78 <sys_link+0x10a>
  ilock(dp);
    80005f06:	ffffe097          	auipc	ra,0xffffe
    80005f0a:	2d4080e7          	jalr	724(ra) # 800041da <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005f0e:	00092703          	lw	a4,0(s2)
    80005f12:	409c                	lw	a5,0(s1)
    80005f14:	04f71d63          	bne	a4,a5,80005f6e <sys_link+0x100>
    80005f18:	40d0                	lw	a2,4(s1)
    80005f1a:	fd040593          	addi	a1,s0,-48
    80005f1e:	854a                	mv	a0,s2
    80005f20:	fffff097          	auipc	ra,0xfffff
    80005f24:	9ae080e7          	jalr	-1618(ra) # 800048ce <dirlink>
    80005f28:	04054363          	bltz	a0,80005f6e <sys_link+0x100>
  iunlockput(dp);
    80005f2c:	854a                	mv	a0,s2
    80005f2e:	ffffe097          	auipc	ra,0xffffe
    80005f32:	50e080e7          	jalr	1294(ra) # 8000443c <iunlockput>
  iput(ip);
    80005f36:	8526                	mv	a0,s1
    80005f38:	ffffe097          	auipc	ra,0xffffe
    80005f3c:	45c080e7          	jalr	1116(ra) # 80004394 <iput>
  end_op();
    80005f40:	fffff097          	auipc	ra,0xfffff
    80005f44:	cdc080e7          	jalr	-804(ra) # 80004c1c <end_op>
  return 0;
    80005f48:	4781                	li	a5,0
    80005f4a:	a085                	j	80005faa <sys_link+0x13c>
    end_op();
    80005f4c:	fffff097          	auipc	ra,0xfffff
    80005f50:	cd0080e7          	jalr	-816(ra) # 80004c1c <end_op>
    return -1;
    80005f54:	57fd                	li	a5,-1
    80005f56:	a891                	j	80005faa <sys_link+0x13c>
    iunlockput(ip);
    80005f58:	8526                	mv	a0,s1
    80005f5a:	ffffe097          	auipc	ra,0xffffe
    80005f5e:	4e2080e7          	jalr	1250(ra) # 8000443c <iunlockput>
    end_op();
    80005f62:	fffff097          	auipc	ra,0xfffff
    80005f66:	cba080e7          	jalr	-838(ra) # 80004c1c <end_op>
    return -1;
    80005f6a:	57fd                	li	a5,-1
    80005f6c:	a83d                	j	80005faa <sys_link+0x13c>
    iunlockput(dp);
    80005f6e:	854a                	mv	a0,s2
    80005f70:	ffffe097          	auipc	ra,0xffffe
    80005f74:	4cc080e7          	jalr	1228(ra) # 8000443c <iunlockput>
  ilock(ip);
    80005f78:	8526                	mv	a0,s1
    80005f7a:	ffffe097          	auipc	ra,0xffffe
    80005f7e:	260080e7          	jalr	608(ra) # 800041da <ilock>
  ip->nlink--;
    80005f82:	04a4d783          	lhu	a5,74(s1)
    80005f86:	37fd                	addiw	a5,a5,-1
    80005f88:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005f8c:	8526                	mv	a0,s1
    80005f8e:	ffffe097          	auipc	ra,0xffffe
    80005f92:	182080e7          	jalr	386(ra) # 80004110 <iupdate>
  iunlockput(ip);
    80005f96:	8526                	mv	a0,s1
    80005f98:	ffffe097          	auipc	ra,0xffffe
    80005f9c:	4a4080e7          	jalr	1188(ra) # 8000443c <iunlockput>
  end_op();
    80005fa0:	fffff097          	auipc	ra,0xfffff
    80005fa4:	c7c080e7          	jalr	-900(ra) # 80004c1c <end_op>
  return -1;
    80005fa8:	57fd                	li	a5,-1
}
    80005faa:	853e                	mv	a0,a5
    80005fac:	70b2                	ld	ra,296(sp)
    80005fae:	7412                	ld	s0,288(sp)
    80005fb0:	64f2                	ld	s1,280(sp)
    80005fb2:	6952                	ld	s2,272(sp)
    80005fb4:	6155                	addi	sp,sp,304
    80005fb6:	8082                	ret

0000000080005fb8 <sys_unlink>:
{
    80005fb8:	7151                	addi	sp,sp,-240
    80005fba:	f586                	sd	ra,232(sp)
    80005fbc:	f1a2                	sd	s0,224(sp)
    80005fbe:	eda6                	sd	s1,216(sp)
    80005fc0:	e9ca                	sd	s2,208(sp)
    80005fc2:	e5ce                	sd	s3,200(sp)
    80005fc4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005fc6:	08000613          	li	a2,128
    80005fca:	f3040593          	addi	a1,s0,-208
    80005fce:	4501                	li	a0,0
    80005fd0:	ffffd097          	auipc	ra,0xffffd
    80005fd4:	54c080e7          	jalr	1356(ra) # 8000351c <argstr>
    80005fd8:	18054163          	bltz	a0,8000615a <sys_unlink+0x1a2>
  begin_op();
    80005fdc:	fffff097          	auipc	ra,0xfffff
    80005fe0:	bc0080e7          	jalr	-1088(ra) # 80004b9c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005fe4:	fb040593          	addi	a1,s0,-80
    80005fe8:	f3040513          	addi	a0,s0,-208
    80005fec:	fffff097          	auipc	ra,0xfffff
    80005ff0:	9b2080e7          	jalr	-1614(ra) # 8000499e <nameiparent>
    80005ff4:	84aa                	mv	s1,a0
    80005ff6:	c979                	beqz	a0,800060cc <sys_unlink+0x114>
  ilock(dp);
    80005ff8:	ffffe097          	auipc	ra,0xffffe
    80005ffc:	1e2080e7          	jalr	482(ra) # 800041da <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006000:	00002597          	auipc	a1,0x2
    80006004:	6f058593          	addi	a1,a1,1776 # 800086f0 <syscalls+0x2c0>
    80006008:	fb040513          	addi	a0,s0,-80
    8000600c:	ffffe097          	auipc	ra,0xffffe
    80006010:	698080e7          	jalr	1688(ra) # 800046a4 <namecmp>
    80006014:	14050a63          	beqz	a0,80006168 <sys_unlink+0x1b0>
    80006018:	00002597          	auipc	a1,0x2
    8000601c:	6e058593          	addi	a1,a1,1760 # 800086f8 <syscalls+0x2c8>
    80006020:	fb040513          	addi	a0,s0,-80
    80006024:	ffffe097          	auipc	ra,0xffffe
    80006028:	680080e7          	jalr	1664(ra) # 800046a4 <namecmp>
    8000602c:	12050e63          	beqz	a0,80006168 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80006030:	f2c40613          	addi	a2,s0,-212
    80006034:	fb040593          	addi	a1,s0,-80
    80006038:	8526                	mv	a0,s1
    8000603a:	ffffe097          	auipc	ra,0xffffe
    8000603e:	684080e7          	jalr	1668(ra) # 800046be <dirlookup>
    80006042:	892a                	mv	s2,a0
    80006044:	12050263          	beqz	a0,80006168 <sys_unlink+0x1b0>
  ilock(ip);
    80006048:	ffffe097          	auipc	ra,0xffffe
    8000604c:	192080e7          	jalr	402(ra) # 800041da <ilock>
  if(ip->nlink < 1)
    80006050:	04a91783          	lh	a5,74(s2)
    80006054:	08f05263          	blez	a5,800060d8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006058:	04491703          	lh	a4,68(s2)
    8000605c:	4785                	li	a5,1
    8000605e:	08f70563          	beq	a4,a5,800060e8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80006062:	4641                	li	a2,16
    80006064:	4581                	li	a1,0
    80006066:	fc040513          	addi	a0,s0,-64
    8000606a:	ffffb097          	auipc	ra,0xffffb
    8000606e:	c68080e7          	jalr	-920(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006072:	4741                	li	a4,16
    80006074:	f2c42683          	lw	a3,-212(s0)
    80006078:	fc040613          	addi	a2,s0,-64
    8000607c:	4581                	li	a1,0
    8000607e:	8526                	mv	a0,s1
    80006080:	ffffe097          	auipc	ra,0xffffe
    80006084:	506080e7          	jalr	1286(ra) # 80004586 <writei>
    80006088:	47c1                	li	a5,16
    8000608a:	0af51563          	bne	a0,a5,80006134 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000608e:	04491703          	lh	a4,68(s2)
    80006092:	4785                	li	a5,1
    80006094:	0af70863          	beq	a4,a5,80006144 <sys_unlink+0x18c>
  iunlockput(dp);
    80006098:	8526                	mv	a0,s1
    8000609a:	ffffe097          	auipc	ra,0xffffe
    8000609e:	3a2080e7          	jalr	930(ra) # 8000443c <iunlockput>
  ip->nlink--;
    800060a2:	04a95783          	lhu	a5,74(s2)
    800060a6:	37fd                	addiw	a5,a5,-1
    800060a8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800060ac:	854a                	mv	a0,s2
    800060ae:	ffffe097          	auipc	ra,0xffffe
    800060b2:	062080e7          	jalr	98(ra) # 80004110 <iupdate>
  iunlockput(ip);
    800060b6:	854a                	mv	a0,s2
    800060b8:	ffffe097          	auipc	ra,0xffffe
    800060bc:	384080e7          	jalr	900(ra) # 8000443c <iunlockput>
  end_op();
    800060c0:	fffff097          	auipc	ra,0xfffff
    800060c4:	b5c080e7          	jalr	-1188(ra) # 80004c1c <end_op>
  return 0;
    800060c8:	4501                	li	a0,0
    800060ca:	a84d                	j	8000617c <sys_unlink+0x1c4>
    end_op();
    800060cc:	fffff097          	auipc	ra,0xfffff
    800060d0:	b50080e7          	jalr	-1200(ra) # 80004c1c <end_op>
    return -1;
    800060d4:	557d                	li	a0,-1
    800060d6:	a05d                	j	8000617c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800060d8:	00002517          	auipc	a0,0x2
    800060dc:	62850513          	addi	a0,a0,1576 # 80008700 <syscalls+0x2d0>
    800060e0:	ffffa097          	auipc	ra,0xffffa
    800060e4:	45e080e7          	jalr	1118(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800060e8:	04c92703          	lw	a4,76(s2)
    800060ec:	02000793          	li	a5,32
    800060f0:	f6e7f9e3          	bgeu	a5,a4,80006062 <sys_unlink+0xaa>
    800060f4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800060f8:	4741                	li	a4,16
    800060fa:	86ce                	mv	a3,s3
    800060fc:	f1840613          	addi	a2,s0,-232
    80006100:	4581                	li	a1,0
    80006102:	854a                	mv	a0,s2
    80006104:	ffffe097          	auipc	ra,0xffffe
    80006108:	38a080e7          	jalr	906(ra) # 8000448e <readi>
    8000610c:	47c1                	li	a5,16
    8000610e:	00f51b63          	bne	a0,a5,80006124 <sys_unlink+0x16c>
    if(de.inum != 0)
    80006112:	f1845783          	lhu	a5,-232(s0)
    80006116:	e7a1                	bnez	a5,8000615e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006118:	29c1                	addiw	s3,s3,16
    8000611a:	04c92783          	lw	a5,76(s2)
    8000611e:	fcf9ede3          	bltu	s3,a5,800060f8 <sys_unlink+0x140>
    80006122:	b781                	j	80006062 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006124:	00002517          	auipc	a0,0x2
    80006128:	5f450513          	addi	a0,a0,1524 # 80008718 <syscalls+0x2e8>
    8000612c:	ffffa097          	auipc	ra,0xffffa
    80006130:	412080e7          	jalr	1042(ra) # 8000053e <panic>
    panic("unlink: writei");
    80006134:	00002517          	auipc	a0,0x2
    80006138:	5fc50513          	addi	a0,a0,1532 # 80008730 <syscalls+0x300>
    8000613c:	ffffa097          	auipc	ra,0xffffa
    80006140:	402080e7          	jalr	1026(ra) # 8000053e <panic>
    dp->nlink--;
    80006144:	04a4d783          	lhu	a5,74(s1)
    80006148:	37fd                	addiw	a5,a5,-1
    8000614a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000614e:	8526                	mv	a0,s1
    80006150:	ffffe097          	auipc	ra,0xffffe
    80006154:	fc0080e7          	jalr	-64(ra) # 80004110 <iupdate>
    80006158:	b781                	j	80006098 <sys_unlink+0xe0>
    return -1;
    8000615a:	557d                	li	a0,-1
    8000615c:	a005                	j	8000617c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000615e:	854a                	mv	a0,s2
    80006160:	ffffe097          	auipc	ra,0xffffe
    80006164:	2dc080e7          	jalr	732(ra) # 8000443c <iunlockput>
  iunlockput(dp);
    80006168:	8526                	mv	a0,s1
    8000616a:	ffffe097          	auipc	ra,0xffffe
    8000616e:	2d2080e7          	jalr	722(ra) # 8000443c <iunlockput>
  end_op();
    80006172:	fffff097          	auipc	ra,0xfffff
    80006176:	aaa080e7          	jalr	-1366(ra) # 80004c1c <end_op>
  return -1;
    8000617a:	557d                	li	a0,-1
}
    8000617c:	70ae                	ld	ra,232(sp)
    8000617e:	740e                	ld	s0,224(sp)
    80006180:	64ee                	ld	s1,216(sp)
    80006182:	694e                	ld	s2,208(sp)
    80006184:	69ae                	ld	s3,200(sp)
    80006186:	616d                	addi	sp,sp,240
    80006188:	8082                	ret

000000008000618a <sys_open>:

uint64
sys_open(void)
{
    8000618a:	7131                	addi	sp,sp,-192
    8000618c:	fd06                	sd	ra,184(sp)
    8000618e:	f922                	sd	s0,176(sp)
    80006190:	f526                	sd	s1,168(sp)
    80006192:	f14a                	sd	s2,160(sp)
    80006194:	ed4e                	sd	s3,152(sp)
    80006196:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80006198:	f4c40593          	addi	a1,s0,-180
    8000619c:	4505                	li	a0,1
    8000619e:	ffffd097          	auipc	ra,0xffffd
    800061a2:	33e080e7          	jalr	830(ra) # 800034dc <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800061a6:	08000613          	li	a2,128
    800061aa:	f5040593          	addi	a1,s0,-176
    800061ae:	4501                	li	a0,0
    800061b0:	ffffd097          	auipc	ra,0xffffd
    800061b4:	36c080e7          	jalr	876(ra) # 8000351c <argstr>
    800061b8:	87aa                	mv	a5,a0
    return -1;
    800061ba:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800061bc:	0a07c963          	bltz	a5,8000626e <sys_open+0xe4>

  begin_op();
    800061c0:	fffff097          	auipc	ra,0xfffff
    800061c4:	9dc080e7          	jalr	-1572(ra) # 80004b9c <begin_op>

  if(omode & O_CREATE){
    800061c8:	f4c42783          	lw	a5,-180(s0)
    800061cc:	2007f793          	andi	a5,a5,512
    800061d0:	cfc5                	beqz	a5,80006288 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800061d2:	4681                	li	a3,0
    800061d4:	4601                	li	a2,0
    800061d6:	4589                	li	a1,2
    800061d8:	f5040513          	addi	a0,s0,-176
    800061dc:	00000097          	auipc	ra,0x0
    800061e0:	968080e7          	jalr	-1688(ra) # 80005b44 <create>
    800061e4:	84aa                	mv	s1,a0
    if(ip == 0){
    800061e6:	c959                	beqz	a0,8000627c <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800061e8:	04449703          	lh	a4,68(s1)
    800061ec:	478d                	li	a5,3
    800061ee:	00f71763          	bne	a4,a5,800061fc <sys_open+0x72>
    800061f2:	0464d703          	lhu	a4,70(s1)
    800061f6:	47a5                	li	a5,9
    800061f8:	0ce7ed63          	bltu	a5,a4,800062d2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800061fc:	fffff097          	auipc	ra,0xfffff
    80006200:	db0080e7          	jalr	-592(ra) # 80004fac <filealloc>
    80006204:	89aa                	mv	s3,a0
    80006206:	10050363          	beqz	a0,8000630c <sys_open+0x182>
    8000620a:	00000097          	auipc	ra,0x0
    8000620e:	8f8080e7          	jalr	-1800(ra) # 80005b02 <fdalloc>
    80006212:	892a                	mv	s2,a0
    80006214:	0e054763          	bltz	a0,80006302 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006218:	04449703          	lh	a4,68(s1)
    8000621c:	478d                	li	a5,3
    8000621e:	0cf70563          	beq	a4,a5,800062e8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006222:	4789                	li	a5,2
    80006224:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006228:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000622c:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006230:	f4c42783          	lw	a5,-180(s0)
    80006234:	0017c713          	xori	a4,a5,1
    80006238:	8b05                	andi	a4,a4,1
    8000623a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000623e:	0037f713          	andi	a4,a5,3
    80006242:	00e03733          	snez	a4,a4
    80006246:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000624a:	4007f793          	andi	a5,a5,1024
    8000624e:	c791                	beqz	a5,8000625a <sys_open+0xd0>
    80006250:	04449703          	lh	a4,68(s1)
    80006254:	4789                	li	a5,2
    80006256:	0af70063          	beq	a4,a5,800062f6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000625a:	8526                	mv	a0,s1
    8000625c:	ffffe097          	auipc	ra,0xffffe
    80006260:	040080e7          	jalr	64(ra) # 8000429c <iunlock>
  end_op();
    80006264:	fffff097          	auipc	ra,0xfffff
    80006268:	9b8080e7          	jalr	-1608(ra) # 80004c1c <end_op>

  return fd;
    8000626c:	854a                	mv	a0,s2
}
    8000626e:	70ea                	ld	ra,184(sp)
    80006270:	744a                	ld	s0,176(sp)
    80006272:	74aa                	ld	s1,168(sp)
    80006274:	790a                	ld	s2,160(sp)
    80006276:	69ea                	ld	s3,152(sp)
    80006278:	6129                	addi	sp,sp,192
    8000627a:	8082                	ret
      end_op();
    8000627c:	fffff097          	auipc	ra,0xfffff
    80006280:	9a0080e7          	jalr	-1632(ra) # 80004c1c <end_op>
      return -1;
    80006284:	557d                	li	a0,-1
    80006286:	b7e5                	j	8000626e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006288:	f5040513          	addi	a0,s0,-176
    8000628c:	ffffe097          	auipc	ra,0xffffe
    80006290:	6f4080e7          	jalr	1780(ra) # 80004980 <namei>
    80006294:	84aa                	mv	s1,a0
    80006296:	c905                	beqz	a0,800062c6 <sys_open+0x13c>
    ilock(ip);
    80006298:	ffffe097          	auipc	ra,0xffffe
    8000629c:	f42080e7          	jalr	-190(ra) # 800041da <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800062a0:	04449703          	lh	a4,68(s1)
    800062a4:	4785                	li	a5,1
    800062a6:	f4f711e3          	bne	a4,a5,800061e8 <sys_open+0x5e>
    800062aa:	f4c42783          	lw	a5,-180(s0)
    800062ae:	d7b9                	beqz	a5,800061fc <sys_open+0x72>
      iunlockput(ip);
    800062b0:	8526                	mv	a0,s1
    800062b2:	ffffe097          	auipc	ra,0xffffe
    800062b6:	18a080e7          	jalr	394(ra) # 8000443c <iunlockput>
      end_op();
    800062ba:	fffff097          	auipc	ra,0xfffff
    800062be:	962080e7          	jalr	-1694(ra) # 80004c1c <end_op>
      return -1;
    800062c2:	557d                	li	a0,-1
    800062c4:	b76d                	j	8000626e <sys_open+0xe4>
      end_op();
    800062c6:	fffff097          	auipc	ra,0xfffff
    800062ca:	956080e7          	jalr	-1706(ra) # 80004c1c <end_op>
      return -1;
    800062ce:	557d                	li	a0,-1
    800062d0:	bf79                	j	8000626e <sys_open+0xe4>
    iunlockput(ip);
    800062d2:	8526                	mv	a0,s1
    800062d4:	ffffe097          	auipc	ra,0xffffe
    800062d8:	168080e7          	jalr	360(ra) # 8000443c <iunlockput>
    end_op();
    800062dc:	fffff097          	auipc	ra,0xfffff
    800062e0:	940080e7          	jalr	-1728(ra) # 80004c1c <end_op>
    return -1;
    800062e4:	557d                	li	a0,-1
    800062e6:	b761                	j	8000626e <sys_open+0xe4>
    f->type = FD_DEVICE;
    800062e8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800062ec:	04649783          	lh	a5,70(s1)
    800062f0:	02f99223          	sh	a5,36(s3)
    800062f4:	bf25                	j	8000622c <sys_open+0xa2>
    itrunc(ip);
    800062f6:	8526                	mv	a0,s1
    800062f8:	ffffe097          	auipc	ra,0xffffe
    800062fc:	ff0080e7          	jalr	-16(ra) # 800042e8 <itrunc>
    80006300:	bfa9                	j	8000625a <sys_open+0xd0>
      fileclose(f);
    80006302:	854e                	mv	a0,s3
    80006304:	fffff097          	auipc	ra,0xfffff
    80006308:	d64080e7          	jalr	-668(ra) # 80005068 <fileclose>
    iunlockput(ip);
    8000630c:	8526                	mv	a0,s1
    8000630e:	ffffe097          	auipc	ra,0xffffe
    80006312:	12e080e7          	jalr	302(ra) # 8000443c <iunlockput>
    end_op();
    80006316:	fffff097          	auipc	ra,0xfffff
    8000631a:	906080e7          	jalr	-1786(ra) # 80004c1c <end_op>
    return -1;
    8000631e:	557d                	li	a0,-1
    80006320:	b7b9                	j	8000626e <sys_open+0xe4>

0000000080006322 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006322:	7175                	addi	sp,sp,-144
    80006324:	e506                	sd	ra,136(sp)
    80006326:	e122                	sd	s0,128(sp)
    80006328:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000632a:	fffff097          	auipc	ra,0xfffff
    8000632e:	872080e7          	jalr	-1934(ra) # 80004b9c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006332:	08000613          	li	a2,128
    80006336:	f7040593          	addi	a1,s0,-144
    8000633a:	4501                	li	a0,0
    8000633c:	ffffd097          	auipc	ra,0xffffd
    80006340:	1e0080e7          	jalr	480(ra) # 8000351c <argstr>
    80006344:	02054963          	bltz	a0,80006376 <sys_mkdir+0x54>
    80006348:	4681                	li	a3,0
    8000634a:	4601                	li	a2,0
    8000634c:	4585                	li	a1,1
    8000634e:	f7040513          	addi	a0,s0,-144
    80006352:	fffff097          	auipc	ra,0xfffff
    80006356:	7f2080e7          	jalr	2034(ra) # 80005b44 <create>
    8000635a:	cd11                	beqz	a0,80006376 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000635c:	ffffe097          	auipc	ra,0xffffe
    80006360:	0e0080e7          	jalr	224(ra) # 8000443c <iunlockput>
  end_op();
    80006364:	fffff097          	auipc	ra,0xfffff
    80006368:	8b8080e7          	jalr	-1864(ra) # 80004c1c <end_op>
  return 0;
    8000636c:	4501                	li	a0,0
}
    8000636e:	60aa                	ld	ra,136(sp)
    80006370:	640a                	ld	s0,128(sp)
    80006372:	6149                	addi	sp,sp,144
    80006374:	8082                	ret
    end_op();
    80006376:	fffff097          	auipc	ra,0xfffff
    8000637a:	8a6080e7          	jalr	-1882(ra) # 80004c1c <end_op>
    return -1;
    8000637e:	557d                	li	a0,-1
    80006380:	b7fd                	j	8000636e <sys_mkdir+0x4c>

0000000080006382 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006382:	7135                	addi	sp,sp,-160
    80006384:	ed06                	sd	ra,152(sp)
    80006386:	e922                	sd	s0,144(sp)
    80006388:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000638a:	fffff097          	auipc	ra,0xfffff
    8000638e:	812080e7          	jalr	-2030(ra) # 80004b9c <begin_op>
  argint(1, &major);
    80006392:	f6c40593          	addi	a1,s0,-148
    80006396:	4505                	li	a0,1
    80006398:	ffffd097          	auipc	ra,0xffffd
    8000639c:	144080e7          	jalr	324(ra) # 800034dc <argint>
  argint(2, &minor);
    800063a0:	f6840593          	addi	a1,s0,-152
    800063a4:	4509                	li	a0,2
    800063a6:	ffffd097          	auipc	ra,0xffffd
    800063aa:	136080e7          	jalr	310(ra) # 800034dc <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800063ae:	08000613          	li	a2,128
    800063b2:	f7040593          	addi	a1,s0,-144
    800063b6:	4501                	li	a0,0
    800063b8:	ffffd097          	auipc	ra,0xffffd
    800063bc:	164080e7          	jalr	356(ra) # 8000351c <argstr>
    800063c0:	02054b63          	bltz	a0,800063f6 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800063c4:	f6841683          	lh	a3,-152(s0)
    800063c8:	f6c41603          	lh	a2,-148(s0)
    800063cc:	458d                	li	a1,3
    800063ce:	f7040513          	addi	a0,s0,-144
    800063d2:	fffff097          	auipc	ra,0xfffff
    800063d6:	772080e7          	jalr	1906(ra) # 80005b44 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800063da:	cd11                	beqz	a0,800063f6 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800063dc:	ffffe097          	auipc	ra,0xffffe
    800063e0:	060080e7          	jalr	96(ra) # 8000443c <iunlockput>
  end_op();
    800063e4:	fffff097          	auipc	ra,0xfffff
    800063e8:	838080e7          	jalr	-1992(ra) # 80004c1c <end_op>
  return 0;
    800063ec:	4501                	li	a0,0
}
    800063ee:	60ea                	ld	ra,152(sp)
    800063f0:	644a                	ld	s0,144(sp)
    800063f2:	610d                	addi	sp,sp,160
    800063f4:	8082                	ret
    end_op();
    800063f6:	fffff097          	auipc	ra,0xfffff
    800063fa:	826080e7          	jalr	-2010(ra) # 80004c1c <end_op>
    return -1;
    800063fe:	557d                	li	a0,-1
    80006400:	b7fd                	j	800063ee <sys_mknod+0x6c>

0000000080006402 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006402:	7135                	addi	sp,sp,-160
    80006404:	ed06                	sd	ra,152(sp)
    80006406:	e922                	sd	s0,144(sp)
    80006408:	e526                	sd	s1,136(sp)
    8000640a:	e14a                	sd	s2,128(sp)
    8000640c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000640e:	ffffb097          	auipc	ra,0xffffb
    80006412:	5ae080e7          	jalr	1454(ra) # 800019bc <myproc>
    80006416:	892a                	mv	s2,a0
  
  begin_op();
    80006418:	ffffe097          	auipc	ra,0xffffe
    8000641c:	784080e7          	jalr	1924(ra) # 80004b9c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006420:	08000613          	li	a2,128
    80006424:	f6040593          	addi	a1,s0,-160
    80006428:	4501                	li	a0,0
    8000642a:	ffffd097          	auipc	ra,0xffffd
    8000642e:	0f2080e7          	jalr	242(ra) # 8000351c <argstr>
    80006432:	04054b63          	bltz	a0,80006488 <sys_chdir+0x86>
    80006436:	f6040513          	addi	a0,s0,-160
    8000643a:	ffffe097          	auipc	ra,0xffffe
    8000643e:	546080e7          	jalr	1350(ra) # 80004980 <namei>
    80006442:	84aa                	mv	s1,a0
    80006444:	c131                	beqz	a0,80006488 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006446:	ffffe097          	auipc	ra,0xffffe
    8000644a:	d94080e7          	jalr	-620(ra) # 800041da <ilock>
  if(ip->type != T_DIR){
    8000644e:	04449703          	lh	a4,68(s1)
    80006452:	4785                	li	a5,1
    80006454:	04f71063          	bne	a4,a5,80006494 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006458:	8526                	mv	a0,s1
    8000645a:	ffffe097          	auipc	ra,0xffffe
    8000645e:	e42080e7          	jalr	-446(ra) # 8000429c <iunlock>
  iput(p->cwd);
    80006462:	15093503          	ld	a0,336(s2)
    80006466:	ffffe097          	auipc	ra,0xffffe
    8000646a:	f2e080e7          	jalr	-210(ra) # 80004394 <iput>
  end_op();
    8000646e:	ffffe097          	auipc	ra,0xffffe
    80006472:	7ae080e7          	jalr	1966(ra) # 80004c1c <end_op>
  p->cwd = ip;
    80006476:	14993823          	sd	s1,336(s2)
  return 0;
    8000647a:	4501                	li	a0,0
}
    8000647c:	60ea                	ld	ra,152(sp)
    8000647e:	644a                	ld	s0,144(sp)
    80006480:	64aa                	ld	s1,136(sp)
    80006482:	690a                	ld	s2,128(sp)
    80006484:	610d                	addi	sp,sp,160
    80006486:	8082                	ret
    end_op();
    80006488:	ffffe097          	auipc	ra,0xffffe
    8000648c:	794080e7          	jalr	1940(ra) # 80004c1c <end_op>
    return -1;
    80006490:	557d                	li	a0,-1
    80006492:	b7ed                	j	8000647c <sys_chdir+0x7a>
    iunlockput(ip);
    80006494:	8526                	mv	a0,s1
    80006496:	ffffe097          	auipc	ra,0xffffe
    8000649a:	fa6080e7          	jalr	-90(ra) # 8000443c <iunlockput>
    end_op();
    8000649e:	ffffe097          	auipc	ra,0xffffe
    800064a2:	77e080e7          	jalr	1918(ra) # 80004c1c <end_op>
    return -1;
    800064a6:	557d                	li	a0,-1
    800064a8:	bfd1                	j	8000647c <sys_chdir+0x7a>

00000000800064aa <sys_exec>:

uint64
sys_exec(void)
{
    800064aa:	7145                	addi	sp,sp,-464
    800064ac:	e786                	sd	ra,456(sp)
    800064ae:	e3a2                	sd	s0,448(sp)
    800064b0:	ff26                	sd	s1,440(sp)
    800064b2:	fb4a                	sd	s2,432(sp)
    800064b4:	f74e                	sd	s3,424(sp)
    800064b6:	f352                	sd	s4,416(sp)
    800064b8:	ef56                	sd	s5,408(sp)
    800064ba:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800064bc:	e3840593          	addi	a1,s0,-456
    800064c0:	4505                	li	a0,1
    800064c2:	ffffd097          	auipc	ra,0xffffd
    800064c6:	03a080e7          	jalr	58(ra) # 800034fc <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800064ca:	08000613          	li	a2,128
    800064ce:	f4040593          	addi	a1,s0,-192
    800064d2:	4501                	li	a0,0
    800064d4:	ffffd097          	auipc	ra,0xffffd
    800064d8:	048080e7          	jalr	72(ra) # 8000351c <argstr>
    800064dc:	87aa                	mv	a5,a0
    return -1;
    800064de:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800064e0:	0c07c263          	bltz	a5,800065a4 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800064e4:	10000613          	li	a2,256
    800064e8:	4581                	li	a1,0
    800064ea:	e4040513          	addi	a0,s0,-448
    800064ee:	ffffa097          	auipc	ra,0xffffa
    800064f2:	7e4080e7          	jalr	2020(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800064f6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800064fa:	89a6                	mv	s3,s1
    800064fc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800064fe:	02000a13          	li	s4,32
    80006502:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006506:	00391793          	slli	a5,s2,0x3
    8000650a:	e3040593          	addi	a1,s0,-464
    8000650e:	e3843503          	ld	a0,-456(s0)
    80006512:	953e                	add	a0,a0,a5
    80006514:	ffffd097          	auipc	ra,0xffffd
    80006518:	f2a080e7          	jalr	-214(ra) # 8000343e <fetchaddr>
    8000651c:	02054a63          	bltz	a0,80006550 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006520:	e3043783          	ld	a5,-464(s0)
    80006524:	c3b9                	beqz	a5,8000656a <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006526:	ffffa097          	auipc	ra,0xffffa
    8000652a:	5c0080e7          	jalr	1472(ra) # 80000ae6 <kalloc>
    8000652e:	85aa                	mv	a1,a0
    80006530:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006534:	cd11                	beqz	a0,80006550 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006536:	6605                	lui	a2,0x1
    80006538:	e3043503          	ld	a0,-464(s0)
    8000653c:	ffffd097          	auipc	ra,0xffffd
    80006540:	f54080e7          	jalr	-172(ra) # 80003490 <fetchstr>
    80006544:	00054663          	bltz	a0,80006550 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006548:	0905                	addi	s2,s2,1
    8000654a:	09a1                	addi	s3,s3,8
    8000654c:	fb491be3          	bne	s2,s4,80006502 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006550:	10048913          	addi	s2,s1,256
    80006554:	6088                	ld	a0,0(s1)
    80006556:	c531                	beqz	a0,800065a2 <sys_exec+0xf8>
    kfree(argv[i]);
    80006558:	ffffa097          	auipc	ra,0xffffa
    8000655c:	492080e7          	jalr	1170(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006560:	04a1                	addi	s1,s1,8
    80006562:	ff2499e3          	bne	s1,s2,80006554 <sys_exec+0xaa>
  return -1;
    80006566:	557d                	li	a0,-1
    80006568:	a835                	j	800065a4 <sys_exec+0xfa>
      argv[i] = 0;
    8000656a:	0a8e                	slli	s5,s5,0x3
    8000656c:	fc040793          	addi	a5,s0,-64
    80006570:	9abe                	add	s5,s5,a5
    80006572:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006576:	e4040593          	addi	a1,s0,-448
    8000657a:	f4040513          	addi	a0,s0,-192
    8000657e:	fffff097          	auipc	ra,0xfffff
    80006582:	164080e7          	jalr	356(ra) # 800056e2 <exec>
    80006586:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006588:	10048993          	addi	s3,s1,256
    8000658c:	6088                	ld	a0,0(s1)
    8000658e:	c901                	beqz	a0,8000659e <sys_exec+0xf4>
    kfree(argv[i]);
    80006590:	ffffa097          	auipc	ra,0xffffa
    80006594:	45a080e7          	jalr	1114(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006598:	04a1                	addi	s1,s1,8
    8000659a:	ff3499e3          	bne	s1,s3,8000658c <sys_exec+0xe2>
  return ret;
    8000659e:	854a                	mv	a0,s2
    800065a0:	a011                	j	800065a4 <sys_exec+0xfa>
  return -1;
    800065a2:	557d                	li	a0,-1
}
    800065a4:	60be                	ld	ra,456(sp)
    800065a6:	641e                	ld	s0,448(sp)
    800065a8:	74fa                	ld	s1,440(sp)
    800065aa:	795a                	ld	s2,432(sp)
    800065ac:	79ba                	ld	s3,424(sp)
    800065ae:	7a1a                	ld	s4,416(sp)
    800065b0:	6afa                	ld	s5,408(sp)
    800065b2:	6179                	addi	sp,sp,464
    800065b4:	8082                	ret

00000000800065b6 <sys_pipe>:

uint64
sys_pipe(void)
{
    800065b6:	7139                	addi	sp,sp,-64
    800065b8:	fc06                	sd	ra,56(sp)
    800065ba:	f822                	sd	s0,48(sp)
    800065bc:	f426                	sd	s1,40(sp)
    800065be:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800065c0:	ffffb097          	auipc	ra,0xffffb
    800065c4:	3fc080e7          	jalr	1020(ra) # 800019bc <myproc>
    800065c8:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800065ca:	fd840593          	addi	a1,s0,-40
    800065ce:	4501                	li	a0,0
    800065d0:	ffffd097          	auipc	ra,0xffffd
    800065d4:	f2c080e7          	jalr	-212(ra) # 800034fc <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800065d8:	fc840593          	addi	a1,s0,-56
    800065dc:	fd040513          	addi	a0,s0,-48
    800065e0:	fffff097          	auipc	ra,0xfffff
    800065e4:	db8080e7          	jalr	-584(ra) # 80005398 <pipealloc>
    return -1;
    800065e8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800065ea:	0c054463          	bltz	a0,800066b2 <sys_pipe+0xfc>
  fd0 = -1;
    800065ee:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800065f2:	fd043503          	ld	a0,-48(s0)
    800065f6:	fffff097          	auipc	ra,0xfffff
    800065fa:	50c080e7          	jalr	1292(ra) # 80005b02 <fdalloc>
    800065fe:	fca42223          	sw	a0,-60(s0)
    80006602:	08054b63          	bltz	a0,80006698 <sys_pipe+0xe2>
    80006606:	fc843503          	ld	a0,-56(s0)
    8000660a:	fffff097          	auipc	ra,0xfffff
    8000660e:	4f8080e7          	jalr	1272(ra) # 80005b02 <fdalloc>
    80006612:	fca42023          	sw	a0,-64(s0)
    80006616:	06054863          	bltz	a0,80006686 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000661a:	4691                	li	a3,4
    8000661c:	fc440613          	addi	a2,s0,-60
    80006620:	fd843583          	ld	a1,-40(s0)
    80006624:	68a8                	ld	a0,80(s1)
    80006626:	ffffb097          	auipc	ra,0xffffb
    8000662a:	052080e7          	jalr	82(ra) # 80001678 <copyout>
    8000662e:	02054063          	bltz	a0,8000664e <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006632:	4691                	li	a3,4
    80006634:	fc040613          	addi	a2,s0,-64
    80006638:	fd843583          	ld	a1,-40(s0)
    8000663c:	0591                	addi	a1,a1,4
    8000663e:	68a8                	ld	a0,80(s1)
    80006640:	ffffb097          	auipc	ra,0xffffb
    80006644:	038080e7          	jalr	56(ra) # 80001678 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006648:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000664a:	06055463          	bgez	a0,800066b2 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000664e:	fc442783          	lw	a5,-60(s0)
    80006652:	07e9                	addi	a5,a5,26
    80006654:	078e                	slli	a5,a5,0x3
    80006656:	97a6                	add	a5,a5,s1
    80006658:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000665c:	fc042503          	lw	a0,-64(s0)
    80006660:	0569                	addi	a0,a0,26
    80006662:	050e                	slli	a0,a0,0x3
    80006664:	94aa                	add	s1,s1,a0
    80006666:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000666a:	fd043503          	ld	a0,-48(s0)
    8000666e:	fffff097          	auipc	ra,0xfffff
    80006672:	9fa080e7          	jalr	-1542(ra) # 80005068 <fileclose>
    fileclose(wf);
    80006676:	fc843503          	ld	a0,-56(s0)
    8000667a:	fffff097          	auipc	ra,0xfffff
    8000667e:	9ee080e7          	jalr	-1554(ra) # 80005068 <fileclose>
    return -1;
    80006682:	57fd                	li	a5,-1
    80006684:	a03d                	j	800066b2 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006686:	fc442783          	lw	a5,-60(s0)
    8000668a:	0007c763          	bltz	a5,80006698 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000668e:	07e9                	addi	a5,a5,26
    80006690:	078e                	slli	a5,a5,0x3
    80006692:	94be                	add	s1,s1,a5
    80006694:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006698:	fd043503          	ld	a0,-48(s0)
    8000669c:	fffff097          	auipc	ra,0xfffff
    800066a0:	9cc080e7          	jalr	-1588(ra) # 80005068 <fileclose>
    fileclose(wf);
    800066a4:	fc843503          	ld	a0,-56(s0)
    800066a8:	fffff097          	auipc	ra,0xfffff
    800066ac:	9c0080e7          	jalr	-1600(ra) # 80005068 <fileclose>
    return -1;
    800066b0:	57fd                	li	a5,-1
}
    800066b2:	853e                	mv	a0,a5
    800066b4:	70e2                	ld	ra,56(sp)
    800066b6:	7442                	ld	s0,48(sp)
    800066b8:	74a2                	ld	s1,40(sp)
    800066ba:	6121                	addi	sp,sp,64
    800066bc:	8082                	ret
	...

00000000800066c0 <kernelvec>:
    800066c0:	7111                	addi	sp,sp,-256
    800066c2:	e006                	sd	ra,0(sp)
    800066c4:	e40a                	sd	sp,8(sp)
    800066c6:	e80e                	sd	gp,16(sp)
    800066c8:	ec12                	sd	tp,24(sp)
    800066ca:	f016                	sd	t0,32(sp)
    800066cc:	f41a                	sd	t1,40(sp)
    800066ce:	f81e                	sd	t2,48(sp)
    800066d0:	fc22                	sd	s0,56(sp)
    800066d2:	e0a6                	sd	s1,64(sp)
    800066d4:	e4aa                	sd	a0,72(sp)
    800066d6:	e8ae                	sd	a1,80(sp)
    800066d8:	ecb2                	sd	a2,88(sp)
    800066da:	f0b6                	sd	a3,96(sp)
    800066dc:	f4ba                	sd	a4,104(sp)
    800066de:	f8be                	sd	a5,112(sp)
    800066e0:	fcc2                	sd	a6,120(sp)
    800066e2:	e146                	sd	a7,128(sp)
    800066e4:	e54a                	sd	s2,136(sp)
    800066e6:	e94e                	sd	s3,144(sp)
    800066e8:	ed52                	sd	s4,152(sp)
    800066ea:	f156                	sd	s5,160(sp)
    800066ec:	f55a                	sd	s6,168(sp)
    800066ee:	f95e                	sd	s7,176(sp)
    800066f0:	fd62                	sd	s8,184(sp)
    800066f2:	e1e6                	sd	s9,192(sp)
    800066f4:	e5ea                	sd	s10,200(sp)
    800066f6:	e9ee                	sd	s11,208(sp)
    800066f8:	edf2                	sd	t3,216(sp)
    800066fa:	f1f6                	sd	t4,224(sp)
    800066fc:	f5fa                	sd	t5,232(sp)
    800066fe:	f9fe                	sd	t6,240(sp)
    80006700:	97ffc0ef          	jal	ra,8000307e <kerneltrap>
    80006704:	6082                	ld	ra,0(sp)
    80006706:	6122                	ld	sp,8(sp)
    80006708:	61c2                	ld	gp,16(sp)
    8000670a:	7282                	ld	t0,32(sp)
    8000670c:	7322                	ld	t1,40(sp)
    8000670e:	73c2                	ld	t2,48(sp)
    80006710:	7462                	ld	s0,56(sp)
    80006712:	6486                	ld	s1,64(sp)
    80006714:	6526                	ld	a0,72(sp)
    80006716:	65c6                	ld	a1,80(sp)
    80006718:	6666                	ld	a2,88(sp)
    8000671a:	7686                	ld	a3,96(sp)
    8000671c:	7726                	ld	a4,104(sp)
    8000671e:	77c6                	ld	a5,112(sp)
    80006720:	7866                	ld	a6,120(sp)
    80006722:	688a                	ld	a7,128(sp)
    80006724:	692a                	ld	s2,136(sp)
    80006726:	69ca                	ld	s3,144(sp)
    80006728:	6a6a                	ld	s4,152(sp)
    8000672a:	7a8a                	ld	s5,160(sp)
    8000672c:	7b2a                	ld	s6,168(sp)
    8000672e:	7bca                	ld	s7,176(sp)
    80006730:	7c6a                	ld	s8,184(sp)
    80006732:	6c8e                	ld	s9,192(sp)
    80006734:	6d2e                	ld	s10,200(sp)
    80006736:	6dce                	ld	s11,208(sp)
    80006738:	6e6e                	ld	t3,216(sp)
    8000673a:	7e8e                	ld	t4,224(sp)
    8000673c:	7f2e                	ld	t5,232(sp)
    8000673e:	7fce                	ld	t6,240(sp)
    80006740:	6111                	addi	sp,sp,256
    80006742:	10200073          	sret
    80006746:	00000013          	nop
    8000674a:	00000013          	nop
    8000674e:	0001                	nop

0000000080006750 <timervec>:
    80006750:	34051573          	csrrw	a0,mscratch,a0
    80006754:	e10c                	sd	a1,0(a0)
    80006756:	e510                	sd	a2,8(a0)
    80006758:	e914                	sd	a3,16(a0)
    8000675a:	6d0c                	ld	a1,24(a0)
    8000675c:	7110                	ld	a2,32(a0)
    8000675e:	6194                	ld	a3,0(a1)
    80006760:	96b2                	add	a3,a3,a2
    80006762:	e194                	sd	a3,0(a1)
    80006764:	4589                	li	a1,2
    80006766:	14459073          	csrw	sip,a1
    8000676a:	6914                	ld	a3,16(a0)
    8000676c:	6510                	ld	a2,8(a0)
    8000676e:	610c                	ld	a1,0(a0)
    80006770:	34051573          	csrrw	a0,mscratch,a0
    80006774:	30200073          	mret
	...

000000008000677a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000677a:	1141                	addi	sp,sp,-16
    8000677c:	e422                	sd	s0,8(sp)
    8000677e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006780:	0c0007b7          	lui	a5,0xc000
    80006784:	4705                	li	a4,1
    80006786:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006788:	c3d8                	sw	a4,4(a5)
}
    8000678a:	6422                	ld	s0,8(sp)
    8000678c:	0141                	addi	sp,sp,16
    8000678e:	8082                	ret

0000000080006790 <plicinithart>:

void
plicinithart(void)
{
    80006790:	1141                	addi	sp,sp,-16
    80006792:	e406                	sd	ra,8(sp)
    80006794:	e022                	sd	s0,0(sp)
    80006796:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006798:	ffffb097          	auipc	ra,0xffffb
    8000679c:	1f8080e7          	jalr	504(ra) # 80001990 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800067a0:	0085171b          	slliw	a4,a0,0x8
    800067a4:	0c0027b7          	lui	a5,0xc002
    800067a8:	97ba                	add	a5,a5,a4
    800067aa:	40200713          	li	a4,1026
    800067ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800067b2:	00d5151b          	slliw	a0,a0,0xd
    800067b6:	0c2017b7          	lui	a5,0xc201
    800067ba:	953e                	add	a0,a0,a5
    800067bc:	00052023          	sw	zero,0(a0)
}
    800067c0:	60a2                	ld	ra,8(sp)
    800067c2:	6402                	ld	s0,0(sp)
    800067c4:	0141                	addi	sp,sp,16
    800067c6:	8082                	ret

00000000800067c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800067c8:	1141                	addi	sp,sp,-16
    800067ca:	e406                	sd	ra,8(sp)
    800067cc:	e022                	sd	s0,0(sp)
    800067ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800067d0:	ffffb097          	auipc	ra,0xffffb
    800067d4:	1c0080e7          	jalr	448(ra) # 80001990 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800067d8:	00d5179b          	slliw	a5,a0,0xd
    800067dc:	0c201537          	lui	a0,0xc201
    800067e0:	953e                	add	a0,a0,a5
  return irq;
}
    800067e2:	4148                	lw	a0,4(a0)
    800067e4:	60a2                	ld	ra,8(sp)
    800067e6:	6402                	ld	s0,0(sp)
    800067e8:	0141                	addi	sp,sp,16
    800067ea:	8082                	ret

00000000800067ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800067ec:	1101                	addi	sp,sp,-32
    800067ee:	ec06                	sd	ra,24(sp)
    800067f0:	e822                	sd	s0,16(sp)
    800067f2:	e426                	sd	s1,8(sp)
    800067f4:	1000                	addi	s0,sp,32
    800067f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800067f8:	ffffb097          	auipc	ra,0xffffb
    800067fc:	198080e7          	jalr	408(ra) # 80001990 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006800:	00d5151b          	slliw	a0,a0,0xd
    80006804:	0c2017b7          	lui	a5,0xc201
    80006808:	97aa                	add	a5,a5,a0
    8000680a:	c3c4                	sw	s1,4(a5)
}
    8000680c:	60e2                	ld	ra,24(sp)
    8000680e:	6442                	ld	s0,16(sp)
    80006810:	64a2                	ld	s1,8(sp)
    80006812:	6105                	addi	sp,sp,32
    80006814:	8082                	ret

0000000080006816 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006816:	1141                	addi	sp,sp,-16
    80006818:	e406                	sd	ra,8(sp)
    8000681a:	e022                	sd	s0,0(sp)
    8000681c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000681e:	479d                	li	a5,7
    80006820:	04a7cc63          	blt	a5,a0,80006878 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006824:	007bd797          	auipc	a5,0x7bd
    80006828:	62c78793          	addi	a5,a5,1580 # 807c3e50 <disk>
    8000682c:	97aa                	add	a5,a5,a0
    8000682e:	0187c783          	lbu	a5,24(a5)
    80006832:	ebb9                	bnez	a5,80006888 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006834:	00451613          	slli	a2,a0,0x4
    80006838:	007bd797          	auipc	a5,0x7bd
    8000683c:	61878793          	addi	a5,a5,1560 # 807c3e50 <disk>
    80006840:	6394                	ld	a3,0(a5)
    80006842:	96b2                	add	a3,a3,a2
    80006844:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006848:	6398                	ld	a4,0(a5)
    8000684a:	9732                	add	a4,a4,a2
    8000684c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006850:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006854:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006858:	953e                	add	a0,a0,a5
    8000685a:	4785                	li	a5,1
    8000685c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006860:	007bd517          	auipc	a0,0x7bd
    80006864:	60850513          	addi	a0,a0,1544 # 807c3e68 <disk+0x18>
    80006868:	ffffc097          	auipc	ra,0xffffc
    8000686c:	a48080e7          	jalr	-1464(ra) # 800022b0 <wakeup>
}
    80006870:	60a2                	ld	ra,8(sp)
    80006872:	6402                	ld	s0,0(sp)
    80006874:	0141                	addi	sp,sp,16
    80006876:	8082                	ret
    panic("free_desc 1");
    80006878:	00002517          	auipc	a0,0x2
    8000687c:	ec850513          	addi	a0,a0,-312 # 80008740 <syscalls+0x310>
    80006880:	ffffa097          	auipc	ra,0xffffa
    80006884:	cbe080e7          	jalr	-834(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006888:	00002517          	auipc	a0,0x2
    8000688c:	ec850513          	addi	a0,a0,-312 # 80008750 <syscalls+0x320>
    80006890:	ffffa097          	auipc	ra,0xffffa
    80006894:	cae080e7          	jalr	-850(ra) # 8000053e <panic>

0000000080006898 <virtio_disk_init>:
{
    80006898:	1101                	addi	sp,sp,-32
    8000689a:	ec06                	sd	ra,24(sp)
    8000689c:	e822                	sd	s0,16(sp)
    8000689e:	e426                	sd	s1,8(sp)
    800068a0:	e04a                	sd	s2,0(sp)
    800068a2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800068a4:	00002597          	auipc	a1,0x2
    800068a8:	ebc58593          	addi	a1,a1,-324 # 80008760 <syscalls+0x330>
    800068ac:	007bd517          	auipc	a0,0x7bd
    800068b0:	6cc50513          	addi	a0,a0,1740 # 807c3f78 <disk+0x128>
    800068b4:	ffffa097          	auipc	ra,0xffffa
    800068b8:	292080e7          	jalr	658(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800068bc:	100017b7          	lui	a5,0x10001
    800068c0:	4398                	lw	a4,0(a5)
    800068c2:	2701                	sext.w	a4,a4
    800068c4:	747277b7          	lui	a5,0x74727
    800068c8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800068cc:	14f71c63          	bne	a4,a5,80006a24 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800068d0:	100017b7          	lui	a5,0x10001
    800068d4:	43dc                	lw	a5,4(a5)
    800068d6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800068d8:	4709                	li	a4,2
    800068da:	14e79563          	bne	a5,a4,80006a24 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800068de:	100017b7          	lui	a5,0x10001
    800068e2:	479c                	lw	a5,8(a5)
    800068e4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800068e6:	12e79f63          	bne	a5,a4,80006a24 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800068ea:	100017b7          	lui	a5,0x10001
    800068ee:	47d8                	lw	a4,12(a5)
    800068f0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800068f2:	554d47b7          	lui	a5,0x554d4
    800068f6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800068fa:	12f71563          	bne	a4,a5,80006a24 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    800068fe:	100017b7          	lui	a5,0x10001
    80006902:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006906:	4705                	li	a4,1
    80006908:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000690a:	470d                	li	a4,3
    8000690c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000690e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006910:	c7ffe737          	lui	a4,0xc7ffe
    80006914:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff4783a7cf>
    80006918:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000691a:	2701                	sext.w	a4,a4
    8000691c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000691e:	472d                	li	a4,11
    80006920:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006922:	5bbc                	lw	a5,112(a5)
    80006924:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006928:	8ba1                	andi	a5,a5,8
    8000692a:	10078563          	beqz	a5,80006a34 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000692e:	100017b7          	lui	a5,0x10001
    80006932:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006936:	43fc                	lw	a5,68(a5)
    80006938:	2781                	sext.w	a5,a5
    8000693a:	10079563          	bnez	a5,80006a44 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000693e:	100017b7          	lui	a5,0x10001
    80006942:	5bdc                	lw	a5,52(a5)
    80006944:	2781                	sext.w	a5,a5
  if(max == 0)
    80006946:	10078763          	beqz	a5,80006a54 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000694a:	471d                	li	a4,7
    8000694c:	10f77c63          	bgeu	a4,a5,80006a64 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006950:	ffffa097          	auipc	ra,0xffffa
    80006954:	196080e7          	jalr	406(ra) # 80000ae6 <kalloc>
    80006958:	007bd497          	auipc	s1,0x7bd
    8000695c:	4f848493          	addi	s1,s1,1272 # 807c3e50 <disk>
    80006960:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006962:	ffffa097          	auipc	ra,0xffffa
    80006966:	184080e7          	jalr	388(ra) # 80000ae6 <kalloc>
    8000696a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000696c:	ffffa097          	auipc	ra,0xffffa
    80006970:	17a080e7          	jalr	378(ra) # 80000ae6 <kalloc>
    80006974:	87aa                	mv	a5,a0
    80006976:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006978:	6088                	ld	a0,0(s1)
    8000697a:	cd6d                	beqz	a0,80006a74 <virtio_disk_init+0x1dc>
    8000697c:	007bd717          	auipc	a4,0x7bd
    80006980:	4dc73703          	ld	a4,1244(a4) # 807c3e58 <disk+0x8>
    80006984:	cb65                	beqz	a4,80006a74 <virtio_disk_init+0x1dc>
    80006986:	c7fd                	beqz	a5,80006a74 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006988:	6605                	lui	a2,0x1
    8000698a:	4581                	li	a1,0
    8000698c:	ffffa097          	auipc	ra,0xffffa
    80006990:	346080e7          	jalr	838(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006994:	007bd497          	auipc	s1,0x7bd
    80006998:	4bc48493          	addi	s1,s1,1212 # 807c3e50 <disk>
    8000699c:	6605                	lui	a2,0x1
    8000699e:	4581                	li	a1,0
    800069a0:	6488                	ld	a0,8(s1)
    800069a2:	ffffa097          	auipc	ra,0xffffa
    800069a6:	330080e7          	jalr	816(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800069aa:	6605                	lui	a2,0x1
    800069ac:	4581                	li	a1,0
    800069ae:	6888                	ld	a0,16(s1)
    800069b0:	ffffa097          	auipc	ra,0xffffa
    800069b4:	322080e7          	jalr	802(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800069b8:	100017b7          	lui	a5,0x10001
    800069bc:	4721                	li	a4,8
    800069be:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800069c0:	4098                	lw	a4,0(s1)
    800069c2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800069c6:	40d8                	lw	a4,4(s1)
    800069c8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800069cc:	6498                	ld	a4,8(s1)
    800069ce:	0007069b          	sext.w	a3,a4
    800069d2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800069d6:	9701                	srai	a4,a4,0x20
    800069d8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800069dc:	6898                	ld	a4,16(s1)
    800069de:	0007069b          	sext.w	a3,a4
    800069e2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800069e6:	9701                	srai	a4,a4,0x20
    800069e8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800069ec:	4705                	li	a4,1
    800069ee:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800069f0:	00e48c23          	sb	a4,24(s1)
    800069f4:	00e48ca3          	sb	a4,25(s1)
    800069f8:	00e48d23          	sb	a4,26(s1)
    800069fc:	00e48da3          	sb	a4,27(s1)
    80006a00:	00e48e23          	sb	a4,28(s1)
    80006a04:	00e48ea3          	sb	a4,29(s1)
    80006a08:	00e48f23          	sb	a4,30(s1)
    80006a0c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006a10:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a14:	0727a823          	sw	s2,112(a5)
}
    80006a18:	60e2                	ld	ra,24(sp)
    80006a1a:	6442                	ld	s0,16(sp)
    80006a1c:	64a2                	ld	s1,8(sp)
    80006a1e:	6902                	ld	s2,0(sp)
    80006a20:	6105                	addi	sp,sp,32
    80006a22:	8082                	ret
    panic("could not find virtio disk");
    80006a24:	00002517          	auipc	a0,0x2
    80006a28:	d4c50513          	addi	a0,a0,-692 # 80008770 <syscalls+0x340>
    80006a2c:	ffffa097          	auipc	ra,0xffffa
    80006a30:	b12080e7          	jalr	-1262(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006a34:	00002517          	auipc	a0,0x2
    80006a38:	d5c50513          	addi	a0,a0,-676 # 80008790 <syscalls+0x360>
    80006a3c:	ffffa097          	auipc	ra,0xffffa
    80006a40:	b02080e7          	jalr	-1278(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006a44:	00002517          	auipc	a0,0x2
    80006a48:	d6c50513          	addi	a0,a0,-660 # 800087b0 <syscalls+0x380>
    80006a4c:	ffffa097          	auipc	ra,0xffffa
    80006a50:	af2080e7          	jalr	-1294(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006a54:	00002517          	auipc	a0,0x2
    80006a58:	d7c50513          	addi	a0,a0,-644 # 800087d0 <syscalls+0x3a0>
    80006a5c:	ffffa097          	auipc	ra,0xffffa
    80006a60:	ae2080e7          	jalr	-1310(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006a64:	00002517          	auipc	a0,0x2
    80006a68:	d8c50513          	addi	a0,a0,-628 # 800087f0 <syscalls+0x3c0>
    80006a6c:	ffffa097          	auipc	ra,0xffffa
    80006a70:	ad2080e7          	jalr	-1326(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006a74:	00002517          	auipc	a0,0x2
    80006a78:	d9c50513          	addi	a0,a0,-612 # 80008810 <syscalls+0x3e0>
    80006a7c:	ffffa097          	auipc	ra,0xffffa
    80006a80:	ac2080e7          	jalr	-1342(ra) # 8000053e <panic>

0000000080006a84 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006a84:	7119                	addi	sp,sp,-128
    80006a86:	fc86                	sd	ra,120(sp)
    80006a88:	f8a2                	sd	s0,112(sp)
    80006a8a:	f4a6                	sd	s1,104(sp)
    80006a8c:	f0ca                	sd	s2,96(sp)
    80006a8e:	ecce                	sd	s3,88(sp)
    80006a90:	e8d2                	sd	s4,80(sp)
    80006a92:	e4d6                	sd	s5,72(sp)
    80006a94:	e0da                	sd	s6,64(sp)
    80006a96:	fc5e                	sd	s7,56(sp)
    80006a98:	f862                	sd	s8,48(sp)
    80006a9a:	f466                	sd	s9,40(sp)
    80006a9c:	f06a                	sd	s10,32(sp)
    80006a9e:	ec6e                	sd	s11,24(sp)
    80006aa0:	0100                	addi	s0,sp,128
    80006aa2:	8aaa                	mv	s5,a0
    80006aa4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006aa6:	00c52d03          	lw	s10,12(a0)
    80006aaa:	001d1d1b          	slliw	s10,s10,0x1
    80006aae:	1d02                	slli	s10,s10,0x20
    80006ab0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006ab4:	007bd517          	auipc	a0,0x7bd
    80006ab8:	4c450513          	addi	a0,a0,1220 # 807c3f78 <disk+0x128>
    80006abc:	ffffa097          	auipc	ra,0xffffa
    80006ac0:	11a080e7          	jalr	282(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006ac4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006ac6:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006ac8:	007bdb97          	auipc	s7,0x7bd
    80006acc:	388b8b93          	addi	s7,s7,904 # 807c3e50 <disk>
  for(int i = 0; i < 3; i++){
    80006ad0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006ad2:	007bdc97          	auipc	s9,0x7bd
    80006ad6:	4a6c8c93          	addi	s9,s9,1190 # 807c3f78 <disk+0x128>
    80006ada:	a08d                	j	80006b3c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006adc:	00fb8733          	add	a4,s7,a5
    80006ae0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006ae4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006ae6:	0207c563          	bltz	a5,80006b10 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006aea:	2905                	addiw	s2,s2,1
    80006aec:	0611                	addi	a2,a2,4
    80006aee:	05690c63          	beq	s2,s6,80006b46 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006af2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006af4:	007bd717          	auipc	a4,0x7bd
    80006af8:	35c70713          	addi	a4,a4,860 # 807c3e50 <disk>
    80006afc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006afe:	01874683          	lbu	a3,24(a4)
    80006b02:	fee9                	bnez	a3,80006adc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006b04:	2785                	addiw	a5,a5,1
    80006b06:	0705                	addi	a4,a4,1
    80006b08:	fe979be3          	bne	a5,s1,80006afe <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006b0c:	57fd                	li	a5,-1
    80006b0e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006b10:	01205d63          	blez	s2,80006b2a <virtio_disk_rw+0xa6>
    80006b14:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006b16:	000a2503          	lw	a0,0(s4)
    80006b1a:	00000097          	auipc	ra,0x0
    80006b1e:	cfc080e7          	jalr	-772(ra) # 80006816 <free_desc>
      for(int j = 0; j < i; j++)
    80006b22:	2d85                	addiw	s11,s11,1
    80006b24:	0a11                	addi	s4,s4,4
    80006b26:	ffb918e3          	bne	s2,s11,80006b16 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006b2a:	85e6                	mv	a1,s9
    80006b2c:	007bd517          	auipc	a0,0x7bd
    80006b30:	33c50513          	addi	a0,a0,828 # 807c3e68 <disk+0x18>
    80006b34:	ffffb097          	auipc	ra,0xffffb
    80006b38:	718080e7          	jalr	1816(ra) # 8000224c <sleep>
  for(int i = 0; i < 3; i++){
    80006b3c:	f8040a13          	addi	s4,s0,-128
{
    80006b40:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006b42:	894e                	mv	s2,s3
    80006b44:	b77d                	j	80006af2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006b46:	f8042583          	lw	a1,-128(s0)
    80006b4a:	00a58793          	addi	a5,a1,10
    80006b4e:	0792                	slli	a5,a5,0x4

  if(write)
    80006b50:	007bd617          	auipc	a2,0x7bd
    80006b54:	30060613          	addi	a2,a2,768 # 807c3e50 <disk>
    80006b58:	00f60733          	add	a4,a2,a5
    80006b5c:	018036b3          	snez	a3,s8
    80006b60:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006b62:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006b66:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006b6a:	f6078693          	addi	a3,a5,-160
    80006b6e:	6218                	ld	a4,0(a2)
    80006b70:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006b72:	00878513          	addi	a0,a5,8
    80006b76:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006b78:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006b7a:	6208                	ld	a0,0(a2)
    80006b7c:	96aa                	add	a3,a3,a0
    80006b7e:	4741                	li	a4,16
    80006b80:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006b82:	4705                	li	a4,1
    80006b84:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006b88:	f8442703          	lw	a4,-124(s0)
    80006b8c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006b90:	0712                	slli	a4,a4,0x4
    80006b92:	953a                	add	a0,a0,a4
    80006b94:	058a8693          	addi	a3,s5,88
    80006b98:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80006b9a:	6208                	ld	a0,0(a2)
    80006b9c:	972a                	add	a4,a4,a0
    80006b9e:	40000693          	li	a3,1024
    80006ba2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006ba4:	001c3c13          	seqz	s8,s8
    80006ba8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006baa:	001c6c13          	ori	s8,s8,1
    80006bae:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006bb2:	f8842603          	lw	a2,-120(s0)
    80006bb6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006bba:	007bd697          	auipc	a3,0x7bd
    80006bbe:	29668693          	addi	a3,a3,662 # 807c3e50 <disk>
    80006bc2:	00258713          	addi	a4,a1,2
    80006bc6:	0712                	slli	a4,a4,0x4
    80006bc8:	9736                	add	a4,a4,a3
    80006bca:	587d                	li	a6,-1
    80006bcc:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006bd0:	0612                	slli	a2,a2,0x4
    80006bd2:	9532                	add	a0,a0,a2
    80006bd4:	f9078793          	addi	a5,a5,-112
    80006bd8:	97b6                	add	a5,a5,a3
    80006bda:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    80006bdc:	629c                	ld	a5,0(a3)
    80006bde:	97b2                	add	a5,a5,a2
    80006be0:	4605                	li	a2,1
    80006be2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006be4:	4509                	li	a0,2
    80006be6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    80006bea:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006bee:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006bf2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006bf6:	6698                	ld	a4,8(a3)
    80006bf8:	00275783          	lhu	a5,2(a4)
    80006bfc:	8b9d                	andi	a5,a5,7
    80006bfe:	0786                	slli	a5,a5,0x1
    80006c00:	97ba                	add	a5,a5,a4
    80006c02:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006c06:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006c0a:	6698                	ld	a4,8(a3)
    80006c0c:	00275783          	lhu	a5,2(a4)
    80006c10:	2785                	addiw	a5,a5,1
    80006c12:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006c16:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006c1a:	100017b7          	lui	a5,0x10001
    80006c1e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006c22:	004aa783          	lw	a5,4(s5)
    80006c26:	02c79163          	bne	a5,a2,80006c48 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006c2a:	007bd917          	auipc	s2,0x7bd
    80006c2e:	34e90913          	addi	s2,s2,846 # 807c3f78 <disk+0x128>
  while(b->disk == 1) {
    80006c32:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006c34:	85ca                	mv	a1,s2
    80006c36:	8556                	mv	a0,s5
    80006c38:	ffffb097          	auipc	ra,0xffffb
    80006c3c:	614080e7          	jalr	1556(ra) # 8000224c <sleep>
  while(b->disk == 1) {
    80006c40:	004aa783          	lw	a5,4(s5)
    80006c44:	fe9788e3          	beq	a5,s1,80006c34 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006c48:	f8042903          	lw	s2,-128(s0)
    80006c4c:	00290793          	addi	a5,s2,2
    80006c50:	00479713          	slli	a4,a5,0x4
    80006c54:	007bd797          	auipc	a5,0x7bd
    80006c58:	1fc78793          	addi	a5,a5,508 # 807c3e50 <disk>
    80006c5c:	97ba                	add	a5,a5,a4
    80006c5e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006c62:	007bd997          	auipc	s3,0x7bd
    80006c66:	1ee98993          	addi	s3,s3,494 # 807c3e50 <disk>
    80006c6a:	00491713          	slli	a4,s2,0x4
    80006c6e:	0009b783          	ld	a5,0(s3)
    80006c72:	97ba                	add	a5,a5,a4
    80006c74:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006c78:	854a                	mv	a0,s2
    80006c7a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006c7e:	00000097          	auipc	ra,0x0
    80006c82:	b98080e7          	jalr	-1128(ra) # 80006816 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006c86:	8885                	andi	s1,s1,1
    80006c88:	f0ed                	bnez	s1,80006c6a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006c8a:	007bd517          	auipc	a0,0x7bd
    80006c8e:	2ee50513          	addi	a0,a0,750 # 807c3f78 <disk+0x128>
    80006c92:	ffffa097          	auipc	ra,0xffffa
    80006c96:	ff8080e7          	jalr	-8(ra) # 80000c8a <release>
}
    80006c9a:	70e6                	ld	ra,120(sp)
    80006c9c:	7446                	ld	s0,112(sp)
    80006c9e:	74a6                	ld	s1,104(sp)
    80006ca0:	7906                	ld	s2,96(sp)
    80006ca2:	69e6                	ld	s3,88(sp)
    80006ca4:	6a46                	ld	s4,80(sp)
    80006ca6:	6aa6                	ld	s5,72(sp)
    80006ca8:	6b06                	ld	s6,64(sp)
    80006caa:	7be2                	ld	s7,56(sp)
    80006cac:	7c42                	ld	s8,48(sp)
    80006cae:	7ca2                	ld	s9,40(sp)
    80006cb0:	7d02                	ld	s10,32(sp)
    80006cb2:	6de2                	ld	s11,24(sp)
    80006cb4:	6109                	addi	sp,sp,128
    80006cb6:	8082                	ret

0000000080006cb8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006cb8:	1101                	addi	sp,sp,-32
    80006cba:	ec06                	sd	ra,24(sp)
    80006cbc:	e822                	sd	s0,16(sp)
    80006cbe:	e426                	sd	s1,8(sp)
    80006cc0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006cc2:	007bd497          	auipc	s1,0x7bd
    80006cc6:	18e48493          	addi	s1,s1,398 # 807c3e50 <disk>
    80006cca:	007bd517          	auipc	a0,0x7bd
    80006cce:	2ae50513          	addi	a0,a0,686 # 807c3f78 <disk+0x128>
    80006cd2:	ffffa097          	auipc	ra,0xffffa
    80006cd6:	f04080e7          	jalr	-252(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006cda:	10001737          	lui	a4,0x10001
    80006cde:	533c                	lw	a5,96(a4)
    80006ce0:	8b8d                	andi	a5,a5,3
    80006ce2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006ce4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006ce8:	689c                	ld	a5,16(s1)
    80006cea:	0204d703          	lhu	a4,32(s1)
    80006cee:	0027d783          	lhu	a5,2(a5)
    80006cf2:	04f70863          	beq	a4,a5,80006d42 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006cf6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006cfa:	6898                	ld	a4,16(s1)
    80006cfc:	0204d783          	lhu	a5,32(s1)
    80006d00:	8b9d                	andi	a5,a5,7
    80006d02:	078e                	slli	a5,a5,0x3
    80006d04:	97ba                	add	a5,a5,a4
    80006d06:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006d08:	00278713          	addi	a4,a5,2
    80006d0c:	0712                	slli	a4,a4,0x4
    80006d0e:	9726                	add	a4,a4,s1
    80006d10:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006d14:	e721                	bnez	a4,80006d5c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006d16:	0789                	addi	a5,a5,2
    80006d18:	0792                	slli	a5,a5,0x4
    80006d1a:	97a6                	add	a5,a5,s1
    80006d1c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006d1e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006d22:	ffffb097          	auipc	ra,0xffffb
    80006d26:	58e080e7          	jalr	1422(ra) # 800022b0 <wakeup>

    disk.used_idx += 1;
    80006d2a:	0204d783          	lhu	a5,32(s1)
    80006d2e:	2785                	addiw	a5,a5,1
    80006d30:	17c2                	slli	a5,a5,0x30
    80006d32:	93c1                	srli	a5,a5,0x30
    80006d34:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006d38:	6898                	ld	a4,16(s1)
    80006d3a:	00275703          	lhu	a4,2(a4)
    80006d3e:	faf71ce3          	bne	a4,a5,80006cf6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006d42:	007bd517          	auipc	a0,0x7bd
    80006d46:	23650513          	addi	a0,a0,566 # 807c3f78 <disk+0x128>
    80006d4a:	ffffa097          	auipc	ra,0xffffa
    80006d4e:	f40080e7          	jalr	-192(ra) # 80000c8a <release>
}
    80006d52:	60e2                	ld	ra,24(sp)
    80006d54:	6442                	ld	s0,16(sp)
    80006d56:	64a2                	ld	s1,8(sp)
    80006d58:	6105                	addi	sp,sp,32
    80006d5a:	8082                	ret
      panic("virtio_disk_intr status");
    80006d5c:	00002517          	auipc	a0,0x2
    80006d60:	acc50513          	addi	a0,a0,-1332 # 80008828 <syscalls+0x3f8>
    80006d64:	ffff9097          	auipc	ra,0xffff9
    80006d68:	7da080e7          	jalr	2010(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
