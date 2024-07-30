# TweakCollection

> [!Note]
> This is **NOT** a step-by-step guide. For a step-by-step guide check out [PC-Tuning](https://github.com/valleyofdoom/PC-Tuning).

## Table of Contents

### [Guidance](#table-of-contents)

- [Network](#network)
    - [Receive Side Scaling (RSS) Configuration](#receive-side-scaling-rss-configuration)

### [Research](Research.md)

- [Which NICs/drivers support Receive Side Scaling (RSS)?](Research.md#which-nicsdrivers-support-receive-side-scaling-rss)

<br>

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

Ensure that the "Limit" setting in [MSI Utility v3](https://forums.guru3d.com/threads/windows-line-based-vs-message-signaled-based-interrupts-msi-tool.378044/) ("MSI Limit" in [GoInterruptPolicy](https://github.com/spddl/GoInterruptPolicy)) for your NIC is set to the number of your desired RSS queues or higher

Adjust the Interrupt Device Policy in GoInterruptPolicy or [Microsoft Interrupt Affinity Tool](https://www.techpowerup.com/download/microsoft-interrupt-affinity-tool/):

- On Intel NICs set the policy to "IrqPolicySpreadMessagesAcrossAllProcessors"

- On Realtek NICs set the policy to "IrqPolicySpecifiedProcessors", then set an affinity that aligns with the settings configured in the registry

> [!IMPORTANT]
> RSS doesn't properly function when using more than 1 RSS queue on some systems with Realtek NICs. It's unclear why and on which systems this happens.
>
> Experiment with disabling SMT/Hyper-Threading as this resolved the issue for some people.

After adjusting the mentioned settings verify that ISRs/DPCs are executed on the desired cores with an xperf trace

- Avoid using the `Get-NetAdapterRss` Powershell command for this verification as it's output can be missleading