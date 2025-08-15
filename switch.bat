@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM ============================================================================
REM 网络切换脚本 v3.5.3 - 语法错误修复版本

REM 作者: YujioNako

REM 功能: 自动切换内外网连接和代理设置

REM 使用风险由使用者自行承担

REM 修复: 语法错误和ESC字符获取问题

REM ============================================================================

REM 配置区域 - 请根据您的网络适配器名称修改以下设置
set "EXTERNAL_ADAPTER=WLAN 2"
set "INTERNAL_ADAPTER=以太网 2"
set "USE_PROXY_BY_DEFAULT=No"

REM 常量定义
set "SCRIPT_VERSION=3.5.3"
set "INODE_PATH=C:\Program Files (x86)\iNode\iNode Client\iNode Client.exe"

REM 尝试启用ANSI支持
set "ANSI_ENABLED=0"
ver | findstr /i "10\." > nul
if !errorlevel! equ 0 set "ANSI_ENABLED=1"
ver | findstr /i "11\." > nul
if !errorlevel! equ 0 set "ANSI_ENABLED=1"

REM 如果是Windows 10/11，尝试启用ANSI
if "!ANSI_ENABLED!"=="1" (
    REM 使用PowerShell启用ANSI支持
    powershell -NoProfile -Command "try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }" 2>nul
    
    REM 创建ESC字符文件
    echo|set /p="">%temp%\esc.txt
    for /f %%i in ('forfiles /p %temp% /m esc.txt /c "cmd /c echo 0x1B"') do set "ESC_CODE=%%i"
    del "%temp%\esc.txt" 2>nul
    
    REM 如果上面的方法失败，使用备用方法
    if not defined ESC_CODE (
        REM 使用PowerShell生成ESC字符
        for /f %%i in ('powershell -NoProfile -Command "[char]27"') do set "ESC_CODE=%%i"
    )
)

REM 定义颜色代码
if defined ESC_CODE (
    set "COLOR_RESET=!ESC_CODE![0m"
    set "COLOR_RED=!ESC_CODE![91m"
    set "COLOR_GREEN=!ESC_CODE![92m"
    set "COLOR_YELLOW=!ESC_CODE![93m"
    set "COLOR_BLUE=!ESC_CODE![94m"
    set "COLOR_MAGENTA=!ESC_CODE![95m"
    set "COLOR_CYAN=!ESC_CODE![96m"
    set "COLOR_WHITE=!ESC_CODE![97m"
    set "COLOR_GRAY=!ESC_CODE![90m"
    set "COLOR_BOLD=!ESC_CODE![1m"
    set "COLORS_ENABLED=1"
) else (
    REM 不支持颜色，使用空值
    set "COLOR_RESET="
    set "COLOR_RED="
    set "COLOR_GREEN="
    set "COLOR_YELLOW="
    set "COLOR_BLUE="
    set "COLOR_MAGENTA="
    set "COLOR_CYAN="
    set "COLOR_WHITE="
    set "COLOR_GRAY="
    set "COLOR_BOLD="
    set "COLORS_ENABLED=0"
)

REM 图标定义
set "ICON_SUCCESS=✓"
set "ICON_ERROR=✗"
set "ICON_WARNING=⚠"
set "ICON_INFO=ℹ"
set "ICON_NETWORK=🌐"
set "ICON_PROXY=🔗"
set "ICON_ARROW=→"

REM 内网代理配置
set "INTERNAL_PROXY_SERVER=10.244.155.137:8081"
set "INTERNAL_PROXY_BYPASS=a*.gmcc.net;c*.gmcc.net;d*.gmcc.net;e*.gmcc.net;f*.gmcc.net;gzmcoas;g*.gmcc.net;*.dhtc.gmcc.net;u*.gmcc.net;m*.gmcc.net;n*.gmcc.net;i*.gmcc.net;p*.gmcc.net;sgs020lu;www.bbc.gmcc.net;training;10.*;*.gz.gmcc.net;*.gd.cmcc;portal*.gmcc.net;*.boss.gmcc.net;blog.gmcc.net;wiki.gmcc.net;10.243.211.*;www.ego139.com.cn;10.244.120.145;211.139.146.66;*cmicp*;h*.gmcc.net;*.gmcc.net;hr.gmcc.net;10.*;bss.gz.gmcc.net;10.252.17.106;*.cmcc;172.*;*.;*.cs.cmos;*.cmos;<local>"

REM 外网代理配置
set "EXTERNAL_PROXY_BYPASS=47.94.192.128;198.23.249.216;111.180.193.194;123.57.134.53;*.ug.link;*.qpic.cn;*.baidu.com;*.qq.com;*.aliyun.com;*.aliyuncs.com;*.taobao.com;*.tmall.com;*.jd.com;*.sina.com.cn;*.weibo.com;*.bilibili.com;*.zhihu.com;*.douban.com;*.alipay.com;*.youku.com;*.iqiyi.com;*.mi.com;*.163.com;*.sogou.com;*.sohu.com;*.58.com;*.ctrip.com;*.xiaomi.com;*.meituan.com;*.dianping.com;*.ele.me;*.kuaishou.com;*.douyin.com;*.tencent.com;*.csdn.net;*.jd.cn;*.360.cn;*.suning.com;*.amazon.cn;*.bing.com;*.deepseek.com;*.chinamobile.com;*.gov.cn;<local>"
set "EXTERNAL_PROXY_SERVER=111.180.193.194:1081"

REM 清屏并开始
cls
call :ShowHeader
call :ValidateAdapters
if !errorlevel! neq 0 exit /b !errorlevel!

call :DetectNetworkStatus
call :ShowCurrentStatus
call :ShowMenu
call :GetUserChoice
call :ProcessUserChoice
goto :EOF

REM ============================================================================
REM 彩色输出和UI子程序
REM ============================================================================

:ColorEcho
REM 参数: %1=颜色代码, %2=文本内容, %3=是否换行(可选,默认换行)
set "color_code=%~1"
set "text=%~2"
set "newline=%~3"
if "!newline!"=="" set "newline=yes"

if "!newline!"=="yes" (
    echo !color_code!!text!!COLOR_RESET!
) else (
    echo|set /p="!color_code!!text!!COLOR_RESET!"
)
goto :EOF

:DrawLine
set "char=%~1"
set "length=%~2"  
set "color=%~3"
if "!char!"=="" set "char=="
if "!length!"=="" set "length=60"
if "!color!"=="" set "color=!COLOR_CYAN!"

set "line="
for /l %%i in (1,1,!length!) do set "line=!line!!char!"
call :ColorEcho "!color!" "!line!"
goto :EOF

:ShowHeader
call :DrawLine "=" 70 "!COLOR_CYAN!"
call :ColorEcho "!COLOR_BOLD!!COLOR_WHITE!" "                    !ICON_NETWORK! 内外网切换脚本 v!SCRIPT_VERSION! !ICON_NETWORK!"
call :ColorEcho "!COLOR_GRAY!" "                        作者: YujioNako"
call :ColorEcho "!COLOR_YELLOW!" "                  !ICON_WARNING! 使用风险由使用者自行承担 !ICON_WARNING!"
call :ColorEcho "!COLOR_GRAY!" "                   初次使用请配置网络适配器设置"
call :DrawLine "=" 70 "!COLOR_CYAN!"
echo.
goto :EOF

:ValidateAdapters
call :ColorEcho "!COLOR_BLUE!" "!ICON_INFO! 正在检测网络适配器..."

netsh interface show interface name="!EXTERNAL_ADAPTER!" >nul 2>&1
set "external_exists=!errorlevel!"

netsh interface show interface name="!INTERNAL_ADAPTER!" >nul 2>&1
set "internal_exists=!errorlevel!"

if !external_exists! neq 0 (
    call :ColorEcho "!COLOR_RED!" "!ICON_ERROR! 外部网络适配器 '!EXTERNAL_ADAPTER!' 不存在"
    call :ColorEcho "!COLOR_YELLOW!" "      请打开脚本修改 EXTERNAL_ADAPTER 设置"
)

if !internal_exists! neq 0 (
    call :ColorEcho "!COLOR_RED!" "!ICON_ERROR! 内部网络适配器 '!INTERNAL_ADAPTER!' 不存在"
    call :ColorEcho "!COLOR_YELLOW!" "      请打开脚本修改 INTERNAL_ADAPTER 设置"
)

if !internal_exists! neq 0 (
    call :ColorEcho "!COLOR_BLUE!" "!ICON_INFO! 正在打开网络连接面板，请查看内部网络适配器名称..."
    control ncpa.cpl
    call :WaitAndExit
    exit /b 1
) else if !external_exists! neq 0 (
    call :ColorEcho "!COLOR_BLUE!" "!ICON_INFO! 正在打开网络连接面板，请查看外部网络适配器名称..."
    control ncpa.cpl
    call :WaitAndExit
    exit /b 1
)

call :ColorEcho "!COLOR_GREEN!" "!ICON_SUCCESS! 已检测到网络适配器: '!INTERNAL_ADAPTER!' 与 '!EXTERNAL_ADAPTER!'"
echo.
goto :EOF

:DetectNetworkStatus
call :ColorEcho "!COLOR_BLUE!" "!ICON_INFO! 正在检测网络状态..."

REM 检测外部网络状态
set "EXTERNAL_STATUS=Connected"
for /f "tokens=*" %%i in ('netsh interface show interface name^="!EXTERNAL_ADAPTER!" ^| findstr /i "Disconnected"') do (
    set "EXTERNAL_STATUS=Disconnected"
)

REM 检测内部网络状态
set "INTERNAL_STATUS=Connected"
for /f "tokens=*" %%i in ('netsh interface show interface name^="!INTERNAL_ADAPTER!" ^| findstr /i "Disconnected"') do (
    set "INTERNAL_STATUS=Disconnected"
)

REM 检测用户级代理状态
call :DetectProxyStatus
echo.
goto :EOF

:DetectProxyStatus
set "PROXY_STATUS=Disabled"
set "PROXY_SERVER=未设置"

REM 查询注册表中的代理启用状态
for /f "tokens=3" %%i in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable 2^>nul ^| findstr /i "ProxyEnable"') do (
    if "%%i"=="0x1" (
        set "PROXY_STATUS=Enabled"
    )
)

REM 如果代理已启用，获取代理服务器地址
if "!PROXY_STATUS!"=="Enabled" (
    for /f "tokens=3*" %%i in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer 2^>nul ^| findstr /i "ProxyServer"') do (
        set "PROXY_SERVER=%%i %%j"
        if "!PROXY_SERVER:~-1!"==" " set "PROXY_SERVER=!PROXY_SERVER:~0,-1!"
    )
)
goto :EOF

:ShowCurrentStatus
call :DrawLine "-" 50 "!COLOR_GRAY!"
call :ColorEcho "!COLOR_BOLD!!COLOR_WHITE!" "               !ICON_NETWORK! 当前网络状态"
call :DrawLine "-" 50 "!COLOR_GRAY!"

REM 显示适配器状态

call :ColorEcho "!COLOR_CYAN!" "外部适配器:" "no"
if "!EXTERNAL_STATUS!"=="Connected" (
    call :ColorEcho "!COLOR_GREEN!" " !ICON_SUCCESS! 已连接"
) else (
    call :ColorEcho "!COLOR_RED!" " !ICON_ERROR! 未连接"
)

call :ColorEcho "!COLOR_CYAN!" "内部适配器:" "no"
if "!INTERNAL_STATUS!"=="Connected" (
    call :ColorEcho "!COLOR_GREEN!" " !ICON_SUCCESS! 已连接"
) else (
    call :ColorEcho "!COLOR_RED!" " !ICON_ERROR! 未连接"
)

call :ColorEcho "!COLOR_CYAN!" "HTTP代理:  " "no"
if "!PROXY_STATUS!"=="Enabled" (
    call :ColorEcho "!COLOR_GREEN!" " !ICON_SUCCESS! 已启用"
    call :ColorEcho "!COLOR_GRAY!" "           服务器: !PROXY_SERVER!"
) else (
    call :ColorEcho "!COLOR_RED!" " !ICON_ERROR! 未启用"
)

echo.
call :DetermineCurrentNetwork
call :DrawLine "-" 50 "!COLOR_GRAY!"
echo.
goto :EOF

:DetermineCurrentNetwork
set "CURRENT_NETWORK=未知"
set "NETWORK_COLOR=!COLOR_GRAY!"

if "!EXTERNAL_STATUS!"=="Connected" if "!INTERNAL_STATUS!"=="Disconnected" (
    set "CURRENT_NETWORK=外网环境"
    set "NETWORK_COLOR=!COLOR_GREEN!"
) else if "!EXTERNAL_STATUS!"=="Disconnected" if "!INTERNAL_STATUS!"=="Connected" (
    set "CURRENT_NETWORK=内网环境"
    set "NETWORK_COLOR=!COLOR_BLUE!"
) else if "!EXTERNAL_STATUS!"=="Connected" if "!INTERNAL_STATUS!"=="Connected" (
    set "CURRENT_NETWORK=双网卡模式"
    set "NETWORK_COLOR=!COLOR_MAGENTA!"
) else (
    set "CURRENT_NETWORK=无网络连接"
    set "NETWORK_COLOR=!COLOR_RED!"
)

call :ColorEcho "!COLOR_BOLD!!NETWORK_COLOR!" "!ICON_ARROW! 检测结果: !CURRENT_NETWORK!"

REM 根据代理设置进一步判断
if "!PROXY_STATUS!"=="Enabled" (
    if "!PROXY_SERVER!"=="!INTERNAL_PROXY_SERVER!" (
        call :ColorEcho "!COLOR_BLUE!" "!ICON_PROXY! 代理分析: 使用内网代理配置"
    ) else if "!PROXY_SERVER!"=="!EXTERNAL_PROXY_SERVER!" (
        call :ColorEcho "!COLOR_GREEN!" "!ICON_PROXY! 代理分析: 使用外网代理配置"
    ) else (
        call :ColorEcho "!COLOR_YELLOW!" "!ICON_PROXY! 代理分析: 使用自定义代理: !PROXY_SERVER!"
    )
) else (
    call :ColorEcho "!COLOR_GRAY!" "!ICON_PROXY! 代理分析: 未使用代理"
)
goto :EOF

:ShowMenu
call :DrawLine "=" 50 "!COLOR_CYAN!"
call :ColorEcho "!COLOR_BOLD!!COLOR_WHITE!" "                  操作菜单"
call :DrawLine "=" 50 "!COLOR_CYAN!"

call :ColorEcho "!COLOR_GREEN!" "  [1] !ICON_ARROW! 切换至外网"
call :ColorEcho "!COLOR_BLUE!" "  [2] !ICON_ARROW! 切换至内网"
call :ColorEcho "!COLOR_MAGENTA!" "  [3] !ICON_ARROW! 切换至外网并使用代理"
call :ColorEcho "!COLOR_YELLOW!" "  [4] !ICON_ARROW! 虚拟机模式 (双网卡)"
call :ColorEcho "!COLOR_CYAN!" "  [5] !ICON_ARROW! 查看详细代理信息"
call :ColorEcho "!COLOR_GRAY!" "  [Enter] !ICON_ARROW! 自动切换"

call :DrawLine "=" 50 "!COLOR_CYAN!"
echo.
goto :EOF

:GetUserChoice
call :ColorEcho "!COLOR_BOLD!!COLOR_WHITE!" "请输入选择 (1-5 或直接回车): " "no"
set /p "userChoice="
goto :EOF

:ProcessUserChoice
echo.
if "!userChoice!"=="1" (
    call :SwitchToExternal "No"
) else if "!userChoice!"=="2" (
    call :SwitchToInternal
) else if "!userChoice!"=="3" (
    call :SwitchToExternal "Yes"
) else if "!userChoice!"=="4" (
    call :EnableVMMode
) else if "!userChoice!"=="5" (
    call :ShowDetailedProxyInfo
    echo.
    call :ColorEcho "!COLOR_GRAY!" "按任意键返回主菜单..."
    pause >nul
    cls
    call :ShowHeader
    call :DetectNetworkStatus
    call :ShowCurrentStatus
    call :ShowMenu
    call :GetUserChoice
    call :ProcessUserChoice
) else (
    call :AutoSwitch
)
goto :EOF

:ShowDetailedProxyInfo
cls
call :DrawLine "=" 70 "!COLOR_CYAN!"
call :ColorEcho "!COLOR_BOLD!!COLOR_WHITE!" "                      !ICON_PROXY! 详细代理信息"
call :DrawLine "=" 70 "!COLOR_CYAN!"
echo.

call :ColorEcho "!COLOR_BLUE!" "!ICON_INFO! 用户级代理设置:"
call :DrawLine "-" 40 "!COLOR_GRAY!"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable 2>nul | findstr /i "ProxyEnable"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer 2>nul | findstr /i "ProxyServer"
echo.

call :ColorEcho "!COLOR_BLUE!" "!ICON_INFO! 系统级代理设置:"
call :DrawLine "-" 40 "!COLOR_GRAY!"
netsh winhttp show proxy
echo.

call :ColorEcho "!COLOR_BLUE!" "!ICON_INFO! 脚本配置的代理服务器:"
call :DrawLine "-" 40 "!COLOR_GRAY!"
call :ColorEcho "!COLOR_GREEN!" "内网代理: !INTERNAL_PROXY_SERVER!"
call :ColorEcho "!COLOR_MAGENTA!" "外网代理: !EXTERNAL_PROXY_SERVER!"

call :DrawLine "=" 70 "!COLOR_CYAN!"
goto :EOF

:AutoSwitch
call :ColorEcho "!COLOR_YELLOW!" "!ICON_INFO! 执行自动切换..."
if "!EXTERNAL_STATUS!"=="Disconnected" (
    call :SwitchToExternal "!USE_PROXY_BY_DEFAULT!"
) else (
    call :SwitchToInternal
)
goto :EOF

:SwitchToExternal
set "use_proxy=%~1"
call :ColorEcho "!COLOR_GREEN!" "!ICON_ARROW! 正在切换至外网..."
call :ColorEcho "!COLOR_GRAY!" "按任意键继续..."
pause >nul

call :StopINode
call :DisableAdapter "!INTERNAL_ADAPTER!"

if "!use_proxy!"=="Yes" (
    call :SetExternalProxy
    call :ColorEcho "!COLOR_MAGENTA!" "!ICON_INFO! 代理账号: guest | 密码: yujionako"
) else (
    call :DisableProxy
)

call :EnableAdapter "!EXTERNAL_ADAPTER!"
call :ColorEcho "!COLOR_BLUE!" "!ICON_INFO! 请手动连接Wi-Fi或其他外部网络"
start ms-settings:network

call :WaitAndExit
goto :EOF

:SwitchToInternal
call :ColorEcho "!COLOR_BLUE!" "!ICON_ARROW! 正在切换至内网..."
call :ColorEcho "!COLOR_GRAY!" "按任意键继续..."
pause >nul

call :StopINode
call :DisableAdapter "!EXTERNAL_ADAPTER!"
call :EnableAdapter "!INTERNAL_ADAPTER!"
call :SetInternalProxy

call :ColorEcho "!COLOR_BLUE!" "!ICON_INFO! 正在启动iNode客户端..."
if exist "!INODE_PATH!" (
    start "" "!INODE_PATH!"
    call :ColorEcho "!COLOR_YELLOW!" "!ICON_WARNING! 记得插好网线再连接iNode"
) else (
    call :ColorEcho "!COLOR_RED!" "!ICON_ERROR! 未找到iNode客户端，请手动启动"
)

call :WaitAndExit
goto :EOF

:EnableVMMode
call :ColorEcho "!COLOR_MAGENTA!" "!ICON_ARROW! 正在启用虚拟机模式..."
call :ColorEcho "!COLOR_GRAY!" "此模式将同时启用内外网适配器"
call :ColorEcho "!COLOR_GRAY!" "按任意键继续..."
pause >nul

call :StopINode
call :DisableProxy
call :EnableAdapter "!EXTERNAL_ADAPTER!"
call :EnableAdapter "!INTERNAL_ADAPTER!"

call :ColorEcho "!COLOR_BLUE!" "!ICON_INFO! 请手动连接Wi-Fi或其他外部网络"
start ms-settings:network

call :WaitAndExit
goto :EOF

:StopINode
call :ColorEcho "!COLOR_YELLOW!" "!ICON_INFO! 正在关闭iNode进程..."
taskkill /f /im "iNode client.exe" >nul 2>&1
taskkill /f /im "iNode Client.exe" >nul 2>&1
taskkill /f /im iNodeCmn.exe >nul 2>&1
taskkill /f /im iNodeMon.exe >nul 2>&1
taskkill /f /im iNodePortal.exe >nul 2>&1
taskkill /f /im iNodeSec.exe >nul 2>&1
timeout /t 2 >nul
goto :EOF

:EnableAdapter
set "adapter_name=%~1"
call :ColorEcho "!COLOR_GREEN!" "!ICON_SUCCESS! 正在启用适配器: !adapter_name!"
netsh interface set interface name="!adapter_name!" admin=enabled
timeout /t 3 >nul
goto :EOF

:DisableAdapter
set "adapter_name=%~1"
call :ColorEcho "!COLOR_YELLOW!" "!ICON_WARNING! 正在禁用适配器: !adapter_name!"
netsh interface set interface name="!adapter_name!" admin=disabled
timeout /t 2 >nul
goto :EOF

:SetInternalProxy
call :ColorEcho "!COLOR_BLUE!" "!ICON_INFO! 正在配置内网代理..."
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "!INTERNAL_PROXY_SERVER!" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /t REG_SZ /d "!INTERNAL_PROXY_BYPASS!" /f >nul
call :ColorEcho "!COLOR_GREEN!" "!ICON_SUCCESS! 内网代理已配置: !INTERNAL_PROXY_SERVER!"
goto :EOF

:SetExternalProxy
call :ColorEcho "!COLOR_MAGENTA!" "!ICON_INFO! 正在配置外网代理..."
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "!EXTERNAL_PROXY_SERVER!" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /t REG_SZ /d "!EXTERNAL_PROXY_BYPASS!" /f >nul
call :ColorEcho "!COLOR_GREEN!" "!ICON_SUCCESS! 外网代理已配置: !EXTERNAL_PROXY_SERVER!"
goto :EOF

:DisableProxy
call :ColorEcho "!COLOR_YELLOW!" "!ICON_INFO! 正在关闭代理服务器..."
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul
REM 保留内网代理设置以便下次使用
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "!INTERNAL_PROXY_SERVER!" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /t REG_SZ /d "!INTERNAL_PROXY_BYPASS!" /f >nul
call :ColorEcho "!COLOR_GREEN!" "!ICON_SUCCESS! 代理已禁用"
goto :EOF

:WaitAndExit
echo.
call :ColorEcho "!COLOR_GREEN!" "!ICON_SUCCESS! 操作完成！"
call :ColorEcho "!COLOR_GRAY!" "将在30秒后自动退出..."
timeout /t 30 >nul
goto :EOF
