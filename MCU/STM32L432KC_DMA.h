// STM32L432KC_DMA.h
// Header for DMA functions

#ifndef STM32L4_DMA_H
#define STM32L4_DMA_H

#include <stdint.h> // Include stdint header
#include <stm32l432xx.h>
static volatile uint8_t dma_adc_sample[64];
static volatile uint8_t test[4];
//uint8_t finished;

void configureDMA();
void DMA1_Channel1_IRQHandler(void);
void dma1_ch3_init();
void spi_transfer_dma();
//void DMA1_Channel3_IRQHandler(void);

#endif