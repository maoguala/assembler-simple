# 🖥️ x86-64 Assembly — hello.asm 逐行解析

###### Tags: `assembly` `nasm` `x86-64` `windows11` `system-programming`

---

## 📄 完整程式碼

```asm
section .data
    msg db "Hello", 0
    msg_len equ 5

section .bss
    written resd 1

section .text
    global _main
    extern GetStdHandle
    extern WriteConsoleA
    extern ExitProcess

_main:
    ; Get stdout handle
    mov rcx, -11
    call GetStdHandle

    ; WriteConsoleA(handle, msg, len, &written, NULL)
    mov rcx, rax
    lea rdx, [rel msg]
    mov r8, msg_len
    lea r9, [rel written]
    push 0
    sub rsp, 32
    call WriteConsoleA
    add rsp, 40

    ; ExitProcess(0)
    xor rcx, rcx
    call ExitProcess
```

---

## 📦 三大區段說明

> Assembly 程式分為三個標準區段，OS 會對每個區段設定不同的記憶體權限

| 區段 | 用途 | 權限 |
|------|------|------|
| `.data` | 存放**已初始化**的常數資料 | 可讀寫，不可執行 |
| `.bss` | 存放**未初始化**的變數（預留空間） | 可讀寫，不可執行 |
| `.text` | 存放**程式碼**指令 | 可執行，不可寫入 |

```
記憶體配置示意圖
┌──────────┐
│  .text   │  ← CPU 從這裡讀取並執行指令
├──────────┤
│  .data   │  ← 程式啟動時載入已知資料
├──────────┤
│  .bss    │  ← 程式啟動時自動清為 0
├──────────┤
│  stack   │  ← 函式呼叫、區域變數
└──────────┘
```

---

## 🔍 逐行解析

### section .data — 資料區段

```asm
section .data
```
宣告「資料區段」，底下放**不會改變**的資料

```asm
msg db "Hello", 0
```
| 部分 | 說明 |
|------|------|
| `msg` | 變數名稱 |
| `db` | Define Byte，定義一串 bytes |
| `"Hello"` | 字串內容 |
| `, 0` | Null terminator，字串結尾符號 |

```asm
msg_len equ 5
```
| 部分 | 說明 |
|------|------|
| `msg_len` | 常數名稱 |
| `equ` | 等於 C 語言的 `#define`，定義常數 |
| `5` | `"Hello"` 的字元長度 |

---

### section .bss — 未初始化資料區段

```asm
section .bss
```
宣告「未初始化區段」，用來**預留記憶體空間**

```asm
written resd 1
```
| 部分 | 說明 |
|------|------|
| `written` | 變數名稱 |
| `resd` | Reserve Double word，預留 4 bytes 空間 |
| `1` | 預留 1 個單位 |
| 用途 | 存放 `WriteConsoleA` 實際寫出的字元數 |

---

### section .text — 程式碼區段

```asm
section .text
```
宣告「程式碼區段」，放置實際執行的指令

```asm
global _main
```
告訴 Linker：`_main` 是程式進入點（對外公開）

> ⚠️ GoLink 需要 `_main`（有底線），不是 `main`

```asm
extern GetStdHandle
extern WriteConsoleA
extern ExitProcess
```
| 函式 | 來源 | 用途 |
|------|------|------|
| `GetStdHandle` | `kernel32.dll` | 取得終端機 handle |
| `WriteConsoleA` | `kernel32.dll` | 輸出文字到終端機 |
| `ExitProcess` | `kernel32.dll` | 結束程式 |

`extern` 代表這些函式來自**外部 DLL**，由 Linker 在連結時解析

---

### _main — 主程式邏輯

```asm
_main:
```
程式開始執行的位置（Entry Point）

---

#### 🔹 Step 1：取得 stdout handle

```asm
mov rcx, -11
```
| 部分 | 說明 |
|------|------|
| `mov` | 把值存入暫存器 |
| `rcx` | Windows x64 第一個參數暫存器 |
| `-11` | 代表 `STD_OUTPUT_HANDLE`（標準輸出） |

```asm
call GetStdHandle
```
呼叫 `GetStdHandle(-11)`，回傳值（stdout handle）會存放在 `rax`

---

#### 🔹 Step 2：呼叫 WriteConsoleA 印出 "Hello"

> Windows x64 呼叫規範：前四個參數依序放入 `rcx`, `rdx`, `r8`, `r9`

```asm
mov rcx, rax
```
把 `GetStdHandle` 回傳的 handle 放入 `rcx`（**第 1 個參數**）

```asm
lea rdx, [rel msg]
```
| 部分 | 說明 |
|------|------|
| `lea` | Load Effective Address，載入記憶體位址 |
| `rdx` | **第 2 個參數**：字串的位址 |
| `[rel msg]` | 使用相對位址（RIP-relative），64位元必須加 `rel` |

```asm
mov r8, msg_len
```
`r8` — **第 3 個參數**：字串長度 `5`

```asm
lea r9, [rel written]
```
`r9` — **第 4 個參數**：存放實際輸出字元數的位址

```asm
push 0
```
**第 5 個參數**：`NULL`，壓入 stack（超過 4 個參數時用 stack 傳遞）

```asm
sub rsp, 32
```
預留 **32 bytes Shadow Space**

> 💡 Windows x64 呼叫規範強制要求，呼叫任何函式前都必須預留 32 bytes 給被呼叫者使用

```asm
call WriteConsoleA
```
呼叫 Windows API，將 `"Hello"` 印到終端機 ✅

```asm
add rsp, 40
```
釋放剛才用掉的 stack 空間：
- `32` bytes（shadow space）
- `+8` bytes（`push 0` 壓入的 NULL）
- = **40** bytes

---

#### 🔹 Step 3：結束程式

```asm
xor rcx, rcx
```
| 部分 | 說明 |
|------|------|
| `xor` 自己 | 結果永遠為 `0` |
| 目的 | 設定結束碼為 `0`（代表程式成功結束） |
| 為何不用 `mov rcx, 0` | `xor` 指令比較短，是常見的最佳化技巧 |

```asm
call ExitProcess
```
呼叫 Windows API 正常結束程式

---

## 📊 整體執行流程

```
_main
  │
  ├─ mov rcx, -11
  ├─ call GetStdHandle        → 取得 stdout handle (存在 rax)
  │
  ├─ 設定 WriteConsoleA 參數
  │   ├─ rcx = handle
  │   ├─ rdx = &msg ("Hello")
  │   ├─ r8  = 5 (長度)
  │   ├─ r9  = &written
  │   └─ push 0 (NULL)
  ├─ sub rsp, 32              → 預留 shadow space
  ├─ call WriteConsoleA       → 印出 "Hello" ✅
  ├─ add rsp, 40              → 釋放 stack 空間
  │
  ├─ xor rcx, rcx             → 設定結束碼 = 0
  └─ call ExitProcess         → 程式結束
```

---

## ⚙️ 暫存器對照表（Windows x64）

| 暫存器 | 用途 |
|--------|------|
| `rcx` | 第 1 個參數 |
| `rdx` | 第 2 個參數 |
| `r8` | 第 3 個參數 |
| `r9` | 第 4 個參數 |
| `rax` | 函式回傳值 |
| `rsp` | Stack Pointer |

---

## 🛠️ 編譯指令

```cmd
nasm -f win64 hello.asm -o hello.obj
golink /console /entry _main hello.obj kernel32.dll
hello.exe
```

### 編譯流程
```
hello.asm  →  hello.obj  →  hello.exe  →  "Hello"
  Write       Assemble       Link          Run ✅
```
