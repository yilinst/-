<#
================================================================
    一键上传代码到 GitHub
================================================================
    使用方法：
      把本文件(和同目录的 一键上传.bat)复制到你的项目文件夹里，
      双击 一键上传.bat 即可。

    它会自动完成：
      1. 初始化 Git 仓库（新项目）
      2. 创建 .gitignore（防止上传密钥）
      3. 打开浏览器创建 GitHub 仓库（只需点一下按钮）
      4. 提交代码
      5. 推送到 GitHub
================================================================
#>

$Host.UI.RawUI.WindowTitle = "一键上传到 GitHub"
$ErrorActionPreference = "Continue"

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$GH_USER = "yilinst"

function Line  { param($t, $c = "Gray")  Write-Host $t -ForegroundColor $c }
function Step  { param($n, $t)           Write-Host "`n[$n] $t" -ForegroundColor Cyan }
function Ok    { param($t)               Write-Host "    v $t" -ForegroundColor Green }
function Err   { param($t)               Write-Host "    x $t" -ForegroundColor Red }
function Warn  { param($t)               Write-Host "    ! $t" -ForegroundColor Yellow }
function Pause2 { param($t = "按回车键继续") Write-Host ""; Read-Host $t }

Write-Host ""
Line "============================================" "White"
Line "        一键上传代码到 GitHub" "White"
Line "============================================" "White"

Set-Location -Path $PSScriptRoot
Line "`n项目目录: $PWD`n" "DarkGray"

# ============ 0. 检查 git ============
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Err "找不到 git 命令"
    Warn "Git 安装在 E:\Git。如果你刚装完 Git，请关掉这个窗口重新双击。"
    Pause2
    exit 1
}

# ============ 1. 初始化 ============
if (-not (Test-Path ".git")) {
    Step "1/5" "初始化 Git 仓库..."
    git init 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Err "初始化失败"; Pause2; exit 1 }
    Ok "已初始化"
} else {
    Step "1/5" "已是 Git 仓库，跳过"
    Ok "跳过"
}

# ============ 2. .gitignore ============
if (-not (Test-Path ".gitignore")) {
    Step "2/5" "创建 .gitignore..."
    $content = @(
        '# 编译产物',
        '*.exe',
        '*.obj',
        '*.o',
        '*.out',
        'a.out',
        '',
        '# 系统文件',
        'Thumbs.db',
        'desktop.ini',
        '',
        '# 编辑器',
        '.vscode/',
        '.idea/',
        '*.swp',
        '',
        '# 敏感信息（绝对不能上传）',
        '.env',
        '*.key',
        '*.pem',
        'id_rsa',
        'id_ed25519'
    )
    Set-Content -Path ".gitignore" -Value $content -Encoding UTF8
    Ok "已创建"
} else {
    Step "2/5" ".gitignore 已存在"
    Ok "跳过"
}

# ============ 3. 远程仓库 ============
Step "3/5" "检查 GitHub 远程仓库..."

$remote = git remote get-url origin 2>$null

if (-not $remote) {
    Line ""
    Warn "这个项目还没有关联 GitHub 仓库"
    Line ""
    Line "  接下来会打开浏览器，你只需要点一下绿色的 Create repository 按钮" "White"
    Line "  （仓库名已经帮你自动填好了）" "DarkGray"
    Line ""

    $defaultName = Split-Path -Leaf $PWD
    $repo = Read-Host "仓库名（直接回车用 [$defaultName]）"
    if ([string]::IsNullOrWhiteSpace($repo)) { $repo = $defaultName }
    $repo = $repo.Trim()

    $newUrl = "https://github.com/new?name=$repo&visibility=public&auto_init=false&gitignore_template=&license_template="
    Line ""
    Line "  正在打开浏览器..." "Cyan"
    Start-Process $newUrl

    Line ""
    Line "  ============================================" "Yellow"
    Line "   请在浏览器里点一下绿色按钮：" "Yellow"
    Line "   Create repository" "Yellow"
    Line "  ============================================" "Yellow"
    Line ""
    Line "  点完之后不用回来按任何键，脚本会自动继续检测" "DarkGray"
    Line ""

    # 轮询等待仓库出现
    $found = $false
    $maxWait = 180
    $elapsed = 0
    Line "  等待仓库创建...（最多等 3 分钟）" "DarkGray"

    while ($elapsed -lt $maxWait) {
        $probe = git ls-remote "git@github.com:$GH_USER/$repo.git" 2>&1
        if ($probe -notmatch "Repository not found" -and $probe -notmatch "Could not read") {
            $found = $true
            break
        }
        Start-Sleep -Seconds 4
        $elapsed += 4
        if ($elapsed % 20 -eq 0) { Line "    已等待 $elapsed 秒..." "DarkGray" }
    }

    if (-not $found) {
        Line ""
        Err "没有检测到仓库创建成功"
        Line ""
        Line "  请确认：" "White"
        Line "    1. 浏览器里点了 Create repository" "Gray"
        Line "    2. 仓库名是: $repo" "Gray"
        Line ""
        Line "  然后重新双击运行本脚本即可。" "White"
        Pause2
        exit 1
    }

    Ok "检测到仓库已创建"
    git remote add origin "git@github.com:$GH_USER/$repo.git"
    Ok "已关联远程仓库"
} else {
    Ok "已关联: $remote"
}

# ============ 4. 提交 ============
Step "4/5" "收集改动并提交..."

git add -A

$changed = git diff --cached --name-only
if ([string]::IsNullOrWhiteSpace($changed)) {
    Line ""
    Warn "没有检测到任何改动，无需上传"
    Pause2
    exit 0
}

$files = $changed -split "`n" | Where-Object { $_.Trim() -ne "" }
Line "    本次改动 $($files.Count) 个文件:" "DarkGray"
foreach ($f in $files) { Line "      $f" "DarkGray" }
Line ""

$msg = Read-Host "修改说明（直接回车自动生成时间）"
if ([string]::IsNullOrWhiteSpace($msg)) {
    $msg = "更新 " + (Get-Date -Format "yyyy-MM-dd HH:mm")
}

git commit -m $msg 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Err "提交失败，详细输出："
    git commit -m $msg
    Pause2
    exit 1
}
Ok "已提交: $msg"

# ============ 5. 推送 ============
Step "5/5" "上传到 GitHub..."

$branch = git branch --show-current
if ([string]::IsNullOrWhiteSpace($branch)) { $branch = "main" }

git push -u origin $branch

if ($LASTEXITCODE -ne 0) {
    Line ""
    Err "上传失败。常见原因："
    Line "    1. 网络波动 -- 等几秒再运行一次即可" "Yellow"
    Line "    2. SSH 密钥失效 -- 运行 ssh -T git@github.com 检查" "Yellow"
    Line "    3. 云端有本地没有的提交 -- 先执行 git pull origin $branch --allow-unrelated-histories" "Yellow"
    Pause2
    exit 1
}

Line ""
Line "============================================" "Green"
Line "              上传成功！" "Green"
Line "============================================" "Green"
Line ""
Line "  查看代码: https://github.com/$GH_USER/$repo" "Cyan"
Line "  个人主页: https://github.com/$GH_USER" "Cyan"
Line ""
Pause2 "按回车键退出"