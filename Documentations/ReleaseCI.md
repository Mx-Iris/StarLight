# 发布 CI 与本地发布脚本

本仓库的发布完全自动化，**绝大多数情况只需要做两件事**：

1. 写一份 `ReleaseNotes/<tag>.md`。
2. 在 `main` 上打个 `vX.Y` 的 tag 并推到 GitHub。

剩下的 CI 都会处理：建临时 keychain → 导入 Developer ID 证书 → archive → export → 走 App Store Connect API 公证 → staple → 打 zip → 上传到 GitHub Release。

如果未来想脱离 GitHub Actions 在本地发布，同一份 `scripts/release.sh` 直接可以跑，参数靠环境变量切。

---

## 一、CI 流程概览

### 触发方式

`.github/workflows/release.yml` 监听两种事件：

| 触发 | 说明 |
|------|------|
| `push` 到 `v*` tag | 正常发版路径。打完 tag 推上去 CI 自动跑。 |
| `workflow_dispatch`（带 `tag` 输入） | 重跑路径。比如证书过期重续后重新打同一个版本。 |

两种方式共用同一个 job，会先 checkout 到指定 tag。

### 必做的硬约束

**`ReleaseNotes/<tag>.md` 必须存在且非空，否则 CI 在签名前就直接失败。** 这是 CI 设计上的一条硬规则：宁可不发，也不发一个没有 release notes 的版本。

### Job 步骤

1. 解析 tag（从 `GITHUB_REF` 或 `inputs.tag`）
2. checkout 到该 tag
3. 校验 `ReleaseNotes/<tag>.md` 存在且非空（不通过直接报错退出）
4. 打印 `xcodebuild -version` 和 `swift --version` 留痕
5. 调 `scripts/release.sh` 完成构建 + 公证 + 打包
6. 上传 artifact 到 Actions（保留 14 天，方便调试）
7. `gh release create` / `gh release upload` 发布

整个 job 用 `concurrency` 锁防止同 tag 双跑互踩。

---

## 二、需要在 GitHub 仓库里配的 6 个 Secrets

到 `https://github.com/Mx-Iris/StarLight/settings/secrets/actions` 配下面 6 个 repository secret：

| Secret | 用途 | 怎么拿 |
|--------|------|--------|
| `MACOS_CERTIFICATE_BASE64` | Developer ID Application 证书（含私钥）的 base64 | 见 §3.1 |
| `MACOS_CERTIFICATE_PASSWORD` | 上面 .p12 的导出密码 | 自己定 |
| `KEYCHAIN_PASSWORD` | CI runner 上临时 keychain 的密码 | 任意字符串即可，建议用密码生成器 |
| `NOTARY_API_KEY_BASE64` | App Store Connect API 私钥 .p8 文件的 base64 | 见 §3.2 |
| `NOTARY_API_KEY_ID` | API Key ID（10 字符大写字母数字） | 在 App Store Connect 创建 key 时显示 |
| `NOTARY_API_ISSUER_ID` | Issuer UUID | App Store Connect → Users and Access → Integrations 页顶 |

---

## 三、生成各项凭证

### 3.1 Developer ID Application 证书（base64）

如果你本机 Xcode 里已经能正常 Archive + Export Developer ID 应用，证书已经在登录 keychain 里了。导出方法：

1. 打开 *钥匙串访问.app* → *登录* keychain → *我的证书* 分类
2. 找到 `Developer ID Application: <Your Name> (D5Q73692VW)`，展开它前面的箭头能看到对应的私钥
3. **同时选中证书和私钥两项** → 右键 → *导出 2 项…*
4. 文件格式选 *Personal Information Exchange (.p12)*，保存（比如 `~/Desktop/devid.p12`）
5. 设一个导出密码（这就是 `MACOS_CERTIFICATE_PASSWORD`）
6. 终端里把 .p12 转成 base64：

   ```bash
   base64 -i ~/Desktop/devid.p12 | pbcopy
   ```

   现在剪贴板里就是 `MACOS_CERTIFICATE_BASE64` 的值。

如果你本机没有 Developer ID Application 证书，去 [https://developer.apple.com/account/resources/certificates/list](https://developer.apple.com/account/resources/certificates/list) 用 CSR 申请一个，然后双击导入到钥匙串再走上面流程。

### 3.2 App Store Connect API Key（.p8 + Key ID + Issuer UUID）

公证走 API Key 比走 Apple ID + App-specific Password 稳，也不怕 2FA 折腾。

1. 打开 [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)
2. 顶部能看到 **Issuer ID**（UUID 格式，例如 `12345678-1234-1234-1234-1234567890ab`）—— 这是 `NOTARY_API_ISSUER_ID`
3. 点 **Generate API Key**（或 `+`），名字随便起，*Access* 选 **Developer**（公证只需要这个权限）
4. 创建完页面会显示一个 10 字符的 **Key ID**（例如 `ABCD1234EF`）—— 这是 `NOTARY_API_KEY_ID`
5. **立刻下载** `AuthKey_<KEY_ID>.p8` 文件（只能下载一次，关掉就拿不回来了，必须重新生成）
6. 转 base64：

   ```bash
   base64 -i AuthKey_ABCD1234EF.p8 | pbcopy
   ```

   剪贴板里就是 `NOTARY_API_KEY_BASE64`。

7. 上传完 secret 后建议把本地的 .p8 文件删掉或挪到 1Password 之类的安全位置。

### 3.3 `KEYCHAIN_PASSWORD`

任意字符串。这个 keychain 只在 CI runner 上活几分钟，跑完就会被销毁，所以怎么填都行，但建议用一个 32 字符的随机串：

```bash
openssl rand -base64 24 | pbcopy
```

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

### 重跑（公证失败 / 临时回退）

到 Actions → Release → **Run workflow**，输入 `v1.7` 重新执行。如果 Release 已经存在，CI 会用 `--clobber` 覆盖原 asset。

### 删 tag 重发

```bash
# 删本地 + 远端 tag，但要先删 GitHub 上的 Release（gh release delete v1.7）
gh release delete v1.7 --yes
git push origin :refs/tags/v1.7
git tag -d v1.7
# 修完代码 / release notes 之后重新打 tag 重推
```

---

## 五、本地脱离 GitHub Actions 发布

`scripts/release.sh` 在本地可以直接跑，证书和公证凭证两种来源都支持。

### 模式 1：用你本地登录 keychain 里的证书（最方便）

如果你电脑上已经能正常 Archive 出 Developer ID 应用，证书已经在登录 keychain 里。先用 `notarytool` 在登录 keychain 里存一份公证 profile：

```bash
xcrun notarytool store-credentials starlight-notary \
    --key ~/Path/To/AuthKey_ABCD1234EF.p8 \
    --key-id ABCD1234EF \
    --issuer 12345678-1234-1234-1234-1234567890ab
```

然后发版：

```bash
RELEASE_TAG=v1.7 \
NOTARY_KEYCHAIN_PROFILE=starlight-notary \
./scripts/release.sh
```

`MACOS_CERTIFICATE_BASE64` 没设，脚本会自动走"用登录 keychain"模式；`NOTARY_KEYCHAIN_PROFILE` 设了，公证就走存好的 profile。

### 模式 2：模拟 CI 环境（用 .p12 + base64 + API key）

```bash
export RELEASE_TAG=v1.7
export MACOS_CERTIFICATE_BASE64="$(base64 -i ~/Desktop/devid.p12)"
export MACOS_CERTIFICATE_PASSWORD="..."
export KEYCHAIN_PASSWORD="..."
export NOTARY_API_KEY_BASE64="$(base64 -i ~/Path/To/AuthKey_ABCD1234EF.p8)"
export NOTARY_API_KEY_ID="ABCD1234EF"
export NOTARY_API_ISSUER_ID="12345678-1234-1234-1234-1234567890ab"

./scripts/release.sh
```

跑完 `build/dist/StarLight-v1.7.zip` 就是要传的产物，可以手动 `gh release create` 或拖到 GitHub Release 页面。

---

## 六、常见错误

| 现象 | 原因 / 解决 |
|------|--------|
| `Release notes file 'ReleaseNotes/v1.7.md' is missing.` | 没写 release notes 就打了 tag。补写文件、删 tag、重打。 |
| `errSecInternalComponent` 公证时 | 证书或私钥导出不完整，重新走 §3.1 同时选中证书+私钥重新导出 .p12。 |
| `Invalid key file` | base64 含换行或 BOM。用 `base64 -i <file>` 重新生成；不要手动复制带换行的内容粘贴进 secret 输入框。 |
| `The signature does not include a secure timestamp` | 没联网或 codesign 时 timestamp 服务器不可达。CI runner 网络偶发抖动，重跑 workflow。 |
| `Status: Invalid` 公证返回 | 二进制本身有问题（未签名 dylib / 缺 hardened runtime / 未启用 sandbox 但 entitlement 含 sandbox key 等）。下载 notarytool 的 log 看：`xcrun notarytool log <submission-id> --keychain-profile <profile>`。 |
