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

static int dev_init(void) {
    return 0;
}

static void dev_destroy(void) {
}

static u8 dev_read(u16 addr) {
    return 0;
}

static void dev_write(u16 addr, u8 val) {
}

static const struct device dev = {
    .init = dev_init,
    .destroy = dev_destroy,

    .read = dev_read,
    .write = dev_write
};

struct device NODEV = dev;
