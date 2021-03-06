# Cpt6. Improve Kernel

## 32位系统下的函数调用约定

> 我们在后续的编程中使用cdecl调用约定

64位系统中C语言大多使用fastcall（x64）。这个表格描述的是**x86架构**下的函数调用约定。

| 栈清理负责人             | 类别     | 描述                                                         |
| ------------------------ | -------- | ------------------------------------------------------------ |
| 调用者清理               | cdecl    | C语言的函数调用约定，多用于32位cpu。函数参数从右到左入栈，EAX,ECX和EDX由调用者保存，返回值在EAX |
| 调用者清理               | syscall  | 与cdecl类似， 参数从左到右入栈，参数列表的大小放在al中。<br />syscall是32位OS/2 API的标准 |
| 被调用者清理             | stdcall  | 和cdecl基本一致，只是栈清理由被调用函数清理，使用指令：<br />retn xxxx |
| 被调用者清理             | fastcall | x86架构下的fastcall还没有标准化，但是GUN和MSF已经达成一致。**从左到右**的前两个参数放在ECX和EDX，其余的**从右到左入栈** |
| 调用者或者<br />被调用者 | thiscall | 老生常谈的thiscall，C++非静态成员函数使用。ecx作为对象指针传入被调用者，其余和cdecl一致。 |

## 实现基本的屏幕输出

这一块直接抄了代码，没什么特别需要注意的地方

## gcc扩展内联汇编

### 模板：

```c
asm(
  "addl %%ebx,%%eax" \
  :"=a"(input) \
  :"a"(output) \
)
```

### 寄存器约束

a:表示寄存器 eax,ax,al

b:表示寄存器ebx,bx,bl

c,d同上

D:表示寄存器edi

S:表示寄存器esi

q：表示四个通用寄存器之一（eax,ebx,ecx,edx)

r：表示6个统用寄存器之一(eax,ebx,ecx,edx,esi,edi)

g:表示可以存放到任意地点（寄存器和内存）。相当于除了同q一样以外，还可以让gcc安排在内存中

A：把eax和edx组合成64位整数

f：表示浮点寄存器

t：表示第一个浮点寄存器

u：表示第二个浮点寄存器

### 内存约束

m:表示操作数可以使用任意一种内存形式

o:操作数为内存变量，但访问它是通过偏移量的形式访问，即包含offset_address的格式

### 立即数约束

这一类约束只能放在input中

i:表示操作数为整数立即数

F：表示操作数为浮点数立即数

I：表示操作数为0~31之间的立即数

J：表示操作数为0~63之间的立即数

N：表示操作数为0~255之间的立即数

O：表示操作数为0~32之间的立即数

X：表示操作数为任何类型立即数

### 通用约束

0~9：此约束只用在input部分，但表示可与output和input中第n个操作数用象通的寄存器或内存。

### 序号占用符

序号占位符是对在 output input 中的操作数，按照它们从左到右出现的次序从0 开始编号，一直到 9，也就是说最多支持 10 个序号占位符。

操作数用在 assembly code 中，引用它的格式是%0~9



### 名称占位符

看代码，还是模板

```c
#include<stdio.h>
int main(){
    int in_a = 18,in_b = 3,out = 0;
    asm(
        "divb %[divisor];"\
        "movb %%al,%[result]"\
        :[result]"=m"(out)\
        :"a"(in_a),[divisor]"m"(in_b)\
    );
    printf("result is %d\n,out");
}
```

### output约束

=：表示操作数是只写的

+：表示操作数是可读写的

&：表示此ouput中的操作数要独占所约束的寄存器，只供output使用，input中的约束不能出现使用了这个约束的寄存器

### input约束

%：该操作数可以和下一个输入操作数互换

## 内联汇编之机器模式

暂时略，等到用到了再回来补充