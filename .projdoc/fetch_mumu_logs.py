#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从 MuMu 模拟器抓取和平精英 UE4 客户端日志并解密。
用法: python fetch_mumu_logs.py [adb_serial]
流程: adb root -> pull Saved/Logs -> XOR 0x73 解密 -> 输出到 Clientlog/Decoded
"""
import os, sys, glob, subprocess, shutil

ADB = r"D:\App\Netease\MuMu\nx_main\adb.exe"
REMOTE = "/storage/emulated/0/Android/data/com.tencent.tmgp.projectg/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Logs"
BASE = r"D:\Games\WeGameApps\rail_apps\OasisEraEditor(2001776)\ShadowTrackerExtra\Saved\Logs\UGC01_Zombie\Clientlog"
XOR_KEY = 0x73

def sh(args, serial=None):
    """执行 adb 命令, MSYS_NO_PATHCONV 防路径转换"""
    cmd = [ADB]
    if serial:
        cmd += ["-s", serial]
    cmd += args
    env = dict(os.environ)
    env["MSYS_NO_PATHCONV"] = "1"
    r = subprocess.run(cmd, capture_output=True, text=True, env=env)
    return r.returncode, r.stdout, r.stderr

def find_serial():
    rc, out, err = sh(["devices"])
    for line in out.splitlines()[1:]:
        if line.strip() and "device" in line and "offline" not in line:
            serial = line.split()[0]
            if serial != "emulator-5554" or True:
                return serial
    return None

def main():
    serial = sys.argv[1] if len(sys.argv) > 1 else None
    if not serial:
        serial = find_serial()
    if not serial:
        print("[ERROR] 未找到 adb 设备, 请先启动 MuMu"); sys.exit(1)
    print(f"[OK] 使用设备: {serial}")

    # 1. adb root (模拟器日志文件对 shell 用户只读)
    rc, out, err = sh(["root"], serial)
    print("[1/4] adb root ...", "OK" if rc == 0 else f"RC={rc} ({err.strip()[:60]})")
    rc, out, err = sh(["wait-for-device"], serial)

    # 2. 拉取全部日志
    os.makedirs(BASE, exist_ok=True)
    print("[2/4] pull 远程日志 ->", BASE)
    rc, out, err = sh(["pull", REMOTE + "/.", BASE], serial)
    print("      ", (out or err).strip().splitlines()[-1][:100] if (out or err) else "")

    # 3. 解密 XOR 0x73
    dec_dir = os.path.join(BASE, "Decoded")
    os.makedirs(dec_dir, exist_ok=True)
    print("[3/4] XOR 0x73 解密 ...")
    n = 0
    for f in glob.glob(os.path.join(BASE, "ShadowTrackerExtra*.log")):
        if os.path.dirname(f) == dec_dir:
            continue
        with open(f, "rb") as fh:
            raw = fh.read()
        dec = bytes(b ^ XOR_KEY for b in raw)
        name = os.path.basename(f).replace(".log", "_decoded.log")
        with open(os.path.join(dec_dir, name), "wb") as fh:
            fh.write(dec)
        n += 1

    # 4. 汇总
    print(f"[4/4] 完成: 解密 {n} 个文件 -> {dec_dir}")
    for f in sorted(glob.glob(os.path.join(dec_dir, "*_decoded.log"))):
        with open(f, "rb") as fh:
            first = fh.readline().decode("utf-8", errors="replace").strip()[:70]
        print(f"  {os.path.basename(f)}  |  {first}")

if __name__ == "__main__":
    main()
