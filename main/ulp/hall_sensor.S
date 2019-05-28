/* ULP Example: Read hall sensor in deep sleep

   For other examples please check:
   https://github.com/espressif/esp-iot-solution/tree/master/examples

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
 */


/* ULP assembly files are passed through C preprocessor first, so include directives
   and C macros may be used in these files 
 */

#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"
#include "soc/sens_reg.h"

	/* Configure the number of ADC samples to average on each measurement.
	   For convenience, make it a power of 2. */
	.set adc_oversampling_factor_log, 2
	.set adc_oversampling_factor, (1 << adc_oversampling_factor_log)
	.set threshold, 70

	/* Define variables, which go into .bss section (zero-initialized data) */
	.bss
	.global Offset
Offset:
	.long 0	

	/* Code goes into .text section */
	.text
	.global entry
entry:

	/* SENS_XPD_HALL_FORCE = 1, hall sensor force enable, XPD HALL is controlled by SW */
	WRITE_RTC_REG(SENS_SAR_TOUCH_CTRL1_REG, SENS_XPD_HALL_FORCE_S, 1, 1)

	/* RTC_IO_XPD_HALL = 1, xpd hall, Power on hall sensor and connect to VP and VN */
	WRITE_RTC_REG(RTC_IO_HALL_SENS_REG, RTC_IO_XPD_HALL_S, 1, 1)

	/* SENS_HALL_PHASE_FORCE = 1, phase force, HALL PHASE is controlled by SW */
	WRITE_RTC_REG(SENS_SAR_TOUCH_CTRL1_REG, SENS_HALL_PHASE_FORCE_S, 1, 1)

	/* RTC_IO_HALL_PHASE = 0, phase of hall sensor */
	WRITE_RTC_REG(RTC_IO_HALL_SENS_REG, RTC_IO_HALL_PHASE_S, 1, 0)

	/* SENS_FORCE_XPD_SAR, Force power up */
	WRITE_RTC_REG(SENS_SAR_MEAS_WAIT2_REG, SENS_FORCE_XPD_SAR_S, 2, SENS_FORCE_XPD_SAR_PU)

	/* r1, r2 will be used as accumulator */
	move r1, 0
	move r2, 0	
	/* initialize the loop counter */
	move r0, 0
measure0:
	/* Get vp0 */
	adc r3, 0, 1
	/* Add vp0 to R1 */
	add r1, r1, r3

	/* Get vn0 */
	adc r3, 0, 4
	/* Add vn0 to R2 */
	add r2, r2, r3

	/* Increment counter */
	add r0, r0, 1
	/* Jump to phase 1 measure only if counter > 4 */
	jumpr measure0, adc_oversampling_factor, lt

	/* Getting averages on R1 and R2 */
	rsh r1, r1, adc_oversampling_factor_log
	rsh r2, r2, adc_oversampling_factor_log

	/* Resetting loop counter */
	move r0, 0

	/* RTC_IO_HALL_PHASE = 1, phase of hall sensor */
	WRITE_RTC_REG(RTC_IO_HALL_SENS_REG, RTC_IO_HALL_PHASE_S, 1, 1)

measure1:
	/* Get vp1 */
	adc r3, 0, 1
	/* Getting average part of this vp1 reading */
	rsh r3, r3, adc_oversampling_factor_log
	/* Subtracting value from R1 so in the end it comes R1 = (Vp0 - Vp1) */
	sub r1, r1, r3

	/* Get vn1 */
	adc r3, 0, 4
	/* Getting average part of this vn1 reading */
	rsh r3, r3, adc_oversampling_factor_log
	/* Subtracting value from R2 so in the end it comer R2 = (Vn0 - Vn1) */
	sub r2, r2, r3

	/* Increment counter */
	add r0, r0, 1

	/* Jump to next stuff only if counter > 4 */
	jumpr measure1, adc_oversampling_factor, lt

	/* Getting offset value = (Vp0 - Vp1) - (Vn0 - Vn1) */
	sub r0, r1, r2

	/* Getting absolute value from offset */
	jumpr threshold_compare, 32767, lt
	move r1, 65535
	sub r0, r1, r0
	add r0, r0, 1
threshold_compare:
	/* Comparing to threshold */
	sub r0, r0, threshold
	/* Goes to beginning if r0 is positive */
	jumpr entry, 32767, ge

	wake
	halt