# A better zip bomb

> **论文发表**: WOOT '19 (13th USENIX Workshop on Offensive Technologies), 2019年8月  
> **作者**: David Fifield  
> **项目地址**: <https://www.bamsoftware.com/hacks/zipbomb/>  
> **论文资料**: 参见 `./paper/` 目录  

---

## 概述

这是一个**非递归**的 zip 炸弹生成工具。与传统递归 zip 炸弹（如著名的 `42.zip`）不同，本项目的炸弹**不需要嵌套 zip 文件**——只需平铺压缩一个内核，然后让多个文件条目在 zip 归档中引用同一压缩数据区域。这使得炸弹对**不递归解压**的解压器同样有效。

通过优化文件数量与压缩内核大小的配比，可以在极小压缩比下实现极高的膨胀率。

---

## 示例炸弹

| 文件名 | 压缩大小 | 解压后大小 | 压缩比 | 说明 |
|--------|----------|-----------|--------|------|
| 文件名 | 压缩大小 | 解压后大小 | 压缩比 | 说明 | 获取方式 |
|--------|----------|-----------|--------|------|----------|
| `zbsm.zip` | 42 KB | 5.5 GB | 130,000× | 非递归，单层 | ✅ 已预生成（`zip/`） |
| `zblg.zip` | 10 MB | 281 TB | 28,000,000× | 最大非 Zip64 炸弹 | ✅ 已预生成（`zip/`） |
| `zbxl.zip` | 46 MB | 4.5 PB | 98,000,000× | 超过 42.zip 解压后大小 | ⚙ 由 `make zbxl.zip` 生成 |
| `zbxxl.zip` | 2.8 GB | 18 EB (2⁶⁴) | — | 达到 64 位极限 | ⚙ 由 `make zbxxl.zip` 生成 |
| `zbbz2.zip` | — | 4.3 GB | — | bzip2 算法变体 | ⚙ 由 `make zbbz2.zip` 生成 |

对比: 经典的 `42.zip` 为 42 KB → 4.5 PB（但只能递归解压才有效）。

`zip/` 目录下已预生成 `zbsm.zip` 与 `zblg.zip` 两个示例炸弹（可直接用 `ratio` 分析，但**切勿解压**）。其余炸弹体积庞大，请用 `make` 按需生成，生成的是压缩归档文件本身、不会占用解压后的空间。

---

## 项目结构

```
zipbomb/
├── zipbomb              # 主程序：Python 3 脚本，生成 zip 炸弹
├── zipbomb-20190702.zip # 2019-07-02 初始发布版本的完整快照
├── Makefile             # 构建系统，包含各类炸弹的生成配方
├── ratio                # 压缩比计算器：计算 zip 文件的压缩/解压比
├── optimize.R           # R 优化脚本：计算最优的文件数量与内核大小参数
├── optimize.out         # optimize.R 的预计算结果
├── LICENSE              # 公共领域（Public Domain）说明
├── README.md            # 本文件
├── .gitignore           # 忽略 make 生成的巨型炸弹，保留 zip/ 样例
├── .gitattributes       # 脚本统一 LF 换行，zip 标记为二进制
├── website/             # 项目网站（官网 bamsoftware.com/hacks/zipbomb）全文存档
│   ├── Abetterzipbomb-webpage.jpg
│   ├── Abetterzipbomb-webpage.pdf
└── zip/                 # 预生成的示例炸弹文件
    ├── zbsm.zip         # 42 KB → 5.5 GB
    └── zblg.zip         # 10 MB → 281 TB
```

### 子目录

```
zipbomb/
├── paper/               # WOOT '19 学术论文附属资料
│   ├── data/            # 压缩率基准测试数据与 C 源码
│   ├── figures/         # Asymptote 图表源码
│   ├── samples/         # 解析器兼容性测试样例
│   ├── zipbomb.bib      # 论文参考文献
│   ├── zipbomb.tex      # 论文 LaTeX 正文
│   └── reviews-woot19.txt  # 同行评审反馈
└── website/             # 项目网站（官网 bamsoftware.com/hacks/zipbomb）全文存档
    ├── Abetterzipbomb-webpage.jpg
    ├── Abetterzipbomb-webpage.pdf
    └── A better zip bomb.md   # 项目网站全文存档
```

---

## 核心原理

### 为什么传统递归 zip 炸弹不再有效？

现代解压软件（如信息-ZIP unzip 6.0、7-Zip 等）通常**不支持递归解压**——即在解压过程中遇到 `.zip` 文件时，不会自动继续解压。因此 `42.zip` 层层嵌套的方式对这些软件无效。

### 本项目的方法: 文件重叠 (File Overlap)

Zip 格式的核心特性是：多个文件条目可以指向归档中**同一块压缩数据**。利用这一特性：

1. **生成一个高度压缩的内核** —— 一段重复字节的 DEFLATE 流，压缩后极小（如 1 字节表示几 MB 数据）
2. **创建大量文件条目** —— 每个条目的文件头和 CRC-32 仍占空间，但它们都引用同一个压缩内核
3. **收益倍增** —— 如果有 `n` 个文件，每个解压后为 `u` 字节，总输出 = `n × u`。由于压缩内核只需存一次，压缩比接近 `n` 倍于单文件的压缩比

### 引用技术 (Quoting)

当文件数量很大时，每个文件的**本地文件头 (30 字节)** 和**中央目录头 (46 字节)** 本身会占据大量空间。引用技术利用 DEFLATE 的非压缩块来"引用"相邻文件头作为自身数据的一部分，从而回收利用这些开销空间，进一步放大膨胀效果。

### 三种构造方式

| 构造 | 文件重叠方式 | 对解压器兼容性 | 压缩效率 |
|------|------------|-------------|---------|
| **完全重叠** | 所有文件指向同一个内核，起始偏移相同 | 最低（大多数解析器不支持） | 最优 |
| **引用重叠** | 文件在归档中偏移错开，后一个引用前一个的文件头作为数据 | 中等 | 较好 |
| **不重叠** | 每个文件有独立的压缩内核 | 最高 | 最低 |

`zbsm.zip` 和 `zblg.zip` 使用**引用重叠**构造，已被测试在 7 种主流 zip 解析器中均能正常解压。

---

## 依赖

- **Python 3（仅标准库）** — 运行主程序 `zipbomb` 与 `ratio`。
  脚本**完全自包含**：DEFLATE 压缩内核、CRC-32 组合运算（`crc32_combine` 思路，用 GF(2) 矩阵实现）均用纯 Python 完成，**不需要** `crcmod`、`zlib` 之外的任何第三方库，也**不需要**编译 `bulk_deflate.c` 之类的 C 程序。
- **R（可选）** — 仅当要运行 `optimize.R` 重新计算参数优化时才需要；`optimize.out` 已包含预计算结果。

> 说明：本项目早期文档曾提及依赖 `crcmod` 与 C 源码 `bulk_deflate.c`，但当前 `zipbomb` 脚本已改为纯 Python 实现，这些外部依赖均已移除。

---

## 使用方法

### 计算已有 zip 炸弹的压缩比

```bash
./ratio zip/zbsm.zip zip/zblg.zip
```

### 生成自定义炸弹

```bash
# 生成类似 zbsm.zip (42KB) 的炸弹
make zbsm.zip

# 生成最大非 Zip64 炸弹 (10MB)
make zblg.zip

# 生成极致炸弹 (46MB, 需要 Zip64)
make zbxl.zip

# 生成所有示例炸弹
make all
```

> **Windows 用户**：若未安装 `make` 或命令名为 `python` 而非 `python3`，可直接调用脚本（输出重定向到文件即可）：
> ```powershell
> python zipbomb --mode=quoted_overlap --num-files=250 --compressed-size=21179 > zbsm.zip
> ```
> 生成动作只是**写出 zip 归档文件本身**（体积很小），并不会占用解压后的空间，因此可以安全执行。

---

## zipbomb 脚本详细参数

### 必需参数

- `--num-files=N`：指定 zip 炸弹包含的文件数量
- `--compressed-size=N`：指定压缩内核的大小（字节）
- `--max-uncompressed-size=N`：指定最大解压后大小（字节，与 `--compressed-size` 二选一）

### 模式选择

- `--mode=no_overlap`：不重叠模式，每个文件有独立的压缩内核
- `--mode=full_overlap`：完全重叠模式，所有文件指向同一个内核
- `--mode=quoted_overlap`：引用重叠模式（默认），文件在归档中偏移错开

在 `quoted_overlap` 模式下，可以启用额外字段引用（需要提供 4 位十六进制标签类型）：
```bash
--mode=quoted_overlap --extra=9999
```

### 压缩算法

- `--algorithm=deflate`：使用 DEFLATE 算法（默认）
- `--algorithm=bzip2`：使用 bzip2 算法

**bzip2 限制**：如果在 `quoted_overlap` 模式下使用 bzip2，必须同时使用 `--extra`，因为 bzip2 没有自己的本地文件头引用方式。此外，`--compressed-size` 的参数值在使用 bzip2 时必须满足 `≡ 14 (mod 32)`。

### Zip64 支持

对于需要 Zip64 的 zip 炸弹（超过 0xfffe 个文件或文件大于 0xfffffffe 字节），启用 Zip64 支持：
```bash
--zip64
```

如果输出需要 Zip64 但未启用该选项，脚本会在某处崩溃。需要 Zip64 的情况不会自动检测，因为作者希望提前决定特定的 zip 炸弹是否应该使用 Zip64（如果计算错误则报错），而且在 `quoted_overlap` 模式下预测最大文件大小是否会超过阈值稍微有些棘手（尽管 `optimize.R` 脚本会进行此计算）。

### 其他选项

- `--alphabet=STRING`：更改默认的文件名字母表（默认为 `0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ`）
  ```bash
  --alphabet=0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
  ```

- `--template=FILE`：提供一个或多个模板 zip 文件，让 zip 炸弹除了炸弹文件外还包含某些普通文件
  ```bash
  --template=other.zip
  ```
  `--num-files` 选项是**额外**于模板中已有文件的。

### 示例

```bash
# 生成一个包含 250 个文件、压缩内核大小为 21179 字节的 zip 炸弹
python3 zipbomb --mode=quoted_overlap --num-files=250 --compressed-size=21179 > zbsm.zip

# 使用 bzip2 算法生成炸弹
python3 zipbomb --mode=quoted_overlap --extra=9999 --algorithm=bzip2 --num-files=100 --compressed-size=14 > bomb.zip

# 生成需要 Zip64 的大型炸弹
python3 zipbomb --mode=quoted_overlap --num-files=100000 --compressed-size=100000 --zip64 > huge.zip
```

---

## optimize.R 脚本

`optimize.R` 是一个 R 脚本，用于计算 `zipbomb` 脚本生成各种大小 zip 炸弹的最优参数。`optimize.out` 是 `optimize.R` 的预生成输出。

```bash
Rscript optimize.R | tee optimize.out
```

优化后的参数就是你在 `Makefile` 中看到的那些。

---

## ratio 脚本

`ratio` 是一个 Python 3 脚本，用于计算命令行列出的 zip 文件的压缩比。

```bash
$ make zbsm.zip zblg.zip zbxl.zip
$ python3 ratio zbsm.zip zblg.zip zbxl.zip
zbsm.zip	5461307620 / 42374	128883.45730872705	+51.102 dB
zblg.zip	281395456244934 / 9893525	28442385.9286689	+74.54 dB
zbxl.zip	4507981427706459 / 45876952	98262444.01996146	+79.924 dB
```

输出格式为：`文件名 解压后大小 / 压缩大小 压缩比 分贝值`

---

## 兼容性测试

项目中的炸弹已在以下 zip 解析器中测试：

- **Info-ZIP unzip 6.0** (Linux)
- **Python 3.7 `zipfile` 模块**
- **Go 1.12 `archive/zip`**
- **Node.js `yauzl`**
- **Nail** (解析生成器)
- **Android 9.0 `libziparchive`** (仅 `zbsm.zip`)
- **sunzip** (Mark Adler 的流式解压器)

详见 `./paper/samples/README`。

---

## 安全提示

1. **不要直接解压这些 zip 炸弹文件！** 它们会使你的磁盘瞬间填满
2. **不要用文件管理器双击打开** —— 许多文件管理器会在后台自动解压以预览内容
3. 如需测试，请在隔离环境（如 RAM 盘或容器）中进行
4. 本项目仅供安全研究和教育用途

---

## 参考文献

- **WOOT '19 论文**: *A better zip bomb* — David Fifield  
  (相关资料在 `./paper/`)
- **42.zip**: 经典的递归 zip 炸弹
- **Russ Cox**: [Zip Files All The Way Down](https://research.swtch.com/zip)
- **Gynvael Coldwind**: [Ten thousand security pitfalls: The ZIP file format](https://gynvael.coldwind.pl/?id=682)
- **CVE-2019-9670**: Zimbra 邮件服务器 zip 炸弹漏洞 (引用重叠技术)

---

## 版权与许可

- **代码**（`zipbomb`、`ratio`、`Makefile`、`optimize.R` 等）：作者 **David Fifield**
  （<david@bamsoftware.com>，项目主页 <https://www.bamsoftware.com/hacks/zipbomb/>），
  以 **公共领域（Public Domain）** 发布，见 `LICENSE` 文件与 `zipbomb` 脚本头声明。
- **论文 / 官方介绍**（`website/A better zip bomb.md`）：作者发表于 USENIX WOOT 2019 的
  《A better zip bomb》正式稿，原文发布于
  <https://www.bamsoftware.com/hacks/zipbomb/>；本目录 `website/` 为其存档副本（原文未附
  显式版权声明，版权归作者所有）。
- **中文翻译**：`website/` 中的中文译文来自「北岸冷若冰霜」（zerosun.top，
  <https://zerosun.top/2019/07/07/A-better-zip-bomb/>）。
- **经典递归炸弹 `42.zip`**：来自 unforgettable.dk（见 `recursive/README.md`），
  与本项目代码无关，仅供研究 zip 解析器健壮性。
