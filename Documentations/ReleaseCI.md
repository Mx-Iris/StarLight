# 发布 CI 与本地发布

发版由通用发版引擎 [AppRelease](https://github.com/Mx-Iris/AppRelease) 执行，配置在仓库根目录的
`Release.zsh`。**绝大多数情况只需要做两件事**：

1. 写一份 `ReleaseNotes/<tag>.md`。
2. 在 `main` 上打个 `vX.Y` 的 tag 并推到 GitHub。

剩下的 CI 都会处理：预检 → archive → Developer ID 导出 → 走 App Store Connect API 公证 → staple →
打 zip → 建 GitHub Release。同一份 `Release.zsh` 在本机也能发版，见第五节。

2026-11 起改由 AppRelease 执行，依据是它的提案《通用 Mac 发版引擎 AppRelease》；之前的
`scripts/release.sh` 已删除。那份 workflow 加进来之后一次都没运行过，仓库当时也没有配 secrets，
v1.4 及更早的版本都是 CI 之前发的。

---

## 一、CI 流程概览

### 触发方式

`.github/workflows/release.yml` 有三种跑法：

| 触发 | 做什么 |
|------|--------|
| `push` 到 `v*` tag | 正常发版：构建、公证，并发布这个 tag。 |
| 手动运行，填 `tag` | 重新构建并发布一个已有的 tag，比如证书过期重续之后。Release 已存在时覆盖它的 zip。 |
| 手动运行，`tag` 留空 | 只构建、公证所选的分支，产物留在 Actions 的 artifact 里，**什么都不发布**。发版前试跑用。 |

同一个 tag 或分支同时只跑一个（`concurrency`），防止两次运行互相覆盖。runner 是 `macos-26`，用它的
默认 Xcode；AppRelease 开头打印的计划里写着具体版本。

### 必做的硬约束

**`ReleaseNotes/<tag>.md` 必须存在且非空，否则在构建之前就失败。** 宁可不发，也不发一个没有 release
notes 的版本。这道检查由 AppRelease 的预检完成（`release_notes_path`，1.1.1 起在预检里查）。

### Job 步骤

1. checkout 到 tag；手动运行且没填 tag 时是所选的分支
2. 按 `Release.zsh` 钉住的版本拉下 AppRelease，跑 `app-release all`；发版时加
   `--version-tag <tag> --publish`
3. 把 `StarLight-<tag>.zip` 和 `SHA256SUMS` 作为 artifact 上传，保留 14 天
4. 失败时另外上传每一步 `xcodebuild` 的完整日志 —— 终端里只显示失败摘要

AppRelease 在 runner 上建临时钥匙串导入证书，结束时（包括失败）删掉；公证只认结果里的 `status`；
staple 之后核对 Gatekeeper 认作 `Notarized Developer ID`，zip 解开再验一次。

---

## 二、需要在 GitHub 仓库里配的 5 个 Secrets

到 `https://github.com/Mx-Iris/StarLight/settings/secrets/actions` 配下面 5 个 repository secret：

| Secret | 用途 | 怎么拿 |
|--------|------|--------|
| `MACOS_CERTIFICATE_BASE64` | Developer ID Application 证书（含私钥）的 base64 | 见 §3.1 |
| `MACOS_CERTIFICATE_PASSWORD` | 上面 .p12 的导出密码 | 自己定 |
| `NOTARY_API_KEY_BASE64` | App Store Connect API 私钥 .p8 文件的 base64 | 见 §3.2 |
| `NOTARY_API_KEY_ID` | API Key ID（10 字符大写字母数字） | 在 App Store Connect 创建 key 时显示 |
| `NOTARY_API_ISSUER_ID` | Issuer UUID | App Store Connect → Users and Access → Integrations 页顶 |

workflow 把它们映射成 AppRelease 读的 `APP_RELEASE_*` 环境变量。临时钥匙串的密码由 AppRelease
自己生成，不再需要 `KEYCHAIN_PASSWORD`。

---

## 三、生成各项凭证

### 3.1 Developer ID Application 证书（base64）

如果你本机 Xcode 里已经能正常 Archive + Export Developer ID 应用，证书已经在登录 keychain 里了。导出方法：

1. 打开 *钥匙串访问.app* → *登录* keychain → *我的证书* 分类
2. 找到 `Developer ID Application: <Your Name> (D5Q73692VW)`，展开它前面的箭头能看到对应的私钥
3. **同时选中证书和私钥两项** → 右键 → *导出 2 项…*
4. 文件格式选 *Personal Information Exchange (.p12)*，保存（比如 `~/Desktop/devid.p12`）
5. 设一个导出密码（这就是 `MACOS_CERTIFICATE_PASSWORD`）
6. 直接从文件写进 secret，不经过剪贴板：

   ```bash
   base64 -i ~/Desktop/devid.p12 | gh secret set MACOS_CERTIFICATE_BASE64 --repo Mx-Iris/StarLight
   gh secret set MACOS_CERTIFICATE_PASSWORD --repo Mx-Iris/StarLight   # 提示时输入导出密码
   ```

如果你本机没有 Developer ID Application 证书，去 [https://developer.apple.com/account/resources/certificates/list](https://developer.apple.com/account/resources/certificates/list) 用 CSR 申请一个，然后双击导入到钥匙串再走上面流程。

### 3.2 App Store Connect API Key（.p8 + Key ID + Issuer UUID）

公证走 API Key 比走 Apple ID + App-specific Password 稳，也不怕 2FA 折腾。

1. 打开 [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)
2. 顶部能看到 **Issuer ID**（UUID 格式，例如 `12345678-1234-1234-1234-1234567890ab`）—— 这是 `NOTARY_API_ISSUER_ID`
3. 点 **Generate API Key**（或 `+`），名字随便起，*Access* 选 **Developer**（公证只需要这个权限）
4. 创建完页面会显示一个 10 字符的 **Key ID**（例如 `ABCD1234EF`）—— 这是 `NOTARY_API_KEY_ID`
5. **立刻下载** `AuthKey_<KEY_ID>.p8` 文件（只能下载一次，关掉就拿不回来了，必须重新生成）
6. 写进 secret：

   ```bash
   base64 -i AuthKey_ABCD1234EF.p8 | gh secret set NOTARY_API_KEY_BASE64 --repo Mx-Iris/StarLight
   gh secret set NOTARY_API_KEY_ID --repo Mx-Iris/StarLight --body ABCD1234EF
   gh secret set NOTARY_API_ISSUER_ID --repo Mx-Iris/StarLight --body 12345678-1234-1234-1234-1234567890ab
   ```

7. 上传完 secret 后建议把本地的 .p8 文件删掉或挪到 1Password 之类的安全位置。

---

## 四、发版操作流程

正常发 `v1.7`：

```bash
# 1. 主分支上的代码已经是要发的状态
git checkout main
git pull

# 2. 提前写好 release notes
$EDITOR ReleaseNotes/v1.7.md
git add ReleaseNotes/v1.7.md
git commit -m "docs: release notes for v1.7"
git push

# 3. 打 tag 并推送，CI 自动跑
git tag v1.7
git push origin v1.7
```

去 [Actions 页](https://github.com/Mx-Iris/StarLight/actions) 看一下，几分钟内就会出现新 Release。
tag 必须与 `MARKETING_VERSION` 一致（`v1.7` 对 `1.7`），对不上会在预检里失败。

### 发版前试跑

Actions → Release → **Run workflow**，选要试的分支，`tag` 留空。它会完整走一遍构建和公证，但不打 tag、
不建 Release，zip 在这次运行的 artifact 里。

### 重跑（公证失败 / 证书重续之后）

Actions → Release → **Run workflow**，`tag` 填 `v1.7`。如果 Release 已经存在，只用 `--clobber` 覆盖
原来的 zip，说明不动。

### 删 tag 重发

```bash
# 删本地 + 远端 tag，但要先删 GitHub 上的 Release（gh release delete v1.7）
gh release delete v1.7 --yes
git push origin :refs/tags/v1.7
git tag -d v1.7
# 修完代码 / release notes 之后重新打 tag 重推
```

---

## 五、在本机发版

装一次 AppRelease 的启动器（双击它仓库里的 `Install app-release.command`），之后在仓库里：

```bash
app-release all                               # 构建、公证、打包，不发布
app-release all --version-tag v1.7 --publish  # 另外打 tag、推送、建 GitHub Release
app-release all --dry-run                     # 只打印每条命令
```

签名用登录钥匙串里的 Developer ID 证书。公证用 `Release.zsh` 里写的钥匙串配置
`notarytool-password`，没有就先存一份：

```bash
xcrun notarytool store-credentials notarytool-password \
    --key ~/Path/To/AuthKey_ABCD1234EF.p8 \
    --key-id ABCD1234EF \
    --issuer 12345678-1234-1234-1234-1234567890ab
```

产物在 `build/AppRelease/StarLight/<版本>-<构建号>/Products/StarLight-<tag>.zip`，每一步的
`xcodebuild` 日志在同一目录的 `logs/` 下。锁屏时 notarytool 读不到钥匙串里的配置：先
`app-release all --to export` 跑完前三段，解锁后 `app-release all --from notary` 接着跑。

---

## 六、常见错误

| 现象 | 原因 / 解决 |
|------|--------|
| `release_notes_path: no release notes at …/ReleaseNotes/v1.7.md` | 没写 release notes 就打了 tag，或文件是空的。补写文件、删 tag、重打。 |
| `the tag v1.7 does not match the app's version` | tag 与 `MARKETING_VERSION` 不一致。改版本号或改 tag。 |
| `no "Developer ID Application" identity of team D5Q73692VW in the keychain` | CI 上是 secrets 没配好，或 .p12 只导出了证书、没带私钥（重新走 §3.1，同时选中两项导出）；本机是登录钥匙串里没有这张证书。 |
| `the notary service refused these credentials or could not be reached` | API key 三项不对，或 base64 含换行（用 `base64 -i <file>` 重新生成）；本机还可能是锁屏，或钥匙串配置名不对。 |
| 公证结果 `Invalid` | 二进制本身有问题（未签名的 dylib、缺 hardened runtime 等）。AppRelease 会取回 notarytool 的日志并列出问题。 |
| 本机经 ssh 发版被拒 | ssh 会话拿不到登录钥匙串，codesign 会报 `errSecInternalComponent`，所以 AppRelease 直接拒绝。回本机终端发，或改用 CI。 |
