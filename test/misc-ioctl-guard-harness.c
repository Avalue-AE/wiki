#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>

#include <linux/types.h>
#include "configs/config.h"
#include "hal/misc.h"

struct ec_ops {
	u8 (*read8)(u8 reg);
	void (*write8)(u8 reg, u8 val);
};
struct ec_device {
	struct ec_ops *ops;
};

static int read_count;
static int write_count;
static u8 last_read_reg;
static u8 last_write_reg;
static u8 last_write_val;
static u8 ec_mem[256];

static u8 stub_read8(u8 reg)
{
	read_count++;
	last_read_reg = reg;
	return ec_mem[reg];
}

static void stub_write8(u8 reg, u8 val)
{
	write_count++;
	last_write_reg = reg;
	last_write_val = val;
	ec_mem[reg] = val;
}

static struct ec_ops stub_ops = { stub_read8, stub_write8 };
struct ec_device ite_dev = { &stub_ops };

#include "dispatch.inc"

static int check(const char *name, int cond, const char *detail)
{
	if (cond) {
		printf("PASS %s\n", name);
		return 0;
	}
	printf("FAIL %s: %s\n", name, detail);
	return 1;
}

int main(int argc, char **argv)
{
	u32 udata, kdata;
	s32 ret;
	int fails = 0;
	char detail[256];

	if (argc != 2) {
		fprintf(stderr, "usage: %s undefined|channel0-read|channel0-write\n", argv[0]);
		return 2;
	}

	if (strcmp(argv[1], "undefined") == 0) {
		read_count = write_count = 0;
		udata = 0xAB; kdata = 0;
		ret = hal_misc_ioctl(0, &udata, &kdata);
		snprintf(detail, sizeof(detail), "ret=%d reads=%d writes=%d", ret, read_count, write_count);
		fails += check("undefined-cmd-rejected",
				ret == -ENOTTY && read_count == 0 && write_count == 0, detail);
	} else if (strcmp(argv[1], "channel0-read") == 0) {
		read_count = write_count = 0;
		udata = 0; kdata = 0xFFFFFFFF;
		ret = hal_misc_ioctl(hal_misc_configs[0].ior, &udata, &kdata);
		snprintf(detail, sizeof(detail), "ret=%d reads=%d last_reg=0x%02x want_reg=0x%02x",
			 ret, read_count, last_read_reg, hal_misc_configs[0].reg);
		fails += check("channel0-read-still-works",
				ret == 0 && read_count == 1 && write_count == 0 &&
				last_read_reg == hal_misc_configs[0].reg, detail);
	} else if (strcmp(argv[1], "channel0-write") == 0) {
		if (hal_misc_configs[0].iow == 0) {
			printf("SKIP channel0-write: channel 0 has no write command on this board\n");
			return 0;
		}
		read_count = write_count = 0;
		udata = 0x55; kdata = 0;
		ret = hal_misc_ioctl(hal_misc_configs[0].iow, &udata, &kdata);
		snprintf(detail, sizeof(detail), "ret=%d writes=%d last_reg=0x%02x want_reg=0x%02x",
			 ret, write_count, last_write_reg, hal_misc_configs[0].reg);
		fails += check("channel0-write-still-works",
				ret == 0 && write_count == 1 &&
				last_write_reg == hal_misc_configs[0].reg, detail);
	} else {
		fprintf(stderr, "unknown case: %s\n", argv[1]);
		return 2;
	}

	return fails > 0 ? 1 : 0;
}
