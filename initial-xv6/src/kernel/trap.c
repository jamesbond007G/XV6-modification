#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
ptrtotrapframe arr_of_trapframes_storing_past[1000010];

struct spinlock tickslock;
uint ticks;

extern char trampoline[], uservec[], userret[];

// in kernelvec.S, calls kerneltrap().
void kernelvec();

extern int devintr();

void trapinit(void)
{
  initlock(&tickslock, "time");
}

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
  w_stvec((uint64)kernelvec);
}

//
// handle an interrupt, exception, or system call from user space.
// called from trampoline.S
//
int min(int a, int b)
{
  if (a < b)
  {
    return a;
  }
  else
  {
    return b;
  }
}
void usertrap(void)
{
  int which_dev = 0;

  if ((r_sstatus() & SSTATUS_SPP) != 0)
    panic("usertrap: not from user mode");

  // send interrupts and exceptions to kerneltrap(),
  // since we're now in the kernel.
  w_stvec((uint64)kernelvec);

  struct proc *p = myproc();

  // save user program counter.
  p->trapframe->epc = r_sepc();

  if (r_scause() == 8)
  {
    // system call

    if (killed(p))
      exit(-1);

    // sepc points to the ecall instruction,
    // but we want to return to the next instruction.
    p->trapframe->epc += 4;

    // an interrupt will change sepc, scause, and sstatus,
    // so enable only now that we're done with those registers.
    intr_on();

    syscall();
  }
  else if ((which_dev = devintr()) != 0)
  {
  }
  else
  {
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    setkilled(p);
  }

  if (killed(p))
    exit(-1);

  // give up the CPU if this is a timer interrupt.
  if (which_dev == 2)
  {
    printf("%d %d %d\n", ticks, p->pid, p->queue);

    myproc()->passed_ticks++;
    // printf("Yes %d %d\n", myproc()->passed_ticks, myproc()->no_of_ticks);
    if (myproc()->passed_ticks % myproc()->no_of_ticks == 0)
    {
      if (myproc()->flag_check_handler == 0)
      {
        myproc()->flag_check_handler = 1;
        // myproc()->
        // myproc()->past_trap_frame = kalloc();
        arr_of_trapframes_storing_past[myproc()->pid] = kalloc();
        memmove(arr_of_trapframes_storing_past[myproc()->pid], myproc()->trapframe, PGSIZE);
        p->trapframe->epc = myproc()->handler;
      }
    }

#ifdef RR
    yield();
#endif
#ifdef FCFS
#endif
#ifdef MLFQ

    // procdump();
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        p->wait++;
      }
      else if (p->state == RUNNING)
      {
        p->ticks_when_switch++;
      }
      release(&p->lock);
    }
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        if ((p->wait >= 30) && p->queue > 0)
        {
          if (p->pid >= 9)
          {
            printf("%d %d %d\n", ticks - 1,p->pid, p->queue);
            // printf("%d %d %d before promtotion\n", ticks - 1, p->pid, p->queue);
          }

          p->queue--;

          if (p->pid >= 9)
          {
            printf("%d %d %d after promotion\n", ticks, p->pid, p->queue);
          }
          p->new_flag = 0;
          p->ticks_when_switch = 0;
          p->wait = 0;
        }
      }
      release(&p->lock);
    }
    int current_level = myproc()->queue;
    for (int i = 0; i < current_level; i++)
    {
      for (p = proc; p < &proc[NPROC]; p++)
      {
        // acquire(&p->lock);

        if (p->state == RUNNABLE && p->queue == i)
        {
          // Switch to chosen process.  It is the process's job
          // to release its lock and then reacquire it
          // before jumping back to us.
          // p->state = RUNNING;
          // c->proc = p;
          // swtch(&c->context, &p->context);
          // if (myproc()->queue<3)
          // {
          //   myproc()->queue++;
          // }
          // release(&p->lock);
          // printf("pidc = %d %d\n", myproc()->ticks_when_switch, myproc()->pid);
          myproc()->new_flag = 1;
          yield();

          // break;
          // Process is done running for now.
          // It should have changed its p->state before coming back.
          // c->proc = 0;
        }
        // release(&p->lock);
      }
    }
    int queu_of_myproc = myproc()->queue;
    // myproc()->ticks_when_switch++;
    if (queu_of_myproc == 0)
    {
      if (myproc()->ticks_when_switch == 1)
      {
        // if (myproc()->pid >= 9)
        // {
        //   printf("%d %d %d\n", ticks - 1, p->pid, p->queue);
        // }
        myproc()->queue++;
        if (myproc()->pid >= 9)
        {
          printf("%d %d %d after demotion \n", ticks, myproc()->pid, myproc()->queue);
        }
        myproc()->ticks_when_switch = 0;
        myproc()->wait = 0;
        myproc()->new_flag = 0;
        yield();
      }
      // 1 second
    }
    else if (queu_of_myproc == 1)
    {
      if (myproc()->ticks_when_switch == 3)
      {
        // printf("%d %d %d\n", ticks - 1, p->pid, p->queue);

        myproc()->queue++;
        // printf("%d %d %d\n", ticks, myproc()->pid, myproc()->queue);
        if (myproc()->pid >= 9)
        {
          printf("%d %d %d after demotion \n", ticks, myproc()->pid, myproc()->queue);
        }
        myproc()->ticks_when_switch = 0;
        myproc()->wait = 0;

        myproc()->new_flag = 0;

        yield();
      }
      // 3 second
    }
    else if (queu_of_myproc == 2)
    {
      if (myproc()->ticks_when_switch == 9)
      {
        // printf("%d %d %d\n", ticks - 1, p->pid, p->queue);

        myproc()->queue++;
        if (myproc()->pid >= 9)
        {
          printf("%d %d %d after demotion \n", ticks, myproc()->pid, myproc()->queue);
        }
        myproc()->ticks_when_switch = 0;
        myproc()->wait = 0;

        myproc()->new_flag = 0;

        yield();
      }
      // 9second
    }
    else if (queu_of_myproc == 3)
    {
      if (myproc()->ticks_when_switch == 15)
      {

        myproc()->new_flag = 0;
        myproc()->wait = 0;

        // myproc()->queue++;
        myproc()->ticks_when_switch = 0;
        yield();
      }
      // 15 second
    }

    // yield();
#endif

    //     int min_time = __INT_MAX__;
    //     int i_of_process =qwertyuiop[[[[[[[[[poiuytrewqqqqqqqqqqqqqqqqqqqqwertyuiop[[[[[[[[[poiiop[gvbnm,bnm,bnm,.nm,./]]]]]]]]]]]]]]]]]]] -1;
    //     struct proc *proc1;
    //     for (int i = 0; i < NPROC; i++)
    //     {
    //       proc1 = &proc[i];
    //       if (proc1->state == RUNNABLE && p->ctime < min_time)
    //       {
    //         min_time = p->ctime;
    //         i_of_process = i;
    //       }
    //     }
    //     if (i_of_process != -1)
    //     {
    //       myproc()
    //     }

    // #endif
    // yield();
  }
  usertrapret();
}

//
// return to user space
//
void usertrapret(void)
{
  struct proc *p = myproc();

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
  p->trapframe->kernel_trap = (uint64)usertrap;
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()

  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
  x |= SSTATUS_SPIE; // enable interrupts in user mode
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64))trampoline_userret)(satp);
}

// interrupts and exceptions from kernel code go here via kernelvec,
// on whatever the current kernel stack is.
void kerneltrap()
{
  int which_dev = 0;
  uint64 sepc = r_sepc();
  uint64 sstatus = r_sstatus();
  uint64 scause = r_scause();

  if ((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: not from supervisor mode");
  if (intr_get() != 0)
    panic("kerneltrap: interrupts enabled");

  if ((which_dev = devintr()) == 0)
  {
    printf("scause %p\n", scause);
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    panic("kerneltrap");
  }

  // give up the CPU if this is a timer interrupt.
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
  {
#ifdef RR
    yield();
#endif
#ifdef MLFQ
    struct proc *p;
    // procdump();
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        p->wait++;
      }
      else if (p->state == RUNNING)
      {
        p->ticks_when_switch++;
      }
      release(&p->lock);
    }
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        if ((p->wait >= 30) && p->queue > 0)
        {
          if (myproc()->pid >= 9)
          {
            // printf("%d %d %d\n", ticks-1, myproc()->pid, myproc()->queue);
            // printf("%d %d %d before promtotion\n", ticks - 1, p->pid, p->queue);
          }

          p->queue--;

          if (p->pid >= 9)
          {
            // printf("%d %d %d after promotion\n", ticks, p->pid, p->queue);
          }
          p->new_flag = 0;
          p->ticks_when_switch = 0;
          p->wait = 0;
        }
      }
      release(&p->lock);
    }
    int current_level = myproc()->queue;
    for (int i = 0; i < current_level; i++)
    {
      for (p = proc; p < &proc[NPROC]; p++)
      {
        // acquire(&p->lock);

        if (p->state == RUNNABLE && p->queue == i)
        {
          // Switch to chosen process.  It is the process's job
          // to release its lock and then reacquire it
          // before jumping back to us.
          // p->state = RUNNING;
          // c->proc = p;
          // swtch(&c->context, &p->context);
          // if (myproc()->queue<3)
          // {
          //   myproc()->queue++;
          // }
          // release(&p->lock);
          // printf("pidc = %d %d\n", myproc()->ticks_when_switch, myproc()->pid);
          myproc()->new_flag = 1;
          yield();

          // break;
          // Process is done running for now.
          // It should have changed its p->state before coming back.
          // c->proc = 0;
        }
        // release(&p->lock);
      }
    }
    int queu_of_myproc = myproc()->queue;
    // myproc()->ticks_when_switch++;
    if (queu_of_myproc == 0)
    {
      if (myproc()->ticks_when_switch == 1)
      {

        // printf("%d %d %d\n", ticks - 1, p->pid, p->queue);
        myproc()->queue++;
        if (myproc()->pid >= 9)
        {
          // printf("%d %d %d after demotion \n", ticks, myproc()->pid, myproc()->queue);
        }
        myproc()->ticks_when_switch = 0;
        myproc()->wait = 0;
        myproc()->new_flag = 0;
        yield();
      }
      // 1 second
    }
    else if (queu_of_myproc == 1)
    {
      if (myproc()->ticks_when_switch == 3)
      {
        // printf("%d %d %d\n", ticks - 1, p->pid, p->queue);

        myproc()->queue++;
        // printf("%d %d %d\n", ticks, myproc()->pid, myproc()->queue);
        if (myproc()->pid >= 9)
        {
          // printf("%d %d %d after demotion \n", ticks, myproc()->pid, myproc()->queue);
        }
        myproc()->ticks_when_switch = 0;
        myproc()->wait = 0;

        myproc()->new_flag = 0;

        yield();
      }
      // 3 second
    }
    else if (queu_of_myproc == 2)
    {
      if (myproc()->ticks_when_switch == 9)
      {
        // printf("%d %d %d\n", ticks - 1, p->pid, p->queue);

        myproc()->queue++;
        if (myproc()->pid >= 9)
        {
          // printf("%d %d %d after demotion \n", ticks, myproc()->pid, myproc()->queue);
        }
        myproc()->ticks_when_switch = 0;
        myproc()->wait = 0;

        myproc()->new_flag = 0;

        yield();
      }
      // 9second
    }
    else if (queu_of_myproc == 3)
    {
      if (myproc()->ticks_when_switch == 15)
      {

        myproc()->new_flag = 0;
        myproc()->wait = 0;

        // myproc()->queue++;
        myproc()->ticks_when_switch = 0;
        yield();
      }
      // 15 second
    }

    // yield();
#endif
  }
  // yield
  // the yield() may have caused some traps to occur,
  // so restore trap registers for use by kernelvec.S's sepc instruction.
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
  acquire(&tickslock);
  ticks++;
  update_time();
  // for (struct proc *p = proc; p < &proc[NPROC]; p++)
  // {
  //   acquire(&p->lock);
  //   if (p->state == RUNNING)
  //   {
  //     printf("here");
  //     p->rtime++;
  //   }
  //   // if (p->state == SLEEPING)
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
  release(&tickslock);
}

// check if it's an external interrupt or software interrupt,
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
      (scause & 0xff) == 9)
  {
    // this is a supervisor external interrupt, via PLIC.

    // irq indicates which device interrupted.
    int irq = plic_claim();

    if (irq == UART0_IRQ)
    {
      uartintr();
    }
    else if (irq == VIRTIO0_IRQ)
    {
      virtio_disk_intr();
    }
    else if (irq)
    {
      printf("unexpected interrupt irq=%d\n", irq);
    }

    // the PLIC allows each device to raise at most one
    // interrupt at a time; tell the PLIC the device is
    // now allowed to interrupt again.
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
  {
    // software interrupt from a machine-mode timer interrupt,
    // forwarded by timervec in kernelvec.S.

    if (cpuid() == 0)
    {
      clockintr();
    }

    // acknowledge the software interrupt by clearing
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  }
  else
  {
    return 0;
  }
}
