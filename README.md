# hello

C / C++ 入门练习：从一段视频里辨认出的 `hello.cpp`，以及对应的 C 语言版本。

## 文件说明

| 文件 | 说明 |
|---|---|
| `hello.cpp` | C++ 原版，使用 `bits/stdc++.h` 与 `cout` |
| `hello.c` | C 语言等价版本，使用 `stdio.h` 与 `printf` |
| `.gitignore` | 排除编译产物与敏感文件 |

## 编译与运行

### C 版本

```bash
gcc hello.c -o hello
./hello
```

### C++ 版本

```bash
g++ hello.cpp -o hello
./hello
```

### 预期输出

```
Hello, world!
```

## 两者的差异

`hello.cpp` 里的 `#include <bits/stdc++.h>` 是 GCC 专属的非标准聚合头文件，不是 C++ 标准的一部分。
用 MSVC 编译会报 `fatal error C1083: 无法打开包括文件 bits/stdc++.h`。

C 语言没有命名空间机制，因此 `hello.c` 里删掉了 `using namespace std;`，
并把 `cout << ... << endl` 换成 `printf("...\n")`。