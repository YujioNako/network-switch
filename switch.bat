chcp 65001
@echo off
setlocal

echo -----------------------------------------------
echo              内外网切换脚本 v3.2
echo 本脚本由YujioNako编写，使用风险由使用者自行承担

echo         初次使用请打开脚本配置必要设置
echo -----------------------------------------------

REM 请在下方设置WLAN与以太网的网络适配器名称；这个两个名称在不同设备上可能不同，请在“控制面板\网络和 Internet\网络连接”处查看，也可以通过cmd运行命令 control ncpa.cpl 快捷打开网络连接面板
set WLAN_NAME=WLAN
set ETHERNET_NAME=以太网 2

REM 检测网络适配器是否存在

REM 检测WLAN适配器
netsh interface show interface name="%WLAN_NAME%" >nul
set wlan=%errorlevel%

REM 检测以太网适配器
netsh interface show interface name="%ETHERNET_NAME%" >nul
set ethernet=%errorlevel%

REM 判断两个适配器是否都存在
if not %wlan%==0 (
    echo 网络适配器 %WLAN_NAME% 不存在，请打开脚本设置WLAN_NAME
)
if not %ethernet%==0 (
    echo 网络适配器 %ETHERNET_NAME% 不存在，请打开脚本设置ETHERNET_NAME
) 
if not %ethernet%==0 (
    echo 请在弹出的窗口查看以太网的网络适配器名称，之后在脚本内修改ETHERNET_NAME
    control ncpa.cpl
    pause
    exit /b
) else  if not %wlan%==0 (
    echo 请在弹出的窗口此查看WLAN的网络适配器名称，之后在脚本内修改WLAN_NAME
    control ncpa.cpl
    pause
    exit /b
) else (
    echo 网络适配器已检测
)

REM 检测WLAN状态
set WLAN_STATUS=Connected
for /f "tokens=*" %%i in ('netsh interface show interface name^="%WLAN_NAME%" ^| findstr /i "Disconnected"') do (
    set WLAN_STATUS=Disconnected
)

REM 检测以太网线缆状态
set ETHERNET_STATUS=Connected
for /f "tokens=*" %%i in ('netsh interface show interface name^="%ETHERNET_NAME%" ^| findstr /i "Disconnected"') do (
    set ETHERNET_STATUS=Disconnected
)

echo WLAN_STATUS . . . . . . . . %WLAN_STATUS%
echo ETHERNET_STATUS . . . . . . %ETHERNET_STATUS%

REM 如果WLAN未连接且以太网断开
if "%WLAN_STATUS%"=="Disconnected" (
 if "%ETHERNET_STATUS%"=="Disconnected" (
    echo 将切换至外网？
    pause
    echo 关闭iNode...
    taskkill /f /im iNode client.exe
    taskkill /f /im iNodeCmn.exe
    taskkill /f /im iNodeMon.exe
    taskkill /f /im iNodePortal.exe
    taskkill /f /im iNodeSec.exe
    echo 关闭代理服务器...
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f
    
    echo 开启WLAN...
    netsh interface set interface name="%WLAN_NAME%" admin=enabled
    echo 请自行连接WiFi
    start ms-settings:network-wifi
    pause
    exit /b
  )
  if "%ETHERNET_STATUS%"=="Connected" (
    echo 内网缆线未断开，要将断开有线网络网卡后尝试切换外网吗？
    pause
    echo 关闭iNode...
    taskkill /f /im "iNode Client.exe"
    taskkill /f /im iNodeCmn.exe
    taskkill /f /im iNodeMon.exe
    taskkill /f /im iNodePortal.exe
    taskkill /f /im iNodeSec.exe
    echo 正在关闭以太网...
    netsh interface set interface name="%ETHERNET_NAME%" admin=disabled

    echo 等待以太网状态变更
    timeout /t 5
         
    echo 关闭代理服务器...
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f
    
    echo 开启WLAN...
    netsh interface set interface name="%WLAN_NAME%" admin=enabled
    timeout /t 3
    echo 请自行连接WiFi
    start ms-settings:network-wifi
    pause
    exit /b
  )
)

REM 如果WLAN已连接
if "%WLAN_STATUS%"=="Connected" (
    echo 将切换至内网？
    pause
    echo 关闭WLAN...
    netsh interface set interface name="%WLAN_NAME%" admin=disabled
    timeout /t 1
    echo 开启以太网...
    netsh interface set interface name="%ETHERNET_NAME%" admin=enabled
    
    echo 开启代理服务器...
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f
    
    echo 启动iNode客户端
    start "" "C:\Program Files (x86)\iNode\iNode Client\iNode Client.exe"
    echo 记得插好线缆再连接
    pause
    exit /b
)

REM 如果无法控制代理，则打开设置界面
echo 打开网络设置界面
start ms-settings:network-proxy

endlocal
pause
