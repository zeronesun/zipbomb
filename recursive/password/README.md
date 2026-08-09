# 密码版递归 zip 炸弹（42.password.zip）

- **文件**：`42.password.zip`
- **大小**：42,838 字节
- **密码**：`42`
- **来源**：http://www.unforgettable.dk/42.zip （网站已下线，存档见
  https://web.archive.org/web/20120210181357/http://www.unforgettable.dk/42.zip）
- **类型**：经典**递归** zip 炸弹（与本项目 `zipbomb` 生成器的非递归炸弹不同）

## 结构

5 层嵌套，每层 16 个 zip，最内层文件约 4.3 GB。
完整解压后约 **4.5 PB**。详见 `../README.md`。

## 安全

**不要解压、双击或让任何工具自动解压。** 仅供研究 zip 解析器对递归炸弹的
检测能力（见 `../paper/samples/README` 中列出的各类解析器测试）。
