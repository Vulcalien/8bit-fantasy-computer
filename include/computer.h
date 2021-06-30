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
#ifndef VULC_8BIT_EMULATOR_CORE
#define VULC_8BIT_EMULATOR_CORE

#include "vulcalien/vulcalien.h"

#include <stdlib.h>

struct device {
    u8 page_offset;

    int (*init)(void);
    void (*destroy)(void);

    u8 (*read)(u16 addr);
    void (*write)(u16 addr, u8 val);
};

// unit: pages
#define RAM_SIZE (16)
#define ROM_SIZE (8)
#define SCR_SIZE (65)

extern struct device NODEV;
extern struct device RAM;
extern struct device ROM;
extern struct device SCR;

extern void screen_tick(void);

#endif // VULC_8BIT_EMULATOR_CORE
