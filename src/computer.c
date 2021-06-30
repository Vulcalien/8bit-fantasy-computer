/* Copyright 2021 Vulcalien
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 2 only.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */
#include "computer.h"

#include "6502_emulator.h"

// SLEEP macro
#ifdef __unix__
    #include <unistd.h>
    #define SLEEP(millis) usleep(millis * 1000)
#elif _WIN32
    #include <windows.h>
    #define SLEEP(millis) Sleep(millis)
#endif

// --- MEMORY MAPPING ---
#define NODEV_ID (0)
#define RAM_ID   (1)
#define ROM_ID   (2)

static struct device *devices[] = {
    &NODEV, &RAM, &ROM
};

static u8 memory_mapping[256] = { NODEV_ID };

static void map_memory(u8 first_page, u8 pages, u8 dev_id) {
    devices[dev_id]->page_offset = first_page;

    for(u8 i = 0; i < pages; i++) {
        u32 page = first_page + i;
        if(page > 0xff)
            break;

        memory_mapping[page] = dev_id;
    }
}

static void do_memory_mapping(void) {
    // map the first RAM_SIZE pages
    map_memory(0, RAM_SIZE, RAM_ID);

    // map the last ROM_SIZE pages
    map_memory(256 - ROM_SIZE - 1, ROM_SIZE, ROM_ID);
}

static u16 get_device(u16 addr, struct device **dev) {
    u8 page = addr >> 8;
    *dev = devices[memory_mapping[page]];
    return (*dev)->page_offset;
}
// END --- MEMORY MAPPING ---

static u8 read_byte(u16 addr) {
    struct device *dev;
    addr -= get_device(addr, &dev);

    return dev->read(addr);
}

static void write_byte(u16 addr, u8 val) {
    struct device *dev;
    addr -= get_device(addr, &dev);

    dev->write(addr, val);
}

static int init_devices(void) {
    for(u32 i = 0; i < sizeof(devices) / sizeof(devices[0]); i++) {
        struct device *dev = devices[i];
        int err = dev->init();

        if(err)
            return err;
    }
    return 0;
}

static void destroy_devices(void) {
    for(u32 i = 0; i < sizeof(devices) / sizeof(devices[0]); i++) {
        struct device *dev = devices[i];
        dev->destroy();
    }
}

int main(int argc, const char *argv[]) {
    cpu_library_init();
    cpu_read_byte = read_byte;
    cpu_write_byte = write_byte;

    {
        int err = init_devices();
        if(err)
            return err;
    }
    do_memory_mapping();

    cpu_reset();

    while(true) {
        cpu_clock();

        // 2 ms of sleep - the 6502 will operate at 500 op/second
        // Yes, I want it slow, really slow
        SLEEP(2);
    }

    destroy_devices();
    return 0;
}
