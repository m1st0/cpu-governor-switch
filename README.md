<!--
SPDX-FileCopyrightText: Copyright (c) 2017–2026 Maulik Mistry
SPDX-License-Identifier: Apache-2.0
-->
# ⚡ CPU Governor Switch

A Zsh utility for inspecting and safely switching Linux CPU frequency policies,
governors, and maximum frequency limits through the kernel's `cpufreq` sysfs
interface.

Originally developed for Intel CPU frequency management and later rewritten as
a modern Zsh implementation.

Copyright © 2017–2026 Maulik Mistry

## ✨ Features

* Zsh-native implementation
* Supports Linux `cpufreq` policy interfaces
* Switches CPU frequency governors across available policies
* Optionally sets a maximum CPU frequency in kHz
* Validates governors and frequencies before modifying system state
* Verifies kernel values after changes are written
* Handles systems with multiple CPU frequency policies
* Reports current and available governors and frequencies

## 🛠️ Usage

### Clone

```zsh
git clone --recurse-submodules https://github.com/m1st0/cpu-governor-switch.git
cd cpu-governor-switch
```

If the repository was cloned without its submodules:

```zsh
git submodule update --init --recursive
```

### Make executable

```zsh
chmod +x performance_switch_cpu.zsh
```

### Inspect the current configuration

```zsh
./performance_switch_cpu.zsh
```

### Change the governor

```zsh
./performance_switch_cpu.zsh performance
```

### Set a governor and maximum frequency

```zsh
./performance_switch_cpu.zsh performance 3500000
```

Changing CPU frequency policy values generally requires elevated privileges.
The script uses `sudo` only for the kernel interfaces that require it.

## 🔐 Safety and Verification

The script does not assume that every CPU policy exposes the same governors or
frequency ranges.

Before changing system state, it:

1. Discovers the available CPU frequency policies.
2. Validates the requested governor.
3. Validates requested frequency limits against the policy ranges.
4. Writes the requested values through the kernel `cpufreq` interface.
5. Reads the values back and verifies the kernel accepted them.

This is intended to avoid silently reporting success when the kernel rejected
or changed a requested value.

## 📦 Vendor Dependency

The output formatting helper is included as the
[`tput_shell_colorize`](vendor/tput_shell_colorize) Git submodule.

When cloning the repository, use `--recurse-submodules` as shown above.

If the submodule is missing or uninitialized:

```zsh
git submodule update --init --recursive
```

## 📚 Background

The original implementation was based on work involving Intel CPU frequency
management and the Linux `cpufreq` interface.

For system-specific information:

```zsh
sudo cat /sys/devices/system/cpu/cpu*/cpufreq/*
```

The current implementation is an independent rewrite and is not copied from the
referenced material.

## 📄 License

Licensed under the **Apache License 2.0**.

See [`LICENSE.txt`](LICENSE.txt) for the complete license text.

## 🙏 Support

Please consider supporting me:

* **PayPal:** https://www.paypal.com/paypalme/m1st0
* **Venmo:** https://venmo.com/code?user_id=3319592654995456106&created=1753283702

