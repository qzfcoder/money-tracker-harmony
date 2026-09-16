# 闪控球自动记账实验功能

当前发布版默认关闭该功能，避免额外权限影响审核。

## 发布版状态

- `FeatureFlags.AUTO_BOOKKEEPING_VISIBLE = false`
- `FeatureFlags.FLOATING_BALL_VISIBLE = false`
- `entry/src/main/module.json5` 不申请权限
- `main_pages.json` 不注册 `pages/AutoBookkeeping`

## 实验包开启步骤

1. 修改 `entry/src/main/ets/constants/FeatureFlags.ets`：

```ts
static readonly AUTO_BOOKKEEPING_VISIBLE: boolean = true;
static readonly FLOATING_BALL_VISIBLE: boolean = true;
```

2. 在 `entry/src/main/resources/base/profile/main_pages.json` 添加：

```json
"pages/AutoBookkeeping"
```

3. 在 `entry/src/main/module.json5` 的 `requestPermissions` 中添加闪控球权限：

```json5
{
  "name": "ohos.permission.USE_FLOAT_BALL",
  "reason": "$string:float_ball_permission_reason",
  "usedScene": {
    "abilities": [
      "EntryAbility"
    ],
    "when": "inuse"
  }
}
```

4. 在 `entry/src/main/resources/base/element/string.json` 添加权限说明：

```json
{
  "name": "float_ball_permission_reason",
  "value": "用于用户主动点击闪控球后回到应用进行账单识别确认"
}
```

## 测试流程

1. 进入 `pages/AutoBookkeeping`。
2. 打开“自动记账总开关”。
3. 打开“闪控球入口”。
4. 切到支付宝、微信或银行账单页面。
5. 用户主动点击闪控球。
6. 应用回到自动记账页，并进入截图识别流程。
7. 识别结果先进入“待确认账单”，确认后才正式入账。

## 边界

- 该实现不后台抓取内容，不后台截屏。
- 当前代码使用系统闪控球 click 事件作为用户主动触发入口。
- OCR 仍依赖系统本机识别能力；模拟器或部分云调试设备可能不可用。
- 如需真正识别其它 App 当前屏幕，必须使用系统允许的屏幕捕获能力，并在审核材料里解释用途和用户主动触发流程。
