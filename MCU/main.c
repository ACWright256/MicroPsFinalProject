/*********************************************************************
*                    SEGGER Microcontroller GmbH                     *
*                        The Embedded Experts                        *
**********************************************************************

-------------------------- END-OF-HEADER -----------------------------

File    : main.c
Purpose : Generic application start

*/
#include "STM32L432KC.h"
#include "STM32L432KC_DMA.h"
#include <stdio.h>
#include <stdlib.h>

//static volatile uint8_t dma_adc_sample[64];
/*********************************************************************
*
*       main()
*
*  Function description
*   Application entry point.
*/

int main(void) {
  configureFlash();
  configureClock();
  RCC->APB2ENR |= _VAL2FLD(RCC_APB2ENR_TIM1EN, 0b1);
  initTIM(TIM1);

  gpioADCpin(); //set PA0 to analog input and clock to GPIOA
  TIM2_Config(); //set TIM2 up to be used as the trigger for ADC conversion
  configureDMA(); //initializing DMA for ADC to mem
  configureADC();

  initSPI(1,0,0); // polarity and phase 0, baud rate: fpclk/4
  dma1_ch3_init(); //initializing DMA for mem to SPI
  
  uint16_t data = 0;
  uint16_t test = 0;
  //uint8_t finished;
  // SPI and DMA
  //initSPI(1,0,0); // polarity and phase 0, baud rate: fpclk/4
  uint8_t SPI_count = 0;
  uint8_t ADC_count = 0;
  uint8_t count = 0;
  digitalWrite(PA11, 0);
  pinMode(PA7,GPIO_OUTPUT);
  while(1){
    //printf("%i\n",data);
    ////data = sampleSignal();

    DMA1_Channel1->CCR |= DMA_CCR_EN_Msk;
    for(ADC_count = 0; ADC_count < 64; ADC_count++){
      data = sampleSignal();
      printf("%i\n",data);
    }
    DMA1_Channel1->CCR &= ~DMA_CCR_EN_Msk;
    
    digitalWrite(PA7, 1);

    spi_transfer_dma();
    //finished = 1;
    while(finished==0);
    finished = 0;
    
    delay_millis(TIM1,2000);

    //digitalWrite(PA11, PIO_HIGH);

    //DMA1_Channel3->CCR |= DMA_CCR_EN_Msk;
    
    //while(_FLD2VAL(DMA_ISR_TCIF3, DMA1->ISR) == 0);
    //DMA1->IFCR |= DMA_IFCR_CTCIF3_Msk;
    //DMA1_Channel3->CCR &= ~DMA_CCR_EN_Msk;
    //digitalWrite(PA11, PIO_LOW);
    

    //delay_millis(TIM1,2000);
    //for(SPI_count = 0; SPI_count < 64; SPI_count++){
    //  while(!(SPI1->SR & SPI_SR_TXE)); // Wait until the transmit buffer is empty
      //*(volatile char *) (&SPI1->DR) = dma_adc_sample[SPI_count];
      //while(!(SPI1->SR & SPI_SR_RXNE)); // Wait until data has been received
      //char rec = (volatile char) SPI1->DR;
    //}
    
  }
}

void DMA1_Channel3_IRQHandler(void){
  // DMA transfer complete
  if(_FLD2VAL(DMA_ISR_TCIF3, DMA1->ISR)){
    finished = 1;
    digitalWrite(PA7, 0);
    printf("%i\n",finished);
    printf("finished transfered\r\n");
    DMA1->IFCR |= DMA_IFCR_CTCIF3_Msk;
    DMA1_Channel3->CCR &= ~DMA_CCR_EN_Msk;
  }

  // DMA transfer error
  //if(_FLD2VAL(DMA_ISR_TEIF3, DMA1->ISR)){
  //  DMA1->IFCR |= DMA_IFCR_CTEIF3_Msk;
  //}
}


/*************************** End of file ****************************/

 

 
//// Driver code to test above function
//int main()
//{
//    int i;
//    for (i = 0; i < 10; i++) {
//        // delay of one second
//        delay(1000);
//        printf("%d seconds have passed\n", i + 1);
//    }
//    return 0;
//}