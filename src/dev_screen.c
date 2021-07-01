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

#include <stdio.h>

#include <SDL2/SDL.h>

#define SCR_W (128)
#define SCR_H (SCR_W)
#define SCALE (4)

static SDL_Window *window;
static SDL_Renderer *renderer;

static SDL_Texture *texture;

static u32 *pixels;

static u32 palette[16] = {
    0x484848, 0xcc3333, 0x33bb33, 0xccbb33,
    0x3333aa, 0x9933aa, 0x3399aa, 0xcccccc,
    0x222222, 0x881111, 0x117011, 0x886633,
    0x111166, 0x551188, 0x115588, 0x777777
};
#define PALETTE_SIZE (sizeof(palette) / sizeof(palette[0]))

static int dev_init(void) {
    pixels = malloc(SCR_W * SCR_H * sizeof(u32));
    if(pixels == NULL) {
        fprintf(
            stderr, "Error: could not allocate %d bytes",
            (int) (SCR_W * SCR_H * sizeof(u32))
        );
        return -1;
    }
    memset(pixels, palette[0], SCR_W * SCR_H * sizeof(u32));

    int err = SDL_Init(SDL_INIT_VIDEO);
    if(err < 0) {
        fprintf(stderr, "Error: could not initialize SDL.\n");
        return err;
    }

    window = SDL_CreateWindow(
        "8Bit fantasy computer",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        SCR_W * SCALE, SCR_H * SCALE,
        SDL_WINDOW_SHOWN
    );

    if(window == NULL) {
        fprintf(stderr, "Error: could not create a SDL window.\n");
        return -1;
    }

    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if(renderer == NULL) {
        fprintf(stderr, "Error: could not create a SDL renderer.\n");
        return -1;
    }

    texture = SDL_CreateTexture(
        renderer,
        SDL_PIXELFORMAT_ARGB8888,
        SDL_TEXTUREACCESS_STREAMING,
        SCR_W, SCR_H
    );

    return 0;
}

static void dev_destroy(void) {
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

static u8 dev_read(u16 addr) {
    return 0;
}

static void dev_write(u16 addr, u8 val) {
    // if writing to the vram...
    if(addr < SCR_W * SCR_H) {
        u8 col = val & 0x0f;

        pixels[addr] = palette[col];
    } else {
        u32 *texture_pixels;
        int pitch;
        SDL_LockTexture(texture, NULL, (void **) &texture_pixels, &pitch);

        memcpy(texture_pixels, pixels, SCR_W * SCR_H * sizeof(u32));

        SDL_UnlockTexture(texture);

        SDL_RenderCopy(renderer, texture, NULL, NULL);
        SDL_RenderPresent(renderer);
    }
}

void screen_tick(void) {
    SDL_Event e;
    while(SDL_PollEvent(&e)) {
        if(e.type == SDL_QUIT) {
            // TODO very temporary
            exit(0);
        }
    }
}

static const struct device dev = {
    .init = dev_init,
    .destroy = dev_destroy,

    .read = dev_read,
    .write = dev_write
};

struct device SCR = dev;
