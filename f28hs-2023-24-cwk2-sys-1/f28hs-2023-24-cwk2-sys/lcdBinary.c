#define	PAGE_SIZE		(4*1024)
#define	BLOCK_SIZE		(4*1024)

#define	INPUT			 0
#define	OUTPUT			 1

#define	LOW			 0
#define	HIGH			 1


// APP constants   ---------------------------------

// Wiring (see call to lcdInit in main, using BCM numbering)
// NB: this needs to match the wiring as defined in master-mind.c

#define STRB_PIN 24
#define RS_PIN   25
#define DATA0_PIN 23
#define DATA1_PIN 10
#define DATA2_PIN 27
#define DATA3_PIN 22

// -----------------------------------------------------------------------------
// includes 
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/types.h>
#include <time.h>

// -----------------------------------------------------------------------------
// prototypes


/* send a @value@ (LOW or HIGH) on pin number @pin@; @gpio@ is the mmaped GPIO base address */
void digitalWrite(uint32_t *gpio, int pin, int value) {
    if (value == LOW) { //if value is set to LOW
        asm volatile (
            //load value 1 into r2
            "mov r2, #1\n\t"
            //left shift the value in r2 by pin number
            "lsl r2, %[pin]\n\t"
            //storing the value in r2 to the GPIO register at offset 40 bytes
            "str r2, [%[gpio], #40]" 
            :
            : [gpio] "r" (gpio), [pin] "r" (pin)
            : "r2", "memory"
        );
    } else { // if value is HIGH
        asm volatile (
            //load the value 1 into r2
            "mov r2, #1\n\t"
            //left shift by pin number 
            "lsl r2, %[pin]\n\t"
            //storing value in r2 at offser 28 bytes
            "str r2, [%[gpio], #28]" 
            :
            : [gpio] "r" (gpio), [pin] "r" (pin)
            : "r2", "memory"
        );
    }
}



/* set the @mode@ of a GPIO @pin@ to INPUT or OUTPUT; @gpio@ is the mmaped GPIO base address */
void pinMode(uint32_t *gpio, int pin, int mode) {
    int register_offset = pin / 10;  //calculating register offset for GPIO pin
    int bit_offset = (pin % 10) * 3; //calculating the but offset within the register
    
    if (mode == OUTPUT) {
        asm volatile (
            //loading the value from GPIO register at the specified offset into r3
            "ldr r3, [%[gpio], %[offset]]\n\t"
            //load value 1 to r2
            "mov r2, #1\n\t"
            //ledt shift
            "lsl r2, %[bit_offset]\n\t"
            //OR the value in r3 with the value in r2 to set bit to 1  
            "orr r3, r3, r2\n\t" 
            //storing value backto the GPIO register
            "str r3, [%[gpio], %[offset]]\n\t"
            :
            : [gpio] "r" (gpio), [offset] "r" (register_offset * 4), [bit_offset] "r" (bit_offset)
            : "r2", "r3", "memory"
        );
    } else {  //MODE IS INPUT 
        asm volatile (
            //loading thevalue from GPIO register 
            "ldr r3, [%[gpio], %[offset]]\n\t"
            // Load the value 7 into register r2 (111 in binary to clear pin to 0)
            "mov r2, #7\n\t"
            //left shift
            "lsl r2, %[bit_offset]\n\t"
            //inverting the bits to create a mask
            "mvn r2, r2\n\t" 
            //AND operation in r3
            "and r3, r3, r2\n\t" 
            //storing modified value bcakto GPIO register
            "str r3, [%[gpio], %[offset]]\n\t"
            :
            : [gpio] "r" (gpio), [offset] "r" (register_offset * 4), [bit_offset] "r" (bit_offset)
            : "r2", "r3", "memory"
        );
    }
}


/* send a @value@ (LOW or HIGH) on pin number @pin@; @gpio@ is the mmaped GPIO base address */
/* can use digitalWrite(), depending on your implementation */
void writeLED(uint32_t *gpio, int led, int value) {
    if (value == HIGH) {
        asm volatile (
            "mov r2, #1\n\t"
            //left shift the value in r2 by the LED number to get pin mask
            "lsl r2, %[led]\n\t"
            //storing pin mask at offset
            "str r2, [%[gpio], #28]" 
            :
            : [gpio] "r" (gpio), [led] "r" (led)
            : "r2", "memory"
        );
    } else {  //value == LOW
        asm volatile (
            "mov r2, #1\n\t"
            "lsl r2, %[led]\n\t"
            //store the pin mask value in r2 to the GPIO register at offset 40
            "str r2, [%[gpio], #40]" 
            :
            : [gpio] "r" (gpio), [led] "r" (led)
            : "r2", "memory"
        );
    }
}


/* read a @value@ (OFF or ON) from pin number @pin@ (a button device); @gpio@ is the mmaped GPIO base address */
int readButton(uint32_t *gpio, int pin) {
    int value;
    asm volatile (
        //load the value of the GPIO register at offset 52 into register r2
        "ldr r2, [%[gpio], #52]\n\t" 
        "mov r3, #1\n\t"
        //left shift to get the pin mask
        "lsl r3, %[pin]\n\t" 
        //AND operation between r2 & r3, result is stored in value variable
        "and %[value], r2, r3\n\t" 
        //compare value with 0
        "cmp %[value], #0\n\t"
        //if the result of the comparison is equal, move 0 into value
        "moveq %[value], #0\n\t" 
        // If the result of the comparison is not equal, move 1 into value
        "movne %[value], #1\n\t" 
        : [value] "=r" (value)  
        : [gpio] "r" (gpio), [pin] "r" (pin) 
        : "r2", "r3", "cc" 
    );
    return value;
}