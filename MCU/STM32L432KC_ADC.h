// STM32L432KC_ADC.h
// Header for ADC functions

#ifndef STM32L4_ADC_H
#define STM32L4_ADC_H

#include <stdint.h> // Include stdint header
#include <stm32l432xx.h>


void configureADC();

uint16_t sampleSignal();

#endif