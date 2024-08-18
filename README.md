# TweakCollection

> [!Note]
> This is **NOT** a step-by-step guide. For a step-by-step guide check out [PC-Tuning](https://github.com/valleyofdoom/PC-Tuning).

## Table of Contents

### [Guidance](#guidance)

- [Power Plan](#power-plan)
- [Enable MMCSS Scheduling of DWM and CSRSS Threads](#enable-mmcss-scheduling-of-dwm-and-csrss-threads)
- [Disable Timer Serialization](#disable-timer-serialization)
- [Network](#network)
    - [Receive Side Scaling (RSS) Configuration](#receive-side-scaling-rss-configuration)
    - [Disable Delayed TCP Acknowledgments](#disable-delayed-tcp-acknowledgments)

### [<ins>Research</ins>](Research.md)

---

# Power Plan

Use the [generate-power-plan.bat](scripts/generate-power-plan.bat) script to generate an optimized power plan. Read through the script and modify it according to your needs before running it.

- See also: [CPU Idle States - PC-Tuning](https://github.com/valleyofdoom/PC-Tuning#1146-cpu-idle-states)

# Enable MMCSS Scheduling of DWM and CSRSS Threads

Enabling MMCSS scheduling of DWM and CSRSS threads will boost the priorities of the input (and other) threads, resulting in decreased input handling latency.

To do this, download [DWMEnableMMCSS](https://github.com/Duckleeng/DWMEnableMMCSS), then add the following command to a shortcut in the `shell:startup` folder:

```cmd
C:\DWMEnableMMCSS.exe --no-console
```

# Disable Timer Serialization

When timer serialization is enabled, the kernel always chooses CPU 0 as the timer expiration processing core. This behavior can lead to congestion and delays in DPC execution. Disabling timer serialization helps resolve this issue by distributing timer-expiration load among unparked logical processors.

On client systems that support [Modern Standby](https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/modern-standby), timer serialization is enabled by default, as distributing timers across cores makes Modern Standby difficult to implement. Timer serialization is disabled by default on systems without Modern Standby support.

Timer serialization can be forcefully disabled with the following command:

```cmd
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "SerializeTimerExpiration" /t REG_DWORD /d "2" /f
```

# Network

## Receive Side Scaling (RSS) Configuration

Keep in mind that MSI-X is required for RSS to function properly [as it allows the ISR to run on the same CPU that executes the DPC](https://learn.microsoft.com/en-us/windows-hardware/drivers/network/introduction-to-receive-side-scaling#how-rss-improves-system-performance).

Firstly, ensure that a driver with proper RSS support is installed - [Which NICs/drivers support RSS?](Research.md#which-nicsdrivers-support-receive-side-scaling-rss)

Navigate to the following registry key to configure RSS via the registry:

- `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0000`, use the key that corresponds to your NIC: [Driver-key.png](img/Driver-key.png)

- Add/change the following values (all values are of type String):

    - `*RSS` - "0" = Disable RSS, "1" = Enable RSS
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

After adjusting the mentioned settings verify that ISRs/DPCs are executed on the desired cores with an xperf trace.

- Avoid using the `Get-NetAdapterRss` Powershell command for this verification as it's output can be missleading

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