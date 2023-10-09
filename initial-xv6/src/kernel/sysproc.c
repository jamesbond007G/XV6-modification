#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
extern int getread_count;
uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; // not reached
}
uint64
sys_getreadcount(void)
{
  return getread_count;
}
uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}
// uint64 sys_getreadcount(void)
// {
//   return getre
// }
uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1); // user virtual memory
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc *p = myproc();
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}
extern ptrtotrapframe arr_of_trapframes_storing_past[1000010];

uint64 sys_sigalarm(void)
{
  uint64 address_of_handler;
  uint64 no_of_ticks;

  argaddr(0, &no_of_ticks);
  argaddr(1, &address_of_handler);
  // address_of_handler = argc
  myproc()->no_of_ticks = no_of_ticks;
  myproc()->handler = address_of_handler;
  return 0; 
}
uint64 sys_sigreturn(void)
{
  memmove(myproc()->trapframe,arr_of_trapframes_storing_past[myproc()->pid], PGSIZE);
  kfree(arr_of_trapframes_storing_past[myproc()->pid]);
  myproc()->flag_check_handler = 0; 
  myproc()->passed_ticks =  0; 
  myproc()->past_trap_frame = 0; 
  
  return myproc()->trapframe->a0; 
  // return 0;
}