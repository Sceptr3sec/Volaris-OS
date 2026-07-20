---
title: Home
layout: home
nav_order: 1
---

# Volaris OS

A lightweight, security-focused, RAM-resident operating environment built
entirely from source using Linux From Scratch.

Volaris OS boots from a portable ISO, loads its entire runtime into RAM,
and leaves no recoverable trace on the host machine after shutdown —
purpose-built for cybersecurity research, network analysis, and
incident response.

## Key Properties

- **RAM-resident** — custom initramfs hydrates the full system into tmpfs
  and disconnects boot media before handing off to the real init
- **Built from scratch** — every core component compiled from source
  via Linux From Scratch, no black-box packages
- **Default-deny firewall** — nftables policy verified via external scan
  (999/1000 ports filtered)
- **Zero persistence** — verified: session data does not survive a reboot

## Get Started

- [Build Documentation](build.html)
- [Test Report & Evidence](test-report.html)
- [Download the Latest Release](https://github.com/Sceptr3sec/Volaris-OS/releases)
