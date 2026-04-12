# Flutter Web 静态部署说明

本地构建产物目录：**`build/web/`**（将整个目录上传到静态托管根目录，或子目录）。

## 1. 本地构建

在项目根目录执行：

```bash
flutter build web --release
```

- 部署在**网站根路径**（如 `https://wardrobe.example.com/`）：一般无需改 base，默认即可。
- 部署在**子路径**（如 `https://user.github.io/wardrobe_app/`）：必须带 base：

```bash
flutter build web --release --base-href=/wardrobe_app/
```

`--base-href` 必须以 `/` 开头并以 `/` 结尾。

### 1.1 关于「Gitee → 服务」里找不到 Gitee Pages

仓库顶栏 **「服务」** 里一般是 **第三方集成**（Sonar、腾讯云托管等），**不是**以前的「Gitee Pages 静态站」。  
近年 Gitee 对 **普通用户 / 新仓库** 的 **Gitee Pages 已下线或收紧**，所以很多人 **菜单里根本没有「Gitee Pages」**，这不是你点错了。

**结论**：静态网页请改用下面之一部署 **`build/web`**（或脚本生成的 **`wardrobe_app-web.zip`**）：

- **国内常用**：**腾讯云 COS「静态网站」**（见本文 §4）、阿里云 OSS 静态页等。  
- **国外常用**：**GitHub Pages**、Cloudflare Pages、Netlify（把 `build/web` 或 zip 传上去即可）。

下面脚本仍可用于 **带 `/wardrobe_app/` 子路径** 的构建（例如将来镜像到 GitHub `username.github.io/wardrobe_app`）；若你部署在 **域名根路径**，请改用 §1 里无 `--base-href` 的构建命令。

### 1.2 一键构建 + zip（原 Gitee Pages 脚本，仍可用）

- 若曾计划使用 Gitee 项目站，默认子路径为：`/wardrobe_app/`（与仓库名一致）。

在本机项目根任选一种方式：

**方式 A（推荐，不受执行策略限制）**：双击或在终端执行

```text
scripts\build_web_gitee_pages.cmd
```

**方式 B**：在 PowerShell 里对单文件绕过策略

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_web_gitee_pages.ps1
```

若希望长期允许本机脚本，可在 **管理员或当前用户** 下执行 `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`（自行评估安全策略后再改）。

脚本会依次：

1. `flutter build web --release --base-href=/wardrobe_app/`  
2. 生成 **`404.html`**（与 `index.html` 相同，便于刷新/深链不白屏）  
3. 在仓库根生成 **`wardrobe_app-web.zip`**，便于在 Gitee Pages 控制台 **本地上传**（若你的套餐支持）

部署完成后，把 **浏览器里实际打开的 https 地址**（含路径）填进 **Supabase → Authentication → URL Configuration** 的 **Site URL / Redirect URLs**。

（若已不再使用 `*.gitee.io`，请改成你 COS / GitHub Pages 等上的真实域名。）

## 2. Nginx

将 `build/web/` 内所有文件放到站点根（或 `location` 对应目录），并保证 **SPA 回退到 index.html**（否则直接打开子路由或刷新会 404）：

```nginx
server {
    listen 80;
    server_name wardrobe.example.com;
    root /var/www/wardrobe-web;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # 可选：缓存带 hash 的静态资源
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }
}
```

若使用 **子路径** `https://example.com/app/`，`root` 指向子目录，且构建时已使用匹配的 `--base-href=/app/`。

## 3. GitHub Pages

### 方案 A：项目页 `https://<user>.github.io/<repo>/`

1. 构建（注意 base 与仓库名一致）：

   ```bash
   flutter build web --release --base-href=/<repo>/
   ```

2. **GitHub Pages 对 SPA 的惯例**：把 `index.html` 再复制一份为 **`404.html`**（未知路径会返回 404 页，复制后仍加载同一套 Flutter，由前端路由接管）：

   ```powershell
   .\scripts\copy_web_spa_404.ps1
   ```

3. 将 **`build/web/`** 全部内容推到 `gh-pages` 分支，或在 Actions 里 `actions/upload-pages-artifact` 上传该目录。

4. 仓库 **Settings → Pages**：Source 选对应分支/目录（常为 `/ (root)`）。

### 方案 B：用户/组织页根域名

若站点在仓库根 `https://<user>.github.io/`（无子路径），使用：

```bash
flutter build web --release
```

再执行 `copy_web_spa_404.ps1` 后上传 `build/web/`。

## 4. 腾讯云 COS「静态网站」

1. 创建存储桶，开启 **静态网站**，索引文档设为 **`index.html`**。
2. 错误文档也指向 **`index.html`**（或与 GitHub 一样上传 **`404.html`** 为 `index.html` 副本，按控制台说明操作），避免刷新子路径 404。
3. 使用控制台或 `coscmd`/`coscli` 将 **`build/web/` 下全部文件**（含 `assets/`、`canvaskit/` 等）上传到网站根路径；若挂在子目录，构建时使用对应 `--base-href`。
4. 若绑定自定义域名，配置 HTTPS 证书。
5. **跨域**：若前端直连 Supabase 等 API，一般无需改 COS；若报 CORS，到 **Supabase 控制台 → Authentication → URL Configuration** 把站点 origin 加入允许列表。

## 5. 环境与密钥（重要）

- Web 会把 **`assets/env/app.env`** 打进包体，**切勿把生产密钥提交到公开仓库**；对外演示可用 `app.env.example` 或单独构建流水线注入。
- **Supabase Auth**：在控制台把部署后的 **Site URL / Redirect URLs** 写成真实页面地址（含 `https` 与路径），否则登录回调会失败。

## 6. 本项目的 Web 能力说明

- 当前 Web 构建已通过；Isar 等 **dart:ffi** 在 Web 上不可用，工程内已通过 **条件导入** 走内存/云端等路径，与移动端行为可能略有差异，部署后请在浏览器自测核心流程。

## 7. 可选脚本

- **`scripts/build_web_gitee_pages.ps1`**：针对本仓库 Gitee Pages 的 **一键构建 + 404 + zip**（见 §1.1）。  
- **`scripts/copy_web_spa_404.ps1`**：仅复制 `404.html`；GitHub Pages / 自建 Nginx 也可用。
