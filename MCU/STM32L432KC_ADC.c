// STM32L432KC_ADC.c
// Source code for ADC functions

#include "STM32L432KC_ADC.h"
#include "STM32L432KC_RCC.h"
#include "STM32L432KC_GPIO.h"

void delay(int ms)
{
    while(ms-- > 0){
      volatile int x = 1000;
      while(x-- > 0)
        __asm("nop");
    }
}

void configureADC(){
  //RCC->CCIPR |= _VAL2FLD(RCC_CCIPR_ADCSEL, 0b11);
  RCC->AHB2ENR |= _VAL2FLD(RCC_AHB2ENR_ADCEN, 0b1); //Enable SysClk to ADC
  ADC1->CFGR &= ~ADC_CFGR_DMACFG_Msk;
  ADC1->CFGR |= ADC_CFGR_DMAEN_Msk;

  ADC1->CFGR |= ADC_CFGR_DMACFG_Msk;
  ADC1->CFGR |= ADC_CFGR_DMAEN_Msk;
  //Setup
  ADC1->CR &= ~ADC_CR_ADEN_Msk; //Disable ADC
  ADC1->CR &= ~ADC_CR_DEEPPWD_Msk; //Exit Deep power mode
  ADC1->CR |= _VAL2FLD(ADC_CR_ADVREGEN, 0b1); //Enable ADC internal voltage regulator
  // T startup: 20 microseconds
  delay(20);
  //ADC1->DIFSEL &= ~ADC_DIFSEL_DIFSEL_5; //Set Channel 5 to single-ended input channel
  
  //Calibration
  //ADC1->CR &= ~ADC_CR_ADEN_Msk; //Ensure ADC is disabled
  ADC1->CR &= ~ADC_CR_ADCALDIF_Msk; //Calibration on single-ended input mode
  ADC1->CR |= _VAL2FLD(ADC_CR_ADCAL, 0b1); //Begin calibration
  RCC->CCIPR |= _VAL2FLD(RCC_CCIPR_ADCSEL, 0b11);
  while(_FLD2VAL(ADC_CR_ADCAL, ADC1->CR) != 0); //wait until calibration is completed (ADCAL == 0)
  
  //delay(20);
  //// Waiting for ADC to be ready
  ADC1->ISR |= _VAL2FLD(ADC_ISR_ADRDY, 0b1); //Clearing ADRDY bit by writing 1
  ADC1->CR |= _VAL2FLD(ADC_CR_ADEN, 0b1); //Enable the ADC
  while(_FLD2VAL(ADC_ISR_ADRDY, ADC1->ISR) == 0); //wait until the ADC is ready (ADRDY == 1)

  
  // Defining number of conversions, channels, and sampling speed
  ADC1->SQR1 &= ~ADC_SQR1_L_Msk; //sequence only has 1 conversion
  ADC1->SQR1 &= ~ADC_SQR1_SQ1_Msk; // clear SQ1
  ADC1->SQR1 |= _VAL2FLD(ADC_SQR1_SQ1, 5); //1st & only conversion takes from analog channel 5
  ADC1->SMPR1 &= ~ADC_SMPR1_SMP1_Msk; //clear SMPR1
  ADC1->SMPR1 |= _VAL2FLD(ADC_SMPR1_SMP1, 0b010); //Sampling @80 MHz and 12.5 ADC clock cycles
  
  // TIMER trigger and not continuous mode
  ADC1->CFGR &= ~ADC_CFGR_CONT_Msk; //Continuous conversion mode off since using TIM2 to signal conversions
  ADC1->CFGR &= ~ADC_CFGR_EXTSEL_Msk; //Clear EXTSEL
  ADC1->CFGR |= _VAL2FLD(ADC_CFGR_EXTSEL, 0b1011); //Set EXTSEL to 1011:TIM2_TRGO
  ADC1->CFGR &= ~ADC_CFGR_EXTEN_Msk; //CLear EXTEN before setting trigger dectection to PWM rising edge
  ADC1->CFGR |= _VAL2FLD(ADC_CFGR_EXTEN, 0b01); //Begin conversion on TIM2 rising edge
  
  //ADC1->CFGR &= ~ADC_CFGR_CONT_Msk; //Continuous conversion mode off 
  //ADC1->CFGR &= ~ADC_CFGR_EXTEN_Msk; //Software triggered conversion
  
  ADC1->CFGR |= _VAL2FLD(ADC_CFGR_RES, 0b11);

  // Waiting for ADC to be ready
  //ADC1->ISR |= _VAL2FLD(ADC_ISR_ADRDY, 0b1); //Clearing ADRDY bit by writing 1
  //ADC1->CR |= _VAL2FLD(ADC_CR_ADEN, 0b1); //Enable the ADC
  //while(_FLD2VAL(ADC_ISR_ADRDY, ADC1->ISR) == 0); //wait until the ADC is ready (ADRDY == 1)
}

uint16_t sampleSignal(){
  
  ADC1->CR |= _VAL2FLD(ADC_CR_ADSTART, 0b1); //Start ADC conversion
  while(_FLD2VAL(ADC_ISR_EOS, ADC1->ISR) == 0); //Wait for ADC conversion to be complete: EOC = 1
  //digitalWrite(PA10,1);
  //digitalWrite(PA10,0);
  //while(~ ADC_ISR_EOC); //ADC conversion completed: EOS = 1
  ADC1->ISR |= _VAL2FLD(ADC_ISR_EOS, 0b1);
  return (uint16_t)(_FLD2VAL(ADC_DR_RDATA, ADC1->DR));
  //ADC1->CR |= _VAL2FLD(ADC_CR_ADSTP, 0b1);
}