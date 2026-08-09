# zipbomb-paper — WOOT '19 学术论文

> **论文标题**: *A better zip bomb*  
> **会议**: WOOT '19 (13th USENIX Workshop on Offensive Technologies), 2019年8月  
> **作者**: David Fifield  
> **论文仓库**: <https://www.bamsoftware.com/git/zipbomb-paper.git/>

## 目录结构

```
zipbomb-paper/
├── zipbomb.tex          # LaTeX 论文正文 (USENIX 格式, 双栏)
├── zipbomb.bib          # BibTeX 参考文献
├── Makefile             # 构建论文 PDF 的配方
├── reviews-woot19.txt   # 同行评审反馈（已接受）
├── README.md            # 本文件
├── figures/             # Asymptote (.asy) 图表源码
│   ├── common.asy       # 共用绘图设置
│   ├── overlap.asy      # 重叠构造示意图
│   ├── quote.asy        # 引用构造示意图
│   └── normal.asy       # 普通构造示意图
├── data/                # 压缩率基准测试数据与分析
│   ├── README           # 数据目录说明
│   ├── versions.txt     # 测试软件版本记录
│   ├── zlib_deflate.c   # zlib DEFLATE 基准测试 C 源码
│   ├── compressed_size.sh   # 压缩率采集脚本
│   ├── compressed_size.csv  # 压缩率原始数据 (95K+ 行)
│   ├── zipped_size.R    # 生成归档元数据对比数据
│   ├── zipped_size.csv  # 各归档器大小对比
│   ├── graphs.R         # 图表生成 R 脚本
│   ├── max_uncompressed_size.pdf  # 生成图表
│   ├── bulk_deflate     # bulk_deflate 已编译二进制
│   └── Makefile         # 数据采集构建
└── samples/             # 解析器兼容性测试样例
    ├── README           # 测试说明
    ├── non-recursive.zip
    └── recursive.zip    # 传统递归炸弹（用于对比）
```

## 构建论文

### 依赖

- LaTeX (pdflatex)
- Asymptote (用于图表)
- R + Rscript (用于数据图表)

### 构建

```bash
make -j$(nproc)
```

输出: `zipbomb.pdf`

## 同行评审结果

论文于 2019 年 WOOT 会议接收。评审意见见 `reviews-woot19.txt`。

评审对以下方面给予肯定：
- 非递归方法的新颖性
- 文件重叠技术的巧妙运用
- 对 zip 格式的深入分析
- 实际影响（CVE-2019-9670 Zimbra 漏洞）

## 与主项目的关系

- **主项目** (`..`): 炸弹生成工具和示例文件
- **本目录**: 论文源码、数据分析、基准测试
- 论文中的表格和图表均由此目录的数据和脚本生成
