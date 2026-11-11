# 小程序端开发规范（面向 AI Agent）

> 读者：接下来要在 `letmedoit-miniprogram/` 里写代码的 AI Agent / 新同事。
> 目标：不动现有架构约定就能加页面、接接口、改样式。
> 业务规则与 UI 设计结论的唯一来源：`../../doc/design/让我做-总设计文档.md`（本文只写怎么写代码，不重复业务定义）。

---

## 0. 动手前 5 行

1. 页面里**禁止**出现 `wx.request`、URL 字面量、`res.code` 判断 —— 一律走 `services/*`。
2. 后端 VO 与页面模型之间只隔一层 `services/adapt.js`，页面永远只看到一套字段。
3. 改完跑 `node tools/check.js` + `node tools/sim.js`；动了接口契约再跑 `node tools/e2e.js <baseUrl>`。
4. tabBar 页跳转只能 `wx.switchTab`；分享/外部入口一律过 `utils/entry.js#ensureEntry(route)`。
5. 样式先看总设计文档第 9 章的设计令牌，颜色全走 CSS 变量，不写死色值。

---

## 1. 分层与调用链

```
pages/            ← 只做渲染与交互：try { await taskApi.complete(id, dto) } catch (e) { toast }
  └ services/     ← 领域方法（task.accept / notice.list），一个文件一个领域
      ├ adapt.js        VO → 页面模型：ID 转字符串、状态数字转枚举、时间转展示结构（唯一转换层）
      └ utils/request.js  统一信封拆包、App-Token 注入、30007 静默重登重放、错误提示
          └ config/index.js  ENV 切换（dev / prod），baseUrl 唯一出处
```

- 新增接口：在对应 `services/xxx.js` 加方法 → 在 `adapt.js` 加转换（如需要）→ 页面调用。**不要**在页面里拼参数形状以外的任何请求细节。
- `services/notice.js` 是只读的：通知卡片字段由服务端 `fields_json` 直接驱动，前端不拼。

## 2. 入口与登录

- 所有分享/外部进入点（`tasks/receive`、`helpers/invite`、`tasks/detail`、三个 tab 首页）第一行走 `ensureEntry(route)`：无 token → `reLaunch` 登录页 → 新用户走 `pages/onboarding/index` 引导 → 回原页（route 必须含 query）。
- 页面**不做静默登录**（`ensureLogin()` 会替新用户注册「用户XXXX」，引导页永远走不到）。
- 用户资料缓存 key 是 `lmd_user`（`app.setUser/clearUser`）；冷启动 `restoreUser()` 先渲染缓存；退出登录必须清。
- 版本号一律 `services/version.js#current()`（内存 + `lmd_app_version` 缓存），页面禁止版本字面量。

## 3. 状态与常量

- 状态文案/色值/映射唯一出口：`constants/task.js`（任务 6 态 + 参与者 5 态）。新增状态先改这里，不要在页面里写「待接受」字面量。
- 权限位（`canAccept/canComplete/canEdit/canRemind/canDelete/...`）只读服务端返回值，前端不自己推。列表的 `showRemind` 走 `present.js#presentTask`（`isCreator`），不用 `wx:else` 兜底。

## 4. 硬约束（踩过的坑，别回退）

| 约束 | 原因 |
|---|---|
| `app.wxss` 全局 box-sizing 重置必须含 `input/textarea/button` | 原生组件不受 `*` 影响，`width:100%`+padding 会撑出屏幕 |
| tabBar 页只能 `wx.switchTab` | `redirectTo/navigateTo` 静默失败，页面无反应 |
| 自定义 tabBar 每页 `onShow` 同步 `this.getTabBar().setData({selected:n})` | 组件实例按页面独立，不同步高亮会错 |
| 悬浮 tabBar 页面底部留 `tab-space`，列表页 `padding-bottom` 给够 | 内容从胶囊底下穿过，最后一项必须完整可见 |
| 昵称头像不调 `wx.getUserProfile` | 2022-10 起只回「微信用户」+灰头像；用 `chooseAvatar` + `input type="nickname"` |
| `input type="nickname"` 按非受控用 | `value` 只绑初始值，打字时绝不 setData 回写，提交从 `e.detail.value.nickname` 取 |
| `chooseAvatar/chooseMedia` 临时路径绝不入库 | 必须先 `services/file.js#uploadImage(path, bizType)` 换公网 URL；`isRemoteAvatar()` 只认 http(s) |
| 头像两层兜底 | `present.js#presentUser` 输出默认头像（昵称末字+稳定色块）永不为空；`<image>` 必须带 `binderror` |
| 时间解析走 `utils/format.js#parseTime` | 先识别带时区标记的 ISO 再给 `new Date()`，否则偏一个时区；后端格式 `yyyy-MM-dd HH:mm:ss` |
| 涉及相册/头像/摄像头的页面挂 `components/privacy-popup` | 已挂：onboarding / mine-profile / tasks-create / tasks-complete / mine-feedback |
| 删除任务二次确认，无上一页时 `switchTab` | 删除入口只对「已撤回 + 委托人」开放 |

## 5. 设计要求（摘要，全文见总设计文档第 9 章）

- **风格**：暖、轻、有人味。米白纸感底 `--bg:#F7F4F1` + 珊瑚橘 `--brand:#FF6B4A` + 大圆角卡片（32rpx）+ 极轻阴影。
- **间距**：8rpx 基准；页面左右 32rpx；卡片内边距 26rpx、间距 22rpx。
- **液态玻璃全页最多两处**（首页 banner + tabBar）：折射源用 `radial-gradient` 色斑（不用 `filter:blur` 圆形），必须 `@supports` 降级，玻璃里放结论不放列表，不给卡片/列表项加 blur。
- **状态用色不用形**；动作固定在拇指区（`padding-bottom: env(safe-area-inset-bottom)`）。
- **每页必须实现**：骨架屏、下拉刷新、空态文案、错误重试、提交 loading。
- **文案去企业化**：「已交给小王，等 TA 接单」而不是「任务创建成功」。语气表见总设计文档 §9.6。

## 6. 自检（在 `letmedoit-miniprogram/` 下）

```bash
node tools/check.js                 # 静态检查：页面四件套、JS 语法、require 路径、图片引用、跳转目标、事件绑定
node tools/sim.js                   # 离线自检：契约替身 + 桩跑真实页面，不需要数据库
node tools/e2e.js http://127.0.0.1:1025   # 真后端联调：sa-app 已启动且 wx.miniapp.mock=true，156 项
node tools/gen-assets.js            # 改图标定义后重新生成 miniprogram/images/icons
```

交付标准：check / sim 全绿；动了接口契约时 e2e 全绿。

## 7. 资源

- Logo：`assets/logo/icon.svg` 是矢量源文件，改色改比例改这里；各尺寸 PNG 用 `assets/logo/render.html` 经无头浏览器导出。
- 原型：`doc/prototype/index.html`（按模块拆分的高保真页面，浏览器直接打开）。
