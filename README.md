# TweakCollection

> [!NOTE]
> This is **NOT** a step-by-step guide. For a step-by-step guide check out [PC-Tuning](https://github.com/valleyofdoom/PC-Tuning).

## Table of Contents

### [Guidance](#guidance)

- [Power Plan](#power-plan)
- [Disable Unnecessary Services and Drivers](#disable-unnecessary-services-and-drivers)
- [Enable MMCSS Scheduling of DWM and CSRSS Threads](#enable-mmcss-scheduling-of-dwm-and-csrss-threads)
- [Disable Timer Serialization](#disable-timer-serialization)
- [Network](#network)
    - [Receive Side Scaling (RSS) Configuration](#receive-side-scaling-rss-configuration)
    - [Disable Delayed TCP Acknowledgments](#disable-delayed-tcp-acknowledgments)

### [<ins>Research</ins>](Research.md)

---

# Power Plan

Use the [generate-power-plan.bat](scripts/generate-power-plan.bat) script to generate an optimized power plan. Read through the script and modify it according to your needs before running it.

If possible, configure [Reserved CPU Sets](https://github.com/valleyofdoom/PC-Tuning#reserved-cpu-sets-windows-10) instead of relying on core parking-dependent scheduling techniques present in many recent CPU architectures, as core parking does not function when CPU idle states are disabled.

- See also: [CPU Idle States - PC-Tuning](https://github.com/valleyofdoom/PC-Tuning#cpu-idle-states)

# Disable Unnecessary Services and Drivers

> [!CAUTION]
> This section is targeted towards <ins>**ADVANCED USERS ONLY**</ins>. Improperly following this section may permanently damage your operating system, requiring a reinstall. I am not responsible for any issues that may occur while or due to following this section.
>
> Please familiarize yourself with [service-list-builder](https://github.com/valleyofdoom/service-list-builder) and thoroughly read its entire README before following this section.

> [!WARNING]
> Following this section may negatively impact security as several security features (such as Windows Defender and Firewall) will be disabled.

The main goal of disabling unnecessary services and drivers (from now on referred to as "services") is minimizing unnecessary context switches and CPU cycles wasted by these unused background processes while a real-time application is in use.

The provided config aims to balance resource usage and compatibility. Even so, compatibility issues with many applications may arise while services are disabled, which is why services should be disabled only while a real-time application is in use, and enabled when doing other activities (such as installing or using other applications).

- Windows Defender should be disabled before running service-list-builder as it may interfere with the generated scripts

- The optimal time to generate the scripts is after a clean reinstall of the operating system, before any 3rd-party applications have been installed, as this will allow for 3rd-party services to be installed onto the system later without being disabled by the script

    - If the scripts are generated after 3rd-party applications have been installed, the user-mode services you wish to keep enabled must be added to the `[enabled_services]` section of the config

Copy and paste the following config into the `lists.ini` file in the service-list-builder directory:

```ini
[enabled_services]
Appinfo
AppXSvc
AudioEndpointBuilder
Audiosrv
BrokerInfrastructure
camsvc
CaptureService
CoreMessagingRegistrar
CryptSvc
DcomLaunch
DeviceInstall
DevicesFlowUserSvc
DispBrokerDesktopSvc
Dnscache
EFS
gpsvc
hidserv
KeyIso
LSM
MMCSS
msiserver
netprofm
nsi
PlugPlay
Power
ProfSvc
RpcEptMapper
RpcSs
seclogon
sppsvc
StateRepository
SystemEventsBroker
TextInputManagementService
TrustedInstaller
UserManager
WFDSConMgrSvc
Winmgmt
AMD External Events Utility # Required for: VRR (FreeSync)
Dhcp # Required for: Wi-Fi (set static IP when disabling)
EventLog # Required for: Wi-Fi
Netman # Required for: Wi-Fi
NetSetupSvc # Required for: Wi-Fi
NlaSvc # Required for: Wi-Fi
Wcmsvc # Required for: Wi-Fi
WinHttpAutoProxySvc # Required for: Wi-Fi
WlanSvc # Required for: Wi-Fi
UdkUserSvc # Required for: Windows Start Menu (not required when using alternatives e.g. Open-Shell)
WpnService # Required for: Windows Notifications
WpnUserService # Required for: Windows Notifications
Schedule # Required for: Task Scheduler
TimeBrokerSvc # Required for: Task Scheduler

[individual_disabled_services]
applockerfltr
bfs
EhStorClass
luafv
Ndu
NetBIOS
NetBT
UCPD
UnionFS
WdNisDrv
wtd
ZTDNS
# fvevol # Uncommenting breaks: BitLocker
# msisadrv # Uncommenting breaks: Keyboard on mobile devices
# volsnap # Uncommenting breaks: Win8 and lower
# vwififlt # Uncommenting breaks: Wi-Fi

[rename_binaries]
\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\TextInputHost.exe # Uncommenting breaks: Windows Emoji Panel
# \Windows\System32\RuntimeBroker.exe # Uncommenting breaks: Game Bar, Windows Start Menu (not required when using alternatives e.g. Open-Shell)
# \Windows\System32\ctfmon.exe # Uncommenting breaks: Windows Start Menu (not required when using alternatives e.g. Open-Shell)
# \Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe # Uncommenting breaks: Windows Start Menu (not required when using alternatives e.g. Open-Shell)
# \Windows\System32\ShellHost.exe # Uncommenting breaks: Windows Shell (Internet/Audio button)
```

- Optionally comment/uncomment entries that include a note according to your needs, **carefully read the provided notes when doing so**

- Optionally add unnecessary drivers from [unnecessary-drivers.txt](scripts/unnecessary-drivers.txt) to the `[individual_disabled_services]` section, **please note that this list is not officially supported and may lead to additional compatibility issues**

- If you removed/commented out the `Schedule` and `TimeBrokerSvc` entries, run the following command to prevent the Software Protection service from attempting to schedule a restart every 30 seconds:

    ```cmd
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v "InactivityShutdownDelay" /t REG_DWORD /d "4294967295" /f
    ```

- When rebuilding the scripts, make sure to run the generated `Services-Enable.bat` script beforehand as the tool relies on the current state of the registry to generate the scripts

# Enable MMCSS Scheduling of DWM and CSRSS Threads

Enabling MMCSS scheduling of DWM and CSRSS threads will boost the priorities of the input (and other) threads, resulting in decreased input handling latency.

To do this, download [DWMEnableMMCSS](https://github.com/Duckleeng/DWMEnableMMCSS), then add the following command to a shortcut in the `shell:startup` folder:

```cmd
C:\DWMEnableMMCSS.exe --no-console
```

# Disable Timer Serialization

> [!CAUTION]
> Disabling timer serialization increases the number of clock interrupts that occur across all CPU cores, which may introduce unnecessary overhead. It is recommended to benchmark the effect of this optimization as it may have different performance outcomes on different workloads.

When timer serialization is enabled, the kernel always chooses CPU 0 as the timer expiration processing core. This behavior can lead to congestion and delays in DPC execution. Disabling timer serialization helps resolve this issue by distributing timer-expiration load among unparked logical processors.

On client systems that support [Modern Standby](https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/modern-standby), timer serialization is enabled by default, as distributing timers across cores makes Modern Standby difficult to implement. Timer serialization is disabled by default on systems without Modern Standby support.

Timer serialization can be forcefully disabled with the following command:

```cmd
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "SerializeTimerExpiration" /t REG_DWORD /d "2" /f
```

# Network

## Receive Side Scaling (RSS) Configuration

Receive side scaling (RSS) is a network driver technology that enables distribution of network receive processing across multiple CPUs in multiprocessor systems, therefore improving performance. However, it is often not properly configured out of the box with drivers, so additional configuration is necessary.

Keep in mind that MSI-X is required for RSS to function properly [as it allows the ISR to run on the same CPU that executes the DPC](https://learn.microsoft.com/en-us/windows-hardware/drivers/network/introduction-to-receive-side-scaling#how-rss-improves-system-performance).

- If your NIC doesn't support MSI-X, I recommend disabling RSS and instead configuring a single-core affinity policy to avoid unnecessary inter-core communication

    - If this configuration does not yield the expected results, try using RSS configured with a single RSS queue

Firstly, ensure that a driver with proper RSS support is installed - [Which NICs/drivers support RSS?](Research.md#which-nicsdrivers-support-receive-side-scaling-rss)

Navigate to the following registry key to configure RSS via the registry:

- `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0000`, use the key that corresponds to your NIC: [Driver-key.png](img/Driver-key.png)

- Add/change the following values (all values are of type String):

    - `*RSS` - 0 = Disable RSS, 1 = Enable RSS
    - `*RSSProfile` - Set to 4, rest of the settings might get ignored otherwise
    - `*RssBaseProcNumber` - Set to your desired base processor
    - `*NumRssQueues` - Set to your desired amount of RSS queues
    - `*MaxRssProcessors` - Set to the same value as *NumRssQueues, required only on Intel NICs

<br>

Ensure that the "Limit" setting in [MSI Utility v3](https://forums.guru3d.com/threads/windows-line-based-vs-message-signaled-based-interrupts-msi-tool.378044/) ("MSI Limit" in [GoInterruptPolicy](https://github.com/spddl/GoInterruptPolicy)) for your NIC is set to the number of your desired RSS queues or higher.

Adjust the Interrupt Device Policy in GoInterruptPolicy or [Microsoft Interrupt Affinity Tool](https://www.techpowerup.com/download/microsoft-interrupt-affinity-tool/):

- On Intel NICs set the policy to "IrqPolicySpreadMessagesAcrossAllProcessors"

- On Realtek NICs set the policy to "IrqPolicySpecifiedProcessors", then set an affinity that aligns with the settings configured in the registry

> [!IMPORTANT]
> RSS doesn't properly function when using more than 1 RSS queue on some systems with Realtek NICs. It's unclear why and on which systems this happens.
>
> Experiment with disabling SMT/Hyper-Threading as this resolved the issue for some people.

After adjusting the mentioned settings verify that ISRs/DPCs are executed on the desired cores with an [xperf trace](https://github.com/valleyofdoom/PC-Tuning/blob/main/bin/xperf-dpcisr.bat).

- Avoid using the `Get-NetAdapterRss` Powershell command for this verification as it's output can be misleading

## Disable Delayed TCP Acknowledgments

> [!NOTE]
> This section is related to TCP traffic only. Since most applications use UDP for latency-sensitive traffic, there are no gains from following it in most cases.
>
> Only follow this section if you're dealing with latency-sensitive TCP traffic.

By default, [Windows delays sending TCP acknowledgments until a second segment is received or 200 milliseconds pass](https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/registry-entry-control-tcp-acknowledgment-behavior). This can cause unwanted latencies in communication with the server.

Delayed TCP Acknowledgments can be disabled for all present interfaces with the following command:

```cmd
for /f "usebackq delims=" %a in (`reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces`) do (reg add %a /v "TcpAckFrequency" /t REG_DWORD /d "1" /f)
```