# Kernel学习之路

《操作系统真象还原》

## 第一章

配环境

## 第二章

继续配环境+初步测试环境

这里需要注意的几个点：

1. bochsrc.disk中关于虚拟硬盘的路径得是绝对路径（从根目录开始全部梭哈)
2. 多找资料多尝试

## 第三章

### 3.1 有关nasm

**section**:nasm定义的section和pe/elf文件中的段是两个不同的定义。

**vstart**:偏移量定义，定义后边写的代码的基准偏移，不是在文件中的偏移

### 3.2 CPU的实模式

#### 3.2.1 复习计算机组成原理——CPU的组成和运行模式

#### 3.2.2 实模式下的寄存器 & 8086汇编基础

实模式下，默认用到的寄存器都是16bits的。

CPU中寄存器分为两类：

- 内部寄存器，用户不可见：这一部分寄存器用于为CPU的运行提供支持

  虽然内部寄存器不可见，不可直接使用，但仍然有一部分寄存器需要我们手动为其初始化

- 用户寄存器，用户可见：这一部分寄存器用于为用户程序的运行提供支持

然后讲了一些8086汇编基础

这里得讲俩指令，之前没学过的。

**in指令**：格式： `in al,dx`或者`in ax,dx`

- in指令用于从端口中读取数据。dx为端口号，ax/al用来储存获取的数据。
- 使用al还是ax来储存储存数据，取决于端口指代的寄存器长度是8bits还是16bits

**out指令**：

- 格式：
  1. `out dx,al`
  2. `out dx,ax`
  3. `out 立即数,al`
  4. `out 立即数,ax`
- 端口号是dx或者立即数。写入的数据是al/ax
- 使用ax还是al的规则同in指令。

挖一个有点历史的东西。cpu对外的数据接口通过**南桥、北桥**统一管理。北桥管理高速设备，南桥管理低速设备。

这时候就不得不说AMD,YES!

细数amd的功绩：

1. 推进cpu与北桥一体化
2. 推进64位cpu发展
3. 推进cpu模块化核心
4. 率先量产7nm

**Intel，NO!**

### 3.3 直接对屏幕写点东西呗

（小声BB，写在开始看之前）我觉得这个肯定是在讲25*80彩色缓冲区

hmmm，害

显存开始地址：0x0b800，25行，80列

一个字符分为ascii码和颜色代码两个部分，长度为16bits

低字节（AL）是ascii码部分，高字节（AH）是颜色代码部分

### 3.4 bochs调试手段

在开始讲这段之前，有一点需要先说明的。bochs中的关键字WORD不是两个字节，而是四个字节。

熟悉gdb的应该可以很快上手这一套调试工具

#### 输入“h”获取bochs的调试指令集

#### 输入“h 其他指令”获取关于该调试指令的详细内容

```<bochs:5> h
h|help - show list of debugger commands
h|help command - show short command description
-*- Debugger control -*-
    help, q|quit|exit, set, instrument, show, trace, trace-reg,
    trace-mem, u|disasm, ldsym, slist
```

#### debuger控制指令

**q**:退出bochs

**set**:set是一个指令族，可以使用set来设定寄存器，或者是反汇编相关的事情

- `set (regname) = (expr)`:设定指定寄存器的值
- 

**instrument**:

**show**:show是一个指令族，可以用来做很多东西

- `show` 显实当前的展示模式
- `show mode` : 每次CPU变换模式的时候就提示，模式是保护模式、实模式，比如从实模式进入到保护模式的时候会有提示
- `show int`: 每次终端的时候会有提示，同时显示3种中断类型（sofrint，extint，iret)。可以单独显示某类中断，如执行 `show softint` 只显示软件主动触发的中断， `show extint` 则只显示来自 外部设备的中断， `show iret` 只显示 iretd 指令有关的信息。 
- `show call` : 每次有函数调用发生的时候就会提示
- `show off`: 关闭提示信息
- `show all` : 提示所有信息

**trace**:`trace on`/`off`，打开此选项的时候，每次执行一条指令，都会把执行的指令打印到控制台。

**trace-reg**:

**trace-mem**:

**u**: u [/count]  (start)  (end) ，反汇编指令

- /count是可选选项，指定翻译多少条指令
  - 例子：`u /10`:按顺序翻译eip所在地址往下的10条指令
- u (start)：翻译地址位于start处的一条指令
- u (start) (end): 翻译地址位于start和end之间的指令
  - 例子：`u /5 0x70000 0x70020` 翻译在0x70000和0x70020之间代码块中从0x70000开始的5条指令
  - 例子：`u 0x70000 0x70020` 翻译在0x70000和0x70020之间代码块中的所有指令
- u switch-mode  切换反汇编模式(AT&T和Intel两种模式来回切换)
- u hex on/off 原文：control disasm offsets and displacements format
- u size = n ,n可以是16位，32位或者64位。设定反汇编器的反汇编字长

**ldsym**:

**slist**:

#### 执行控制指令

```c
-*- Execution control -*-
    c|cont|continue, s|step, p|n|next, modebp, vmexitbp
```

**c**:运行到下一个断点（如果没有，那就等于放弃控制权了）

**s**:单步执行，call指令会进入被call函数

**n**:单步执行，call指令不会进入被call函数

**modebp**:

**vmexitbp**:

#### CPU & 内存状态查看

```c
-*- CPU and memory contents -*-
    x, xp, setpmem, writemem, crc, info,
    r|reg|regs|registers, fp|fpu, mmx, sse, sreg, dreg, creg,
    page, set, ptime, print-stack, ?|calc
```

**x**:查看内存，根据线性地址查看。实模式中不可用。格式同指令`xp`，参数同`xp`

**xp /nuf (addr)**:查看内存，根据物理地址查看。

- 例子：`xp /20xg` 0x7fff,以十六进制的形式查看0x7fff开始的20个double word

- /nuf: "/"+数据数量+数据格式+数据字长

  - 数据格式：

    | 符号 | 含义         | 符号 | 含义           |
    | ---- | ------------ | ---- | -------------- |
    | x    | 十六进制     | t    | 二进制         |
    | d    | 有符号十进制 | c    | 字符           |
    | u    | 无符号十进制 | s    | asciiz         |
    | o    | 八进制       | i    | instr(啥意思?) |

  - 数据字长

    | 符号 | 含义               | 符号 | 含义                |
    | ---- | ------------------ | ---- | ------------------- |
    | b    | 1字节（byte)       | w    | 4字节（word)        |
    | h    | 2字节（half-word） | g    | 8字节（giant word） |

    

**setpmem**:

**writemem**:

**crc**:

**info**:

**r**:查看普通寄存器数据

**fp**:查看浮点寄存器数据

**mmx**:

**sse**:

**sreg**:

**dreg**:

**creg**:

**page**:

**set**:

**ptime**:

**print-stack**:

**calc**:

#### 断点控制指令

```c
-*- Breakpoint management -*-
    vb|vbreak, lb|lbreak, pb|pbreak|b|break, sb, sba, blist,
    bpe, bpd, d|del|delete, watch, unwatch
-*- Working with bochs param tree -*-
    show "param", restore
```

**vb**:

**lb**:

**b**:

**sb**:

**sba**:

**blist**:

**bpe**:

**bpd**:

**d**:
**watch**:

**unwatch**:



