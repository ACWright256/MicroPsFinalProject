// STM32L432KC_DMA.c
// Source code for DMA functions

#include "STM32L432KC_ADC.h"
#include "STM32L432KC_RCC.h"
#include "STM32L432KC_GPIO.h"
#include "STM32L432KC_DMA.h"

#include <stm32l432xx.h>
static volatile uint8_t dma_adc_sample[64];
static volatile uint8_t test[4] = {0, 1, 2, 3};


void configureDMA(){
  RCC->AHB1ENR |= _VAL2FLD(RCC_AHB1ENR_DMA1EN, 0b1); //DMA clock
  //ADC1->CFGR |= ADC_CFGR_DMACFG_Msk;
  //ADC1->CFGR |= ADC_CFGR_DMAEN_Msk;
  
  DMA1_CSELR->CSELR &= ~DMA_CSELR_C1S_Msk; //ADC1 on channel 1
  //Channel 1 configurations
  DMA1_Channel1->CCR &= ~DMA_CCR_PL_Msk;
  DMA1_Channel1->CCR |= _VAL2FLD(DMA_CCR_PL, 0b10); //Setting Priority level
  DMA1_Channel1->CCR |= _VAL2FLD(DMA_CCR_MINC, 0b1); //Setting address increment
  DMA1_Channel1->CCR |= _VAL2FLD(DMA_CCR_CIRC, 0b1); //Setting circular addressing (loops back around)
  DMA1_Channel1->CCR &= ~DMA_CCR_DIR_Msk; //Read from peripheral
  
  DMA1_Channel1->CMAR = _VAL2FLD(DMA_CMAR_MA,(uint32_t) &dma_adc_sample);
  DMA1_Channel1->CPAR = _VAL2FLD(DMA_CPAR_PA,(uint32_t) &(ADC1->DR));

  DMA1_Channel1->CNDTR |= _VAL2FLD(DMA_CNDTR_NDT, 64);  

  NVIC_SetPriority(DMA1_Channel1_IRQn, 1); 
  NVIC_EnableIRQ(DMA1_Channel1_IRQn);

  DMA1_Channel1->CCR |= DMA_CCR_TCIE_Msk;
  DMA1_Channel1->CCR |= DMA_CCR_TEIE_Msk;

  //DMA1_Channel1->CCR |= DMA_CCR_EN_Msk;
}

void dma1_ch3_init(){
  //Channel 3 configurations: SPI
  //TODO
  DMA1_CSELR->CSELR &= ~DMA_CSELR_C3S_Msk; 
  DMA1_CSELR->CSELR |= _VAL2FLD(DMA_CSELR_C3S, 0b0001); //SPI1TX on channel 3
  
  DMA1_Channel3->CCR &= (DMA_CCR_PL | DMA_CCR_MINC | DMA_CCR_CIRC | DMA_CCR_DIR); //clear registers
  DMA1_Channel3->CCR |= _VAL2FLD(DMA_CCR_PL, 0b10); //Priority level high
  DMA1_Channel3->CCR |= _VAL2FLD(DMA_CCR_MINC, 0b1); //Increment address
  //DMA1_Channel3->CCR |= _VAL2FLD(DMA_CCR_CIRC, 0b1); //Setting circular addressing (loops back around)
  DMA1_Channel3->CCR |= _VAL2FLD(DMA_CCR_DIR, 0b1); //Read from memory

  //DMA1_Channel3->CMAR = _VAL2FLD(DMA_CMAR_MA,(uint32_t) &dma_adc_sample);
  //DMA1_Channel3->CMAR = _VAL2FLD(DMA_CMAR_MA,(uint32_t) &test);
  //DMA1_Channel3->CPAR = _VAL2FLD(DMA_CPAR_PA,(uint32_t) &(SPI1->DR));
  
  //DMA1_Channel3->CNDTR |= _VAL2FLD(DMA_CNDTR_NDT, 64);
  //DMA1_Channel3->CNDTR |= _VAL2FLD(DMA_CNDTR_NDT, 4);

  NVIC_SetPriority(DMA1_Channel3_IRQn, 1); 
  NVIC_EnableIRQ(DMA1_Channel3_IRQn);

  DMA1_Channel3->CCR |= DMA_CCR_TCIE_Msk;
  //DMA1_Channel3->CCR |= DMA_CCR_TEIE_Msk;

  //DMA1_Channel3->CCR |= DMA_CCR_EN_Msk;
}

void spi_transfer_dma(){
  //finished = 0;
  DMA1->IFCR |= DMA_IFCR_CTCIF3_Msk; //clear interrupt
  DMA1_Channel3->CMAR = _VAL2FLD(DMA_CMAR_MA,(uint32_t) &dma_adc_sample);
  DMA1_Channel3->CPAR = _VAL2FLD(DMA_CPAR_PA,(uint32_t) &(SPI1->DR));
  DMA1_Channel3->CNDTR |= _VAL2FLD(DMA_CNDTR_NDT, 64);
  DMA1_Channel3->CCR |= DMA_CCR_EN_Msk;
}

void DMA1_Channel1_IRQHandler(void){
  // DMA transfer complete
  if(_FLD2VAL(DMA_ISR_TCIF1, DMA1->ISR)){
    DMA1->IFCR |= DMA_IFCR_CTCIF1_Msk;
  }

  // DMA transfer error
  //if(_FLD2VAL(DMA_ISR_TEIF1, DMA1->ISR)){
  //  DMA1->IFCR |= DMA_IFCR_CTEIF1_Msk;
  //}
}

//void DMA1_Channel3_IRQHandler(void){
//  // DMA transfer complete
//  if(_FLD2VAL(DMA_ISR_TCIF3, DMA1->ISR)){
//    finished = 1;
//    printf("%i\n",finished);
//    printf("finished transfered\r\n");
//    DMA1->IFCR |= DMA_IFCR_CTCIF3_Msk;
//    DMA1_Channel3->CCR &= ~DMA_CCR_EN_Msk;
//  }

//  // DMA transfer error
//  //if(_FLD2VAL(DMA_ISR_TEIF3, DMA1->ISR)){
//  //  DMA1->IFCR |= DMA_IFCR_CTEIF3_Msk;
//  //}
//}