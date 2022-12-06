// STM32F401RE_TIM.c
// TIM functions

#include "STM32L432KC_TIM.h"
#include "STM32L432KC_RCC.h"

void initTIM(TIM_TypeDef * TIMx){
  // Set prescaler to give 1 ms time base
  uint32_t psc_div = (uint32_t) ((SystemCoreClock/1e3));

  // Set prescaler division factor
  TIMx->PSC = (psc_div - 1);
  // Generate an update event to update prescaler value
  TIMx->EGR |= 1;
  // Enable counter
  TIMx->CR1 |= 1; // Set CEN = 1
}

void delay_millis(TIM_TypeDef * TIMx, uint32_t ms){
  TIMx->ARR = ms;// Set timer max count
  TIMx->EGR |= 1;     // Force update
  TIMx->SR &= ~(0x1); // Clear UIF
  TIMx->CNT = 0;      // Reset count

  while(!(TIMx->SR & 1)); // Wait for UIF to go high
}

void TIM2_Config(uint32_t ARR_val){
  RCC->APB1ENR1 |= _VAL2FLD(RCC_APB1ENR1_TIM2EN, 0b1); //Enable clk to TIM2
  
  //pinMode(5, GPIO_ALT); // Pin 0 uses alt func

  //GPIOA->AFRL &= ~(0b1111 << 20); // Clear AFSEL5
  //GPIOA->AFRL |= (0b0001 << 20); // Set AFSEL5 to AF1
  
  //GPIOA->AFRL &= ~GPIO_AFRL_AFSEL5;
  //GPIOA->AFRL |= _VAL2FLD(GPIO_AFRL_AFSEL5, 0b0001);

  // Counter runs at 100 Hz
  // = 80MHz/(80*10000)
  //Test1: wavegen 1hz, sampling at 64hz, we see one period in memory
  TIM2->PSC |= _VAL2FLD(TIM_PSC_PSC, 5); //Set Prescalar to 80
  TIM2->ARR &= ~TIM_ARR_ARR_Msk;
  TIM2->ARR |= _VAL2FLD(TIM_ARR_ARR, ARR_val); //Set ARR to 10000
  

  TIM2->CR1 &= ~TIM_CR1_DIR_Msk; //Counter used as upcounter
  TIM2->CR1 &= ~TIM_CR1_CMS_Msk; //Depends on DIR register

  TIM2->CR2 &= ~TIM_CR2_MMS_Msk; //Clear MMS
  TIM2->CR2 |= _VAL2FLD(TIM_CR2_MMS, 0b010); //update event set a trigger output
  TIM2->EGR |= _VAL2FLD(TIM_EGR_UG, 0b1);

  TIM2->CR1 |= _VAL2FLD(TIM_CR1_CEN, 0b1);
  
}