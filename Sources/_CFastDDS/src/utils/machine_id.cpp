/*
 * machine_id.cpp
 * utils
 * 
 * Created by Hunter Baker on 2/27/2025
 * Copyright (C) 2024-2025, by Hunter Baker hunterbaker@me.com
 */
#include "utils/machine_id.hpp"

#include <cstdint>
#include <string>

#if defined(_WIN32)
#  include <WinSock2.h> // Avoid conflicts with WinSock of Windows.h
#  include <windows.h>
#  include <process.h>
#elif defined(__APPLE__)
#  include <IOKit/IOKitLib.h>
#else
#  include <unistd.h>
#  include <fcntl.h>
#endif

#include <fastdds/utils/md5.hpp>

// The implementation of getMachineIdString() is taken directly from https://github.com/eProsima/Fast-DDS/blob/master/src/cpp/utils/Host.cpp,
// which is a private API used for other purposes in Fast-DDS. It is not exposed in the public API.
std::string getMachineIdString() {
#ifdef _WIN32

        char machine_id[255];
        DWORD BufferSize = sizeof(machine_id);
        LONG res = RegGetValueA(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Cryptography", "MachineGuid", RRF_RT_REG_SZ,
                        NULL, machine_id, &BufferSize);
        if (res == 0)
        {
            return machine_id;
        }
        return "";

#elif defined(__APPLE__)

        io_registry_entry_t ioRegistryRoot = IORegistryEntryFromPath(kIOMainPortDefault, "IOService:/");
        if (!ioRegistryRoot)
        {
            return "";
        }
        CFStringRef uuidCf = (CFStringRef) IORegistryEntryCreateCFProperty(ioRegistryRoot, CFSTR(
                            kIOPlatformUUIDKey), kCFAllocatorDefault, 0);
        IOObjectRelease(ioRegistryRoot);
        if (!uuidCf)
        {
            return "";
        }

        char buf[255];
        if (!CFStringGetCString(uuidCf, buf, sizeof(buf), kCFStringEncodingUTF8))
        {
            CFRelease(uuidCf);
            return "";
        }
        CFRelease(uuidCf);
        return buf;

#elif defined(_POSIX_SOURCE)

        int fd = open("/etc/machine-id", O_RDONLY);
        if (fd == -1)
        {
            return "";
        }

        char buffer[33] = {0};
        ssize_t bytes_read = read(fd, buffer, 32);
        close(fd);

        if (bytes_read < 32)
        {
            return "";
        }

        return buffer;

#else
        return "";
#endif
}

using eprosima::fastdds::MD5;

namespace FastDDS {

    uint16_t getMachineId() {
        std::string machine_id_str = getMachineIdString();
        if (machine_id_str.empty())
        {
            return 0;
        }

        MD5 md5;
        md5.update(machine_id_str.c_str(), static_cast<MD5::size_type>(machine_id_str.size()));
        md5.finalize();

        // Hash the 16-bytes md5.digest into a uint16_t
        uint16_t ret_val = 0;
        for (size_t i = 0; i < sizeof(md5.digest); i += 2)
        {
            // Treat the next two bytes as a big-endian uint16_t and
            // hash them into ret_val.
            uint16_t tmp = static_cast<uint16_t>(md5.digest[i]);
            tmp = (tmp << 8) | static_cast<uint16_t>(md5.digest[i + 1]);
            ret_val ^= tmp;
        }
        return ret_val;
    }

}

