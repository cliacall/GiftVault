# GiftVault

X账号礼物金库 — 指定X/Twitter账号控制手续费定向到任意EVM地址，7天宽限期

## OpenFour 模块

直接集成到 four.meme OpenFour 发射引擎中。

## 合约架构

```
contracts/
├── GiftVault.sol              # 主合约
├── interfaces/
│   ├── IOpenFourVault.sol   # OpenFour Vault 接口
│   ├── ITagDescriptor.sol   # 模块标签接口
│   └── IOpenFourModuleSchema.sol  # 前端表单Schema接口
```

## 部署

1. 访问 https://four.meme/zh-TW/contract/create
2. 上传合约文件
3. 填写信息并提交审核
