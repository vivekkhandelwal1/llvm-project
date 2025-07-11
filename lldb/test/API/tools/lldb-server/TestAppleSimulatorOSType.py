import gdbremote_testcase
import lldbgdbserverutils
from lldbsuite.test.decorators import *
from lldbsuite.test.lldbtest import *
from lldbsuite.test import lldbutil

import json
import platform
import re


class TestAppleSimulatorOSType(gdbremote_testcase.GdbRemoteTestCaseBase):
    # Number of stderr lines to read from the simctl output.
    READ_LINES = 10

    def check_simulator_ostype(self, sdk, platform_name, arch=platform.machine()):
        # Get simulator
        deviceUDID = None
        try:
            deviceUDID = lldbutil.get_latest_apple_simulator(platform_name, self.trace)
        except json.decoder.JSONDecodeError:
            self.fail("Could not parse output. Authorization denied?")
        if not deviceUDID:
            self.skipTest(
                "Could not find a simulator for {} ({})".format(platform_name, arch)
            )

        # Launch the process using simctl
        exe_name = "test_simulator_platform_{}".format(platform_name)
        sdkroot = lldbutil.get_xcode_sdk_root(sdk)
        vers = lldbutil.get_xcode_sdk_version(sdk)
        clang = lldbutil.get_xcode_clang(sdk)

        # Older versions of watchOS (<7.0) only support i386
        if platform_name == "watchos":
            from packaging import version

            if version.parse(vers) < version.parse("7.0"):
                arch = "i386"

        triple = "-".join([arch, "apple", platform_name + vers, "simulator"])
        version_min = "-m{}-simulator-version-min={}".format(platform_name, vers)
        self.build(
            dictionary={
                "EXE": exe_name,
                "SDKROOT": sdkroot.strip(),
                "ARCH": arch,
                "ARCH_CFLAGS": "-target {} {}".format(triple, version_min),
                "USE_SYSTEM_STDLIB": 1,
            },
            compiler=clang,
        )

        # Launch the executable in the simulator
        exe_path, matched_groups = lldbutil.launch_exe_in_apple_simulator(
            deviceUDID,
            self.getBuildArtifact(exe_name),
            ["print-pid", "sleep:10"],
            self.READ_LINES,
            [r"PID: (.*)"],
            self.trace,
        )

        # Make sure we found the PID.
        self.assertIsNotNone(matched_groups[0])
        pid = int(matched_groups[0])

        # Launch debug monitor attaching to the simulated process
        server = self.connect_to_debug_monitor(attach_pid=pid)

        # Setup packet sequences
        self.do_handshake()
        self.add_process_info_collection_packets()
        self.test_sequence.add_log_lines(
            [
                "read packet: "
                + '$jGetLoadedDynamicLibrariesInfos:{"fetch_all_solibs" : true}]#ce',
                {
                    "direction": "send",
                    "regex": r"^\$(.+)#[0-9a-fA-F]{2}$",
                    "capture": {1: "dylib_info_raw"},
                },
            ],
            True,
        )

        # Run the stream
        context = self.expect_gdbremote_sequence()
        self.assertIsNotNone(context)

        # Gather process info response
        process_info = self.parse_process_info_response(context)
        self.assertIsNotNone(process_info)

        # Check that ostype is correct
        self.assertEqual(process_info["ostype"], platform_name + "simulator")

        # Now for dylibs
        dylib_info_raw = context.get("dylib_info_raw")
        dylib_info = json.loads(self.decode_gdbremote_binary(dylib_info_raw))
        images = dylib_info["images"]

        image_info = None
        for image in images:
            if image["pathname"] != exe_path:
                continue
            image_info = image
            break

        self.assertIsNotNone(image_info)
        self.assertEqual(image["min_version_os_name"], platform_name + "simulator")

    @apple_simulator_test("iphone")
    @skipIfRemote
    def test_simulator_ostype_ios(self):
        self.check_simulator_ostype(sdk="iphonesimulator", platform_name="ios")

    @apple_simulator_test("appletv")
    @skipIfRemote
    def test_simulator_ostype_tvos(self):
        self.check_simulator_ostype(sdk="appletvsimulator", platform_name="tvos")

    @apple_simulator_test("watch")
    @skipIfRemote
    def test_simulator_ostype_watchos(self):
        self.check_simulator_ostype(sdk="watchsimulator", platform_name="watchos")
