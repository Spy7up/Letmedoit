# letmedoit-miniprogram · 小程序端

「让我做」微信小程序前端，原生 WXML/WXSS。项目整体介绍见[根目录 README](../README.md)，设计结论见 [`doc/design/让我做-总设计文档.md`](../doc/design/让我做-总设计文档.md)。

## 开发现状

**v1.0.0 已发布上线**（`ENV='prod'` → `https://letmedoit.site/gateway`）。已实现：微信登录与首登引导、帮手（邀请码/申请/解除）、任务全状态机（布置/接受/拒绝/完成/撤回/删除/催办/追加参与者）、两种完成条件、定时生效与到期提醒、站内通知中心、头像昵称、问题与反馈、账号注销、协议阅读、隐私授权弹窗、举报入口、版本接口下发。

自检全绿（在**本目录**下执行）：

```bash
node tools/check.js                 # 静态检查（页面四件套、语法、require、图片引用）
node tools/sim.js                   # 离线自检（契约替身 + 桩跑真实页面）
node tools/e2e.js <baseUrl>         # 真后端联调（需 sa-app 已启动且 wx.miniapp.mock=true），当前 156 项全通过
node tools/gen-assets.js            # 改了图标定义后重新生成图标
```

## 开发注意事项

- **跑起来**：微信开发者工具「导入项目」选 `letmedoit-miniprogram`（不是里层 `miniprogram`）；基础库 ≥ 2.32.3；本地联调勾「不校验合法域名」。
- **环境切换**：`miniprogram/config/index.js` 的 `ENV`。`dev` → 局域网 sa-app（本机回退 `http://127.0.0.1:1025`）；`prod` → 线上。e2e 必须显式传地址。
- **页面铁律**：页面里不出现 `wx.request`、不出现 URL 字面量、不判断 `res.code`；一律 `services/*` → `utils/request.js`；VO → 页面模型只隔一层 `services/adapt.js`。
- **tabBar 页只能 `wx.switchTab`**；分享/外部入口一律过 `utils/entry.js#ensureEntry(route)`；页面不做静默登录。
- **原生组件 box-sizing**：`app.wxss` 全局重置必须含 `input/textarea/button`，否则 `width:100%` 加 padding 会撑出屏幕。
- **昵称头像**：不调 `wx.getUserProfile`；`input type="nickname"` 按非受控用；`chooseAvatar` 临时路径必须先 `services/file.js#uploadImage()` 换公网 URL，临时路径绝不入库。
- **版本号**：页面禁止写死，一律 `services/version.js#current()`。
- **设计规则**：配色/字号/间距令牌、液态玻璃纪律、状态与文案规范见总设计文档第 9 章；完整开发规范见 [`docs/AI-Agent-小程序开发规范.md`](./docs/AI-Agent-小程序开发规范.md)。

## 目录速览

```
letmedoit-miniprogram/
├── project.config.json      # 工程配置（AppID wxaa5051e002ac4fba）
├── miniprogram/
│   ├── app.js / app.json / app.wxss
│   ├── custom-tab-bar/      # 悬浮液态玻璃 tabBar
│   ├── pages/               # tasks / helpers / messages / mine / launch / onboarding / agreement
│   ├── components/          # privacy-popup、user-avatar
│   ├── services/            # 领域方法 + adapt.js（VO→页面模型）
│   ├── utils/               # request / entry / format / present / avatar
│   ├── constants/           # 状态与文案映射（唯一出口）
│   └── config/              # 环境开关
├── assets/logo/             # Logo 源文件与各尺寸导出
├── docs/                    # 开发规范
└── tools/                   # check / sim / e2e / contract-server / gen-assets
```
